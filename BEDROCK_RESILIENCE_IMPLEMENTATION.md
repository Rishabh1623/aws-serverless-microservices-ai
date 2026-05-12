# Bedrock Resilience Implementation

## Overview

Implemented exponential backoff retry logic and multi-region fallback to handle AWS Bedrock ThrottlingException while waiting for AWS Support to enable quotas on the new account.

## Problem

- **Issue**: Lambda function crashes with `ThrottlingException: Too many tokens per day` on Amazon Bedrock
- **Root Cause**: New AWS account (955510722779) has **ZERO default quota** for all Bedrock models
- **Status**: AWS Support ticket submitted, waiting for quota enablement
- **Workaround**: Implement retry logic and multi-region fallback

## Solution Architecture

### 1. Exponential Backoff Retry
- **Max Retries**: 3 attempts per region
- **Base Delay**: 2 seconds
- **Max Delay**: 32 seconds
- **Jitter**: Random jitter added to prevent thundering herd
- **Retry On**: `ThrottlingException`, `TooManyRequestsException`

### 2. Multi-Region Fallback
- **Primary Region**: us-east-1 (from `BEDROCK_REGION` env var)
- **Fallback Regions**: us-west-2 (from `BEDROCK_FALLBACK_REGIONS` env var)
- **Strategy**: Try primary region with retries, then fallback to us-west-2 if all retries fail

### 3. Graceful Degradation
- If all regions fail, return user-friendly error message
- Provide fallback URLs to traditional hotel search
- Suggest retry after 60 seconds

## Files Changed

### 1. **agent-service/src/agent_handler/bedrock_resilience.py** (NEW)
**Status**: ✅ Created

Resilience module with three main functions:

```python
def exponential_backoff_retry(
    func: Callable,
    max_retries: int = 3,
    base_delay: float = 2.0,
    max_delay: float = 32.0,
    jitter: bool = True,
    retry_on_exceptions: List[str] = None
) -> Any
```

```python
def multi_region_fallback(
    func: Callable,
    primary_region: str = 'us-east-1',
    fallback_regions: Optional[List[str]] = None,
    max_retries_per_region: int = 3
) -> Any
```

```python
def with_bedrock_resilience(
    func: Callable,
    enable_retry: bool = True,
    enable_multi_region: bool = True,
    primary_region: str = 'us-east-1',
    fallback_regions: Optional[List[str]] = None,
    max_retries: int = 3
) -> Any
```

**Features**:
- Exponential backoff with jitter
- Multi-region fallback
- Detailed logging for debugging
- Custom exception: `BedrockResilienceError`

---

### 2. **agent-service/src/agent_handler/app.py** (UPDATED)
**Status**: ✅ Updated

**Changes**:

#### a. Import resilience module
```python
from bedrock_resilience import with_bedrock_resilience, BedrockResilienceError
```

#### b. Updated `get_agent()` function to support region parameter
```python
def get_agent(region: str = None):
    """
    Initialize Strands Agent (lazy loading)
    
    Args:
        region: AWS region for Bedrock (defaults to BEDROCK_REGION env var)
    """
    # If region is specified, create new agent for that region
    if region is not None:
        bedrock_client = boto3.client('bedrock-runtime', region_name=region)
        return Agent(
            system_prompt=SYSTEM_PROMPT,
            tools=get_tools(),
            model=bedrock_model_id,
            client=bedrock_client
        )
    # ... existing code for cached agent
```

#### c. Updated `get_tools()` to pass region to tools
```python
def get_tools():
    # Get Bedrock region from environment
    bedrock_region = os.environ.get('BEDROCK_REGION', 'us-east-1')
    
    if _travel_planner_tools is None:
        _travel_planner_tools = TravelPlannerTools(
            hotel_api_url=os.environ.get('HOTEL_API_URL'),
            bedrock_model_id=os.environ.get('BEDROCK_MODEL_ID', '...'),
            bedrock_region=bedrock_region  # NEW
        )
    # ... similar for upselling_tools
```

#### d. Updated `lambda_handler()` to use resilience wrapper
```python
# Get primary region and fallback regions from environment
primary_region = os.environ.get('BEDROCK_REGION', 'us-east-1')
fallback_regions_str = os.environ.get('BEDROCK_FALLBACK_REGIONS', 'us-west-2')
fallback_regions = [r.strip() for r in fallback_regions_str.split(',') if r.strip()]

# Define function to invoke agent with specific region
def invoke_agent_with_region(region: str):
    logger.info(f"Invoking agent in region: {region}")
    agent = get_agent(region=region)
    return agent(enhanced_message)

# Process message through agent with resilience
try:
    response = with_bedrock_resilience(
        func=invoke_agent_with_region,
        enable_retry=True,
        enable_multi_region=True,
        primary_region=primary_region,
        fallback_regions=fallback_regions,
        max_retries=3
    )
except BedrockResilienceError as e:
    logger.error(f"All Bedrock regions failed: {str(e)}")
    # Return graceful error to user
    return {
        'statusCode': 503,
        'headers': {...},
        'body': json.dumps({
            'error': 'service_unavailable',
            'message': 'AI assistant is temporarily unavailable...',
            'retry_after': 60
        })
    }
```

---

### 3. **agent-service/src/agent_handler/tools/travel_planner_tools.py** (UPDATED)
**Status**: ✅ Updated

**Changes**:

#### Updated `__init__()` to accept region parameter
```python
def __init__(self, hotel_api_url: str, bedrock_model_id: str, bedrock_region: str = 'us-east-1'):
    self.hotel_api_url = hotel_api_url.rstrip('/')
    self.bedrock_region = bedrock_region
    self.bedrock = boto3.client('bedrock-runtime', region_name=bedrock_region)  # NEW
    self.dynamodb = boto3.resource('dynamodb')
    self.model_id = bedrock_model_id
    self.timeout = 10
```

**Impact**: All Bedrock calls in this tool now use the specified region

---

### 4. **agent-service/src/agent_handler/tools/upselling_tools.py** (UPDATED)
**Status**: ✅ Updated

**Changes**:

#### Updated `__init__()` to accept region parameter
```python
def __init__(self, hotel_api_url: str, bedrock_model_id: str, bedrock_region: str = 'us-east-1'):
    self.hotel_api_url = hotel_api_url.rstrip('/')
    self.bedrock_region = bedrock_region
    self.bedrock = boto3.client('bedrock-runtime', region_name=bedrock_region)  # NEW
    self.model_id = bedrock_model_id
```

**Impact**: All Bedrock calls in this tool now use the specified region

---

### 5. **terraform/agent-service/dev/main.tf** (UPDATED)
**Status**: ✅ Updated

**Changes**:

#### a. Added `BEDROCK_FALLBACK_REGIONS` environment variable
```hcl
environment {
  variables = {
    HOTEL_API_URL              = local.hotel_api_url
    CART_API_URL               = local.cart_api_url
    ORDER_API_URL              = local.order_api_url
    PAYMENT_API_URL            = local.payment_api_url
    BEDROCK_MODEL_ID           = "anthropic.claude-haiku-4-5-20251001-v1:0"
    CONVERSATION_TABLE         = aws_dynamodb_table.conversations.name
    SECRETS_ARN                = module.secrets.secret_arns["bedrock_config"]
    LOG_LEVEL                  = "INFO"
    BEDROCK_REGION             = var.aws_region
    BEDROCK_FALLBACK_REGIONS   = "us-west-2"  # NEW - Fallback region
  }
}
```

#### b. Updated IAM policy comment for multi-region support
```hcl
# Bedrock permissions (multi-region support for fallback)
resource "aws_iam_role_policy" "bedrock_access" {
  # ... existing policy already has wildcard for all regions (*)
}
```

**Note**: IAM policy already allows Bedrock access in all regions using `arn:aws:bedrock:*::foundation-model/*`, so no policy changes needed.

---

## Configuration

### Environment Variables

| Variable | Value | Description |
|----------|-------|-------------|
| `BEDROCK_REGION` | `us-east-1` | Primary AWS region for Bedrock |
| `BEDROCK_FALLBACK_REGIONS` | `us-west-2` | Comma-separated list of fallback regions |
| `BEDROCK_MODEL_ID` | `anthropic.claude-haiku-4-5-20251001-v1:0` | Bedrock model ID |

### Retry Configuration

| Parameter | Value | Description |
|-----------|-------|-------------|
| `max_retries` | 3 | Maximum retry attempts per region |
| `base_delay` | 2.0s | Base delay for exponential backoff |
| `max_delay` | 32.0s | Maximum delay between retries |
| `jitter` | True | Add random jitter to delays |

## Behavior

### Success Flow
1. **Primary Region (us-east-1)**:
   - Attempt 1: Invoke Bedrock → Success ✅
   - Return response to user

### Retry Flow (Throttled in Primary)
1. **Primary Region (us-east-1)**:
   - Attempt 1: Invoke Bedrock → ThrottlingException ⚠️
   - Wait 2s (with jitter)
   - Attempt 2: Invoke Bedrock → ThrottlingException ⚠️
   - Wait 4s (with jitter)
   - Attempt 3: Invoke Bedrock → ThrottlingException ⚠️
   - Wait 8s (with jitter)
   - Attempt 4: Invoke Bedrock → ThrottlingException ❌

2. **Fallback Region (us-west-2)**:
   - Attempt 1: Invoke Bedrock → Success ✅
   - Return response to user

### All Regions Failed
1. **Primary Region (us-east-1)**: All 4 attempts failed ❌
2. **Fallback Region (us-west-2)**: All 4 attempts failed ❌
3. **Return Error**:
   ```json
   {
     "statusCode": 503,
     "body": {
       "error": "service_unavailable",
       "message": "AI assistant is temporarily unavailable due to high demand. Please try again in a few moments or use the traditional hotel search.",
       "retry_after": 60
     }
   }
   ```

## Logging

### Log Messages

**Region Selection**:
```
INFO: Bedrock config - Primary: us-east-1, Fallback: ['us-west-2']
```

**Retry Attempts**:
```
WARNING: ⚠️  Attempt 1/4 failed with ThrottlingException. Retrying in 2.34s... Error: Too many tokens per day
WARNING: ⚠️  Attempt 2/4 failed with ThrottlingException. Retrying in 4.12s... Error: Too many tokens per day
```

**Region Fallback**:
```
ERROR: ❌ Region us-east-1 failed: Failed after 3 retries
INFO: 🔄 Falling back to next region...
INFO: 🌍 Attempting Bedrock call in region: us-west-2
```

**Success After Retry**:
```
INFO: ✅ Retry successful on attempt 2
```

**All Regions Failed**:
```
ERROR: ❌ Region us-west-2 failed: Failed after 3 retries
ERROR: All Bedrock regions failed: Failed in all regions ['us-east-1', 'us-west-2']
```

## Testing

### Test on EC2

1. **Rebuild Lambda package**:
   ```bash
   cd ~/aws-serverless-microservices-ai/agent-service
   bash build-lambda.sh
   ```

2. **Trigger CodeBuild** (or deploy manually):
   ```bash
   cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev
   terraform apply
   ```

3. **Test with curl**:
   ```bash
   curl -X POST https://zwp2qpu3q7.execute-api.us-east-1.amazonaws.com/agent \
     -H "Content-Type: application/json" \
     -d '{
       "message": "Find me hotels in Paris for June 15-20",
       "userId": "test-user"
     }'
   ```

4. **Check CloudWatch logs**:
   ```bash
   aws logs tail /aws/lambda/agent-service-dev --follow
   ```

### Expected Behavior

**Scenario 1: Quota still 0 in both regions**
- Lambda will retry 3 times in us-east-1
- Then retry 3 times in us-west-2
- Return 503 error with graceful message
- Total time: ~30 seconds (2+4+8+2+4+8 = 28s + processing)

**Scenario 2: AWS Support enables quota in us-east-1**
- Lambda succeeds on first attempt in us-east-1
- Returns AI response immediately
- Total time: ~2-5 seconds

**Scenario 3: Quota enabled only in us-west-2**
- Lambda fails 4 times in us-east-1 (~14s)
- Succeeds on first attempt in us-west-2
- Returns AI response
- Total time: ~16-20 seconds
- Log shows: "⚠️  Using fallback region us-west-2"

## Benefits

1. **Resilience**: Handles temporary throttling gracefully
2. **Multi-Region**: Automatically fails over to us-west-2
3. **User Experience**: Provides clear error messages instead of crashes
4. **Observability**: Detailed logging for debugging
5. **Production-Ready**: Exponential backoff prevents overwhelming Bedrock
6. **Configurable**: Easy to add more fallback regions via env var

## Next Steps

1. **Wait for AWS Support** to enable Bedrock quotas
2. **Test immediately** after quota is enabled:
   ```bash
   aws bedrock-runtime invoke-model \
     --model-id anthropic.claude-haiku-4-5-20251001-v1:0 \
     --region us-east-1 \
     --body '{"anthropic_version":"bedrock-2023-05-31","max_tokens":100,"messages":[{"role":"user","content":"Hello"}]}' \
     --cli-binary-format raw-in-base64-out /tmp/test.json
   ```
3. **Deploy updated Lambda** with resilience logic
4. **Monitor CloudWatch logs** for retry patterns
5. **Remove retry logic** once quota is stable (optional - can keep for production resilience)

## Rollback Plan

If resilience logic causes issues:

1. **Revert app.py**:
   ```bash
   git checkout HEAD~1 agent-service/src/agent_handler/app.py
   ```

2. **Remove resilience module**:
   ```bash
   rm agent-service/src/agent_handler/bedrock_resilience.py
   ```

3. **Rebuild and deploy**:
   ```bash
   cd agent-service && bash build-lambda.sh
   cd ../terraform/agent-service/dev && terraform apply
   ```

## Summary

✅ **Implemented**:
- Exponential backoff retry logic (max 3 retries, 2s base delay)
- Multi-region fallback (us-east-1 → us-west-2)
- Graceful error handling with user-friendly messages
- Detailed logging for debugging
- Region parameter support in tools
- Terraform environment variable for fallback regions

✅ **Files Changed**:
1. `agent-service/src/agent_handler/bedrock_resilience.py` (NEW)
2. `agent-service/src/agent_handler/app.py` (UPDATED)
3. `agent-service/src/agent_handler/tools/travel_planner_tools.py` (UPDATED)
4. `agent-service/src/agent_handler/tools/upselling_tools.py` (UPDATED)
5. `terraform/agent-service/dev/main.tf` (UPDATED)

✅ **Ready for Deployment**:
- All code changes complete
- Terraform configuration updated
- IAM permissions already support multi-region
- Ready to rebuild and deploy

🎯 **Next Action**: Rebuild Lambda package and deploy to test resilience logic
