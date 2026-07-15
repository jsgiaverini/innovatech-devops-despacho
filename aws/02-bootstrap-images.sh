#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  02B - Imagenes iniciales para ECS"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# Docker Desktop para Windows necesita contextos con formato C:/..., mientras
# que Git Bash representa la misma carpeta como /c/....
if command -v cygpath >/dev/null 2>&1; then
    PROJECT_DIR_DOCKER="$(cygpath -m "$PROJECT_DIR")"
else
    PROJECT_DIR_DOCKER="$PROJECT_DIR"
fi
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_functions.sh"
load_env

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker es obligatorio para construir las imagenes iniciales." >&2
    exit 1
fi

for REQUIRED_VAR in AWS_REGION ECR_REGISTRY; do
    if [ -z "${!REQUIRED_VAR:-}" ]; then
        echo "ERROR: Falta $REQUIRED_VAR. Ejecuta primero aws/02-ecr.sh." >&2
        exit 1
    fi
done

echo "Iniciando sesion en ECR $ECR_REGISTRY..."
aws ecr get-login-password --region "$AWS_REGION" \
    | docker login --username AWS --password-stdin "$ECR_REGISTRY"

build_and_push() {
    local repository="$1"
    local context="$2"
    local image="$ECR_REGISTRY/$repository:latest"
    echo "Construyendo $image desde $context..."
    docker build --pull -t "$image" "$context"
    echo "Publicando $image..."
    docker push "$image"
}

build_and_push "front-despacho" "$PROJECT_DIR_DOCKER/front_despacho"
build_and_push "back-ventas" "$PROJECT_DIR_DOCKER/back-Ventas_SpringBoot/Springboot-API-REST"
build_and_push "back-despachos" "$PROJECT_DIR_DOCKER/back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO"

echo "Imagenes iniciales publicadas. ECS ya puede crear sus servicios."
