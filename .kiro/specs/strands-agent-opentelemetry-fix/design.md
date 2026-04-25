# Strands Agent OpenTelemetry Fix - Bugfix Design

## Overview

The AI Agent service Lambda function crashes on startup due to a Python 3.11 compatibility issue with OpenTelemetry's context loading mechanism. The root cause is an outdated OpenTelemetry version (1.20.0) that is incompatible with Python 3.11's PEP 479 changes to StopIteration handling in generators. The Strands Agents SDK requires OpenTelemetry >= 1.30.0, but the current `requirements.txt` pins it to >= 1.20.0, < 2.0.0, creating a version conflict.

The fix involves updating the OpenTelemetry dependency versions in `agent-service/requirements.txt` to match the Strands SDK's requirements (>= 1.30.0), ensuring Python 3.11 compatibility and proper context loading during Lambda initialization.

## Glossary

- **Bug_Condition (C)**: The condition that triggers the bug - when the Lambda imports `strands.agent` with OpenTelemetry < 1.30.0 on Python 3.11
- **Property (P)**: The desired behavior - Lambda successfully initializes and imports Strands SDK without StopIteration errors
- **Preservation**: Existing Lambda functionality (Bedrock integration, tool execution, conversation management, X-Ray tracing) that must remain unchanged
- **PEP 479**: Python Enhancement Proposal that changed StopIteration handling in generators (enforced in Python 3.11+)
- **OpenTelemetry (OTEL)**: Observability framework used by Strands SDK for tracing and instrumentation
- **_load_runtime_context()**: The OpenTelemetry function in `/var/task/opentelemetry/context/__init__.py` that fails with StopIteration in versions < 1.30.0 on Python 3.11
- **Strands Agents SDK**: AWS open-source framework for building AI agents with built-in OpenTelemetry observability

## Bug Details

### Bug Condition

The bug manifests when the Lambda function cold starts and attempts to import the Strands Agents SDK. OpenTelemetry versions < 1.30.0 contain a `_load_runtime_context()` function that uses generator patterns incompatible with Python 3.11's PEP 479 enforcement, causing a `StopIteration` exception to propagate as a `RuntimeError`.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type LambdaInitializationEvent
  OUTPUT: boolean
  
  RETURN input.pythonVersion == "3.11"
         AND input.opentelemetryApiVersion < "1.30.0"
         AND input.opentelemetrySdkVersion < "1.30.0"
         AND input.importsStrandsAgent == true
         AND input.strandsAgentRequiresOtel >= "1.30.0"
END FUNCTION
```

**Technical Context:**
- **Python 3.11 + PEP 479**: In Python 3.11, raising `StopIteration` inside a generator is converted to `RuntimeError` to prevent silent failures
- **OpenTelemetry < 1.30.0**: Contains generator code in `_load_runtime_context()` that raises `StopIteration` in a way that violates PEP 479
- **Strands SDK Dependency**: Requires `opentelemetry-sdk>=1.30.0` and `opentelemetry-instrumentation-threading>=0.51b0`
- **Current Requirements**: Pins `opentelemetry-api>=1.20.0,<2.0.0` and `opentelemetry-sdk>=1.20.0,<2.0.0`

### Examples

**Example 1: Lambda Cold Start Failure**
- **Input**: Lambda cold start with Python 3.11, OpenTelemetry 1.20.0, importing `strands.agent`
- **Expected**: Successful import and Lambda ready to handle requests
- **Actual**: `StopIteration` error from `/var/task/opentelemetry/context/__init__.py:_load_runtime_context()`, Lambda initialization fails

**Example 2: API Gateway Request**
- **Input**: POST request to `/agent` endpoint with user message
- **Expected**: HTTP 200 with AI agent response
- **Actual**: HTTP 500 "Internal Server Error" because Lambda never successfully initialized

**Example 3: OpenTelemetry 1.30.0+ (Fixed)**
- **Input**: Lambda cold start with Python 3.11, OpenTelemetry 1.30.0, importing `strands.agent`
- **Expected**: Successful import and Lambda ready to handle requests
- **Actual**: Successful import (bug fixed in OpenTelemetry 1.30.0)

**Example 4: Python 3.10 (No Bug)**
- **Input**: Lambda cold start with Python 3.10, OpenTelemetry 1.20.0, importing `strands.agent`
- **Expected**: Successful import (PEP 479 not strictly enforced in Python 3.10)
- **Actual**: Successful import (bug does not manifest)

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Strands SDK functionality (Agent class, tool execution, model invocation) must continue to work exactly as before
- AWS Bedrock integration for Claude models must remain unchanged
- Travel planner tools and upselling tools must continue to function
- Conversation history storage in DynamoDB must remain unchanged
- AWS X-Ray tracing integration must continue to send trace data
- Lambda environment variables (HOTEL_API_URL, BEDROCK_MODEL_ID, etc.) must continue to be accessible
- API Gateway CORS configuration and throttling must remain unchanged
- Lambda deployment package structure must remain compatible with existing Terraform configuration

**Scope:**
All Lambda functionality that does NOT involve the OpenTelemetry version upgrade should be completely unaffected by this fix. This includes:
- Agent response generation logic
- Tool invocation mechanisms
- DynamoDB conversation storage
- Bedrock model API calls
- Error handling and graceful degradation
- JSON response formatting
- Session management

## Hypothesized Root Cause

Based on the bug description and research, the root cause is:

1. **Version Mismatch**: The `agent-service/requirements.txt` specifies `opentelemetry-api>=1.20.0,<2.0.0` and `opentelemetry-sdk>=1.20.0,<2.0.0`, but the Strands Agents SDK requires `opentelemetry-sdk>=1.30.0` and `opentelemetry-instrumentation-threading>=0.51b0`

2. **Python 3.11 PEP 479 Enforcement**: Python 3.11 strictly enforces PEP 479, which converts `StopIteration` raised inside generators to `RuntimeError`. OpenTelemetry versions < 1.30.0 have generator code in `_load_runtime_context()` that violates this rule.

3. **Dependency Resolution Failure**: When pip installs dependencies, it may resolve to OpenTelemetry 1.20.x (satisfying the explicit requirement in `requirements.txt`) rather than 1.30.x (required by Strands SDK), causing a runtime incompatibility.

4. **Lambda Python Runtime**: The Lambda function uses Python 3.11 runtime, which triggers the PEP 479 enforcement during the import of `strands.agent`, causing the initialization to fail before the handler can execute.

## Correctness Properties

Property 1: Bug Condition - Lambda Initialization Success

_For any_ Lambda cold start event where Python 3.11 is used and the Strands Agents SDK is imported, the fixed Lambda function SHALL successfully initialize without StopIteration errors from OpenTelemetry's context loading mechanism, allowing the handler to process incoming requests.

**Validates: Requirements 2.1, 2.3, 2.4**

Property 2: Preservation - Existing Agent Functionality

_For any_ valid AI agent request (POST to `/agent` with message, userId, sessionId), the fixed Lambda function SHALL produce exactly the same agent responses, tool invocations, and conversation history storage as the original code, preserving all Strands SDK functionality, Bedrock integration, and DynamoDB operations.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct (version mismatch causing Python 3.11 incompatibility):

**File**: `agent-service/requirements.txt`

**Specific Changes**:

1. **Update OpenTelemetry API Version**: Change `opentelemetry-api>=1.20.0,<2.0.0` to `opentelemetry-api>=1.30.0,<2.0.0`
   - Ensures compatibility with Python 3.11's PEP 479 enforcement
   - Aligns with Strands SDK's minimum requirement

2. **Update OpenTelemetry SDK Version**: Change `opentelemetry-sdk>=1.20.0,<2.0.0` to `opentelemetry-sdk>=1.30.0,<2.0.0`
   - Fixes the `_load_runtime_context()` StopIteration bug
   - Matches Strands SDK's dependency requirement

3. **Add OpenTelemetry Instrumentation Threading** (if not already present): Add `opentelemetry-instrumentation-threading>=0.51b0,<1.0.0`
   - Required by Strands SDK for proper thread context propagation
   - Ensures observability works correctly in multi-threaded Lambda environments

4. **Verify Strands SDK Version**: Ensure `strands-agents>=0.1.0` is present and compatible with OpenTelemetry 1.30.0+
   - Strands SDK 0.1.0+ requires OpenTelemetry 1.30.0+
   - No changes needed if already specified correctly

5. **Rebuild Lambda Deployment Package**: After updating `requirements.txt`, rebuild the Lambda deployment package to include the updated OpenTelemetry libraries
   - Run `pip install -r requirements.txt -t ./package` (or equivalent build script)
   - Redeploy Lambda function with updated dependencies

**Expected Result After Fix:**
```
# agent-service/requirements.txt (FIXED)
strands-agents>=0.1.0
boto3>=1.34.0
botocore>=1.34.0
requests>=2.31.0
python-json-logger>=2.0.7

# OpenTelemetry - Fixed for Python 3.11 compatibility
opentelemetry-api>=1.30.0,<2.0.0
opentelemetry-sdk>=1.30.0,<2.0.0
opentelemetry-instrumentation-threading>=0.51b0,<1.0.0
```

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code (exploratory testing), then verify the fix works correctly and preserves existing behavior (fix checking and preservation checking).

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm or refute the root cause analysis (OpenTelemetry version incompatibility with Python 3.11). If we refute, we will need to re-hypothesize.

**Test Plan**: Attempt to import `strands.agent` in a Python 3.11 environment with OpenTelemetry 1.20.0 installed. Run these tests on the UNFIXED code to observe failures and confirm the root cause.

**Test Cases**:
1. **Import Test with OpenTelemetry 1.20.0**: Create a minimal Python 3.11 script that imports `strands.agent` with OpenTelemetry 1.20.0 installed (will fail on unfixed code with StopIteration)
2. **Lambda Cold Start Simulation**: Invoke the Lambda function locally using SAM CLI or Docker with Python 3.11 runtime and observe the initialization failure (will fail on unfixed code)
3. **API Gateway Integration Test**: Send a POST request to the deployed Lambda endpoint and observe HTTP 500 error (will fail on unfixed code)
4. **OpenTelemetry Context Loading Test**: Directly test `opentelemetry.context._load_runtime_context()` in Python 3.11 with version 1.20.0 (will fail on unfixed code)

**Expected Counterexamples**:
- `StopIteration` exception raised from `/var/task/opentelemetry/context/__init__.py:_load_runtime_context()`
- Lambda initialization fails before handler execution
- API Gateway returns HTTP 500 "Internal Server Error"
- Possible causes: OpenTelemetry < 1.30.0 incompatible with Python 3.11 PEP 479, version mismatch with Strands SDK requirements

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds (Python 3.11 + OpenTelemetry < 1.30.0 + Strands import), the fixed function produces the expected behavior (successful initialization).

**Pseudocode:**
```
FOR ALL lambdaEvent WHERE isBugCondition(lambdaEvent) DO
  result := lambda_handler_fixed(lambdaEvent)
  ASSERT result.statusCode == 200
  ASSERT result.body contains valid agent response
  ASSERT no StopIteration errors in logs
END FOR
```

**Test Cases:**
1. **Lambda Cold Start with Fixed Dependencies**: Deploy Lambda with OpenTelemetry 1.30.0+ and verify successful initialization
2. **Import Test with OpenTelemetry 1.30.0**: Run the same import test from exploratory phase with fixed version (should succeed)
3. **API Gateway Request with Fixed Lambda**: Send POST request to `/agent` endpoint and verify HTTP 200 response with valid agent output
4. **Multiple Cold Starts**: Trigger multiple Lambda cold starts to ensure consistent initialization success

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold (valid agent requests after successful initialization), the fixed function produces the same result as the original function.

**Pseudocode:**
```
FOR ALL agentRequest WHERE NOT isBugCondition(agentRequest) DO
  ASSERT lambda_handler_original(agentRequest) = lambda_handler_fixed(agentRequest)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many test cases automatically across the input domain (different user messages, session IDs, user contexts)
- It catches edge cases that manual unit tests might miss (empty messages, long messages, special characters)
- It provides strong guarantees that behavior is unchanged for all non-buggy inputs (agent responses, tool invocations, DynamoDB writes)

**Test Plan**: Observe behavior on UNFIXED code first for valid agent requests (after manually fixing the import to bypass the bug), then write property-based tests capturing that behavior.

**Test Cases**:
1. **Agent Response Preservation**: For a set of known user messages, verify that the agent produces the same responses before and after the fix
   - Test with simple queries: "Find hotels in Paris"
   - Test with complex queries: "I need a romantic hotel in Bali for 5 nights with spa and ocean view"
   - Test with edge cases: empty message, very long message, special characters

2. **Tool Invocation Preservation**: Verify that the same tools are invoked with the same parameters before and after the fix
   - Monitor which tools are called (recommend_hotels, suggest_room_upgrade, etc.)
   - Verify tool input parameters are identical
   - Verify tool output is used correctly in agent responses

3. **DynamoDB Conversation History Preservation**: Verify that conversation messages are stored identically before and after the fix
   - Check that user messages are saved with correct userId, sessionId, role, content
   - Check that assistant messages are saved with correct metadata (tools_used)
   - Verify conversation retrieval works correctly

4. **Bedrock Model Integration Preservation**: Verify that Bedrock API calls are made identically before and after the fix
   - Check that model ID is correct (Claude 3 Sonnet)
   - Verify system prompt is unchanged
   - Verify model parameters (temperature, max tokens) are unchanged

5. **X-Ray Tracing Preservation**: Verify that X-Ray traces are emitted correctly before and after the fix
   - Check that trace segments are created for Lambda invocation
   - Verify subsegments are created for Bedrock calls, DynamoDB operations, tool invocations
   - Ensure OpenTelemetry spans are properly converted to X-Ray format

### Unit Tests

- Test Lambda handler with valid agent requests (message, userId, sessionId)
- Test Lambda handler with invalid requests (missing message, empty body)
- Test conversation manager save/retrieve operations
- Test tool initialization (lazy loading)
- Test agent initialization (lazy loading)
- Test error handling and graceful degradation
- Test CORS headers in responses

### Property-Based Tests

- Generate random user messages and verify agent produces valid responses (no crashes, valid JSON)
- Generate random session IDs and verify conversation history is stored correctly
- Generate random tool invocation scenarios and verify tools are called correctly
- Test that OpenTelemetry context propagation works across all code paths

### Integration Tests

- Test full Lambda cold start → API Gateway request → agent response → DynamoDB storage flow
- Test multiple requests in the same Lambda warm container (verify state isolation)
- Test Lambda timeout handling (long-running agent requests)
- Test X-Ray tracing end-to-end (verify traces appear in X-Ray console)
- Test Bedrock throttling and retry logic
- Test conversation history retrieval across multiple sessions
