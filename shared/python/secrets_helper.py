"""
AWS Secrets Manager Helper

Simplifies retrieving secrets from AWS Secrets Manager with caching.
"""

import boto3
import json
import os
from functools import lru_cache
from typing import Dict, Any, Optional

# Initialize Secrets Manager client
secrets_client = boto3.client('secretsmanager')


@lru_cache(maxsize=128)
def get_secret(secret_name: str, region: Optional[str] = None) -> Dict[str, Any]:
    """
    Retrieve secret from AWS Secrets Manager with caching
    
    Args:
        secret_name: Name of the secret
        region: AWS region (defaults to environment variable)
        
    Returns:
        Dictionary containing secret values
        
    Example:
        secret = get_secret("travel-platform/dev/stripe_api_key")
        api_key = secret['api_key']
    """
    try:
        if region:
            client = boto3.client('secretsmanager', region_name=region)
        else:
            client = secrets_client
        
        response = client.get_secret_value(SecretId=secret_name)
        
        # Parse secret string
        if 'SecretString' in response:
            return json.loads(response['SecretString'])
        else:
            # Binary secret
            return {'binary': response['SecretBinary']}
            
    except Exception as e:
        print(f"Error retrieving secret {secret_name}: {str(e)}")
        raise


def get_secret_value(secret_name: str, key: str, default: Any = None) -> Any:
    """
    Get specific value from secret
    
    Args:
        secret_name: Name of the secret
        key: Key within the secret
        default: Default value if key not found
        
    Returns:
        Secret value or default
        
    Example:
        api_key = get_secret_value("travel-platform/dev/stripe", "api_key")
    """
    try:
        secret = get_secret(secret_name)
        return secret.get(key, default)
    except Exception:
        return default


def get_secret_from_env(env_var: str, secret_name: str, key: str) -> str:
    """
    Get secret from environment variable or Secrets Manager
    
    Useful for local development (use env var) vs production (use Secrets Manager)
    
    Args:
        env_var: Environment variable name
        secret_name: Secrets Manager secret name
        key: Key within the secret
        
    Returns:
        Secret value
        
    Example:
        stripe_key = get_secret_from_env(
            "STRIPE_API_KEY",
            "travel-platform/prod/stripe",
            "api_key"
        )
    """
    # Check environment variable first (for local development)
    value = os.environ.get(env_var)
    if value:
        return value
    
    # Fall back to Secrets Manager (for production)
    return get_secret_value(secret_name, key)


def clear_cache():
    """Clear the secrets cache (useful for testing)"""
    get_secret.cache_clear()
