#!/bin/bash

# Add Sample Products to DynamoDB
# This script populates the Product Service with sample data

set -e

echo "=========================================="
echo "Adding Sample Products to DynamoDB"
echo "=========================================="
echo ""

TABLE_NAME="product-service-product_table-dev"

echo "Adding products to table: $TABLE_NAME"
echo ""

# Product 1: Dell Laptop
echo "Adding: Dell Inspiron 15 Laptop..."
aws dynamodb put-item \
  --table-name $TABLE_NAME \
  --item '{
    "productId": {"S": "prod-001"},
    "name": {"S": "Dell Inspiron 15 Laptop"},
    "description": {"S": "15.6 inch FHD display, Intel Core i5-1135G7, 8GB RAM, 256GB SSD, Windows 11"},
    "price": {"N": "699"},
    "category": {"S": "Electronics"},
    "stock": {"N": "50"},
    "imageUrl": {"S": "https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=400&h=300&fit=crop"}
  }'

# Product 2: HP Laptop
echo "Adding: HP Pavilion Laptop..."
aws dynamodb put-item \
  --table-name $TABLE_NAME \
  --item '{
    "productId": {"S": "prod-002"},
    "name": {"S": "HP Pavilion Laptop"},
    "description": {"S": "14 inch FHD, AMD Ryzen 5 5500U, 16GB RAM, 512GB SSD, Windows 11"},
    "price": {"N": "849"},
    "category": {"S": "Electronics"},
    "stock": {"N": "30"},
    "imageUrl": {"S": "https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400&h=300&fit=crop"}
  }'

# Product 3: MacBook Air
echo "Adding: Apple MacBook Air..."
aws dynamodb put-item \
  --table-name $TABLE_NAME \
  --item '{
    "productId": {"S": "prod-003"},
    "name": {"S": "Apple MacBook Air M2"},
    "description": {"S": "13.6 inch Liquid Retina, Apple M2 chip, 8GB RAM, 256GB SSD, macOS"},
    "price": {"N": "1199"},
    "category": {"S": "Electronics"},
    "stock": {"N": "25"},
    "imageUrl": {"S": "https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=400&h=300&fit=crop"}
  }'

# Product 4: Lenovo ThinkPad
echo "Adding: Lenovo ThinkPad..."
aws dynamodb put-item \
  --table-name $TABLE_NAME \
  --item '{
    "productId": {"S": "prod-004"},
    "name": {"S": "Lenovo ThinkPad E15"},
    "description": {"S": "15.6 inch FHD, Intel Core i7-1165G7, 16GB RAM, 512GB SSD, Windows 11 Pro"},
    "price": {"N": "949"},
    "category": {"S": "Electronics"},
    "stock": {"N": "40"},
    "imageUrl": {"S": "https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=400&h=300&fit=crop"}
  }'

# Product 5: ASUS VivoBook
echo "Adding: ASUS VivoBook..."
aws dynamodb put-item \
  --table-name $TABLE_NAME \
  --item '{
    "productId": {"S": "prod-005"},
    "name": {"S": "ASUS VivoBook 15"},
    "description": {"S": "15.6 inch FHD, AMD Ryzen 7 5700U, 12GB RAM, 512GB SSD, Windows 11"},
    "price": {"N": "649"},
    "category": {"S": "Electronics"},
    "stock": {"N": "35"},
    "imageUrl": {"S": "https://images.unsplash.com/photo-1525547719571-a2d4ac8945e2?w=400&h=300&fit=crop"}
  }'

# Product 6: Microsoft Surface Laptop
echo "Adding: Microsoft Surface Laptop..."
aws dynamodb put-item \
  --table-name $TABLE_NAME \
  --item '{
    "productId": {"S": "prod-006"},
    "name": {"S": "Microsoft Surface Laptop 5"},
    "description": {"S": "13.5 inch PixelSense, Intel Core i5-1235U, 8GB RAM, 256GB SSD, Windows 11"},
    "price": {"N": "999"},
    "category": {"S": "Electronics"},
    "stock": {"N": "20"},
    "imageUrl": {"S": "https://images.unsplash.com/photo-1484788984921-03950022c9ef?w=400&h=300&fit=crop"}
  }'

echo ""
echo "✅ 6 sample products added!"
echo ""
echo "Verifying products..."
curl "https://8s9xp3ko0d.execute-api.us-east-1.amazonaws.com/dev/products" | jq '.'
echo ""
