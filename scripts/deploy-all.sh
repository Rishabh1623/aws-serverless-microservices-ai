#!/bin/bash

# ============================================================================
# Deploy All Services Script
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install it first."
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform not found. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    fi
    
    print_success "All prerequisites met!"
}

# Function to deploy a service
deploy_service() {
    local service_name=$1
    local service_path=$2
    
    print_info "Deploying $service_name..."
    
    cd "$service_path"
    
    # Initialize Terraform
    terraform init -input=false
    
    # Plan
    terraform plan -out=tfplan
    
    # Apply
    terraform apply -auto-approve tfplan
    
    # Clean up plan file
    rm -f tfplan
    
    # Get API URL if available
    if terraform output api_gateway_url &> /dev/null; then
        local api_url=$(terraform output -raw api_gateway_url)
        print_success "$service_name deployed! API URL: $api_url"
        
        # Export for later use
        export "${service_name^^}_API=$api_url"
    else
        print_success "$service_name deployed!"
    fi
    
    cd - > /dev/null
}

# Main deployment flow
main() {
    print_info "Starting deployment of all services..."
    echo ""
    
    # Check prerequisites
    check_prerequisites
    echo ""
    
    # Get project root
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
    
    print_info "Project root: $PROJECT_ROOT"
    echo ""
    
    # Ask for Stripe API key
    print_warning "Payment service requires Stripe API key"
    read -p "Enter Stripe API key (or press Enter for demo key): " stripe_key
    if [ -z "$stripe_key" ]; then
        stripe_key="sk_test_demo_key"
        print_warning "Using demo Stripe key"
    fi
    export TF_VAR_stripe_api_key="$stripe_key"
    echo ""
    
    # 1. Deploy Bootstrap
    print_info "Step 1/6: Deploying Bootstrap..."
    deploy_service "bootstrap" "$PROJECT_ROOT/terraform/bootstrap"
    echo ""
    
    # 2. Deploy Hotel Service
    print_info "Step 2/6: Deploying Hotel Service..."
    deploy_service "hotel-service" "$PROJECT_ROOT/terraform/hotel-service/dev"
    echo ""
    
    # 3. Deploy Cart Service
    print_info "Step 3/6: Deploying Cart Service..."
    deploy_service "cart-service" "$PROJECT_ROOT/terraform/cart-service/dev"
    echo ""
    
    # 4. Deploy Order Service
    print_info "Step 4/6: Deploying Order Service..."
    deploy_service "order-service" "$PROJECT_ROOT/terraform/order-service/dev"
    echo ""
    
    # 5. Deploy Payment Service
    print_info "Step 5/6: Deploying Payment Service..."
    deploy_service "payment-service" "$PROJECT_ROOT/terraform/payment-service/dev"
    echo ""
    
    # 6. Deploy Agent Service
    print_info "Step 6/6: Deploying Agent Service..."
    deploy_service "agent-service" "$PROJECT_ROOT/terraform/agent-service/dev"
    echo ""
    
    # Summary
    print_success "========================================="
    print_success "All services deployed successfully!"
    print_success "========================================="
    echo ""
    
    print_info "API Endpoints:"
    echo "  Hotel Service:   ${HOTEL_SERVICE_API:-Not available}"
    echo "  Cart Service:    ${CART_SERVICE_API:-Not available}"
    echo "  Order Service:   ${ORDER_SERVICE_API:-Not available}"
    echo "  Payment Service: ${PAYMENT_SERVICE_API:-Not available}"
    echo "  Agent Service:   ${AGENT_SERVICE_API:-Not available}"
    echo ""
    
    print_info "Next steps:"
    echo "  1. Add sample data: cd scripts && ./add-sample-hotels.sh"
    echo "  2. Configure frontend: cd frontend && create .env file"
    echo "  3. Test APIs: See DEPLOYMENT_GUIDE.md for examples"
    echo ""
    
    print_success "Deployment complete! 🎉"
}

# Run main function
main
