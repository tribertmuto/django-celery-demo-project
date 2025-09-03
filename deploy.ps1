# Windows Deployment Script

# Stop on error
$ErrorActionPreference = "Stop"

# Load environment variables
if (Test-Path .\local.env) {
    Get-Content .\local.env | ForEach-Object {
        $name, $value = $_.Split('=', 2)
        if ($name -and $value) {
            [Environment]::SetEnvironmentVariable($name.Trim(), $value.Trim(), "Process")
        }
    }
}

# Check for Python
Write-Host "Checking Python installation..."
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "Python is not installed. Please install Python 3.8 or higher and add it to PATH."
    exit 1
}

# Check for PostgreSQL
Write-Host "Checking PostgreSQL installation..."
if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
    Write-Warning "PostgreSQL is not installed or not in PATH. You'll need to install it manually."
}

# Check for Redis
Write-Host "Checking Redis installation..."
if (-not (Get-Service -Name "Redis" -ErrorAction SilentlyContinue)) {
    Write-Warning "Redis is not installed. You'll need to install it manually."
}

# Create and activate virtual environment
Write-Host "Setting up Python virtual environment..."
python -m venv venv
.\venv\Scripts\Activate.ps1

# Install Python dependencies
Write-Host "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Run migrations
Write-Host "Running database migrations..."
python manage.py migrate

# Collect static files
Write-Host "Collecting static files..."
python manage.py collectstatic --noinput

Write-Host "`nDeployment complete!"
Write-Host "To start the application, run the following commands in separate terminals:"
Write-Host "1. Start Redis server (if installed as a service)"
Write-Host "2. Start Celery worker: .\venv\Scripts\celery -A core worker -l info"
Write-Host "3. Start Celery beat: .\venv\Scripts\celery -A core beat -l info"
Write-Host "4. Start the development server: .\venv\Scripts\python manage.py runserver"
Write-Host "`nOr use Docker Compose: docker-compose up --build"
