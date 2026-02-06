"""
AWS Secrets Manager helper for Lambda functions
Provides caching and automatic secret retrieval
"""

import json
import boto3
from botocore.exceptions import ClientError
from typing import Dict, Any, Optional
from functools import lru_cache


class SecretsManager:
    """Helper class for AWS Secrets Manager"""
    
    def __init__(self, region_name: str = 'us-east-1'):
        self.client = boto3.client('secretsmanager', region_name=region_name)
        self._cache = {}
    
    @lru_cache(maxsize=128)
    def get_secret(self, secret_name: str) -> Dict[str, Any]:
        """
        Retrieve secret from AWS Secrets Manager with caching
        
        Args:
            secret_name: Name of the secret
            
        Returns:
            Dictionary containing secret values
        """
        try:
            response = self.client.get_secret_value(SecretId=secret_name)
            
            if 'SecretString' in response:
                return json.loads(response['SecretString'])
            else:
                # Binary secret
                return {'binary': response['SecretBinary']}
                
        except ClientError as e:
            error_code = e.response['Error']['Code']
            
            if error_code == 'ResourceNotFoundException':
                raise Exception(f"Secret {secret_name} not found")
            elif error_code == 'InvalidRequestException':
                raise Exception(f"Invalid request for secret {secret_name}")
            elif error_code == 'InvalidParameterException':
                raise Exception(f"Invalid parameter for secret {secret_name}")
            elif error_code == 'DecryptionFailure':
                raise Exception(f"Cannot decrypt secret {secret_name}")
            elif error_code == 'InternalServiceError':
                raise Exception(f"Internal service error retrieving {secret_name}")
            else:
                raise e
    
    def get_secret_value(self, secret_name: str, key: str) -> str:
        """Get specific value from secret"""
        secret = self.get_secret(secret_name)
        return secret.get(key)


# Global instance
secrets_manager = SecretsManager()


def get_secret(secret_name: str) -> Dict[str, Any]:
    """Convenience function to get secret"""
    return secrets_manager.get_secret(secret_name)


def get_secret_value(secret_name: str, key: str) -> str:
    """Convenience function to get secret value"""
    return secrets_manager.get_secret_value(secret_name, key)
