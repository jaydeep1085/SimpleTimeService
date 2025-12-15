# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/simpletimeservice"
  retention_in_days = 7

  tags = {
    Name = "simpletimeservice-logs"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "simpletimeservice-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    Name = "simpletimeservice-cluster"
  }
}

# ECS Cluster Capacity Providers (for EC2 launch type)
# Using default capacity provider strategy for EC2 launch type
# Capacity provider registration is handled automatically by ASG

# Get latest ECS-optimized AMI
data "aws_ami" "ecs" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Launch Template for EC2 instances
resource "aws_launch_template" "ecs" {
  name_prefix   = "simpletimeservice-ecs-"
  image_id      = data.aws_ami.ecs.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "ECS_CLUSTER=simpletimeservice-cluster" >> /etc/ecs/ecs.config
    echo "ECS_AVAILABLE_LOGGING_DRIVERS=[\"json-file\",\"awslogs\"]" >> /etc/ecs/ecs.config
  EOF
  )

  vpc_security_group_ids = [aws_security_group.ecs_tasks.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "simpletimeservice-ecs-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_iam_instance_profile.ecs_instance]
}

# Auto Scaling Group for ECS EC2 instances
resource "aws_autoscaling_group" "ecs" {
  name                = "simpletimeservice-asg"
  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  min_size            = var.min_capacity
  max_size            = var.max_capacity
  desired_capacity    = var.desired_capacity
  health_check_type   = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "simpletimeservice-ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_ecs_cluster.main]
}

# ECS Task Definition (EC2 launch type with awsvpc)
resource "aws_ecs_task_definition" "main" {
  family                   = "simpletimeservice"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = "simpletimeservice"
    image     = var.container_image
    essential = true

    portMappings = [{
      containerPort = var.container_port
      hostPort      = var.container_port
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 10
    }

    memory = 512
    cpu    = 256
  }])

  tags = {
    Name = "simpletimeservice-task-def"
  }
}

# ECS Service (EC2 launch type with awsvpc)
resource "aws_ecs_service" "main" {
  name            = "simpletimeservice-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_capacity
  launch_type     = "EC2"

  network_configuration {
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "simpletimeservice"
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener.main,
    aws_autoscaling_group.ecs,
    aws_iam_role_policy.ecs_task_execution
  ]

  tags = {
    Name = "simpletimeservice-service"
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "simpletimeservice-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "simpletimeservice-ecs-task-execution-role"
  }
}

# IAM Role Policy for ECS Task Execution
resource "aws_iam_role_policy" "ecs_task_execution" {
  name = "simpletimeservice-ecs-task-execution-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.ecs.arn}:*"
    }]
  })
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ecs_instance_role" {
  name = "simpletimeservice-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "simpletimeservice-ecs-instance-role"
  }
}

# IAM Role Policy for EC2 instances
resource "aws_iam_role_policy" "ecs_instance_policy" {
  name = "simpletimeservice-ecs-instance-policy"
  role = aws_iam_role.ecs_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:CreateCluster",
          "ecs:DeregisterContainerInstance",
          "ecs:DiscoverPollEndpoint",
          "ecs:Poll",
          "ecs:RegisterContainerInstance",
          "ecs:StartTelemetrySession",
          "ecs:Submit*",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ecs_instance" {
  name = "simpletimeservice-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}
