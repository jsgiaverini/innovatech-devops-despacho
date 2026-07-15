#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  06 - ECS Cluster + Service Connect"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_functions.sh"
load_env

CLUSTER_NAME="${ECS_CLUSTER:-innovatech-cluster}"
NAMESPACE_NAME="${SERVICE_CONNECT_NAMESPACE:-innovatech.local}"

EXISTING_CLUSTER=$(aws ecs describe-clusters \
    --clusters "$CLUSTER_NAME" \
    --query "clusters[?status=='ACTIVE'].clusterName" \
    --output text)

if [ "$EXISTING_CLUSTER" = "$CLUSTER_NAME" ]; then
    echo "Cluster $CLUSTER_NAME ya existe"
else
    echo "Creando cluster ECS $CLUSTER_NAME..."
    aws ecs create-cluster \
        --cluster-name "$CLUSTER_NAME" \
        --capacity-providers FARGATE FARGATE_SPOT \
        --default-capacity-provider-strategy \
            "capacityProvider=FARGATE,base=1,weight=1" \
            "capacityProvider=FARGATE_SPOT,base=0,weight=1" >/dev/null
    echo "Cluster $CLUSTER_NAME creado"
fi
set_env "ECS_CLUSTER" "$CLUSTER_NAME"

NAMESPACE_ID=$(aws servicediscovery list-namespaces \
    --filters "Name=NAME,Values=$NAMESPACE_NAME,Condition=EQ" \
    --query "Namespaces[0].Id" \
    --output text)

if [ "$NAMESPACE_ID" = "None" ] || [ -z "$NAMESPACE_ID" ]; then
    echo "Creando namespace privado $NAMESPACE_NAME..."
    if ! OPERATION_ID=$(aws servicediscovery create-private-dns-namespace \
        --name "$NAMESPACE_NAME" \
        --vpc "$VPC_ID" \
        --query "OperationId" \
        --output text 2>/dev/null); then
        echo "AVISO: El laboratorio no permite crear Service Discovery."
        echo "       Se usara la IP privada de la tarea MySQL."
        set_env "SERVICE_CONNECT_ENABLED" "false"
        exit 0
    fi

    for _ in $(seq 1 60); do
        STATUS=$(aws servicediscovery get-operation \
            --operation-id "$OPERATION_ID" \
            --query "Operation.Status" \
            --output text)
        case "$STATUS" in
            SUCCESS) break ;;
            FAIL)
                echo "ERROR: Falló la creación del namespace $NAMESPACE_NAME" >&2
                exit 1
                ;;
            *) sleep 5 ;;
        esac
    done

    NAMESPACE_ID=$(aws servicediscovery list-namespaces \
        --filters "Name=NAME,Values=$NAMESPACE_NAME,Condition=EQ" \
        --query "Namespaces[0].Id" \
        --output text)

    if [ "$NAMESPACE_ID" = "None" ] || [ -z "$NAMESPACE_ID" ]; then
        echo "ERROR: El namespace no quedó disponible dentro del tiempo esperado." >&2
        exit 1
    fi
    echo "Namespace $NAMESPACE_NAME creado: $NAMESPACE_ID"
else
    echo "Namespace $NAMESPACE_NAME ya existe: $NAMESPACE_ID"
fi

set_env "SERVICE_CONNECT_NAMESPACE" "$NAMESPACE_NAME"
set_env "SERVICE_CONNECT_NAMESPACE_ID" "$NAMESPACE_ID"
set_env "SERVICE_CONNECT_ENABLED" "true"

echo "Cluster y namespace listos."
