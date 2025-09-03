#!/usr/bin/env python3
"""
Generate a production environment file with secure defaults.
"""
import os
import secrets
import string
from pathlib import Path

def generate_secret_key(length=50):
    """Generate a random secret key."""
    chars = string.ascii_letters + string.digits + "!@#$%^&*(-_=+)"
    return ''.join(secrets.choice(chars) for _ in range(length))

def main():
    # Define the output file
    output_file = ".env.prod"
    
    # Check if file already exists
    if os.path.exists(output_file):
        print(f"{output_file} already exists. Backing up to {output_file}.bak")
        if os.path.exists(f"{output_file}.bak"):
            os.remove(f"{output_file}.bak")
        os.rename(output_file, f"{output_file}.bak")
    
    # Generate secure values
    secret_key = generate_secret_key()
    db_password = generate_secret_key(16)
    redis_password = generate_secret_key(32)
    
    # Get the current directory name for default values
    default_project_name = Path.cwd().name.lower().replace('-', '_')
    
    # Template for production environment
    template = f"""# Django Settings
DEBUG=False
SECRET_KEY='{secret_key}'
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com,localhost,127.0.0.1

# Database
POSTGRES_DB={default_project_name}_prod
POSTGRES_USER={default_project_name}_user
POSTGRES_PASSWORD={db_password}
POSTGRES_HOST=db
POSTGRES_PORT=5432

# Redis
REDIS_PASSWORD={redis_password}

# Celery
CELERY_BROKER_URL=redis://:{redis_password}@redis:6379/0
CELERY_RESULT_BACKEND=redis://:{redis_password}@redis:6379/1

# Email (configure with your email provider)
EMAIL_HOST=smtp.sendgrid.net
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=apikey
EMAIL_HOST_PASSWORD=your-sendgrid-api-key
DEFAULT_FROM_EMAIL=noreply@yourdomain.com

# CORS (update with your frontend domain)
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# Security (recommended for production)
CSRF_TRUSTED_ORIGINS=https://*.yourdomain.com,https://yourdomain.com
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
SECURE_BROWSER_XSS_FILTER=True
SECURE_CONTENT_TYPE_NOSNIFF=True
X_FRAME_OPTIONS="DENY"
SECURE_HSTS_SECONDS=31536000  # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS=True
SECURE_HSTS_PRELOAD=True

# Logging
LOG_LEVEL=INFO
LOG_FILE=/var/log/django/{default_project_name}.log

# Application specific settings
DJANGO_SETTINGS_MODULE=core.settings
"""
    # Write to file
    with open(output_file, 'w') as f:
        f.write(template)
    
    print(f"Generated {output_file} with secure defaults.")
    print("\nIMPORTANT: Please review and update the following:")
    print("1. Update ALLOWED_HOSTS with your domain(s)")
    print("2. Configure your email settings")
    print("3. Update CORS_ALLOWED_ORIGINS with your frontend domain(s)")
    print("4. Update CSRF_TRUSTED_ORIGINS with your domain(s)")
    print("\nKeep this file secure and do not commit it to version control!")

if __name__ == "__main__":
    main()
