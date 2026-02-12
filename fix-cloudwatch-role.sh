#!/bin/bash
# Fix CloudWatch Logs role for API Gateway
# This is a ONE-TIME setup for your AWS account

echo "Creating IAM role for API Gateway CloudWatch Logs..."

# Create trust policy
cat > /tmp/trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role
aws iam create-role \
  --role-name APIGatewayCloudWatchLogsRole \
  --assume-role-policy-document file:///tmp/trust-policy.json \
  --description "Allows API Gateway to push logs to CloudWatch Logs"

# Attach the managed policy
aws iam attach-role-policy \
  --role-name APIGatewayCloudWatchLogsRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs

# Get the role ARN
ROLE_ARN=$(aws iam get-role --role-name APIGatewayCloudWatchLogsRole --query 'Role.Arn' --output text)

echo "Role ARN: $ROLE_ARN"

# Set the CloudWatch role ARN in API Gateway account settings
aws apigateway update-account \
  --patch-operations op=replace,path=/cloudwatchRoleArn,value=$ROLE_ARN

echo ""
echo "✅ SUCCESS! API Gateway can now write to CloudWatch Logs"
echo ""
echo "Verify with:"
echo "aws apigateway get-account --query 'cloudwatchRoleArn'"
echo ""
echo "Now you can run: terraform apply"
