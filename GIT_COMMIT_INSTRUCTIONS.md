# Git Commit Instructions for Bedrock Resilience Fix

## Files Changed

### New Files (5)
1. `agent-service/src/agent_handler/bedrock_resilience.py` - Resilience module with retry and fallback logic
2. `agent-service/deploy-resilience-fix.sh` - Deployment script
3. `BEDROCK_RESILIENCE_IMPLEMENTATION.md` - Complete implementation documentation
4. `GIT_COMMIT_INSTRUCTIONS.md` - This file

### Modified Files (4)
1. `agent-service/src/agent_handler/app.py` - Integrated resilience logic into Lambda handler
2. `agent-service/src/agent_handler/tools/travel_planner_tools.py` - Added region parameter support
3. `agent-service/src/agent_handler/tools/upselling_tools.py` - Added region parameter support
4. `terraform/agent-service/dev/main.tf` - Added BEDROCK_FALLBACK_REGIONS env var

## Git Commands to Run

### On Windows (Local IDE)

```powershell
# Check status
git status

# Stage all changes
git add agent-service/src/agent_handler/bedrock_resilience.py
git add agent-service/src/agent_handler/app.py
git add agent-service/src/agent_handler/tools/travel_planner_tools.py
git add agent-service/src/agent_handler/tools/upselling_tools.py
git add terraform/agent-service/dev/main.tf
git add agent-service/deploy-resilience-fix.sh
git add BEDROCK_RESILIENCE_IMPLEMENTATION.md
git add GIT_COMMIT_INSTRUCTIONS.md

# Commit with descriptive message
git commit -m "feat: Add Bedrock resilience with exponential backoff and multi-region fallback

- Add bedrock_resilience.py module with retry logic and region fallback
- Update Lambda handler to use resilience wrapper
- Add region parameter support to travel_planner_tools and upselling_tools
- Add BEDROCK_FALLBACK_REGIONS environment variable (us-west-2)
- Implement exponential backoff (max 3 retries, 2s base delay)
- Add graceful error handling with 503 response
- Add deployment script for easy deployment

This handles ThrottlingException while waiting for AWS Support to enable Bedrock quotas.
Automatically retries in us-east-1, then falls back to us-west-2 if throttled."

# Push to remote
git push origin main
```

### On EC2 (After Push)

```bash
# Navigate to project directory
cd ~/aws-serverless-microservices-ai

# Pull latest changes
git pull origin main

# Verify files are updated
ls -la agent-service/src/agent_handler/bedrock_resilience.py
cat agent-service/src/agent_handler/bedrock_resilience.py | head -20

# Deploy the changes
cd agent-service
bash deploy-resilience-fix.sh
```

## Alternative: Stage and Commit All at Once

```powershell
# Stage all changes
git add .

# Commit
git commit -m "feat: Add Bedrock resilience with exponential backoff and multi-region fallback"

# Push
git push origin main
```

## Verify Changes After Push

```powershell
# Check commit was created
git log -1

# Check remote status
git status
```

## What Happens Next

1. **On Windows**: Commit and push changes
2. **On EC2**: Pull changes with `git pull origin main`
3. **On EC2**: Run deployment script:
   ```bash
   cd ~/aws-serverless-microservices-ai/agent-service
   bash deploy-resilience-fix.sh
   ```
4. **Test**: The Lambda will now retry 3 times in us-east-1, then fallback to us-west-2
5. **Monitor**: Check CloudWatch logs for retry attempts

## Expected Git Output

```
[main abc1234] feat: Add Bedrock resilience with exponential backoff and multi-region fallback
 8 files changed, 450 insertions(+), 20 deletions(-)
 create mode 100644 agent-service/src/agent_handler/bedrock_resilience.py
 create mode 100755 agent-service/deploy-resilience-fix.sh
 create mode 100644 BEDROCK_RESILIENCE_IMPLEMENTATION.md
 create mode 100644 GIT_COMMIT_INSTRUCTIONS.md
```

## Troubleshooting

### If git push fails with authentication error:
```powershell
# Configure git credentials
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Try push again
git push origin main
```

### If there are merge conflicts:
```bash
# On EC2, stash local changes first
git stash

# Pull changes
git pull origin main

# Reapply stashed changes if needed
git stash pop
```

### If you need to see what changed:
```powershell
# See diff of changes
git diff agent-service/src/agent_handler/app.py

# See all changed files
git diff --name-only
```

## Summary

✅ **Ready to commit**: 8 files (4 new, 4 modified)
✅ **Commit message**: Descriptive with implementation details
✅ **Next step**: Run git commands above, then pull on EC2 and deploy

🎯 **Goal**: Get resilience logic deployed to handle Bedrock throttling while waiting for AWS Support
