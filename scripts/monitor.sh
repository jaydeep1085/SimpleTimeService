#!/bin/bash
# Monitor deployed service

CLUSTER_NAME=$(terraform -chdir=terraform output -raw ecs_cluster_name 2>/dev/null || echo "simpletimeservice-cluster")
SERVICE_NAME=$(terraform -chdir=terraform output -raw ecs_service_name 2>/dev/null || echo "simpletimeservice-service")
LOG_GROUP=$(terraform -chdir=terraform output -raw cloudwatch_log_group 2>/dev/null || echo "/ecs/simpletimeservice")

echo "=================================================="
echo "SimpleTimeService - Monitoring Dashboard"
echo "=================================================="
echo ""

# Function to display service status
show_status() {
    echo "[Service Status]"
    aws ecs describe-services \
        --cluster "$CLUSTER_NAME" \
        --services "$SERVICE_NAME" \
        --query 'services[0].[runningCount,desiredCount,status]' \
        --output text | awk '{print "  Running: "$1"/"$2" | Status: "$3}'
    echo ""
}

# Function to display recent logs
show_logs() {
    echo "[Recent Logs]"
    aws logs tail "$LOG_GROUP" --max-items 10
    echo ""
}

# Function to display ALB health
show_health() {
    echo "[Load Balancer Target Health]"
    aws elbv2 describe-target-health \
        --target-group-arn $(aws elbv2 describe-target-groups --names simpletimeservice-tg --query 'TargetGroups[0].TargetGroupArn' --output text) \
        --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' \
        --output text | awk '{print "  "$1": "$2}'
    echo ""
}

# Display all information
show_status
show_health
show_logs

echo "[Commands]"
echo "  View all logs:     aws logs tail $LOG_GROUP --follow"
echo "  Get ALB URL:       terraform -chdir=terraform output alb_url"
echo "  Scale tasks:       aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --desired-count N"
echo ""
