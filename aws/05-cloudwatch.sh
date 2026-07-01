#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  05 - CloudWatch Log Groups"
echo "========================================"

LOG_GROUPS=(
    "/ecs/innovatech/frontend"
    "/ecs/innovatech/back-ventas"
    "/ecs/innovatech/back-despachos"
    "/ecs/innovatech/mysql"
)

for LG in "${LOG_GROUPS[@]}"; do
    if aws logs describe-log-groups --log-group-name-pattern "$LG" --query "logGroups[?logGroupName=='$LG'].logGroupName" --output text &>/dev/null; then
        echo "Log group $LG ya existe"
    else
        echo "Creando log group $LG..."
        aws logs create-log-group --log-group-name "$LG"
        aws logs put-retention-policy --log-group-name "$LG" --retention-in-days 7
        echo "Log group $LG creado"
    fi
done

echo ""
echo "CloudWatch Log Groups listos:"
for LG in "${LOG_GROUPS[@]}"; do
    echo "  $LG"
done
