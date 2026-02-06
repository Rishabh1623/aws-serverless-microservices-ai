# Product Service

## Problem Statement

In monolithic Lambda repositories, product-related functions (GetProduct, ListProducts) are mixed with hundreds of other functions across different domains. This creates:
- Deployment bottlenecks where product changes require full platform deployment
- Unclear ownership between teams
- Tight coupling with unrelated services
- Difficult performance optimization for product catalog operations

## Why This is Its Own Service

The product service represents a distinct bounded context:
- **Shared Domain**: All functions operate on product catalog data
- **Single Data Model**: Uses one DynamoDB table (ProductTable) with GSI for category queries
- **Team Ownership**: Typically owned by the catalog/inventory team
- **Independent Scaling**: Product reads may have different traffic patterns than cart or orders
- **Performance Isolation**: Product catalog optimizations don't impact other services

## Architecture

```
API Gateway (/products/*)
    ├── GET /products/{productId}  → GetProduct Lambda
    └── GET /products?category=X   → ListProducts Lambda
                                            ↓
                                    ProductTable (DynamoDB)
                                    └── CategoryIndex (GSI)
```

## CI/CD Flow

```
GitHub Push (main)
    ↓
Source Stage (CodePipeline)
    ↓
Build & Test (CodeBuild)
    - Install dependencies
    - Run unit tests
    - sam build
    - sam package
    ↓
Deploy to Dev
    - sam deploy --config-env dev
    - Automated deployment
    ↓
Manual Approval
    - Review dev environment
    - Approve for production
    ↓
Deploy to Prod
    - sam deploy --config-env prod
    - Canary deployment (10% → 100%)
    - Auto-rollback on errors
```

## Deployment Strategy

- **Lambda Versions & Aliases**: Every deployment creates a new version with `live` alias
- **Canary Deployment**: 10% traffic for 5 minutes, then 100% if no errors
- **Auto-Rollback**: CloudWatch alarms trigger automatic rollback on failures
- **Environment Separation**: Completely isolated dev and prod stacks
- **GSI for Performance**: CategoryIndex enables efficient category-based queries

## Blast Radius Reduction

**Before (Monolithic)**:
- Product changes require deploying entire platform
- Risk of breaking cart, order, or payment services
- Shared CI/CD pipeline creates deployment queues
- Product team blocked by other teams' changes

**After (Microservices)**:
- Product team deploys independently
- Product failures don't impact cart or orders
- Faster iteration on catalog features
- Clear performance metrics per service

## Local Development

```bash
# Install dependencies
cd product-service
pip install -r requirements.txt -t src/get_product/
pip install -r requirements.txt -t src/list_products/

# Run tests
python -m pytest tests/

# Build
sam build

# Deploy to dev
sam deploy --config-env dev

# Deploy to prod
sam deploy --config-env prod
```

## API Endpoints

### Get Product by ID
```bash
GET /products/prod123
```

Response:
```json
{
  "product": {
    "productId": "prod123",
    "name": "Wireless Headphones",
    "category": "electronics",
    "price": 99.99,
    "stock": 50
  }
}
```

### List Products
```bash
# All products
GET /products

# Filter by category
GET /products?category=electronics

# Limit results
GET /products?limit=20
```

Response:
```json
{
  "products": [...],
  "count": 15,
  "category": "electronics"
}
```

## Monitoring

- CloudWatch Logs: `/aws/lambda/product-service-*`
- CloudWatch Metrics: Lambda duration, errors, throttles
- Alarms: Error rate > 5% triggers rollback
- X-Ray Tracing: End-to-end request tracing enabled

## Team Ownership

This service is owned by the **Catalog Team**, responsible for:
- Product data management
- Search and filtering features
- Performance optimization for high-traffic reads
- Integration with inventory systems
- On-call rotation for product-related incidents

## Service Boundaries

**This service owns**:
- Product catalog data
- Product search and retrieval
- Category management

**This service does NOT own**:
- Inventory reservations (handled by inventory-service)
- Product pricing rules (may be separate pricing-service)
- Product reviews (separate reviews-service)

All cross-service communication happens via API calls, not shared database access.
