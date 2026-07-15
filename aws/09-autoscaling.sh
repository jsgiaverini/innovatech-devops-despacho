#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  09 - Autoscaling (Target Tracking)"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_functions.sh"
load_env

declare -A SERVICES=(
    [frontend-service]="1:3"
    [back-ventas-service]="1:3"
    [back-despachos-service]="1:3"
)

for SERVICE in "${!SERVICES[@]}"; do
    IFS=':' read -r MIN MAX <<< "${SERVICES[$SERVICE]}"
    RESOURCE_ID="service/$ECS_CLUSTER/$SERVICE"

    echo "Configurando $SERVICE (min=$MIN, max=$MAX)..."
    aws application-autoscaling register-scalable-target \
        --service-namespace ecs \
        --resource-id "$RESOURCE_ID" \
        --scalable-dimension ecs:service:DesiredCount \
        --min-capacity "$MIN" \
        --max-capacity "$MAX" \
        --region "$AWS_REGION" >/dev/null

    aws application-autoscaling put-scaling-policy \
        --service-namespace ecs \
        --resource-id "$RESOURCE_ID" \
        --scalable-dimension ecs:service:DesiredCount \
        --policy-name "${SERVICE}-cpu-autoscaling" \
        --policy-type TargetTrackingScaling \
        --target-tracking-scaling-policy-configuration '{
            "TargetValue": 50.0,
            "PredefinedMetricSpecification": {
                "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
            },
            "ScaleOutCooldown": 60,
            "ScaleInCooldown": 60
        }' >/dev/null

    aws application-autoscaling put-scaling-policy \
        --service-namespace ecs \
        --resource-id "$RESOURCE_ID" \
        --scalable-dimension ecs:service:DesiredCount \
        --policy-name "${SERVICE}-memory-autoscaling" \
        --policy-type TargetTrackingScaling \
        --target-tracking-scaling-policy-configuration '{
            "TargetValue": 50.0,
            "PredefinedMetricSpecification": {
                "PredefinedMetricType": "ECSServiceAverageMemoryUtilization"
            },
            "ScaleOutCooldown": 60,
            "ScaleInCooldown": 60
        }' >/dev/null

    echo "  Autoscaling configurado."
done

echo "Autoscaling listo para frontend y backends."
