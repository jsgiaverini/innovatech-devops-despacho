#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_functions.sh"
load_env

echo "========================================"
echo "  04 - Roles IAM para ECS"
echo "========================================"

# AWS Academy normalmente entrega LabRole y bloquea la creacion de roles IAM.
# Si esta disponible, se reutiliza para mantener el despliegue compatible con
# el laboratorio sin solicitar permisos adicionales.
if LAB_ROLE_ARN=$(aws iam get-role \
    --role-name LabRole \
    --query "Role.Arn" \
    --output text 2>/dev/null) && [ -n "$LAB_ROLE_ARN" ] && [ "$LAB_ROLE_ARN" != "None" ]; then
    set_env "EXECUTION_ROLE_ARN" "$LAB_ROLE_ARN"
    set_env "TASK_ROLE_ARN" "$LAB_ROLE_ARN"
    echo "AWS Academy detectado: se reutilizara LabRole."
    echo "  Execution Role: $LAB_ROLE_ARN"
    echo "  Task Role: $LAB_ROLE_ARN"
    exit 0
fi

# Rol 1: ecsTaskExecutionRole
ROLE_EXEC="ecsTaskExecutionRole"
if aws iam get-role --role-name "$ROLE_EXEC" &>/dev/null; then
    echo "Rol $ROLE_EXEC ya existe"
else
    echo "Creando rol $ROLE_EXEC..."
    aws iam create-role \
        --role-name "$ROLE_EXEC" \
        --assume-role-policy-document '{
            "Version": "2012-10-17",
            "Statement": [{
                "Effect": "Allow",
                "Principal": { "Service": "ecs-tasks.amazonaws.com" },
                "Action": "sts:AssumeRole"
            }]
        }'
    echo "Rol $ROLE_EXEC creado"
fi
aws iam attach-role-policy \
    --role-name "$ROLE_EXEC" \
    --policy-arn "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

# Rol 2: innovatechTaskRole
ROLE_TASK="innovatechTaskRole"
if aws iam get-role --role-name "$ROLE_TASK" &>/dev/null; then
    echo "Rol $ROLE_TASK ya existe"
else
    echo "Creando rol $ROLE_TASK..."
    aws iam create-role \
        --role-name "$ROLE_TASK" \
        --assume-role-policy-document '{
            "Version": "2012-10-17",
            "Statement": [{
                "Effect": "Allow",
                "Principal": { "Service": "ecs-tasks.amazonaws.com" },
                "Action": "sts:AssumeRole"
            }]
        }'
    echo "Rol $ROLE_TASK creado (sin permisos extra)"
fi

EXEC_ARN=$(aws iam get-role --role-name "$ROLE_EXEC" --query "Role.Arn" --output text)
TASK_ARN=$(aws iam get-role --role-name "$ROLE_TASK" --query "Role.Arn" --output text)

set_env "EXECUTION_ROLE_ARN" "$EXEC_ARN"
set_env "TASK_ROLE_ARN" "$TASK_ARN"

echo ""
echo "Roles IAM listos:"
echo "  Execution Role: $EXEC_ARN"
echo "  Task Role: $TASK_ARN"
