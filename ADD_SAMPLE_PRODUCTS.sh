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
    "description": {"S": "15.6 inch FHD display, Intel Core i5, 8GB RAM, 256GB SSD"},
    "price": {"N": "699"},
    "category": {"S": "Electronics"},
    "stock": {"N": "50"}
  }'

# Product 2: HP Laptop
echo "Adding: HP Pavilion Laptop..."
aws dynamodb put-item \
  --table-name $TABLE_NAME \
  --item '{
    "productId": {"S": "prod-002"},
    "name": {"S": "HP Pavilion Laptop"},
    "description": {"S": "14 inch FHD, AMD Ryzen 5, 16GB RAM, 512GB SSD"},
    "price": {"N": "849"},
    "category": {"S": "Electronics"},
    "stock": {"N": "30"}
  }'

# Product 3: MacBook Air
echo "Adding: Apple MacBook Air..."
aws dynamodb put-item \
  --table-name $TABLE_NAME \
  --item '{
    "productId": {"S": "prod-003"},
    "name": {"S": "Apple MacBook Air M2"},
    "description": {"S": "13.6 inch Liquid Retina, M2 chip, 8GB RAM, 256GB SSD"},
    "price": {"N": "1199"},
    "category": {"S": "Electronics"},
    "stock": {"N": "25"}
  }'

echo ""
echo "✅ Sample products added!"
echo ""
echo "Verifying products..."
curl "https://8s9xp3ko0d.execute-api.us-east-1.amazonaws.com/dev/products" | jq '.'
echo ""
