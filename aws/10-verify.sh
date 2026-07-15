#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  10 - Verificación de Infraestructura"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_functions.sh"
load_env

PASS=0
FAIL=0
WARN=0
TOTAL=0

pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); TOTAL=$((TOTAL + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); }
warn() { echo "  ⚠️  $1"; WARN=$((WARN + 1)); TOTAL=$((TOTAL + 1)); }

# El curl incluido con algunas versiones de Git Bash puede no alcanzar el ALB,
# aunque el curl nativo de Windows sí tenga conectividad.
CURL_BIN="curl"
WINDOWS_GIT_BASH=false
if [[ "${OSTYPE:-}" == msys* ]] && [ -x /c/Windows/System32/curl.exe ]; then
    CURL_BIN="/c/Windows/System32/curl.exe"
    WINDOWS_GIT_BASH=true
fi

check_http() {
    local url="$1"
    if [ "$WINDOWS_GIT_BASH" = "true" ]; then
        powershell.exe -NoProfile -Command \
            "try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 20 -Uri '$url' | Out-Null; exit 0 } catch { exit 1 }"
    else
        "$CURL_BIN" --fail --connect-timeout 10 --max-time 20 -s -o /dev/null "$url"
    fi
}

CLUSTER_STATUS=$(aws ecs describe-clusters \
    --clusters "$ECS_CLUSTER" \
    --query "clusters[0].status" \
    --output text 2>/dev/null || true)
[ "$CLUSTER_STATUS" = "ACTIVE" ] && pass "Cluster ECS activo" || fail "Cluster ECS no está activo"

for SERVICE in frontend-service back-ventas-service back-despachos-service mysql-service; do
    STATUS=$(aws ecs describe-services \
        --cluster "$ECS_CLUSTER" \
        --services "$SERVICE" \
        --query "services[0].status" \
        --output text 2>/dev/null || true)
    RUNNING=$(aws ecs describe-services \
        --cluster "$ECS_CLUSTER" \
        --services "$SERVICE" \
        --query "services[0].runningCount" \
        --output text 2>/dev/null || echo 0)

    if [ "$STATUS" = "ACTIVE" ]; then
        pass "$SERVICE está ACTIVE"
    else
        fail "$SERVICE no está ACTIVE"
    fi

    if [[ "$RUNNING" =~ ^[0-9]+$ ]] && [ "$RUNNING" -ge 1 ]; then
        pass "$SERVICE tiene al menos una tarea RUNNING"
    else
        fail "$SERVICE no tiene tareas RUNNING"
    fi
done

for TG in tg-frontend tg-back-ventas tg-back-despachos; do
    TG_ARN=$(aws elbv2 describe-target-groups \
        --names "$TG" \
        --query "TargetGroups[0].TargetGroupArn" \
        --output text 2>/dev/null || true)
    if [ -z "$TG_ARN" ] || [ "$TG_ARN" = "None" ]; then
        fail "$TG no existe"
        continue
    fi

    HEALTHY=$(aws elbv2 describe-target-health \
        --target-group-arn "$TG_ARN" \
        --query "length(TargetHealthDescriptions[?TargetHealth.State=='healthy'])" \
        --output text 2>/dev/null || echo 0)
    if [[ "$HEALTHY" =~ ^[0-9]+$ ]] && [ "$HEALTHY" -ge 1 ]; then
        pass "$TG tiene targets saludables"
    else
        warn "$TG todavía no tiene targets saludables"
    fi
done

ALB_DNS=$(aws elbv2 describe-load-balancers \
    --names alb-innovatech \
    --query "LoadBalancers[0].DNSName" \
    --output text 2>/dev/null || true)

if [ -n "$ALB_DNS" ] && [ "$ALB_DNS" != "None" ]; then
    for SPEC in "/:Frontend" "/api/v1/ventas:API_Ventas" "/api/v1/despachos:API_Despachos"; do
        PATH_PART=${SPEC%%:*}
        LABEL=${SPEC#*:}
        if check_http "http://$ALB_DNS$PATH_PART"; then
            pass "$LABEL responde correctamente"
        else
            fail "$LABEL no responde correctamente"
        fi
    done
else
    fail "ALB alb-innovatech no encontrado"
fi

for SERVICE in frontend-service back-ventas-service back-despachos-service; do
    COUNT=$(aws application-autoscaling describe-scaling-policies \
        --service-namespace ecs \
        --resource-id "service/$ECS_CLUSTER/$SERVICE" \
        --scalable-dimension ecs:service:DesiredCount \
        --query "length(ScalingPolicies)" \
        --output text 2>/dev/null || echo 0)
    if [[ "$COUNT" =~ ^[0-9]+$ ]] && [ "$COUNT" -ge 2 ]; then
        pass "$SERVICE tiene sus dos políticas de autoscaling"
    else
        warn "$SERVICE tiene $COUNT políticas de autoscaling; se esperaban 2"
    fi
done

for LOG_GROUP in "/ecs/innovatech/frontend" "/ecs/innovatech/back-ventas" "/ecs/innovatech/back-despachos" "/ecs/innovatech/mysql"; do
    FOUND=$(aws logs describe-log-groups \
        --log-group-name-prefix "$LOG_GROUP" \
        --query "logGroups[?logGroupName=='$LOG_GROUP'].logGroupName" \
        --output text 2>/dev/null || true)
    [ "$FOUND" = "$LOG_GROUP" ] && pass "Existe $LOG_GROUP" || fail "No existe $LOG_GROUP"
done

echo ""
echo "Resultado: $PASS correctos, $WARN advertencias, $FAIL fallidos, $TOTAL comprobaciones."
[ "$FAIL" -eq 0 ]
