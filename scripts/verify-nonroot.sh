#!/bin/bash
# Verify that the application runs as non-root user

echo "Checking if service runs as non-root user..."

# Get the user ID running inside the container
CONTAINER_ID=$(docker ps -q -f "name=simpletimeservice")

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ Error: simpletimeservice container is not running"
    echo "Start the container with: docker run -d --name simpletimeservice -p 5000:5000 simpletimeservice:latest"
    exit 1
fi

# Check user running the process
UID=$(docker exec "$CONTAINER_ID" id -u)
USERNAME=$(docker exec "$CONTAINER_ID" id -un)

if [ "$UID" = "0" ]; then
    echo "❌ FAIL: Application is running as root (uid: 0)"
    echo "Security risk: Container should run as non-root user"
    exit 1
fi

echo "✅ PASS: Application runs as non-root user"
echo "   User: $USERNAME (uid: $UID)"

# Additional security checks
echo ""
echo "Additional security information:"
docker exec "$CONTAINER_ID" id
