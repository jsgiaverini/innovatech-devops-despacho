#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  02 - Repositorios ECR"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_functions.sh"
load_env

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
set_env "ACCOUNT_ID" "$ACCOUNT_ID"
set_env "ECR_REGISTRY" "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

echo "Account ID: $ACCOUNT_ID"
echo "Registry: $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
echo "Repositorios ECR listos."
