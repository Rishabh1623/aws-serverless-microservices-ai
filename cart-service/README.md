# Cart Service

## Problem Statement

In monolithic Lambda repositories, cart-related functions (AddCart, RemoveCart, GetCart) are scattered among hundreds of other functions. This creates:
- Slow, risky deployments affecting unrelated services
- Unclear ownership and responsibility
- High coupling between unrelated domains
- Difficult testing and maintenance

## Why This is Its Own Service

The cart service represents a clear bounded context:
- **Shared Domain**: All functions operate on shopping cart data
- **Single Data Model**: Uses one DynamoDB table (CartTable)
- **Team Ownership**: Typically owned by a single team
- **Independent Lifecycle**: Cart features evolve independently from products, orders, etc.

## Architecture

```
API Gateway (/cart/*)
    ├── POST /cart/add      → AddCart Lambda
    ├── DELETE /cart/remove → RemoveCart Lambda
    └── GET /cart/{userId}  → GetCart Lambda
                                    ↓
                              CartTable (DynamoDB)
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

## Blast Radius Reduction

**Before (Monolithic)**:
- 1 repository with 100+ functions
- 1 CI/CD pipeline
- Any deployment failure impacts entire platform
- 30+ minute deployments

**After (Microservices)**:
- Isolated cart-service repository
- Independent pipeline
- Failures only impact cart operations
- 5-8 minute deployments

## Local Development

```bash
# Install dependencies
cd cart-service
pip install -r requirements.txt -t src/add_cart/
pip install -r requirements.txt -t src/remove_cart/
pip install -r requirements.txt -t src/get_cart/

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

### Add Item to Cart
```bash
POST /cart/add
{
  "userId": "user123",
  "productId": "prod456",
  "quantity": 2
}
```

### Remove Item from Cart
```bash
DELETE /cart/remove
{
  "userId": "user123",
  "productId": "prod456"
}
```

### Get Cart
```bash
GET /cart/user123
```

## Monitoring

- CloudWatch Logs: `/aws/lambda/cart-service-*`
- CloudWatch Metrics: Lambda duration, errors, throttles
- Alarms: Error rate > 5% triggers rollback

## Team Ownership

This service is owned by the **Cart Team**, responsible for:
- Feature development
- Bug fixes
- Performance optimization
- On-call rotation for cart-related incidents
