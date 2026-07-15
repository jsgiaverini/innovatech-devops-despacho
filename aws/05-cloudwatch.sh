#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_functions.sh"
load_env

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
    EXISTING=$(aws logs describe-log-groups --log-group-name-prefix "$LG" --query "logGroups[?logGroupName=='$LG'].logGroupName" --output text)
    if [ "$EXISTING" = "$LG" ]; then
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
