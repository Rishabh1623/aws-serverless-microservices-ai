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
    "imageUrl": {"S": "https://i.dell.com/is/image/DellContent/content/dam/ss2/product-images/dell-client-products/notebooks/inspiron-notebooks/15-3520/media-gallery/notebook-inspiron-15-3520-nt-blue-gallery-4.psd?fmt=png-alpha&pscan=auto&scl=1&hei=402&wid=402&qlt=100,1&resMode=sharp2&size=402,402&chrss=full"}
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
    "imageUrl": {"S": "https://ssl-product-images.www8-hp.com/digmedialib/prodimg/lowres/c08260396.png"}
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
    "imageUrl": {"S": "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/macbook-air-midnight-select-20220606?wid=904&hei=840&fmt=jpeg&qlt=90&.v=1653084303665"}
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
    "imageUrl": {"S": "https://p3-ofp.static.pub/fes/cms/2021/05/14/sza0qfcgzw3vxnabsaey7vv8yg4wd1427965.png"}
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
    "imageUrl": {"S": "https://dlcdnwebimgs.asus.com/gain/8BC8B3F0-3F3D-4F9E-9F0D-7F3E3C3F3F3F/w717/h525"}
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
    "imageUrl": {"S": "https://img-prod-cms-rt-microsoft-com.akamaized.net/cms/api/am/imageFileData/RE4LqQX?ver=c5c3"}
  }'

echo ""
echo "✅ 6 sample products added!"
echo ""
echo "Verifying products..."
curl "https://8s9xp3ko0d.execute-api.us-east-1.amazonaws.com/dev/products" | jq '.'
echo ""
