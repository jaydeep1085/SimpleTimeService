# SimpleTimeService - Quick Reference

## One-Command Deployment

```bash
# Set your Docker Hub username
export DOCKER_USERNAME="your-docker-hub-username"

# Update terraform.tfvars
sed -i "s|container_image = .*|container_image = \"$DOCKER_USERNAME/simpletimeservice:latest\"|" terraform/terraform.tfvars

# Deploy
terraform -chdir=terraform init && terraform -chdir=terraform apply -auto-approve

# Get URL
terraform -chdir=terraform output alb_url
```

## Infrastructure Overview

```
VPC (10.0.0.0/16)
├── Public Subnets (ALB)
│   ├── 10.0.1.0/24 (us-east-1a)
│   └── 10.0.2.0/24 (us-east-1b)
├── Private Subnets (ECS Tasks)
│   ├── 10.0.11.0/24 (us-east-1a)
│   └── 10.0.12.0/24 (us-east-1b)
└── Application Load Balancer (port 80)
    └── ECS Fargate Service (port 5000)
        └── 1x Task (256 CPU, 512 MB memory)
```

## Cost Breakdown (Free Tier)

| Service | Free Tier | Cost |
|---------|-----------|------|
| ALB | 750 hours/month | Included |
| ECS Fargate | 100 vCPU-hours/month | Included |
| ECS Fargate | 100 GB-hours/month | Included |
| CloudWatch Logs | 5 GB/month | Included |
| **TOTAL** | **For 1-2 weeks** | **FREE** |

> After free tier: ~$0.015/hour (~$10.80/month)

## Terraform Variables

```hcl
aws_region              = "us-east-1"      # Free tier region
environment             = "dev"
ecs_task_count          = 1                # Start with 1 task
ecs_task_cpu            = "256"            # Free tier: 256 units
ecs_task_memory         = "512"            # Free tier: 512 MB
enable_nat_gateway      = false            # Disable to save $32/month
container_image         = "your-image"     # Your Docker image URI
```

## Common Tasks

### Push Docker Image

```bash
# Docker Hub
docker tag simpletimeservice:latest $DOCKER_USERNAME/simpletimeservice:latest
docker push $DOCKER_USERNAME/simpletimeservice:latest

# Or AWS ECR
aws ecr create-repository --repository-name simpletimeservice
aws ecr get-login-password | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
docker tag simpletimeservice:latest <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/simpletimeservice:latest
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/simpletimeservice:latest
```

### Deploy to AWS

```bash
# Initialize
terraform -chdir=terraform init

# Plan
terraform -chdir=terraform plan

# Apply
terraform -chdir=terraform apply

# Get URL
terraform -chdir=terraform output alb_url
```

### Scale Service

```bash
# Scale to 2 tasks
terraform -chdir=terraform apply -var="ecs_task_count=2"

# Or via AWS CLI
aws ecs update-service \
  --cluster simpletimeservice-cluster \
  --service simpletimeservice-service \
  --desired-count 2
```

### Monitor Service

```bash
# View logs
aws logs tail /ecs/simpletimeservice --follow

# Check service status
aws ecs describe-services \
  --cluster simpletimeservice-cluster \
  --services simpletimeservice-service

# Check task health
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --names simpletimeservice-tg \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)
```

### Test Service

```bash
# Get ALB URL
ALB_URL=$(terraform -chdir=terraform output -raw alb_url)

# Test main endpoint
curl $ALB_URL

# Test health endpoint
curl $ALB_URL/health

# Test with jq
curl -s $ALB_URL | jq .
```

### Destroy Infrastructure

```bash
terraform -chdir=terraform destroy
```

## Troubleshooting

### Tasks not starting

```bash
# Check service events
aws ecs describe-services \
  --cluster simpletimeservice-cluster \
  --services simpletimeservice-service

# View task logs
aws logs tail /ecs/simpletimeservice --follow

# Describe tasks
aws ecs list-tasks \
  --cluster simpletimeservice-cluster \
  --service-name simpletimeservice-service

aws ecs describe-tasks \
  --cluster simpletimeservice-cluster \
  --tasks <task-arn>
```

### Image pull errors

```bash
# Verify image exists
docker inspect $DOCKER_USERNAME/simpletimeservice:latest

# Check ECR permissions (if using ECR)
aws ecr describe-repositories --repository-names simpletimeservice
```

### ALB not responding

```bash
# Check ALB security group
aws ec2 describe-security-groups \
  --group-ids $(aws elbv2 describe-load-balancers \
    --names simpletimeservice-alb \
    --query 'LoadBalancers[0].SecurityGroups[0]' \
    --output text)

# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>
```

## AWS CLI Aliases (Optional)

```bash
# Add to ~/.bashrc or ~/.zshrc
alias sts-describe='aws ecs describe-services --cluster simpletimeservice-cluster --services simpletimeservice-service'
alias sts-logs='aws logs tail /ecs/simpletimeservice --follow'
alias sts-tasks='aws ecs list-tasks --cluster simpletimeservice-cluster'
alias sts-url='terraform -chdir=terraform output alb_url'
```

## File Descriptions

| File | Purpose |
|------|---------|
| `provider.tf` | AWS provider and Terraform settings |
| `variables.tf` | Input variables with defaults |
| `vpc.tf` | VPC, subnets, routing, IGW |
| `security_groups.tf` | ALB and ECS security groups |
| `alb.tf` | Application Load Balancer |
| `ecs.tf` | ECS cluster, service, tasks, IAM |
| `outputs.tf` | Output values (URL, cluster name, etc) |
| `backend.tf` | Optional remote state configuration |
| `terraform.tfvars` | Variable values for deployment |
| `README.md` | Full documentation |

## Resources Created

```
✓ VPC (1)
✓ Internet Gateway (1)
✓ Public Subnets (2)
✓ Private Subnets (2)
✓ Route Tables (2)
✓ Route Table Associations (4)
✓ Security Groups (2)
✓ Application Load Balancer (1)
✓ Target Group (1)
✓ ALB Listener (1)
✓ ECS Cluster (1)
✓ ECS Service (1)
✓ ECS Task Definition (1)
✓ IAM Role (1)
✓ IAM Role Policy (1)
✓ CloudWatch Log Group (1)
─────────────────────────────
Total: ~18 resources
```

## Estimated Costs (After Free Tier)

| Component | Hourly | Monthly |
|-----------|--------|---------|
| ALB | $0.0225 | $16.20 |
| ECS Fargate (vCPU) | $0.04048 | $29.15 |
| ECS Fargate (Memory) | $0.004445 | $3.20 |
| NAT Gateway (if enabled) | $0.045 | $32.40 |
| **TOTAL** | **~$0.115** | **~$80.95** |

> Use `enable_nat_gateway = false` to save $32.40/month

## Additional Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Fargate Pricing](https://aws.amazon.com/ecs/pricing/)
- [AWS Free Tier Details](https://aws.amazon.com/free/)
- [ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/best_practices.html)

---

**Version:** 1.0.0
**Last Updated:** December 15, 2025
