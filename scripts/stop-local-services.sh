#!/bin/bash

# Stop all locally running microservices

echo "🛑 Stopping Local Microservices..."
echo ""

# Function to stop a service
stop_service() {
    local service_name=$1
    local pid_file="/tmp/${service_name}.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        echo "   Stopping $service_name (PID: $pid)..."
        kill "$pid" 2>/dev/null || echo "   Process already stopped"
        rm "$pid_file"
    else
        echo "   $service_name not running"
    fi
}

# Stop services
stop_service "product-service"
stop_service "cart-service"
stop_service "order-service"
stop_service "payment-service"

echo ""
echo "🧹 Cleaning up Docker containers..."
docker ps -a | grep "sam-local" | awk '{print $1}' | xargs docker rm -f 2>/dev/null || true

echo ""
echo "✅ All services stopped!"
echo ""
