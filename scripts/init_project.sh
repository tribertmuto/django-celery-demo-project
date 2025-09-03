#!/bin/bash

# Exit on error
set -e

echo "🚀 Initializing Django Celery Demo Project..."

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "🔧 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate  # On Windows, use: .\venv\Scripts\activate

# Install dependencies
echo "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "🔧 Creating .env file from .env.example..."
    cp .env.example .env
    echo "⚠️ Please update the .env file with your configuration"
fi

# Set up pre-commit hooks
echo "🔧 Setting up pre-commit hooks..."
pip install pre-commit
pre-commit install

# Start Docker services
echo "🐳 Starting Docker services..."
docker-compose up -d db redis

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
until docker-compose exec db pg_isready -U $POSTGRES_USER -d $POSTGRES_DB; do
    echo "⌛ Waiting for PostgreSQL..."
    sleep 2
done

# Run database migrations
echo "🔄 Running database migrations..."
python manage.py migrate

# Create superuser if it doesn't exist
echo "👤 Creating superuser (if not exists)..."
cat <<EOF | python manage.py shell
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin')
EOF

echo "✨ Project setup complete!"
echo ""
echo "To start the development server, run:"
echo "  python manage.py runserver"
echo ""
echo "To start Celery worker, run in a new terminal:"
echo "  celery -A core worker -l info"
echo ""
echo "To start Celery beat, run in another terminal:"
echo "  celery -A core beat -l info"
echo ""
echo "Access the admin interface at: http://localhost:8000/admin/"
echo "Username: admin"
echo "Password: admin"
echo ""
echo "Access the API documentation at: http://localhost:8000/swagger/"
echo ""
echo "🚀 Happy coding!"
