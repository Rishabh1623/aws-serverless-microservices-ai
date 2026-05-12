#!/bin/bash
# Update Terraform backend configuration for new AWS account

set -e

# Get new account ID
NEW_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
OLD_ACCOUNT_ID="600105205879"

echo "=========================================="
echo "Updating Terraform Backend Configuration"
echo "=========================================="
echo "Old Account ID: $OLD_ACCOUNT_ID"
echo "New Account ID: $NEW_ACCOUNT_ID"
echo ""

# Update all main.tf files with backend configuration
echo "Updating backend configurations..."

# Find all main.tf files with backend configuration
find terraform -name "main.tf" -type f | while read -r file; do
    if grep -q "terraform-state-$OLD_ACCOUNT_ID" "$file"; then
        echo "Updating: $file"
        sed -i "s/terraform-state-$OLD_ACCOUNT_ID/terraform-state-$NEW_ACCOUNT_ID/g" "$file"
    fi
done

echo ""
echo "✅ Backend configurations updated!"
echo ""
echo "Next steps:"
echo "1. Review changes: git diff"
echo "2. Commit changes: git add -A && git commit -m 'Update Terraform backend for new account'"
echo "3. Deploy services"
