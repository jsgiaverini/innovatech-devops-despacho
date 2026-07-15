#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  07 - ALB, Target Groups y Reglas"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_functions.sh"
load_env

# ─── ALB ───
ALB_ARN=$(aws elbv2 describe-load-balancers --names alb-innovatech --query "LoadBalancers[0].LoadBalancerArn" --output text 2>/dev/null || echo "")
if [ -z "$ALB_ARN" ]; then
    echo "Creando ALB alb-innovatech..."
    ALB_ARN=$(aws elbv2 create-load-balancer \
        --name alb-innovatech \
        --scheme internet-facing \
        --ip-address-type ipv4 \
        --subnets "$SUBNET1" "$SUBNET2" \
        --security-groups "$SG_ALB" \
        --query "LoadBalancers[0].LoadBalancerArn" --output text)
    echo "ALB creado: $ALB_ARN"
else
    echo "ALB alb-innovatech ya existe: $ALB_ARN"
fi
set_env "ALB_ARN" "$ALB_ARN"
ALB_DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns "$ALB_ARN" --query "LoadBalancers[0].DNSName" --output text)
set_env "ALB_DNS" "$ALB_DNS"
echo "  DNS: $ALB_DNS"

# ─── Target Groups ───
declare -A TGS
TGS["tg-frontend"]="8080:/"
TGS["tg-back-ventas"]="8080:/actuator/health"
TGS["tg-back-despachos"]="8081:/actuator/health"

for TG_NAME in "${!TGS[@]}"; do
    # No usar PATH como variable: sobrescribiría la ruta de ejecutables y
    # dejaría inaccesible AWS CLI después de la primera iteración.
    IFS=':' read -r PORT HEALTH_PATH <<< "${TGS[$TG_NAME]}"
    TG_ARN=$(aws elbv2 describe-target-groups --names "$TG_NAME" --query "TargetGroups[0].TargetGroupArn" --output text 2>/dev/null || echo "")
    if [ -z "$TG_ARN" ]; then
        echo "Creando target group $TG_NAME (puerto $PORT, health $HEALTH_PATH)..."
        TG_ARN=$(aws elbv2 create-target-group \
            --name "$TG_NAME" \
            --protocol HTTP \
            --port "$PORT" \
            --target-type ip \
            --vpc "$VPC_ID" \
            --health-check-path "$HEALTH_PATH" \
            --health-check-interval-seconds 30 \
            --health-check-timeout-seconds 5 \
            --healthy-threshold-count 2 \
            --unhealthy-threshold-count 2 \
            --query "TargetGroups[0].TargetGroupArn" --output text)
        echo "  TG creado: $TG_ARN"
    else
        echo "  TG $TG_NAME ya existe: $TG_ARN"
        aws elbv2 modify-target-group \
            --target-group-arn "$TG_ARN" \
            --health-check-path "$HEALTH_PATH" \
            --health-check-interval-seconds 30 \
            --health-check-timeout-seconds 5 \
            --healthy-threshold-count 2 \
            --unhealthy-threshold-count 2 >/dev/null
    fi
    # Store in env with sanitized name
    SAFE_NAME=$(echo "$TG_NAME" | tr '-' '_' | tr '[:lower:]' '[:upper:]')
    set_env "${SAFE_NAME}_ARN" "$TG_ARN"
    echo "  ${SAFE_NAME}_ARN=$TG_ARN"
done

# ─── Listener HTTP:80 ───
LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "$ALB_ARN" --query "Listeners[?Port==\`80\`].ListenerArn" --output text 2>/dev/null || echo "")
# Releer los ARN guardados por el ciclo anterior.
load_env

if [ -z "$LISTENER_ARN" ]; then
    echo "Creando listener HTTP:80..."
    LISTENER_ARN=$(aws elbv2 create-listener \
        --load-balancer-arn "$ALB_ARN" \
        --protocol HTTP \
        --port 80 \
        --default-actions "Type=forward,TargetGroupArn=$TG_FRONTEND_ARN" \
        --query "Listeners[0].ListenerArn" --output text)
    echo "Listener creado: $LISTENER_ARN"
else
    echo "Listener HTTP:80 ya existe: $LISTENER_ARN"
    aws elbv2 modify-listener \
        --listener-arn "$LISTENER_ARN" \
        --default-actions "Type=forward,TargetGroupArn=$TG_FRONTEND_ARN" >/dev/null
fi
set_env "LISTENER_ARN" "$LISTENER_ARN"

# ─── Reglas de path-based routing ───
# Regla 1: /api/v1/ventas* → tg-back-ventas
RULE_VENTAS=$(aws elbv2 describe-rules --listener-arn "$LISTENER_ARN" --query "Rules[?contains(Conditions[0].Values[0], '/api/v1/ventas')].RuleArn" --output text 2>/dev/null || echo "")
if [ -z "$RULE_VENTAS" ]; then
    echo "Creando regla /api/v1/ventas*..."
    aws elbv2 create-rule \
        --listener-arn "$LISTENER_ARN" \
        --priority 10 \
        --conditions "Field=path-pattern,Values=['/api/v1/ventas*']" \
        --actions "Type=forward,TargetGroupArn=$TG_BACK_VENTAS_ARN"
else
    echo "Regla /api/v1/ventas* ya existe"
fi

# Regla 2: /api/v1/despachos* → tg-back-despachos
RULE_DESPACHOS=$(aws elbv2 describe-rules --listener-arn "$LISTENER_ARN" --query "Rules[?contains(Conditions[0].Values[0], '/api/v1/despachos')].RuleArn" --output text 2>/dev/null || echo "")
if [ -z "$RULE_DESPACHOS" ]; then
    echo "Creando regla /api/v1/despachos*..."
    aws elbv2 create-rule \
        --listener-arn "$LISTENER_ARN" \
        --priority 20 \
        --conditions "Field=path-pattern,Values=['/api/v1/despachos*']" \
        --actions "Type=forward,TargetGroupArn=$TG_BACK_DESPACHOS_ARN"
else
    echo "Regla /api/v1/despachos* ya existe"
fi

echo ""
echo "ALB configurado correctamente."
echo "  URL: http://$ALB_DNS"
echo "  /api/v1/ventas* → back-ventas:8080"
echo "  /api/v1/despachos* → back-despachos:8081"
echo "  /* → frontend:8080"
