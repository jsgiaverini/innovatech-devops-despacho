#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  04 - Roles IAM para ECS"
echo "========================================"

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
    aws iam attach-role-policy \
        --role-name "$ROLE_EXEC" \
        --policy-arn "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
    echo "Rol $ROLE_EXEC creado"
fi

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

echo "EXECUTION_ROLE_ARN=$EXEC_ARN" >> .env
echo "TASK_ROLE_ARN=$TASK_ARN" >> .env

echo ""
echo "Roles IAM listos:"
echo "  Execution Role: $EXEC_ARN"
echo "  Task Role: $TASK_ARN"
