#!/usr/bin/env python3
"""
Remove aws-xray-sdk imports and calls from all Lambda functions
"""

import os
import re
from pathlib import Path

def remove_xray_from_file(filepath):
    """Remove X-Ray SDK imports, decorators, and calls from a Python file"""
    with open(filepath, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # Remove import lines
    content = re.sub(r'from aws_xray_sdk\.core import xray_recorder\n', '', content)
    content = re.sub(r'from aws_xray_sdk\.core import patch_all\n', '', content)
    
    # Remove patch_all() calls and comments
    content = re.sub(r'# Enable X-Ray tracing.*\n', '', content)
    content = re.sub(r'patch_all\(\)\n', '', content)
    
    # Remove decorators
    content = re.sub(r'@xray_recorder\.capture\([^)]+\)\n', '', content)
    
    # Remove xray_recorder method calls (put_metadata, put_annotation, etc.)
    content = re.sub(r'\s*xray_recorder\.put_metadata\([^)]+\)\n', '', content)
    content = re.sub(r'\s*xray_recorder\.put_annotation\([^)]+\)\n', '', content)
    
    # Remove empty lines that might be left
    content = re.sub(r'\n\n\n+', '\n\n', content)
    
    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        return True
    return False

def main():
    """Process all Lambda function files"""
    services = ['cart-service', 'order-service', 'payment-service', 'hotel-service']
    fixed_files = []
    
    for service in services:
        service_path = Path(service) / 'src'
        if not service_path.exists():
            continue
        
        # Find all app.py files
        for app_file in service_path.rglob('app.py'):
            if remove_xray_from_file(app_file):
                fixed_files.append(str(app_file))
                print(f"Fixed: {app_file}")
    
    print(f"\nTotal files fixed: {len(fixed_files)}")
    for f in fixed_files:
        print(f"  - {f}")

if __name__ == '__main__':
    main()
