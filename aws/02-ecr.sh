#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  02 - Repositorios ECR"
echo "========================================"

source .env

for REPO in front-despacho back-ventas back-despachos; do
    if aws ecr describe-repositories --repository-names "$REPO" &>/dev/null; then
        echo "Repositorio $REPO ya existe"
    else
        echo "Creando repositorio $REPO..."
        aws ecr create-repository --repository-name "$REPO"
        echo "Repositorio $REPO creado"
    fi
done

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "ACCOUNT_ID=$ACCOUNT_ID" >> .env
echo "ECR_REGISTRY=$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com" >> .env

echo "Account ID: $ACCOUNT_ID"
echo "Registry: $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com"
echo "Repositorios ECR listos."
