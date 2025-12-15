# SimpleTimeService - Terraform Infrastructure

Complete Infrastructure-as-Code for deploying SimpleTimeService on AWS using Terraform.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Internet (0.0.0.0/0)                        │
└──────────────────────────────────┬────────────────────────────────┘
                                   │ HTTP/80
                    ┌──────────────▼──────────────┐
                    │                             │
                    │    Internet Gateway         │
                    │                             │
                    └──────────────┬──────────────┘
                                   │
        ┌──────────────────────────┴──────────────────────────┐
        │                     VPC 10.0.0.0/16                 │
        │                                                      │
        │  ┌────────────────────────────────────────────────┐ │
        │  │          PUBLIC SUBNETS (ALB)                  │ │
        │  │  10.0.1.0/24 (AZ-1)  10.0.2.0/24 (AZ-2)      │ │
        │  │  ┌──────────────────┐  ┌──────────────────┐   │ │
        │  │  │  ALB Instance    │  │  ALB Instance    │   │ │
        │  │  │  (Port 80)       │  │  (Port 80)       │   │ │
        │  │  └─────────┬────────┘  └─────────┬────────┘   │ │
        │  └────────────┼────────────────────┼────────────┘ │
        │               │                    │               │
        │  ┌────────────▼────────────────────▼────────────┐ │
        │  │   Application Load Balancer (Target Group)   │ │
        │  │           simpletimeservice-tg               │ │
        │  └────────────┬───────────────────┬────────────┘ │
        │               │                   │                │
        │  ┌────────────▼──────────┐ ┌──────▼─────────────┐│
        │  │  PRIVATE SUBNET 1      │ │ PRIVATE SUBNET 2  ││
        │  │  10.0.11.0/24 (AZ-1)   │ │ 10.0.12.0/24(AZ-2)││
        │  │                        │ │                   ││
        │  │  ┌──────────────────┐ │ │┌──────────────────┐││
        │  │  │ ECS Fargate Task │ │ ││ ECS Fargate Task ││
        │  │  │  :5000/health    │ │ ││  :5000/health    │││
        │  │  │                  │ │ ││                  │││
        │  │  └──────────────────┘ │ │└──────────────────┘││
        │  └────────────┬──────────┘ └──────┬────────────┘│
        │               │                    │              │
        │  ┌────────────▼────────────────────▼────────────┐ │
        │  │     CloudWatch Logs: /ecs/simpletimeservice  │ │
        │  └─────────────────────────────────────────────┘ │
        │                                                  │
        └──────────────────────────────────────────────────┘
```

## Components

### VPC & Networking
- **VPC CIDR:** 10.0.0.0/16
- **Public Subnets:** 10.0.1.0/24 (AZ-1), 10.0.2.0/24 (AZ-2)
- **Private Subnets:** 10.0.11.0/24 (AZ-1), 10.0.12.0/24 (AZ-2)
- **Internet Gateway:** Public internet access
- **NAT Gateway:** Optional (disabled for free tier to save costs)

### Load Balancer
- **Type:** Application Load Balancer (ALB)
- **Deployment:** Public subnets only
- **Protocol:** HTTP/80
- **Target Group:** Points to ECS tasks on port 5000
- **Health Check:** GET /health endpoint

### ECS Fargate
- **Cluster:** simpletimeservice-cluster
- **Service:** simpletimeservice-service
- **Task Definition:** simpletimeservice
- **Launch Type:** FARGATE (serverless containers)
- **Task Placement:** Private subnets only
- **CPU:** 256 units (free tier)
- **Memory:** 512 MB (free tier)
- **Desired Count:** 1 task (adjustable)

### Logging
- **CloudWatch Log Group:** /ecs/simpletimeservice
- **Retention:** 7 days (free tier)
- **Log Driver:** awslogs

## Cost Estimation (Free Tier)

| Resource | Cost | Notes |
|----------|------|-------|
| ALB | $0.0225/hour | Free tier: 750 hours/month |
| ECS Fargate (vCPU) | $0.04048/hour | Free tier: 100 hours/month |
| ECS Fargate (Memory) | $0.004445/hour/GB | Free tier: 100 hours/month |
| NAT Gateway | $0.045/hour | **Disabled** to save costs |
| CloudWatch Logs | Free | Free tier: 5 GB/month |
| **Total/Month** | ~$8-12 | Free tier limits: ALB + 100h Fargate |

### Cost-Saving Optimizations
✅ **ECS Fargate** instead of EC2 (no server management)
✅ **Single AZ deployment possible** (use private_1 only to reduce costs)
✅ **NAT Gateway disabled** (saves $32/month)
✅ **Minimal task sizes** (256 CPU, 512 MB memory)
✅ **CloudWatch retention:** 7 days (minimal storage)
✅ **No container insights** (saves monitoring costs)

## Prerequisites

1. **AWS Account** with free tier eligibility
2. **Terraform** (>= 1.0)
3. **AWS CLI** configured with credentials
4. **Docker image** pushed to ECR or Docker Hub

```bash
# Install Terraform (macOS/Linux)
brew install terraform

# Install Terraform (Windows)
choco install terraform

# Configure AWS CLI
aws configure
```

## Setup Instructions

### 1. Push Docker Image to Registry

```bash
# Login to Docker Hub
docker login

# Tag image
docker tag simpletimeservice:latest <your-docker-hub-username>/simpletimeservice:latest

# Push image
docker push <your-docker-hub-username>/simpletimeservice:latest
```

**Or use AWS ECR:**

```bash
# Create ECR repository
aws ecr create-repository --repository-name simpletimeservice --region us-east-1

# Get ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Tag and push
docker tag simpletimeservice:latest <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/simpletimeservice:latest
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/simpletimeservice:latest
```

### 2. Update Terraform Variables

Edit `terraform.tfvars`:

```hcl
container_image = "your-docker-hub-username/simpletimeservice:latest"
# OR
container_image = "<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/simpletimeservice:latest"
```

### 3. Initialize Terraform

```bash
cd terraform/
terraform init
```

Output:
```
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully configured!
```

### 4. Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the execution plan to ensure all resources match expectations.

### 5. Apply Configuration

```bash
terraform apply tfplan
```

Wait for deployment (2-3 minutes):
```
aws_vpc.main: Creating...
aws_ecs_cluster.main: Creating...
aws_lb.main: Creating...
...
Apply complete! Resources: 18 added.
```

### 6. Test the Service

```bash
# Get ALB URL
terraform output alb_url

# Or manually
ALB_URL=$(terraform output -raw alb_url)
curl $ALB_URL
```

Expected output:
```json
{
  "timestamp": "2025-12-15T14:30:45.123456Z",
  "ip": "203.0.113.42"
}
```

## Common Operations

### View Outputs

```bash
terraform output
```

### Scale Tasks

```bash
# Change desired count
terraform apply -var="ecs_task_count=2"

# Or edit terraform.tfvars and reapply
terraform apply
```

### Update Container Image

```bash
terraform apply -var="container_image=your-repo/simpletimeservice:v2.0"
```

### View Logs

```bash
# Using AWS CLI
aws logs tail /ecs/simpletimeservice --follow

# Or using Terraform output
LOG_GROUP=$(terraform output -raw cloudwatch_log_group)
aws logs tail $LOG_GROUP --follow
```

### Destroy Infrastructure

```bash
terraform destroy
```

## Troubleshooting

### Tasks not starting

```bash
# Check ECS service
aws ecs describe-services --cluster simpletimeservice-cluster --services simpletimeservice-service

# Check logs
aws logs tail /ecs/simpletimeservice --follow
```

### Image pull errors

```bash
# Verify image exists and is accessible
docker inspect <image-uri>

# Check ECR permissions if using private ECR
aws ecr describe-repositories --repository-names simpletimeservice
```

### ALB health checks failing

```bash
# Check security groups
aws ec2 describe-security-groups --group-ids <ecs-sg-id>

# Verify container is running on port 5000
curl localhost:5000/health  # Inside container
```

### DNS not resolving

```bash
# Wait for ALB to fully provision (2-3 minutes)
aws elbv2 describe-load-balancers --names simpletimeservice-alb
```

## Production Improvements

For production deployments, consider:

- ✅ **Enable NAT Gateway** for private subnet internet access
- ✅ **Enable Container Insights** for advanced monitoring
- ✅ **Use HTTPS** with ACM certificates
- ✅ **Configure Auto Scaling** for multiple tasks
- ✅ **Set up CloudWatch Alarms** for monitoring
- ✅ **Use ECR** instead of Docker Hub for images
- ✅ **Enable VPC Flow Logs** for network debugging
- ✅ **Use RDS/DynamoDB** for data persistence
- ✅ **Configure WAF** for ALB protection
- ✅ **Set up CI/CD** pipeline for automated deployments

## File Structure

```
terraform/
├── provider.tf          # AWS provider configuration
├── variables.tf         # Input variables
├── vpc.tf              # VPC, subnets, routing
├── security_groups.tf  # Security groups
├── alb.tf              # Application Load Balancer
├── ecs.tf              # ECS cluster, service, tasks
├── outputs.tf          # Output values
├── backend.tf          # Backend configuration (optional)
└── terraform.tfvars    # Variable values
```

## Terraform Commands Reference

```bash
# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Destroy resources
terraform destroy

# Refresh state
terraform refresh

# Show state
terraform show

# Get specific output
terraform output alb_url
```

## State Management

### Local State (Development)
Current setup stores state locally in `terraform.tfstate`. For team collaboration:

### Remote State (Recommended)
Uncomment backend.tf and configure S3:

```bash
# Create S3 bucket for state
aws s3api create-bucket --bucket my-terraform-state --region us-east-1

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

Then uncomment backend.tf with your bucket name.

## Security Best Practices

✅ **Network Isolation:** Private subnets for tasks
✅ **Security Groups:** Restrictive ingress rules
✅ **IAM Roles:** Minimal permissions for ECS tasks
✅ **Logging:** CloudWatch for audit trails
✅ **Encryption:** Enable by default for AWS services
✅ **Secrets Management:** Use AWS Secrets Manager for sensitive data

## Support & Documentation

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS Free Tier Details](https://aws.amazon.com/free/)

---

**Version:** 1.0.0
**Last Updated:** December 15, 2025
**Status:** ✅ Production-Ready (Free Tier Optimized)
