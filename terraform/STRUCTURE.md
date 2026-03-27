# Terraform Structure Guide

## Overview

This Terraform infrastructure follows a **standardized file structure** for better organization and maintainability.

## File Structure Convention

Each Terraform configuration directory contains these standard files:

```
service-name/
├── dev/
│   ├── terraform.tf      # Terraform & backend configuration
│   ├── providers.tf      # AWS provider configuration
│   ├── variables.tf      # Input variables
│   ├── main.tf          # Main resource definitions
│   └── outputs.tf       # Output values
└── prod/
    ├── terraform.tf
    ├── providers.tf
    ├── variables.tf
    ├── main.tf
    └── outputs.tf
```

## File Purposes

### 1. `terraform.tf`
**Purpose:** Terraform configuration and backend setup

**Contains:**
- Terraform version requirements
- Required providers (AWS, Archive, etc.)
- Backend configuration (S3 state storage)

**Example:**
```hcl
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "terraform-state-543927035352"
    key            = "cart-service/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### 2. `providers.tf`
**Purpose:** Provider configuration

**Contains:**
- AWS provider settings
- Region configuration
- Default tags for all resources

**Example:**
```hcl
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "serverless-microservices"
      Service     = "cart-service"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}
```

### 3. `variables.tf`
**Purpose:** Input variable definitions

**Contains:**
- All configurable parameters
- Variable types and descriptions
- Default values

**Example:**
```hcl
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 512
}
```

### 4. `main.tf`
**Purpose:** Main resource definitions

**Contains:**
- Data sources
- Local variables
- Resource definitions
- Module calls

**Example:**
```hcl
# Data sources
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "../../../src"
  output_path = "lambda.zip"
}

# Local variables
locals {
  service_name = var.service_name
  environment  = var.environment
}

# Resources
resource "aws_lambda_function" "this" {
  function_name = "${local.service_name}-${local.environment}"
  # ... configuration
}

# Module calls
module "cart_service" {
  source = "../../modules/lambda-service"
  # ... configuration
}
```

### 5. `outputs.tf`
**Purpose:** Output values

**Contains:**
- Values to export after deployment
- API endpoints, ARNs, names, etc.

**Example:**
```hcl
output "api_gateway_url" {
  description = "API Gateway endpoint URL"
  value       = module.cart_service.api_gateway_url
}

output "lambda_function_names" {
  description = "Names of Lambda functions"
  value       = module.cart_service.lambda_function_names
}
```

## Benefits of This Structure

### 1. **Clarity**
- Each file has a single, clear purpose
- Easy to find specific configurations
- Reduces cognitive load

### 2. **Maintainability**
- Changes are isolated to specific files
- Variables are centralized
- Easy to update configurations

### 3. **Reusability**
- Variables can be overridden easily
- Same structure across all services
- Easy to copy and adapt

### 4. **Team Collaboration**
- Standard structure everyone understands
- Reduces merge conflicts
- Clear separation of concerns

### 5. **Documentation**
- Self-documenting through variable descriptions
- Outputs clearly show what's created
- Easy to understand dependencies

## Usage Examples

### Deploy Cart Service (Production)

```bash
cd terraform/cart-service/prod

# Initialize
terraform init

# Plan with custom variables
terraform plan \
  -var="lambda_memory_size=1024" \
  -var="log_retention_days=90"

# Apply
terraform apply

# View outputs
terraform output
```

### Deploy Agent Service (Production)

```bash
cd terraform/agent-service/prod

# Initialize
terraform init

# Plan with API endpoints
terraform plan \
  -var="product_api_url=https://api.example.com/products" \
  -var="cart_api_url=https://api.example.com/cart" \
  -var="alert_email=admin@example.com"

# Apply
terraform apply

# Get API URL
terraform output api_gateway_url
```

### Override Variables

**Method 1: Command Line**
```bash
terraform apply -var="lambda_memory_size=2048"
```

**Method 2: Variable File**
```bash
# Create terraform.tfvars
cat > terraform.tfvars <<EOF
lambda_memory_size = 2048
log_retention_days = 90
alert_email = "admin@example.com"
EOF

terraform apply
```

**Method 3: Environment Variables**
```bash
export TF_VAR_lambda_memory_size=2048
export TF_VAR_alert_email="admin@example.com"
terraform apply
```

## Directory Structure

```
terraform/
├── STRUCTURE.md                    # This file
├── README.md                       # General Terraform documentation
│
├── modules/                        # Reusable modules
│   ├── lambda-service/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── cicd-pipeline/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── cart-service/                   # Cart service infrastructure
│   ├── dev/
│   │   ├── terraform.tf
│   │   ├── providers.tf
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   └── outputs.tf
│   ├── prod/
│   │   ├── terraform.tf
│   │   ├── providers.tf
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   └── outputs.tf
│   └── pipeline/
│       └── ...
│
├── agent-service/                  # Agent service infrastructure
│   ├── dev/
│   │   ├── terraform.tf
│   │   ├── providers.tf
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   └── outputs.tf
│   └── prod/
│       ├── terraform.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── main.tf
│       └── outputs.tf
│
└── [other services follow same pattern]
```

## Best Practices

### 1. **Variable Naming**
- Use snake_case: `lambda_memory_size`
- Be descriptive: `log_retention_days` not `retention`
- Group related variables together

### 2. **Resource Naming**
- Use consistent patterns: `${var.service_name}-${var.environment}`
- Include environment in names
- Use hyphens for AWS resources

### 3. **Comments**
- Add section headers in main.tf
- Document complex logic
- Explain non-obvious configurations

### 4. **Outputs**
- Export all important values
- Include descriptions
- Group related outputs

### 5. **Variables**
- Always include descriptions
- Set sensible defaults
- Use appropriate types

## Common Commands

```bash
# Initialize
terraform init

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy

# Show current state
terraform show

# List resources
terraform state list

# View outputs
terraform output

# Refresh state
terraform refresh
```

## Troubleshooting

### State Lock Issues
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### State Drift
```bash
# Refresh state from AWS
terraform refresh

# Import existing resource
terraform import aws_lambda_function.this function-name
```

### Variable Issues
```bash
# Check variable values
terraform console
> var.lambda_memory_size
```

## Migration from Old Structure

If you have existing Terraform configurations in the old format:

1. **Create new files:**
   ```bash
   touch terraform.tf providers.tf variables.tf outputs.tf
   ```

2. **Split main.tf:**
   - Move `terraform {}` block to `terraform.tf`
   - Move `provider` blocks to `providers.tf`
   - Move `variable` blocks to `variables.tf`
   - Move `output` blocks to `outputs.tf`
   - Keep resources in `main.tf`

3. **Test:**
   ```bash
   terraform init
   terraform plan  # Should show no changes
   ```

4. **Commit:**
   ```bash
   git add .
   git commit -m "Restructure Terraform files for clarity"
   ```

## Summary

This standardized structure makes Terraform configurations:
- **Easier to understand** - Clear file purposes
- **Easier to maintain** - Isolated changes
- **Easier to collaborate** - Standard patterns
- **Easier to scale** - Reusable patterns

All services follow the same structure, making it simple to work across different parts of the infrastructure.
