.PHONY: build run test stop clean logs push

# Build Docker image
build:
	docker build -t simpletimeservice:latest app/

# Run container in detached mode
run:
	docker run -d --name simpletimeservice -p 5000:5000 simpletimeservice:latest

# Run container in foreground (useful for development)
run-fg:
	docker run -p 5000:5000 simpletimeservice:latest

# Test endpoints
test:
	@echo "Testing main endpoint..."
	curl -s http://localhost:5000/ | python -m json.tool
	@echo "\nTesting health endpoint..."
	curl -s http://localhost:5000/health | python -m json.tool

# View logs
logs:
	docker logs -f simpletimeservice

# Stop container
stop:
	docker stop simpletimeservice || true
	docker rm simpletimeservice || true

# Clean - remove images and containers
clean: stop
	docker rmi simpletimeservice:latest || true

# Build and run (quick start)
start: build stop run
	@echo "Service started at http://localhost:5000"

# Rebuild and run
rebuild: clean build run
	@echo "Service rebuilt and started at http://localhost:5000"
