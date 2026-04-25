# OpenTelemetry Fix - Rebuild and Deploy Instructions

## Issue Identified

The Lambda deployment package was being built in the WRONG ORDER:
1. ❌ OLD: Copy source code → Install dependencies (dependencies overwrite source)
2. ✅ NEW: Install dependencies → Copy source code (correct layering)

This caused the deployed Lambda to have the old buggy OpenTelemetry code even though the build directory showed version 1.41.1.

## Fix Applied

Updated `agent-service/build-lambda.sh` to:
- Install dependencies FIRST with `--force-reinstall --upgrade` flags
- Copy source code AFTER to properly layer on top of dependencies
- This ensures OpenTelemetry 1.30.0+ libraries are in the final zip file

## Deployment Steps (Execute on EC2)

### Step 1: Pull Latest Changes

```bash
cd ~/aws-serverless-microservices-ai
git stash  # Stash any local changes to build-lambda.sh
git pull origin main
```

### Step 2: Rebuild Lambda Package

```bash
cd ~/aws-serverless-microservices-ai/agent-service

# Run the fixed build script
bash build-lambda.sh
```

**Expected Output:**
```
Building Agent Service Lambda package...
Installing dependencies...
Copying source code...
Creating deployment package...
✅ Lambda package created: agent-service-lambda.zip
Size: ~XX MB
```

### Step 3: Verify OpenTelemetry Version in Build

```bash
# Check OpenTelemetry version in build directory
cat build/opentelemetry_sdk-*.dist-info/METADATA | grep "^Version:"
```

**Expected:** `Version: 1.41.1` (or any version >= 1.30.0)

### Step 4: Verify OpenTelemetry Version in Zip File

```bash
# Extract a test copy and check the zip contents
mkdir -p /tmp/lambda-test
unzip -q agent-service-lambda.zip -d /tmp/lambda-test
cat /tmp/lambda-test/opentelemetry_sdk-*.dist-info/METADATA | grep "^Version:"
rm -rf /tmp/lambda-test
```

**Expected:** `Version: 1.41.1` (or any version >= 1.30.0)

**CRITICAL:** If this shows a different version than the build directory, the build process is still incorrect.

### Step 5: Deploy to Lambda

```bash
# Deploy using AWS CLI
aws lambda update-function-code \
  --function-name agent-service-dev \
  --zip-file fileb://agent-service-lambda.zip
```

**Expected Output:**
```json
{
    "FunctionName": "agent-service-dev",
    "LastModified": "2026-04-25T...",
    "CodeSize": XXXXXXX,
    "State": "Active",
    ...
}
```

### Step 6: Wait for Lambda Update

```bash
# Wait 15-20 seconds for Lambda to update
sleep 20
```

### Step 7: Test the Fixed Lambda

```bash
cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev

# Test with a simple message
curl -X POST $(terraform output -raw api_endpoint) \
  -H "Content-Type: application/json" \
  -d '{"message":"test","userId":"test","sessionId":"test"}'
```

**Expected Success:**
```json
{
  "response": "...",
  "userId": "test",
  "sessionId": "test"
}
```

**NOT:** `{"message":"Internal Server Error"}`

### Step 8: Check CloudWatch Logs

```bash
# Check recent logs for errors
aws logs tail /aws/lambda/agent-service-dev --since 2m --follow
```

**Expected Success Indicators:**
- ✅ No `StopIteration` errors
- ✅ No `_load_runtime_context()` errors
- ✅ Successful Strands SDK initialization
- ✅ Lambda handler executes successfully

**Expected Failure Indicators (if still broken):**
- ❌ `StopIteration` from `/var/task/opentelemetry/context/__init__.py`
- ❌ `return next(` pattern in error stack trace (indicates old OpenTelemetry code)
- ❌ `INIT_REPORT ... Status: error`

## Verification Checklist

- [ ] Git pull completed successfully
- [ ] Build script executed without errors
- [ ] OpenTelemetry version in build/ is >= 1.30.0
- [ ] OpenTelemetry version in zip file is >= 1.30.0 (CRITICAL CHECK)
- [ ] Lambda deployment succeeded
- [ ] API test returns HTTP 200 with valid JSON (not "Internal Server Error")
- [ ] CloudWatch logs show no StopIteration errors
- [ ] Lambda initialization completes successfully

## Troubleshooting

### If OpenTelemetry version in zip differs from build directory:

The build process is still incorrect. Check:
1. Is the build script using the correct order (dependencies first, source second)?
2. Are there any symbolic links or directory overlaps?
3. Is pip installing to the correct target directory?

### If Lambda still crashes with StopIteration:

1. Verify the deployed Lambda actually has the new code:
   ```bash
   aws lambda get-function --function-name agent-service-dev --query 'Configuration.LastModified'
   ```
2. Check if there are multiple Lambda versions deployed
3. Verify the API Gateway is pointing to the correct Lambda version

### If tests pass but API returns errors:

1. Check API Gateway configuration
2. Verify Lambda permissions and IAM roles
3. Check environment variables are set correctly
4. Review CloudWatch logs for other errors

## Success Criteria

✅ Lambda initializes without StopIteration errors
✅ API Gateway returns HTTP 200 with valid agent responses
✅ CloudWatch logs show successful Strands SDK initialization
✅ OpenTelemetry 1.30.0+ is confirmed in the deployed Lambda package

## Next Steps After Success

Once the Lambda is working:
1. Test with real agent queries (hotel recommendations, travel planning)
2. Verify X-Ray tracing is working
3. Check DynamoDB conversation history storage
4. Monitor Lambda performance and cold start times
5. Consider updating tasks.md to mark remaining tasks complete
