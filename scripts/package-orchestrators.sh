#!/bin/bash

# Package orchestrators with shared dependencies
# This script copies shared Python modules into each orchestrator directory
# so they can be packaged together by Terraform

set -e

echo "Packaging orchestrators with shared dependencies..."

# Shared modules to copy
SHARED_DIR="shared/python"

# Hotel booking orchestrator
echo "Packaging hotel booking orchestrator..."
cp -r $SHARED_DIR/* hotel-service/src/booking_orchestrator/
echo "✓ Hotel orchestrator packaged"

# Order orchestrator
echo "Packaging order orchestrator..."
cp -r $SHARED_DIR/* order-service/src/order_orchestrator/
echo "✓ Order orchestrator packaged"

# Payment orchestrator
echo "Packaging payment orchestrator..."
cp -r $SHARED_DIR/* payment-service/src/payment_orchestrator/
echo "✓ Payment orchestrator packaged"

echo ""
echo "All orchestrators packaged successfully!"
echo "Now run: terraform apply in each service"
