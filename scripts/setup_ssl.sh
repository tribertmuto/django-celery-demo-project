#!/bin/bash

# Exit on error
set -e

# Check if domain is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <domain> [email]"
    exit 1
fi

DOMAIN=$1
EMAIL=${2:-admin@$DOMAIN}
CERTBOT_IMAGE=certbot/certbot

# Create necessary directories
mkdir -p certs/conf/live/$DOMAIN
mkdir -p certs/www

# Create a temporary nginx configuration for the challenge
echo "server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
}" > nginx/temp-nginx.conf

# Start nginx with the temporary configuration
echo "Starting temporary nginx server..."
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d nginx

# Create dummy certificate first to make nginx happy
echo "Creating dummy certificate..."
openssl req -x509 -nodes -newkey rsa:4096 \
    -days 1 \
    -keyout certs/conf/live/$DOMAIN/privkey.pem \
    -out certs/conf/live/$DOMAIN/fullchain.pem \
    -subj "/CN=$DOMAIN"

# Restart nginx with the dummy certificate
echo "Restarting nginx with dummy certificate..."
docker-compose -f docker-compose.yml -f docker-compose.prod.yml restart nginx

# Remove the dummy certificate
echo "Removing dummy certificate..."
rm -rf certs/conf/live/$DOMAIN/*

# Request the real certificate
echo "Requesting Let's Encrypt certificate for $DOMAIN..."
docker run -it --rm \
    -v "$(pwd)/certs/conf:/etc/letsencrypt" \
    -v "$(pwd)/certs/www:/var/www/certbot" \
    $CERTBOT_IMAGE certonly \
    --webroot \
    --webroot-path /var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d $DOMAIN \
    -d www.$DOMAIN

# Set proper permissions
echo "Setting proper permissions..."
sudo chown -R $USER:$USER certs/conf/live
sudo chmod -R 755 certs/conf/live

# Restart nginx with the real certificate
echo "Restarting nginx with the real certificate..."
docker-compose -f docker-compose.yml -f docker-compose.prod.yml restart nginx

echo "SSL certificate setup complete!"
echo "Certificate location: certs/conf/live/$DOMAIN/"

# Clean up
echo "Cleaning up..."
rm nginx/temp-nginx.conf

echo "Done! Your site should now be available at https://$DOMAIN"
