#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  09 - Autoscaling (Target Tracking)"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env" 2>/dev/null || source .env

# ─── Configuración ───
# Min 1 tarea (disponibilidad base)
# Max 3 tareas (límite para laboratorio, evitar cargos excesivos)
# Target CPU 50% (balance rendimiento/costo)
# Target Memory 50% (evitar OOM kills en picos)
# Cooldown 60s (estándar AWS, evita thrashing)
declare -A SERVICES
SERVICES["frontend-service"]="1:3"
SERVICES["back-ventas-service"]="1:3"
SERVICES["back-despachos-service"]="1:3"

echo ""
echo "Registrando scalable targets y creando scaling policies..."
echo ""

for SERVICE in "${!SERVICES[@]}"; do
    IFS=':' read -r MIN MAX <<< "${SERVICES[$SERVICE]}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Servicio: $SERVICE  (min=$MIN, max=$MAX)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # 1. Registrar scalable target
    echo "  [1/3] Registrando scalable target..."
    aws application-autoscaling register-scalable-target \
        --service-namespace ecs \
        --resource-id "service/$ECS_CLUSTER/$SERVICE" \
        --scalable-dimension "ecs:service:DesiredCount" \
        --min-capacity "$MIN" \
        --max-capacity "$MAX" \
        --region "$AWS_REGION" 2>/dev/null \
        && echo "    ✅ Scalable target registrado" \
        || echo "    ⏩ Ya existía"

    # 2. Policy Target Tracking CPU 50%
    echo -n "  [2/3] Policy CPU 50%... "
    POLICY_CPU_NAME="${SERVICE}-cpu-autoscaling"
    if aws application-autoscaling describe-scaling-policies \
        --service-namespace ecs \
        --resource-id "service/$ECS_CLUSTER/$SERVICE" \
        --scalable-dimension "ecs:service:DesiredCount" \
        --policy-names "$POLICY_CPU_NAME" \
        --query "ScalingPolicies[0].PolicyName" --output text 2>/dev/null | grep -q "$POLICY_CPU_NAME"; then
        echo "⏩ Ya existe"
    else
        aws application-autoscaling put-scaling-policy \
            --service-namespace ecs \
            --resource-id "service/$ECS_CLUSTER/$SERVICE" \
            --scalable-dimension "ecs:service:DesiredCount" \
            --policy-name "$POLICY_CPU_NAME" \
            --policy-type TargetTrackingScaling \
            --target-tracking-scaling-policy-configuration '{
                "TargetValue": 50.0,
                "PredefinedMetricSpecification": {
                    "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
                },
                "ScaleOutCooldown": 60,
                "ScaleInCooldown": 60
            }' > /dev/null && echo "✅ Creada"
    fi

    # 3. Policy Target Tracking Memory 50%
    echo -n "  [3/3] Policy Memory 50%... "
    POLICY_MEM_NAME="${SERVICE}-memory-autoscaling"
    if aws application-autoscaling describe-scaling-policies \
        --service-namespace ecs \
        --resource-id "service/$ECS_CLUSTER/$SERVICE" \
        --scalable-dimension "ecs:service:DesiredCount" \
        --policy-names "$POLICY_MEM_NAME" \
        --query "ScalingPolicies[0].PolicyName" --output text 2>/dev/null | grep -q "$POLICY_MEM_NAME"; then
        echo "⏩ Ya existe"
    else
        aws application-autoscaling put-scaling-policy \
            --service-namespace ecs \
            --resource-id "service/$ECS_CLUSTER/$SERVICE" \
            --scalable-dimension "ecs:service:DesiredCount" \
            --policy-name "$POLICY_MEM_NAME" \
            --policy-type TargetTrackingScaling \
            --target-tracking-scaling-policy-configuration '{
                "TargetValue": 50.0,
                "PredefinedMetricSpecification": {
                    "PredefinedMetricType": "ECSServiceAverageMemoryUtilization"
                },
                "ScaleOutCooldown": 60,
                "ScaleInCooldown": 60
            }' > /dev/null && echo "✅ Creada"
    fi
    echo ""
done

echo "═════════════════════════════════════════"
echo "  VERIFICACIÓN FINAL"
echo "═════════════════════════════════════════"
echo ""
printf "%-25s %-10s %-10s %-10s\n" "SERVICIO" "MIN" "MAX" "POLICIES"
echo "─────────────────────────────────────────────────"
for SERVICE in "${!SERVICES[@]}"; do
    IFS=':' read -r MIN MAX <<< "${SERVICES[$SERVICE]}"
    POLICIES=$(aws application-autoscaling describe-scaling-policies \
        --service-namespace ecs \
        --resource-id "service/$ECS_CLUSTER/$SERVICE" \
        --scalable-dimension "ecs:service:DesiredCount" \
        --query "length(ScalingPolicies)" --output text 2>/dev/null || echo "0")
    printf "%-25s %-10s %-10s %-10s\n" "$SERVICE" "$MIN" "$MAX" "$POLICIES"
done

echo ""
echo "═════════════════════════════════════════"
echo "  AUTOSCALING CONFIGURADO EXITOSAMENTE"
echo "═════════════════════════════════════════"
echo ""
echo "Resumen de configuración:"
echo "  - Target Tracking CPU: 50%"
echo "  - Target Tracking Memory: 50%"
echo "  - Min tareas: 1 (disponibilidad base)"
echo "  - Max tareas: 3 (límite laboratorio)"
echo "  - Scale Out Cooldown: 60s"
echo "  - Scale In Cooldown: 60s"
echo ""
echo "Justificación de umbrales:"
echo "  CPU 50%: Valor estándar para apps web. Debajo de 50% hay capacidad"
echo "    ociosa; sobre 50% permite escalar antes de degradar rendimiento."
echo "  Memory 50%: Mantener memoria libre evita OOM kills en picos de"
echo "    tráfico. Fargate cobra por recursos asignados, no por uso."
echo "  Cooldown 60s: Evita oscilaciones (thrashing) dando tiempo a que"
echo "    las nuevas tareas se estabilicen antes de escalar de nuevo."
echo ""
echo "Para probar autoscaling, generar carga con:"
echo "  # Instalar hey (Go):  go install github.com/rakyll/hey@latest"
echo "  hey -n 10000 -c 50 http://<ALB-DNS>/api/v1/ventas"
echo ""
echo "Monitorear en: CloudWatch > Métricas > ECS > ClusterName > ServiceName"
