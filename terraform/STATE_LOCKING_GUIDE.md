# Terraform State Locking Guide

## Overview

This project uses **S3 + DynamoDB** for Terraform state management with automatic locking to prevent concurrent modifications.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Terraform Operations                      │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Dev Team   │    │  CI/CD       │    │  Prod Team   │
│   Member     │    │  Pipeline    │    │  Member      │
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │  State Lock Check      │
              │  (DynamoDB)            │
              └────────────────────────┘
                           │
                ┌──────────┴──────────┐
                │                     │
         Lock Available        Lock Held
                │                     │
                ▼                     ▼
       ┌────────────────┐    ┌────────────────┐
       │ Acquire Lock   │    │ Wait or Fail   │
       │ Proceed        │    │ (Error)        │
       └────────┬───────┘    └────────────────┘
                │
                ▼
       ┌────────────────┐
       │ Read/Write     │
       │ State (S3)     │
       └────────┬───────┘
                │
                ▼
       ┌────────────────┐
       │ Release Lock   │
       └────────────────┘
```

## How State Locking Works

### 1. Lock Acquisition

When you run `terraform apply`:

```bash
$ terraform apply

# Terraform does this automatically:
# 1. Calculate state file path hash
LOCK_ID="terraform-state-<account>/cart-service/prod/terraform.tfstate-md5"

# 2. Try to write lock to DynamoDB
aws dynamodb put-item \
  --table-name terraform-state-lock \
  --item '{
    "LockID": {"S": "'$LOCK_ID'"},
    "Info": {"S": "{
      \"ID\":\"abc-123\",
      \"Operation\":\"OperationTypeApply\",
      \"Who\":\"user@hostname\",
      \"Version\":\"1.5.0\",
      \"Created\":\"2024-01-15T10:30:00Z\",
      \"Path\":\"terraform-state-<account>/cart-service/prod/terraform.tfstate\"
    }"}
  }' \
  --condition-expression "attribute_not_exists(LockID)"

# 3. If successful, proceed with operation
# 4. If fails (lock exists), show error
```

### 2. Lock Information

The lock contains:
- **LockID**: Unique identifier (state file path + hash)
- **Info**: JSON with operation details
  - Who is running Terraform (user@host)
  - What operation (apply, plan, destroy)
  - When it started
  - Terraform version

### 3. Lock Release

When operation completes (success or failure):

```bash
# Terraform automatically deletes the lock
aws dynamodb delete-item \
  --table-name terraform-state-lock \
  --key '{"LockID": {"S": "'$LOCK_ID'"}}'
```

## Setup Instructions

### Step 1: Bootstrap State Backend

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

This creates:
- S3 bucket: `terraform-state-<your-account-id>`
- DynamoDB table: `terraform-state-lock`

### Step 2: Update Account ID

Replace `543927035352` with your AWS account ID in all `terraform.tf` files:

```bash
# Get your account ID
aws sts get-caller-identity --query Account --output text

# Update all terraform.tf files
find terraform -name "terraform.tf" -type f -exec sed -i 's/543927035352/YOUR_ACCOUNT_ID/g' {} \;
```

### Step 3: Initialize Services

```bash
cd terraform/cart-service/prod
terraform init  # Migrates state to S3
terraform apply
```

## Testing State Locking

### Manual Test

**Terminal 1:**
```bash
cd terraform/cart-service/prod
terraform apply
# Don't approve yet - leave it waiting
```

**Terminal 2:**
```bash
cd terraform/cart-service/prod
terraform apply
```

**Expected Result:**
```
Error: Error acquiring the state lock

Error message: ConditionalCheckFailedException: The conditional request failed
Lock Info:
  ID:        abc-123-def-456
  Path:      terraform-state-<account>/cart-service/prod/terraform.tfstate
  Operation: OperationTypeApply
  Who:       user@hostname
  Version:   1.5.0
  Created:   2024-01-15 10:30:00.123456789 +0000 UTC
  Info:      

Terraform acquires a state lock to protect the state from being written
by multiple users at the same time. Please resolve the issue above and try
again. For most commands, you can disable locking with the "-lock=false"
flag, but this is not recommended.
```

### Automated Test

```bash
cd terraform/bootstrap
bash test-locking.sh
```

## Viewing Active Locks

### Check DynamoDB

```bash
# List all active locks
aws dynamodb scan --table-name terraform-state-lock

# Check specific lock
aws dynamodb get-item \
  --table-name terraform-state-lock \
  --key '{"LockID": {"S": "terraform-state-<account>/cart-service/prod/terraform.tfstate-md5"}}'
```

### Example Output

```json
{
  "Items": [
    {
      "LockID": {
        "S": "terraform-state-543927035352/cart-service/prod/terraform.tfstate-md5"
      },
      "Info": {
        "S": "{\"ID\":\"abc-123\",\"Operation\":\"OperationTypeApply\",\"Who\":\"john@laptop\",\"Version\":\"1.5.0\",\"Created\":\"2024-01-15T10:30:00Z\",\"Path\":\"terraform-state-543927035352/cart-service/prod/terraform.tfstate\"}"
      }
    }
  ],
  "Count": 1,
  "ScannedCount": 1
}
```

## Force Unlock (Emergency)

If a lock gets stuck (process crashed, network issue):

```bash
# Get the lock ID from error message
terraform force-unlock <lock-id>

# Example:
terraform force-unlock abc-123-def-456
```

⚠️ **Warning:** Only use if you're absolutely certain no other process is running!

## State File Organization

```
S3: terraform-state-<account-id>
├── cart-service/
│   ├── dev/terraform.tfstate
│   ├── prod/terraform.tfstate
│   └── pipeline/terraform.tfstate
├── product-service/
│   ├── dev/terraform.tfstate
│   └── prod/terraform.tfstate
├── agent-service/
│   ├── dev/terraform.tfstate
│   ├── prod/terraform.tfstate
│   └── pipeline/terraform.tfstate
└── shared/terraform.tfstate

DynamoDB: terraform-state-lock
├── LockID: terraform-state-.../cart-service/dev/...
├── LockID: terraform-state-.../cart-service/prod/...
└── LockID: terraform-state-.../product-service/dev/...
```

Each service/environment has:
- **Separate state file** in S3
- **Independent lock** in DynamoDB
- **No cross-contamination**

## Benefits

### 1. Prevents Concurrent Modifications

**Without locking:**
```
Time  Developer A          Developer B          State
0:00  terraform apply      -                    v1
0:01  reads state v1       terraform apply      v1
0:02  modifies resources   reads state v1       v1
0:03  writes state v2      modifies resources   v2
0:04  -                    writes state v2'     v2' (CORRUPTED!)
```

**With locking:**
```
Time  Developer A          Developer B          State
0:00  terraform apply      -                    v1
0:01  acquires lock        -                    v1 (locked)
0:02  reads state v1       terraform apply      v1 (locked)
0:03  modifies resources   BLOCKED (waiting)    v1 (locked)
0:04  writes state v2      BLOCKED (waiting)    v2 (locked)
0:05  releases lock        acquires lock        v2 (locked)
0:06  -                    reads state v2       v2 (locked)
0:07  -                    modifies resources   v2 (locked)
0:08  -                    writes state v3      v3 (locked)
0:09  -                    releases lock        v3
```

### 2. Team Collaboration

Multiple team members can work safely:
- CI/CD pipeline runs automatically
- Developers run manual applies
- No coordination needed
- Automatic queuing

### 3. Audit Trail

Lock info shows:
- Who ran Terraform
- When it started
- What operation
- Which state file

### 4. Automatic Recovery

If process crashes:
- Lock remains in DynamoDB
- Next operation shows clear error
- Easy to identify and resolve

## Cost

**S3 Storage:**
- State files: ~1-10 MB each
- Cost: $0.023/GB/month
- Total: < $0.01/month

**DynamoDB:**
- Pay-per-request billing
- ~10-100 operations/day
- Cost: $1.25 per million writes
- Total: < $0.01/month

**Total: ~$0.02/month** (essentially free)

## Security

1. **Encryption at Rest**
   - S3: AES256 encryption
   - DynamoDB: AWS managed encryption

2. **Encryption in Transit**
   - All API calls use HTTPS
   - TLS 1.2+

3. **Access Control**
   - IAM policies control access
   - Principle of least privilege

4. **Versioning**
   - S3 versioning enabled
   - Can recover from accidents
   - 90-day retention

5. **Public Access Blocked**
   - S3 bucket not publicly accessible
   - DynamoDB table private

## Troubleshooting

### Lock Timeout

**Error:** Lock acquisition timeout after 10 minutes

**Cause:** Another process is running

**Solution:**
1. Check who has the lock: `aws dynamodb scan --table-name terraform-state-lock`
2. Contact that person
3. Wait for completion
4. Or force-unlock if process crashed

### State File Not Found

**Error:** Failed to load state: NoSuchKey

**Cause:** State file doesn't exist in S3

**Solution:**
```bash
terraform init -migrate-state  # Migrate from local to remote
```

### Permission Denied

**Error:** AccessDenied when accessing S3/DynamoDB

**Cause:** IAM permissions missing

**Solution:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::terraform-state-*",
        "arn:aws:s3:::terraform-state-*/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/terraform-state-lock"
    }
  ]
}
```

## Best Practices

1. ✅ **Always use remote state** - Never commit state files to Git
2. ✅ **Separate state per environment** - Dev/prod isolation
3. ✅ **Enable versioning** - Already configured
4. ✅ **Use descriptive state keys** - `service/environment/terraform.tfstate`
5. ✅ **Never disable locking** - Unless absolutely necessary
6. ✅ **Monitor stuck locks** - Set up CloudWatch alarms
7. ✅ **Regular backups** - S3 versioning provides this
8. ✅ **Restrict access** - Use IAM policies

## References

- [Terraform S3 Backend](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [State Locking](https://www.terraform.io/docs/language/state/locking.html)
- [DynamoDB for Locking](https://www.terraform.io/docs/language/settings/backends/s3.html#dynamodb-state-locking)

---

**Questions?** Check the bootstrap/README.md or run the test script!
