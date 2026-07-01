#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  07 - ALB, Target Groups y Reglas"
echo "========================================"

source .env

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
echo "ALB_ARN=$ALB_ARN" >> .env
ALB_DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns "$ALB_ARN" --query "LoadBalancers[0].DNSName" --output text)
echo "ALB_DNS=$ALB_DNS" >> .env
echo "  DNS: $ALB_DNS"

# ─── Target Groups ───
declare -A TGS
TGS["tg-frontend"]="8080:/"
TGS["tg-back-ventas"]="8080:/api/v1/ventas"
TGS["tg-back-despachos"]="8081:/api/v1/despachos"

for TG_NAME in "${!TGS[@]}"; do
    IFS=':' read -r PORT PATH <<< "${TGS[$TG_NAME]}"
    TG_ARN=$(aws elbv2 describe-target-groups --names "$TG_NAME" --query "TargetGroups[0].TargetGroupArn" --output text 2>/dev/null || echo "")
    if [ -z "$TG_ARN" ]; then
        echo "Creando target group $TG_NAME (puerto $PORT, health $PATH)..."
        TG_ARN=$(aws elbv2 create-target-group \
            --name "$TG_NAME" \
            --protocol HTTP \
            --port "$PORT" \
            --target-type ip \
            --vpc "$VPC_ID" \
            --health-check-path "$PATH" \
            --health-check-interval-seconds 30 \
            --health-check-timeout-seconds 5 \
            --healthy-threshold-count 2 \
            --unhealthy-threshold-count 2 \
            --query "TargetGroups[0].TargetGroupArn" --output text)
        echo "  TG creado: $TG_ARN"
    else
        echo "  TG $TG_NAME ya existe: $TG_ARN"
    fi
    # Store in env with sanitized name
    SAFE_NAME=$(echo "$TG_NAME" | tr '-' '_' | tr '[:lower:]' '[:upper:]')
    echo "${SAFE_NAME}_ARN=$TG_ARN" >> .env
    echo "  ${SAFE_NAME}_ARN=$TG_ARN"
done

# ─── Listener HTTP:80 ───
LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "$ALB_ARN" --query "Listeners[?Port==\`80\`].ListenerArn" --output text 2>/dev/null || echo "")
# Re-read TGs ARNs from env
source .env

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
fi
echo "LISTENER_ARN=$LISTENER_ARN" >> .env

# ─── Reglas de path-based routing ───
# Obtener prioridades existentes
EXISTING_RULES=$(aws elbv2 describe-rules --listener-arn "$LISTENER_ARN" --query "Rules[?Priority!='default'].Priority" --output text)

# Regla 1: /api/v1/ventas* → tg-back-ventas
RULE_VENTAS=$(aws elbv2 describe-rules --listener-arn "$LISTENER_ARN" --query "Rules[?contains(conditions[0].values[0],'/api/v1/ventas')].RuleArn" --output text 2>/dev/null || echo "")
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
RULE_DESPACHOS=$(aws elbv2 describe-rules --listener-arn "$LISTENER_ARN" --query "Rules[?contains(conditions[0].values[0],'/api/v1/despachos')].RuleArn" --output text 2>/dev/null || echo "")
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
