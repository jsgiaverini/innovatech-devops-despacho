#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  08 - ECS Services (Task Definitions)"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_functions.sh"
load_env

if ! command -v envsubst >/dev/null 2>&1; then
    echo "ERROR: Falta envsubst. Instala el paquete gettext antes de continuar." >&2
    exit 1
fi

SERVICE_CONNECT_NAMESPACE="${SERVICE_CONNECT_NAMESPACE:-innovatech.local}"

for REQUIRED_VAR in ECR_REGISTRY EXECUTION_ROLE_ARN TASK_ROLE_ARN SUBNET1 SUBNET2 SG_MYSQL SG_BACKEND SG_FRONTEND TG_FRONTEND_ARN TG_BACK_VENTAS_ARN TG_BACK_DESPACHOS_ARN ALB_DNS DB_NAME DB_USERNAME DB_PASSWORD MYSQL_ROOT_PASSWORD; do
    VALUE="${!REQUIRED_VAR:-}"
    if [ -z "$VALUE" ] || [ "$VALUE" = "change_me" ]; then
        echo "ERROR: Debes configurar $REQUIRED_VAR en aws/.env o ejecutar los pasos previos." >&2
        exit 1
    fi
done

register_task() {
    local file="$1"
    local name
    local task_json
    local task_arn
    local safe_name

    name=$(basename "$file" -task.json)
    echo "Registrando task definition $name..."

    # load_env exporta las variables para que envsubst pueda reemplazarlas.
    task_json=$(envsubst < "$file")
    if grep -q '\${' <<< "$task_json"; then
        echo "ERROR: Quedaron variables sin resolver en $file" >&2
        exit 1
    fi

    task_arn=$(aws ecs register-task-definition \
        --cli-input-json "$task_json" \
        --query "taskDefinition.taskDefinitionArn" \
        --output text)

    echo "  Task Definition registrada: $task_arn"
    safe_name=$(echo "TD_${name}_ARN" | tr '-' '_' | tr '[:lower:]' '[:upper:]')
    set_env "$safe_name" "$task_arn"
}

register_task "$SCRIPT_DIR/task-definitions/mysql-task.json"
load_env

create_service() {
    local service_name="$1"
    local task_definition_arn="$2"
    local target_group_arn="$3"
    local container_port="$4"
    local security_group_id="$5"
    local enable_service_connect="${6:-false}"
    local existing_service

    local service_connect_args=()
    if [ "$enable_service_connect" = "true" ] && [ "${SERVICE_CONNECT_ENABLED:-true}" = "true" ]; then
        service_connect_args=(
            --service-connect-configuration
            "{\"enabled\":true,\"namespace\":\"$SERVICE_CONNECT_NAMESPACE\"}"
        )
    fi

    existing_service=$(aws ecs describe-services \
        --cluster "$ECS_CLUSTER" \
        --services "$service_name" \
        --query "services[?status=='ACTIVE'].serviceName" \
        --output text)

    if [ "$existing_service" = "$service_name" ]; then
        echo "Actualizando servicio ECS $service_name..."
        aws ecs update-service \
            --cluster "$ECS_CLUSTER" \
            --service "$service_name" \
            --task-definition "$task_definition_arn" \
            --force-new-deployment \
            "${service_connect_args[@]}"
        return
    fi

    echo "Creando servicio ECS $service_name..."
    aws ecs create-service \
        --cluster "$ECS_CLUSTER" \
        --service-name "$service_name" \
        --task-definition "$task_definition_arn" \
        --desired-count 1 \
        --launch-type FARGATE \
        --platform-version LATEST \
        --network-configuration "awsvpcConfiguration={subnets=[$SUBNET1,$SUBNET2],securityGroups=[$security_group_id],assignPublicIp=ENABLED}" \
        --load-balancers "targetGroupArn=$target_group_arn,containerName=${service_name%-service},containerPort=$container_port" \
        --health-check-grace-period-seconds 60 \
        "${service_connect_args[@]}"
}

MYSQL_SERVICE_CONNECT="{\"enabled\":true,\"namespace\":\"$SERVICE_CONNECT_NAMESPACE\",\"services\":[{\"portName\":\"mysql3306\",\"discoveryName\":\"mysql\",\"clientAliases\":[{\"port\":3306,\"dnsName\":\"mysql\"}]}]}"
MYSQL_SERVICE_CONNECT_ARGS=()
if [ "${SERVICE_CONNECT_ENABLED:-true}" = "true" ]; then
    MYSQL_SERVICE_CONNECT_ARGS=(--service-connect-configuration "$MYSQL_SERVICE_CONNECT")
fi

echo "Configurando servicio MySQL..."
EXISTING_MYSQL=$(aws ecs describe-services \
    --cluster "$ECS_CLUSTER" \
    --services mysql-service \
    --query "services[?status=='ACTIVE'].serviceName" \
    --output text)

if [ "$EXISTING_MYSQL" = "mysql-service" ]; then
    aws ecs update-service \
        --cluster "$ECS_CLUSTER" \
        --service mysql-service \
        --task-definition "$TD_MYSQL_ARN" \
        "${MYSQL_SERVICE_CONNECT_ARGS[@]}" \
        --force-new-deployment
else
    aws ecs create-service \
        --cluster "$ECS_CLUSTER" \
        --service-name mysql-service \
        --task-definition "$TD_MYSQL_ARN" \
        --desired-count 1 \
        --launch-type FARGATE \
        --platform-version LATEST \
        --network-configuration "awsvpcConfiguration={subnets=[$SUBNET1,$SUBNET2],securityGroups=[$SG_MYSQL],assignPublicIp=ENABLED}" \
        "${MYSQL_SERVICE_CONNECT_ARGS[@]}"
fi

if [ "${SERVICE_CONNECT_ENABLED:-true}" != "true" ]; then
    echo "Esperando MySQL para descubrir su IP privada..."
    aws ecs wait services-stable --cluster "$ECS_CLUSTER" --services mysql-service
    MYSQL_TASK_ARN=$(aws ecs list-tasks \
        --cluster "$ECS_CLUSTER" \
        --service-name mysql-service \
        --desired-status RUNNING \
        --query "taskArns[0]" \
        --output text)
    MYSQL_ENI_ID=$(aws ecs describe-tasks \
        --cluster "$ECS_CLUSTER" \
        --tasks "$MYSQL_TASK_ARN" \
        --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value | [0]" \
        --output text)
    DB_ENDPOINT=$(aws ec2 describe-network-interfaces \
        --network-interface-ids "$MYSQL_ENI_ID" \
        --query "NetworkInterfaces[0].PrivateIpAddress" \
        --output text)
    if [ -z "$DB_ENDPOINT" ] || [ "$DB_ENDPOINT" = "None" ]; then
        echo "ERROR: No se pudo descubrir la IP privada de MySQL." >&2
        exit 1
    fi
    set_env "DB_ENDPOINT" "$DB_ENDPOINT"
    echo "MySQL disponible dentro de la VPC en $DB_ENDPOINT:3306"
else
    set_env "DB_ENDPOINT" "mysql"
fi

register_task "$SCRIPT_DIR/task-definitions/back-ventas-task.json"
register_task "$SCRIPT_DIR/task-definitions/back-despachos-task.json"
register_task "$SCRIPT_DIR/task-definitions/frontend-task.json"
load_env

create_service "back-ventas-service" "$TD_BACK_VENTAS_ARN" "$TG_BACK_VENTAS_ARN" 8080 "$SG_BACKEND" true
create_service "back-despachos-service" "$TD_BACK_DESPACHOS_ARN" "$TG_BACK_DESPACHOS_ARN" 8081 "$SG_BACKEND" true
create_service "frontend-service" "$TD_FRONTEND_ARN" "$TG_FRONTEND_ARN" 8080 "$SG_FRONTEND"

echo ""
echo "ECS Services desplegados:"
echo "  mysql-service (Service Connect: mysql:3306)"
echo "  back-ventas-service → TG_BACK_VENTAS"
echo "  back-despachos-service → TG_BACK_DESPACHOS"
echo "  frontend-service → TG_FRONTEND"
echo ""
echo "URL de acceso: http://$ALB_DNS"
