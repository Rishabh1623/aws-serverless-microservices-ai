# Serverless Microservices Platform

A production-grade e-commerce platform demonstrating Pattern 1: Domain-Driven Serverless Microservices with independent CI/CD pipelines.

## Architecture Overview

This platform implements serverless microservices organized by bounded context, where each service:
- Owns its domain logic and data
- Has independent deployment pipelines
- Reduces blast radius during deployments
- Enables team autonomy

## Services

### 1. Cart Service (`/cart-service`)
Manages shopping cart operations with dedicated Lambda functions and DynamoDB table.

### 2. Product Service (`/product-service`)
Handles product catalog operations with dedicated Lambda functions and DynamoDB table.

## Key Design Principles

- **Domain Boundaries**: Functions grouped by business domain, not scattered individually
- **Independent Deployment**: Each service has its own SAM template and CI/CD pipeline
- **Low Blast Radius**: Changes to one service don't impact others
- **Team Ownership**: Clear boundaries enable multiple teams to work independently

## Getting Started

Each service directory contains:
- Complete AWS SAM infrastructure
- Independent CI/CD pipeline configuration
- Unit tests
- Deployment documentation

Navigate to each service directory for detailed setup instructions.

## STAR Format Context

**Situation**: Growing serverless platforms often accumulate hundreds of Lambda functions in a single repository, creating deployment bottlenecks and unclear ownership.

**Task**: Reorganize Lambda architecture to enable safe, independent deployments while maintaining serverless benefits.

**Action**: Implement domain-driven microservices pattern with independent CI/CD pipelines per bounded context.

**Result**: Reduced deployment times, eliminated cross-service impact, and established clear architectural framework for scaling.
