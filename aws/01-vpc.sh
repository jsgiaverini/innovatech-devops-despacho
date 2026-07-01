#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  01 - VPC y Subredes"
echo "========================================"

source .env

VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)

if [ "$VPC_ID" == "None" ] || [ -z "$VPC_ID" ]; then
    echo "Creando VPC..."
    VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query "Vpc.VpcId" --output text)
    aws ec2 create-tags --resources "$VPC_ID" --tags Key=Name,Value=innovatech-vpc
    aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-support
    aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames
    echo "VPC $VPC_ID creada"
else
    echo "Usando VPC default: $VPC_ID"
fi

echo "VPC_ID=$VPC_ID" >> .env

AZ1="us-east-1a"
AZ2="us-east-1b"
SUBNET1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=availability-zone,Values=$AZ1" "Name=map-public-ip-on-launch,Values=true" --query "Subnets[0].SubnetId" --output text)
SUBNET2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=availability-zone,Values=$AZ2" "Name=map-public-ip-on-launch,Values=true" --query "Subnets[0].SubnetId" --output text)

if [ "$SUBNET1" == "None" ] || [ -z "$SUBNET1" ]; then
    echo "Creando subred en $AZ1..."
    SUBNET1=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.1.0/24 --availability-zone "$AZ1" --query "Subnet.SubnetId" --output text)
    aws ec2 create-tags --resources "$SUBNET1" --tags Key=Name,Value=innovatech-subnet-${AZ1}
    aws ec2 modify-subnet-attribute --subnet-id "$SUBNET1" --map-public-ip-on-launch
fi
if [ "$SUBNET2" == "None" ] || [ -z "$SUBNET2" ]; then
    echo "Creando subred en $AZ2..."
    SUBNET2=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.2.0/24 --availability-zone "$AZ2" --query "Subnet.SubnetId" --output text)
    aws ec2 create-tags --resources "$SUBNET2" --tags Key=Name,Value=innovatech-subnet-${AZ2}
    aws ec2 modify-subnet-attribute --subnet-id "$SUBNET2" --map-public-ip-on-launch
fi

echo "SUBNET1=$SUBNET1" >> .env
echo "SUBNET2=$SUBNET2" >> .env
echo "Subred 1: $SUBNET1 ($AZ1)"
echo "Subred 2: $SUBNET2 ($AZ2)"

IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[0].InternetGatewayId" --output text)
if [ "$IGW_ID" == "None" ] || [ -z "$IGW_ID" ]; then
    echo "Creando Internet Gateway..."
    IGW_ID=$(aws ec2 create-internet-gateway --query "InternetGateway.InternetGatewayId" --output text)
    aws ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
    aws ec2 create-tags --resources "$IGW_ID" --tags Key=Name,Value=innovatech-igw
fi
echo "IGW_ID=$IGW_ID" >> .env

RT_ID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" "Name=association.main,Values=true" --query "RouteTables[0].RouteTableId" --output text)
aws ec2 create-route --route-table-id "$RT_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" 2>/dev/null || true

echo "VPC configurada correctamente."
echo "VPC_ID=$VPC_ID SUBNET1=$SUBNET1 SUBNET2=$SUBNET2 IGW_ID=$IGW_ID"
