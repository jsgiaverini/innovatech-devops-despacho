#!/bin/bash
set -euo pipefail

echo "========================================================"
echo "  Innovatech - Despliegue inicial completo en AWS ECS"
echo "========================================================"

if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "ERROR: AWS CLI no esta configurado o las credenciales expiraron." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    cp "$SCRIPT_DIR/.env.example" "$ENV_FILE"
    echo "Se creo $ENV_FILE. Configura sus contrasenas y vuelve a ejecutar." >&2
    exit 1
fi

# shellcheck disable=SC1091
source "$SCRIPT_DIR/_functions.sh"
load_env
export AWS_REGION="${AWS_REGION:-us-east-1}"
export ECS_CLUSTER="${ECS_CLUSTER:-innovatech-cluster}"

for REQUIRED_VAR in DB_PASSWORD MYSQL_ROOT_PASSWORD; do
    if [ -z "${!REQUIRED_VAR:-}" ] || [ "${!REQUIRED_VAR}" = "change_me" ]; then
        echo "ERROR: Configura $REQUIRED_VAR en aws/.env antes de desplegar." >&2
        exit 1
    fi
done

run_step() {
    local label="$1"
    local script="$2"
    echo ""
    echo "========================================================"
    echo "  $label"
    echo "========================================================"
    bash "$SCRIPT_DIR/$script"
}

run_step "PASO 1: VPC y subredes" "01-vpc.sh"
run_step "PASO 2: Repositorios ECR" "02-ecr.sh"
run_step "PASO 2B: Imagenes iniciales" "02-bootstrap-images.sh"
run_step "PASO 3: Security Groups" "03-security-groups.sh"
run_step "PASO 4: Roles IAM para ECS" "04-iam-roles.sh"
run_step "PASO 5: CloudWatch Log Groups" "05-cloudwatch.sh"
run_step "PASO 6: ECS Cluster y Service Discovery" "06-ecs-cluster.sh"
run_step "PASO 7: ALB, Target Groups y reglas" "07-alb.sh"
run_step "PASO 8: Task Definitions y servicios ECS" "08-ecs-services.sh"
run_step "PASO 9: Autoscaling" "09-autoscaling.sh"

echo ""
echo "========================================================"
echo "  PASO 10: Espera y verificacion"
echo "========================================================"
echo "Esperando que los cuatro servicios ECS queden estables..."
aws ecs wait services-stable \
    --cluster "$ECS_CLUSTER" \
    --services mysql-service back-ventas-service back-despachos-service frontend-service \
    --region "$AWS_REGION"
bash "$SCRIPT_DIR/10-verify.sh"

load_env
echo ""
echo "========================================================"
echo "  DESPLIEGUE INICIAL COMPLETADO"
echo "========================================================"
echo "URL publica: http://${ALB_DNS:-<pendiente>}"
echo "Los cambios siguientes se despliegan desde la rama deploy."
