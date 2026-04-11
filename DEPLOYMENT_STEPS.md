# Durable Functions Deployment Steps

## Following Your Existing Workflow

Based on your project's deployment pattern (from DEPLOY.md), here's how to add the durable function:

### Step 1: Install Lambda Dependencies

```bash
# Navigate to the durable function source
cd hotel-service/src/booking_orchestrator

# Install the AWS Lambda Durable SDK
pip install -r requirements.txt -t .

# Verify installation
ls -la  # Should see aws_lambda_durable folder
```

### Step 2: Initialize Terraform

```bash
# Navigate to Terraform directory
cd ../../terraform/hotel-service-durable

# Initialize Terraform (downloads providers and modules)
terraform init
```

### Step 3: Review the Plan

```bash
# See what will be created
terraform plan

# Review the output carefully:
# - Lambda function with durable execution
# - IAM roles and policies
# - API Gateway integration
# - CloudWatch log groups
```

### Step 4: Deploy

```bash
# Apply the changes
terraform apply

# Type 'yes' when prompted

# Wait ~2-3 minutes for deployment
```

### Step 5: Save API Endpoint

```bash
# Get the API endpoint
terraform output api_endpoint

# Save it for testing
export DURABLE_API=$(terraform output -raw api_endpoint)
echo "Durable Function API: $DURABLE_API"
```

## Git Workflow (If Working in a Team)

```bash
# 1. Commit your changes
git add .
git commit -m "Add Lambda Durable Functions implementation"

# 2. Push to remote
git push origin main

# 3. On deployment machine (or pull if same machine)
git pull origin main

# 4. Deploy (use automated script or manual steps above)
./scripts/deploy-durable-function.bat
```

## Prerequisites Checklist

Before deploying, ensure you have:

- [ ] AWS CLI configured (`aws configure`)
- [ ] Terraform installed (v1.0+)
- [ ] Python 3.11+ installed
- [ ] pip installed
- [ ] Existing DynamoDB tables:
  - `travel-platform-bookings-dev`
  - `travel-platform-rooms-dev`
  - `travel-platform-hotels-dev`
- [ ] Existing API Gateway: `travel-platform-api-dev`
- [ ] Shared Lambda layer deployed
- [ ] SES email template configured

## Testing After Deployment

```bash
# Get the API endpoint from Terraform output
cd terraform/hotel-service-durable
terraform output api_endpoint

# Test the endpoint
curl -X POST https://your-api-gateway.execute-api.us-east-1.amazonaws.com/bookings/orchestrated \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "hotelId": "hotel-001",
    "roomId": "room-001",
    "checkIn": "2024-06-15",
    "checkOut": "2024-06-20",
    "guests": 2,
    "guestDetails": {
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890"
    },
    "paymentMethod": {
      "type": "credit_card",
      "token": "tok_visa"
    }
  }'
```

## Monitor Execution

```bash
# View CloudWatch logs
aws logs tail /aws/lambda/travel-platform-booking-orchestrator-dev --follow

# View metrics
aws cloudwatch get-metric-statistics \
  --namespace TravelPlatform/HotelService \
  --metric-name BookingCount \
  --dimensions Name=Operation,Value=BookingOrchestrator \
  --start-time 2024-06-10T00:00:00Z \
  --end-time 2024-06-10T23:59:59Z \
  --period 3600 \
  --statistics Sum
```

## Rollback (If Needed)

```bash
cd terraform/hotel-service-durable
terraform destroy
```

## Common Issues

### Issue: "aws-lambda-durable not found"
**Solution:**
```bash
cd hotel-service/src/booking_orchestrator
pip install aws-lambda-durable -t .
```

### Issue: "DynamoDB table not found"
**Solution:** Deploy the base infrastructure first:
```bash
cd terraform/hotel-service/dev
terraform apply
```

### Issue: "API Gateway not found"
**Solution:** Deploy API Gateway first:
```bash
cd terraform/bootstrap
terraform apply
```

### Issue: "Permission denied"
**Solution:** Check IAM permissions for Lambda execution role

## Cost Estimate

- Lambda invocations: $0.20 per 1M requests
- Lambda duration: $0.0000166667 per GB-second
- DynamoDB: $0.25 per GB-month
- API Gateway: $1.00 per million requests

**Estimated monthly cost for 10K bookings:** ~$5-10

## Next Steps

1. ✅ Deploy durable function
2. ✅ Test with sample booking
3. ✅ Monitor CloudWatch logs
4. ✅ Review metrics and alarms
5. ✅ Update frontend to use new endpoint
6. ✅ Consider migrating other workflows (order processing, payment flows)

## Support

For issues or questions:
- Check [DURABLE_FUNCTIONS_GUIDE.md](DURABLE_FUNCTIONS_GUIDE.md)
- Review [DEPLOY.md](DEPLOY.md)
- Check AWS CloudWatch logs
- Review Terraform state: `terraform show`
