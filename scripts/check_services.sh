#!/bin/bash

# Exit on error
set -e

echo "🔍 Checking services..."

# Function to check if a service is running
check_service() {
    local name=$1
    local cmd=$2
    
    echo -n "Checking $name... "
    if eval "$cmd" &> /dev/null; then
        echo "✅"
        return 0
    else
        echo "❌"
        return 1
    fi
}

# Check Docker services
echo "\n🐳 Checking Docker services..."
check_service "Docker" "docker info"
check_service "Docker Compose" "docker-compose version"

# Check if containers are running
check_service "Django container" "docker-compose ps web | grep Up"
check_service "PostgreSQL container" "docker-compose ps db | grep Up"
check_service "Redis container" "docker-compose ps redis | grep Up"
check_service "Celery worker" "docker-compose ps celery | grep Up"
check_service "Celery beat" "docker-compose ps celery-beat | grep Up"
check_service "Flower" "docker-compose ps flower | grep Up"

# Check database connection
echo -n "\n🔌 Testing database connection... "
if docker-compose exec db pg_isready -U $POSTGRES_USER -d $POSTGRES_DB &> /dev/null; then
    echo "✅"
else
    echo "❌"
    echo "  Could not connect to PostgreSQL. Make sure the database is running and the credentials are correct."
fi

# Check Redis connection
echo -n "🔌 Testing Redis connection... "
if docker-compose exec redis redis-cli ping | grep -q PONG; then
    echo "✅"
else
    echo "❌"
    echo "  Could not connect to Redis. Make sure Redis is running."
fi

# Check Django application
echo -n "\n🌐 Testing Django application... "
if curl -s http://localhost:8000/health/ | grep -q healthy; then
    echo "✅"
else
    echo "❌"
    echo "  Django application is not responding. Check the logs with: docker-compose logs web"
fi

# Check Celery worker
echo -n "🔧 Testing Celery worker... "
if docker-compose exec celery celery -A core status &> /dev/null; then
    echo "✅"
else
    echo "❌"
    echo "  Celery worker is not responding. Check the logs with: docker-compose logs celery"
fi

# Check Flower monitoring
echo -n "🌸 Testing Flower monitoring... "
if curl -s http://localhost:5555/ &> /dev/null; then
    echo "✅"
    echo "  Flower is running at: http://localhost:5555"
else
    echo "❌"
    echo "  Flower is not running. Check the logs with: docker-compose logs flower"
fi

echo "\n📊 Service Status Summary:"
docker-compose ps

echo "\n📈 Resource Usage:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

echo "\n✅ Health check completed."
echo "For more detailed logs, use: docker-compose logs [service]"
echo "To restart all services: docker-compose restart"
