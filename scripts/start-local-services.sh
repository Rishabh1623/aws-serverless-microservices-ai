#!/bin/bash

# Start all microservices locally using SAM CLI
# Each service runs on a different port

echo "🚀 Starting Local Microservices..."
echo ""

# Check if SAM CLI is installed
if ! command -v sam &> /dev/null; then
    echo "❌ SAM CLI not found. Please install it first:"
    echo "   https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

# Function to start a service
start_service() {
    local service_name=$1
    local port=$2
    local service_dir=$3
    
    echo "📦 Starting $service_name on port $port..."
    
    cd "$service_dir" || exit
    
    # Build if not already built
    if [ ! -d ".aws-sam" ]; then
        echo "   Building $service_name..."
        sam build --quiet
    fi
    
    # Start API in background
    sam local start-api --port "$port" --warm-containers EAGER > "/tmp/${service_name}.log" 2>&1 &
    local pid=$!
    echo "   PID: $pid"
    echo "$pid" > "/tmp/${service_name}.pid"
    
    cd - > /dev/null || exit
    echo ""
}

# Get project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Start services
start_service "product-service" 3001 "$PROJECT_ROOT/product-service"
start_service "cart-service" 3002 "$PROJECT_ROOT/cart-service"
start_service "order-service" 3003 "$PROJECT_ROOT/order-service"
start_service "payment-service" 3004 "$PROJECT_ROOT/payment-service"

echo "⏳ Waiting for services to start (30 seconds)..."
sleep 30

echo ""
echo "✅ All services started!"
echo ""
echo "📍 Service Endpoints:"
echo "   Product Service:  http://localhost:3001"
echo "   Cart Service:     http://localhost:3002"
echo "   Order Service:    http://localhost:3003"
echo "   Payment Service:  http://localhost:3004"
echo ""
echo "📋 Logs:"
echo "   tail -f /tmp/product-service.log"
echo "   tail -f /tmp/cart-service.log"
echo "   tail -f /tmp/order-service.log"
echo "   tail -f /tmp/payment-service.log"
echo ""
echo "🛑 To stop all services, run:"
echo "   bash scripts/stop-local-services.sh"
echo ""
echo "🧪 Test endpoints:"
echo "   curl http://localhost:3001/products"
echo "   curl http://localhost:3002/cart/user123"
echo ""
