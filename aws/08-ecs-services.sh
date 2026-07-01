#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  08 - ECS Services (Task Definitions)"
echo "========================================"

source .env

# ─── Registrar Task Definitions ───
register_task() {
    local FILE=$1
    local NAME=$(basename "$FILE" -task.json)
    echo "Registrando task definition $NAME..."
    # Reemplazar variables en el JSON usando envsubst o sed
    TASK_JSON=$(envsubst < "$FILE")
    TASK_ARN=$(aws ecs register-task-definition --cli-input-json "$TASK_JSON" --query "taskDefinition.taskDefinitionArn" --output text)
    echo "  Task Definition registrada: $TASK_ARN"
    SAFE_NAME=$(echo "TD_${NAME}_ARN" | tr '-' '_' | tr '[:lower:]' '[:upper:]')
    echo "$SAFE_NAME=$TASK_ARN" >> .env
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
register_task "$SCRIPT_DIR/task-definitions/mysql-task.json"
register_task "$SCRIPT_DIR/task-definitions/back-ventas-task.json"
register_task "$SCRIPT_DIR/task-definitions/back-despachos-task.json"
register_task "$SCRIPT_DIR/task-definitions/frontend-task.json"

# Re-read env with task ARNs
source .env

# ─── Crear ECS Services ───
create_service() {
    local SERVICE_NAME=$1
    local TASK_DEF_ARN=$2
    local TG_ARN=$3
    local PORT=$4
    local SG_ID=$5

    echo "Creando servicio ECS $SERVICE_NAME..."
    if aws ecs describe-services --cluster "$ECS_CLUSTER" --services "$SERVICE_NAME" --query "services[?serviceName=='$SERVICE_NAME'].serviceName" --output text &>/dev/null; then
        echo "  Servicio $SERVICE_NAME ya existe, actualizando..."
        aws ecs update-service --cluster "$ECS_CLUSTER" --service "$SERVICE_NAME" --task-definition "$TASK_DEF_ARN" --force-new-deployment
        return
    fi

    aws ecs create-service \
        --cluster "$ECS_CLUSTER" \
        --service-name "$SERVICE_NAME" \
        --task-definition "$TASK_DEF_ARN" \
        --desired-count 1 \
        --launch-type FARGATE \
        --platform-version LATEST \
        --network-configuration "awsvpcConfiguration={subnets=[$SUBNET1,$SUBNET2],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
        --load-balancers "targetGroupArn=$TG_ARN,containerName=$(echo $SERVICE_NAME | sed 's/-service//'),containerPort=$PORT" \
        --health-check-grace-period-seconds 60 \
        --enable-execute-command
    echo "  Servicio $SERVICE_NAME creado"
}

# MySQL (sin ALB)
echo "Creando servicio MySQL (sin ALB)..."
if aws ecs describe-services --cluster "$ECS_CLUSTER" --services mysql-service --query "services[?serviceName=='mysql-service'].serviceName" --output text &>/dev/null; then
    echo "  Servicio mysql-service ya existe"
else
    aws ecs create-service \
        --cluster "$ECS_CLUSTER" \
        --service-name mysql-service \
        --task-definition "$TD_MYSQL_ARN" \
        --desired-count 1 \
        --launch-type FARGATE \
        --platform-version LATEST \
        --network-configuration "awsvpcConfiguration={subnets=[$SUBNET1,$SUBNET2],securityGroups=[$SG_MYSQL],assignPublicIp=ENABLED}" \
        --service-connect-configuration "enabled=true,namespace=\"innovatech.local\",services=[{serviceName=mysql,clientDns=mysql.innovatech.local,portName=mysql3306}]"
    echo "  Servicio mysql-service creado"
fi

create_service "back-ventas-service" "$TD_BACK_VENTAS_ARN" "$TG_BACK_VENTAS_ARN" 8080 "$SG_BACKEND"
create_service "back-despachos-service" "$TD_BACK_DESPACHOS_ARN" "$TG_BACK_DESPACHOS_ARN" 8081 "$SG_BACKEND"
create_service "frontend-service" "$TD_FRONTEND_ARN" "$TG_FRONTEND_ARN" 8080 "$SG_FRONTEND"

echo ""
echo "ECS Services desplegados:"
echo "  mysql-service (sin ALB)"
echo "  back-ventas-service → TG_BACK_VENTAS"
echo "  back-despachos-service → TG_BACK_DESPACHOS"
echo "  frontend-service → TG_FRONTEND"
echo ""
echo "URL de acceso: http://$ALB_DNS"
