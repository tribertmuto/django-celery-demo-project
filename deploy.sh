#!/bin/bash

# Exit on error
set -e

# Load environment variables
if [ -f local.env ]; then
    export $(grep -v '^#' local.env | xargs)
fi

# Install system dependencies
echo "Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y python3-pip python3-venv postgresql postgresql-contrib redis-server

# Install Docker (if not already installed)
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# Install Docker Compose (if not already installed)
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Create a virtual environment
echo "Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Set up the database
echo "Setting up the database..."
sudo -u postgres psql -c "CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';" || true
sudo -u postgres psql -c "CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER;" || true

# Run migrations
echo "Running database migrations..."
python manage.py migrate

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

echo "\nDeployment complete!"
echo "To start the application, run:"
echo "1. Start Redis: sudo systemctl start redis"
echo "2. Start Celery worker: celery -A core worker -l info"
echo "3. Start Celery beat: celery -A core beat -l info"
echo "4. Start the development server: python manage.py runserver"
echo "\nOr use Docker Compose: docker-compose up --build"
