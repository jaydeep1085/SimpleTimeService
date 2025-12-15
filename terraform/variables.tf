variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1" # Free tier region
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "Public subnet 1 CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "Public subnet 2 CIDR"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  description = "Private subnet 1 CIDR"
  type        = string
  default     = "10.0.11.0/24"
}

variable "private_subnet_2_cidr" {
  description = "Private subnet 2 CIDR"
  type        = string
  default     = "10.0.12.0/24"
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 5000
}

variable "container_image" {
  description = "Docker image URI"
  type        = string
  default     = "simpletimeservice:latest"
}

variable "ecs_task_count" {
  description = "Number of ECS tasks (free tier: 1-2)"
  type        = number
  default     = 1
}

variable "ecs_task_cpu" {
  description = "ECS task CPU (free tier: 256)"
  type        = string
  default     = "256"
}

variable "ecs_task_memory" {
  description = "ECS task memory in MB (free tier: 512)"
  type        = string
  default     = "512"
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets (cost: $0.045/hour)"
  type        = bool
  default     = true # Required for EC2 instances in private subnets
}

variable "instance_type" {
  description = "EC2 instance type for ECS (t2.micro for free tier eligibility)"
  type        = string
  default     = "t2.micro"
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances"
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of instances"
  type        = number
  default     = 2
}
