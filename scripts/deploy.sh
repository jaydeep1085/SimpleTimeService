#!/bin/bash
# Deploy SimpleTimeService infrastructure to AWS

set -e

echo "=================================================="
echo "SimpleTimeService - AWS Deployment Script"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "[1/5] Checking prerequisites..."
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}✗ Terraform not found${NC}"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo -e "${RED}✗ AWS CLI not found${NC}"; exit 1; }
echo -e "${GREEN}✓ Terraform and AWS CLI found${NC}"

# Initialize Terraform
echo ""
echo "[2/5] Initializing Terraform..."
cd terraform/
terraform init
cd ..
echo -e "${GREEN}✓ Terraform initialized${NC}"

# Validate configuration
echo ""
echo "[3/5] Validating Terraform configuration..."
terraform -chdir=terraform validate
echo -e "${GREEN}✓ Configuration valid${NC}"

# Plan deployment
echo ""
echo "[4/5] Planning deployment..."
terraform -chdir=terraform plan -out=tfplan
echo ""
echo -e "${YELLOW}Review the plan above. Press Enter to continue with deployment or Ctrl+C to cancel.${NC}"
read -p ""

# Apply configuration
echo ""
echo "[5/5] Applying configuration..."
terraform -chdir=terraform apply tfplan
rm -f terraform/tfplan

echo ""
echo -e "${GREEN}✓ Deployment complete!${NC}"
echo ""
echo "=================================================="
echo "Deployment Summary"
echo "=================================================="
echo ""
echo "Application URL:"
terraform -chdir=terraform output -raw alb_url
echo ""
echo "ECS Cluster:"
terraform -chdir=terraform output -raw ecs_cluster_name
echo ""
echo "CloudWatch Logs:"
terraform -chdir=terraform output -raw cloudwatch_log_group
echo ""
echo "To tail logs:"
echo "  aws logs tail $(terraform -chdir=terraform output -raw cloudwatch_log_group) --follow"
echo ""
echo "To destroy infrastructure:"
echo "  terraform -chdir=terraform destroy"
echo ""
