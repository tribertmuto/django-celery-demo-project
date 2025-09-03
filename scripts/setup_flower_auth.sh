#!/bin/bash

# Exit on error
set -e

# Check if username and password are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <username> <password>"
    exit 1
fi

USERNAME=$1
PASSWORD=$2

# Create the .htpasswd file with the provided credentials
docker run --rm httpd:2.4-alpine htpasswd -nbB $USERNAME $PASSWORD > nginx/.htpasswd

echo "Flower authentication has been set up successfully."
echo "Restarting Nginx to apply changes..."

docker-compose -f docker-compose.yml -f docker-compose.prod.yml restart nginx

echo "Flower monitoring is now protected with Basic Authentication."
echo "Access it at: https://yourdomain.com/flower/"
echo "Username: $USERNAME"
