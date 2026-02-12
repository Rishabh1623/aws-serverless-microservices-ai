# Admin Panel Access

The Admin Dashboard (DevOps Troubleshooting Agent) has been removed from the main navigation to make the site look more customer-ready.

## How to Access Admin Panel

**Direct URL:** 
```
http://serverless-microservices-frontend-543927035352.s3-website-us-east-1.amazonaws.com/admin
```

Or for your specific deployment:
```
http://serverless-microservices-frontend-{YOUR_AWS_ACCOUNT_ID}.s3-website-us-east-1.amazonaws.com/admin
```

## For Demo Recording

When recording your demo:

1. **Customer Flow (First 3 minutes):**
   - Show Home page
   - Browse Products
   - Use AI Shopping Assistant
   - Add items to cart
   - Create order
   - View orders

2. **Admin/DevOps Flow (Last 2 minutes):**
   - Navigate to `/admin` URL directly
   - Show troubleshooting agent
   - Ask: "Check system health"
   - Ask: "Why is the cart service slow?"
   - Show MCP tools in action

## Production Considerations

In a real production environment:

1. **Separate Admin Domain**
   - Customer site: `shop.example.com`
   - Admin panel: `admin.example.com`

2. **Authentication Required**
   - AWS Cognito for user authentication
   - IAM roles for admin access
   - MFA for sensitive operations

3. **Access Control**
   - Role-based access control (RBAC)
   - Audit logging
   - IP whitelisting for admin panel

## Why This Approach?

- **Customer-facing site looks professional** - No admin links visible
- **Admin functionality still accessible** - Via direct URL
- **Demo-friendly** - Easy to show both customer and admin features
- **Realistic** - Mimics real-world separation of concerns
