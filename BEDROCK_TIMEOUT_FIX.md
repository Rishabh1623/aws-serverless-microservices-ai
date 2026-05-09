# Bedrock Timeout Issue - Diagnosis & Fix

## Problem

Lambda times out after 60 seconds when calling Bedrock. The timeout happens consistently in both AWS accounts, suggesting it's a **configuration or code issue**, not a model access problem.

### Symptoms:
- ✅ Lambda initializes successfully
- ✅ Correct model ID: `anthropic.claude-3-haiku-20240307-v1:0`
- ✅ Strands SDK loads
- ❌ **Hangs after "Creating Strands MetricsClient"**
- ❌ Times out after 60 seconds (full Lambda timeout)

### Logs Show:
```
[INFO] Using AWS Bedrock with model: anthropic.claude-3-haiku-20240307-v1:0
[INFO] Creating Strands MetricsClient
[TIMEOUT after 60 seconds]
```

---

## Root Cause Analysis

### Possible Causes (in order of likelihood):

1. **Lambda in VPC without Bedrock endpoint** ⚠️ MOST LIKELY
   - If Lambda is in a VPC, it can't reach Bedrock without:
     - VPC Endpoint for Bedrock, OR
     - NAT Gateway for internet access
   - This would cause indefinite hang until timeout

2. **Region Mismatch**
   - Tools create `boto3.client('bedrock-runtime')` without explicit region
   - Strands SDK might be using different region
   - Bedrock call goes to wrong region where model isn't enabled

3. **Tools Initialization Blocking**
   - `TravelPlannerTools.__init__()` creates Bedrock client
   - This happens during agent initialization
   - Might be making blocking calls

4. **Strands SDK Configuration**
   - SDK might need explicit region configuration
   - Timeout settings might be too high

---

## Diagnostic Steps

### Step 1: Check VPC Configuration

```bash
cd ~/aws-serverless-microservices-ai
bash diagnose-bedrock-timeout.sh
```

This will check:
- Lambda VPC configuration
- IAM permissions
- Direct Bedrock access
- Region settings

### Step 2: Test Direct Bedrock Access

```bash
# Test if Bedrock is accessible from your EC2 (same IAM context)
aws bedrock-runtime invoke-model \
  --model-id anthropic.claude-3-haiku-20240307-v1:0 \
  --region us-east-1 \
  --body '{"anthropic_version":"bedrock-2023-05-31","max_tokens":100,"messages":[{"role":"user","content":"Hello"}]}' \
  --cli-binary-format raw-in-base64-out \
  /tmp/test.json

cat /tmp/test.json | jq '.'
```

**Expected:** Should return response in < 5 seconds

---

## Solutions

### Solution 1: Remove Lambda from VPC (if applicable)

**Check if Lambda is in VPC:**
```bash
aws lambda get-function-configuration \
  --function-name agent-service-dev \
  --query 'VpcConfig'
```

**If VPC is configured, remove it:**

Edit `terraform/agent-service/dev/main.tf`:
```terraform
resource "aws_lambda_function" "agent_package" {
  # ... other config ...
  
  # REMOVE or comment out vpc_config block
  # vpc_config {
  #   subnet_ids         = [...]
  #   security_group_ids = [...]
  # }
}
```

Then apply:
```bash
cd terraform/agent-service/dev
terraform apply -auto-approve
```

### Solution 2: Add Explicit Region to Bedrock Clients

**Update `travel_planner_tools.py`:**

```python
def __init__(self, hotel_api_url: str, bedrock_model_id: str):
    self.hotel_api_url = hotel_api_url.rstrip('/')
    
    # Explicitly set region
    bedrock_region = os.environ.get('BEDROCK_REGION', 'us-east-1')
    
    self.bedrock = boto3.client('bedrock-runtime', region_name=bedrock_region)
    self.dynamodb = boto3.resource('dynamodb', region_name=bedrock_region)
    self.model_id = bedrock_model_id
    self.timeout = 10
```

### Solution 3: Deploy Minimal Version (Test Without Tools)

I've created `app_minimal.py` - a version without tools to isolate the issue.

**Deploy minimal version:**

1. Update Lambda handler in Terraform:
```terraform
handler = "app_minimal.lambda_handler"  # Change from "app.lambda_handler"
```

2. Rebuild and deploy:
```bash
cd ~/aws-serverless-microservices-ai/agent-service
bash build-lambda.sh

cd ../terraform/agent-service/dev
terraform apply -auto-approve
```

3. Test:
```bash
curl -X POST https://zwp2qpu3q7.execute-api.us-east-1.amazonaws.com/agent \
  -H 'Content-Type: application/json' \
  -d '{"message":"Hello","userId":"test"}'
```

**If minimal version works:**
- Issue is in tools initialization
- Fix: Add explicit regions to boto3 clients in tools

**If minimal version also times out:**
- Issue is VPC or IAM permissions
- Fix: Remove VPC or add VPC endpoint

### Solution 4: Increase Lambda Timeout (Temporary Workaround)

```terraform
resource "aws_lambda_function" "agent_package" {
  # ... other config ...
  timeout = 120  # Increase from 60 to 120 seconds
}
```

**Note:** This is a workaround, not a fix. The real issue needs to be addressed.

---

## Quick Fix Commands

### Option A: Run Diagnostics First
```bash
cd ~/aws-serverless-microservices-ai
bash diagnose-bedrock-timeout.sh
```

### Option B: Deploy Minimal Version Immediately
```bash
# 1. Update Terraform to use minimal handler
cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev

# 2. Edit main.tf - change handler line
# handler = "app_minimal.lambda_handler"

# 3. Rebuild Lambda
cd ~/aws-serverless-microservices-ai/agent-service
bash build-lambda.sh

# 4. Deploy
cd ../terraform/agent-service/dev
terraform apply -auto-approve

# 5. Test
curl -X POST https://zwp2qpu3q7.execute-api.us-east-1.amazonaws.com/agent \
  -H 'Content-Type: application/json' \
  -d '{"message":"Hello","userId":"test"}'
```

---

## Expected Results After Fix

### Success Indicators:
- Lambda responds in < 10 seconds
- CloudWatch logs show:
  ```
  [INFO] Using AWS Bedrock with model: anthropic.claude-3-haiku-20240307-v1:0
  [INFO] Agent initialized, calling Bedrock...
  [INFO] Got response from Bedrock: Hello! I'd be happy to help...
  ```
- API returns 200 with agent response
- No timeout errors

### If Still Failing:
1. Check CloudWatch logs for new error messages
2. Verify IAM role has `bedrock:InvokeModel` permission
3. Confirm model is enabled in Bedrock console
4. Check if account has any service quotas or restrictions

---

## Interview Talking Points

This demonstrates:
1. **Systematic Debugging** - Using logs to narrow down where code hangs
2. **VPC Networking** - Understanding Lambda VPC limitations with AWS services
3. **Timeout Analysis** - Distinguishing between code bugs vs infrastructure issues
4. **Isolation Testing** - Creating minimal reproductions to identify root cause
5. **AWS Service Integration** - Bedrock requires specific network/IAM configuration

The key insight: **Consistent timeouts across accounts suggest infrastructure/config issue, not transient API problems**.

---

## Next Steps

1. Run `diagnose-bedrock-timeout.sh` to identify root cause
2. Apply appropriate solution based on diagnostic results
3. Test with minimal version if needed
4. Once working, add tools back incrementally
5. Document final solution for future reference
