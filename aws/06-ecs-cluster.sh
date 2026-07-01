#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  06 - ECS Cluster + Service Discovery"
echo "========================================"

source .env

CLUSTER_NAME="${ECS_CLUSTER:-innovatech-cluster}"

if aws ecs describe-clusters --clusters "$CLUSTER_NAME" --query "clusters[?clusterName=='$CLUSTER_NAME'].clusterName" --output text &>/dev/null; then
    echo "Cluster $CLUSTER_NAME ya existe"
else
    echo "Creando cluster ECS $CLUSTER_NAME..."
    aws ecs create-cluster \
        --cluster-name "$CLUSTER_NAME" \
        --capacity-providers FARGATE FARGATE_SPOT \
        --default-capacity-provider-strategy "capacityProvider=FARGATE,base=1,weight=1" "capacityProvider=FARGATE_SPOT,base=0,weight=1"
    echo "Cluster $CLUSTER_NAME creado"
fi
echo "ECS_CLUSTER=$CLUSTER_NAME" >> .env

# Service Discovery namespace
NS_NAME="innovatech.local"
NS_ID=$(aws servicediscovery list-namespaces --filters "Name=NAME,Values=$NS_NAME,Condition=BEGINS_WITH" --query "Namespaces[0].Id" --output text)
if [ "$NS_ID" == "None" ] || [ -z "$NS_ID" ]; then
    echo "Creando namespace $NS_NAME..."
    NS_ID=$(aws servicediscovery create-private-dns-namespace \
        --name "$NS_NAME" \
        --vpc "$VPC_ID" \
        --query "OperationId" --output text)
    echo "Namespace $NS_NAME creado (OperationId: $NS_ID)"
    # Esperar a que se complete
    aws servicediscovery get-operation --operation-id "$NS_ID" --query "Operation.Status" --output text
    echo "Esperando 30s a que el namespace esté disponible..."
    sleep 30
else
    echo "Namespace $NS_NAME ya existe (ID: $NS_ID)"
fi

echo "Service Discovery namespace: $NS_NAME"
