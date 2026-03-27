# Terraform State Backend Bootstrap

This directory contains the infrastructure for Terraform remote state management.

## What This Creates

1. **S3 Bucket** - Stores Terraform state files
   - Versioning enabled (keeps history)
   - Encryption enabled (AES256)
   - Public access blocked
   - Lifecycle rules (delete old versions after 90 days)

2. **DynamoDB Table** - Provides state locking
   - Prevents concurrent Terraform operations
   - Pay-per-request billing
   - Point-in-time recovery enabled
   - Encryption enabled

## Why State Locking?

**Without locking:**
```
Developer A: terraform apply (starts)
Developer B: terraform apply (starts) ← CONFLICT!
Result: Corrupted state, resources created twice, chaos
```

**With locking:**
```
Developer A: terraform apply (acquires lock)
Developer B: terraform apply (waits for lock)
Developer A: completes (releases lock)
Developer B: proceeds safely
```

## How It Works

### 1. Lock Acquisition
```bash
terraform apply
# Terraform writes lock to DynamoDB:
# LockID: "terraform-state-543927035352/cart-service/prod/terraform.tfstate-md5"
# Info: {"ID":"abc123","Operation":"OperationTypeApply","Who":"user@host","Version":"1.5.0"}
```

### 2. Lock Check
If another process tries to run:
```
Error: Error acquiring the state lock
Lock Info:
  ID:        abc123
  Path:      terraform-state-543927035352/cart-service/prod/terraform.tfstate
  Operation: OperationTypeApply
  Who:       user@host
  Created:   2024-01-15 10:30:00
```

### 3. Lock Release
When operation completes, lock is automatically removed from DynamoDB.

## Setup Instructions

### Step 1: Bootstrap (First Time Only)

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

This creates:
- S3 bucket: `terraform-state-<account-id>`
- DynamoDB table: `terraform-state-lock`

### Step 2: Verify Resources

```bash
# Check S3 bucket
aws s3 ls | grep terraform-state

# Check DynamoDB table
aws dynamodb describe-table --table-name terraform-state-lock
```

### Step 3: Use in Other Projects

All service terraform.tf files already configured:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-<account-id>"
    key            = "cart-service/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

## State File Organization

```
S3 Bucket: terraform-state-<account-id>
├── cart-service/
│   ├── dev/terraform.tfstate
│   ├── prod/terraform.tfstate
│   └── pipeline/terraform.tfstate
├── product-service/
│   ├── dev/terraform.tfstate
│   └── prod/terraform.tfstate
├── order-service/
│   └── dev/terraform.tfstate
└── shared/terraform.tfstate
```

Each service/environment has its own state file with independent locking.

## Testing State Locking

### Test 1: Concurrent Apply (Should Block)

Terminal 1:
```bash
cd terraform/cart-service/prod
terraform apply
# Don't approve yet, leave it waiting
```

Terminal 2:
```bash
cd terraform/cart-service/prod
terraform apply
# Should show lock error immediately
```

### Test 2: View Lock in DynamoDB

```bash
aws dynamodb scan --table-name terraform-state-lock
```

Output:
```json
{
  "Items": [
    {
      "LockID": {
        "S": "terraform-state-543927035352/cart-service/prod/terraform.tfstate-md5"
      },
      "Info": {
        "S": "{\"ID\":\"abc123\",\"Operation\":\"OperationTypeApply\",\"Who\":\"user@host\"}"
      }
    }
  ]
}
```

### Test 3: Force Unlock (Emergency Only)

If a lock gets stuck (process crashed):
```bash
terraform force-unlock <lock-id>
```

⚠️ **Warning:** Only use if you're certain no other process is running!

## Cost

**S3 Bucket:**
- Storage: ~$0.023/GB/month
- Typical state files: 1-10 MB
- Cost: < $0.01/month

**DynamoDB Table:**
- Pay-per-request: $1.25 per million writes
- Typical usage: 10-100 locks/day
- Cost: < $0.01/month

**Total: ~$0.02/month** (essentially free)

## Security Features

1. **Encryption at Rest** - State files encrypted in S3
2. **Encryption in Transit** - HTTPS for all API calls
3. **Versioning** - Can recover from accidental deletions
4. **Access Control** - IAM policies control who can access state
5. **Public Access Blocked** - No public internet access

## Troubleshooting

### Error: Bucket already exists
Someone else created a bucket with that name. Change the bucket name in bootstrap/main.tf.

### Error: Table already exists
DynamoDB table already created. Either use it or delete and recreate.

### Error: Failed to acquire lock
Another Terraform process is running. Wait for it to complete or use `force-unlock`.

### State file not found
Run `terraform init` to initialize the backend connection.

## Best Practices

1. **Never commit state files to Git** - Already in .gitignore
2. **Use separate state files per environment** - Dev/prod isolation
3. **Enable versioning** - Already configured
4. **Regular backups** - S3 versioning provides this
5. **Restrict access** - Use IAM policies to limit who can modify state
6. **Monitor locks** - Set up CloudWatch alarms for stuck locks

## Migration from Local State

If you have existing local state files:

```bash
# 1. Backup local state
cp terraform.tfstate terraform.tfstate.backup

# 2. Configure backend in terraform.tf (already done)

# 3. Initialize backend
terraform init -migrate-state

# 4. Verify state in S3
aws s3 ls s3://terraform-state-<account-id>/cart-service/prod/
```

## Cleanup (Destroy Everything)

⚠️ **Warning:** This will delete all Terraform state! Only do this if you're sure.

```bash
# 1. Destroy all services first
cd terraform/cart-service/prod && terraform destroy
cd terraform/product-service/prod && terraform destroy
# ... destroy all services

# 2. Then destroy bootstrap
cd terraform/bootstrap
terraform destroy
```

---

**Next Steps:**
1. Run bootstrap to create state backend
2. Deploy services using remote state
3. Test concurrent operations to verify locking
