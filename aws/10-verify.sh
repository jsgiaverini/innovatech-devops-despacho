#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  10 - Verificación de Infraestructura"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env" 2>/dev/null || source .env
source "$SCRIPT_DIR/_functions.sh" 2>/dev/null || true

PASS=0
FAIL=0
TOTAL=0

check() {
    TOTAL=$((TOTAL + 1))
    local desc="$1"
    shift
    if eval "$@" 2>/dev/null; then
        echo "  ✅ $desc"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "─────────────────────────────────────────"
echo "  1. Servicios ECS"
echo "─────────────────────────────────────────"
check "ECS Cluster existe" \
    aws ecs describe-clusters --clusters "$ECS_CLUSTER" --query "clusters[0].clusterName" --output text 2>/dev/null | grep -q "$ECS_CLUSTER"

for svc in frontend-service back-ventas-service back-despachos-service mysql-service; do
    check "Servicio $svc está ACTIVE" \
        aws ecs describe-services --cluster "$ECS_CLUSTER" --services "$svc" \
        --query "services[0].status" --output text 2>/dev/null | grep -q "ACTIVE"
done

for svc in frontend-service back-ventas-service back-despachos-service; do
    check "Servicio $svc tiene tareas RUNNING" \
        test "$(aws ecs describe-services --cluster "$ECS_CLUSTER" --services "$svc" \
        --query "services[0].runningCount" --output text 2>/dev/null)" -ge 1
done

echo ""
echo "─────────────────────────────────────────"
echo "  2. Target Groups (Health Checks)"
echo "─────────────────────────────────────────"
for tg in tg-frontend tg-back-ventas tg-back-despachos; do
    TG_ARN=$(aws elbv2 describe-target-groups --names "$tg" --query "TargetGroups[0].TargetGroupArn" --output text 2>/dev/null || echo "")
    if [ -n "$TG_ARN" ] && [ "$TG_ARN" != "None" ]; then
        HEALTHY=$(aws elbv2 describe-target-health --target-group-arn "$TG_ARN" \
            --query "length(TargetHealthDescriptions[?TargetHealth.State=='healthy'])" --output text 2>/dev/null || echo "0")
        if [ "$HEALTHY" -ge 1 ]; then
            echo "  ✅ $tg → $HEALTHY healthy"
            PASS=$((PASS + 1))
        else
            echo "  ⚠️  $tg → 0 healthy (puede estar inicializando)"
        fi
    else
        echo "  ❌ $tg → No encontrado"
        FAIL=$((FAIL + 1))
    fi
    TOTAL=$((TOTAL + 1))
done

echo ""
echo "─────────────────────────────────────────"
echo "  3. Endpoints del ALB"
echo "─────────────────────────────────────────"
ALB_DNS=$(aws elbv2 describe-load-balancers --names "alb-innovatech" \
    --query "LoadBalancers[0].DNSName" --output text 2>/dev/null || echo "")

if [ -n "$ALB_DNS" ] && [ "$ALB_DNS" != "None" ]; then
    echo "  ALB DNS: http://$ALB_DNS"

    check "Frontend responde HTTP 200" \
        curl -s -o /dev/null -w "%{http_code}" "http://$ALB_DNS/" | grep -q "200"

    check "Backend Ventas API responde (no 502/503)" \
        curl -s -o /dev/null -w "%{http_code}" "http://$ALB_DNS/api/v1/ventas" | grep -vq "50[23]"

    check "Backend Despachos API responde (no 502/503)" \
        curl -s -o /dev/null -w "%{http_code}" "http://$ALB_DNS/api/v1/despachos" | grep -vq "50[23]"
else
    echo "  ❌ ALB no encontrado"
    FAIL=$((FAIL + 3))
    TOTAL=$((TOTAL + 3))
fi

echo ""
echo "─────────────────────────────────────────"
echo "  4. Autoscaling"
echo "─────────────────────────────────────────"
for svc in frontend-service back-ventas-service back-despachos-service; do
    POLICY_COUNT=$(aws application-autoscaling describe-scaling-policies \
        --service-namespace ecs \
        --resource-id "service/$ECS_CLUSTER/$svc" \
        --scalable-dimension "ecs:service:DesiredCount" \
        --query "length(ScalingPolicies)" --output text 2>/dev/null || echo "0")
    if [ "$POLICY_COUNT" -ge 2 ]; then
        echo "  ✅ $svc → $POLICY_COUNT policies"
        PASS=$((PASS + 1))
    else
        echo "  ⚠️  $svc → $POLICY_COUNT policies (esperado: 2)"
    fi
    TOTAL=$((TOTAL + 1))
done

echo ""
echo "─────────────────────────────────────────"
echo "  5. CloudWatch Log Groups"
echo "─────────────────────────────────────────"
for lg in "/ecs/frontend" "/ecs/back-ventas" "/ecs/back-despachos" "/ecs/mysql"; do
    check "Log group $lg existe" \
        aws logs describe-log-groups --log-group-name-prefix "$lg" \
        --query "length(logGroups)" --output text 2>/dev/null | grep -q "1"
done

echo ""
echo "═════════════════════════════════════════"
echo "  RESUMEN: $PASS/$TOTAL checks pasaron"
echo "═════════════════════════════════════════"

if [ "$FAIL" -eq 0 ]; then
    echo "  🟢 Todo correcto. Infraestructura operativa."
    exit 0
else
    echo "  🟡 $FAIL checks fallaron. Revisar salida arriba."
    exit 1
fi
