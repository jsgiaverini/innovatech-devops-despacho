#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  03 - Security Groups"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_functions.sh"
load_env

create_sg() {
    local NAME="$1"
    local DESC="$2"
    local SG_ID
    SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$NAME" "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[0].GroupId" --output text)
    if [ "$SG_ID" == "None" ] || [ -z "$SG_ID" ]; then
        SG_ID=$(aws ec2 create-security-group --group-name "$NAME" --description "$DESC" --vpc-id "$VPC_ID" --query "GroupId" --output text)
        echo "Creado $NAME: $SG_ID"
    else
        echo "Ya existe $NAME: $SG_ID"
    fi
    set_env "$NAME" "$SG_ID"
    printf -v "$NAME" '%s' "$SG_ID"
}

create_sg "SG_ALB" "Security Group for ALB Innovatech"
create_sg "SG_FRONTEND" "Security Group for Frontend ECS Innovatech"
create_sg "SG_BACKEND" "Security Group for Backend ECS Innovatech"
create_sg "SG_MYSQL" "Security Group for MySQL ECS Innovatech"

# SG ALB: HTTP 80 desde anywhere
aws ec2 authorize-security-group-ingress --group-id "$SG_ALB" --protocol tcp --port 80 --cidr 0.0.0.0/0 2>/dev/null || true

# SG Frontend: TCP 8080 desde SG ALB
aws ec2 authorize-security-group-ingress --group-id "$SG_FRONTEND" --protocol tcp --port 8080 --source-group "$SG_ALB" 2>/dev/null || true

# SG Backend: TCP 8080 y 8081 desde SG ALB
aws ec2 authorize-security-group-ingress --group-id "$SG_BACKEND" --protocol tcp --port 8080 --source-group "$SG_ALB" 2>/dev/null || true
aws ec2 authorize-security-group-ingress --group-id "$SG_BACKEND" --protocol tcp --port 8081 --source-group "$SG_ALB" 2>/dev/null || true

# SG MySQL: TCP 3306 desde SG Backend
aws ec2 authorize-security-group-ingress --group-id "$SG_MYSQL" --protocol tcp --port 3306 --source-group "$SG_BACKEND" 2>/dev/null || true

echo ""
echo "Security Groups configurados:"
echo "  SG_ALB=$SG_ALB (HTTP 80 desde 0.0.0.0/0)"
echo "  SG_FRONTEND=$SG_FRONTEND (TCP 8080 desde ALB)"
echo "  SG_BACKEND=$SG_BACKEND (TCP 8080,8081 desde ALB)"
echo "  SG_MYSQL=$SG_MYSQL (TCP 3306 desde Backend)"
