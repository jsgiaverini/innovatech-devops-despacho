#!/bin/bash
set -euo pipefail

echo "========================================================"
echo "  Innovatech - Setup de Infraestructura AWS para ECS"
echo "========================================================"
echo ""

# ─── Validación inicial ───
echo "[PRE] Validando AWS CLI..."
if ! aws sts get-caller-identity &>/dev/null; then
    echo "ERROR: AWS CLI no está configurado. Ejecuta 'aws configure' primero."
    exit 1
fi
echo "  AWS CLI configurado correctamente."
echo ""

# ─── Inicializar .env ───
ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
    echo "[PRE] Creando archivo .env..."
    cat > "$ENV_FILE" <<- EOF
# Variables de infraestructura AWS (generadas por setup-infra.sh)
AWS_REGION=us-east-1
ECS_CLUSTER=innovatech-cluster
EOF
fi
# Cargar variables existentes
source "$ENV_FILE"
export AWS_REGION="${AWS_REGION:-us-east-1}"
export ECS_CLUSTER="${ECS_CLUSTER:-innovatech-cluster}"

# ─── Determinar la ruta del script ───
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Ejecutar scripts en orden ───
echo "========================================================"
echo "  PASO 1: VPC y Subredes"
echo "========================================================"
bash "$SCRIPT_DIR/01-vpc.sh"
echo ""

echo "========================================================"
echo "  PASO 2: Repositorios ECR"
echo "========================================================"
bash "$SCRIPT_DIR/02-ecr.sh"
echo ""

echo "========================================================"
echo "  PASO 3: Security Groups"
echo "========================================================"
bash "$SCRIPT_DIR/03-security-groups.sh"
echo ""

echo "========================================================"
echo "  PASO 4: Roles IAM para ECS"
echo "========================================================"
bash "$SCRIPT_DIR/04-iam-roles.sh"
echo ""

echo "========================================================"
echo "  PASO 5: CloudWatch Log Groups"
echo "========================================================"
bash "$SCRIPT_DIR/05-cloudwatch.sh"
echo ""

echo "========================================================"
echo "  PASO 6: ECS Cluster y Service Discovery"
echo "========================================================"
bash "$SCRIPT_DIR/06-ecs-cluster.sh"
echo ""

echo "========================================================"
echo "  PASO 7: ALB, Target Groups y Reglas"
echo "========================================================"
bash "$SCRIPT_DIR/07-alb.sh"
echo ""

echo "========================================================"
echo "  PASO 8: ECS Services (Task Definitions + Services)"
echo "========================================================"
echo ""
echo "  IMPORTANTE: Antes de ejecutar el paso 8, debes:"
echo "  1. Hacer push de las imagenes Docker a ECR"
echo "     (los workflows CI/CD lo harán automaticamente al hacer push a deploy)"
echo "  2. Configurar DB_PASSWORD y MYSQL_ROOT_PASSWORD en .env"
echo ""
read -p "  ¿Ejecutar paso 8 ahora? (s/N): " CONFIRM
if [ "$CONFIRM" = "s" ] || [ "$CONFIRM" = "S" ]; then
    bash "$SCRIPT_DIR/08-ecs-services.sh"
else
    echo "  Paso 8 omitido. Ejecútalo manualmente cuando tengas las imágenes en ECR."
fi

echo ""
echo "========================================================"
echo "  INFRAESTRUCTURA AWS COMPLETADA"
echo "========================================================"
echo ""
source "$ENV_FILE"
echo "  ALB URL: http://${ALB_DNS:-<pendiente>}"
echo "  Cluster ECS: $ECS_CLUSTER"
echo "  ECR Registry: ${ECR_REGISTRY:-<pendiente>}"
echo ""
echo "  Próximos pasos manuales:"
echo "  1. git add . && git commit -m 'feat: migracion a ECS'"
echo "  2. git push origin deploy"
echo "  3. Verificar pipelines en GitHub Actions"
echo "  4. Probar: http://$ALB_DNS"
echo "  5. Probar: http://$ALB_DNS/api/v1/ventas"
echo "  6. Probar: http://$ALB_DNS/api/v1/despachos"
echo ""
