"""
Bedrock Resilience Module

Provides exponential backoff retry logic and multi-region fallback
for handling ThrottlingException from AWS Bedrock.

Features:
- Exponential backoff with jitter
- Multi-region fallback (us-east-1 → us-west-2)
- Automatic retry on throttling
- Detailed logging for debugging
"""

import time
import logging
import random
from typing import Callable, Any, List, Optional
from botocore.exceptions import ClientError

logger = logging.getLogger()


class BedrockResilienceError(Exception):
    """Custom exception for Bedrock resilience failures"""
    pass


def exponential_backoff_retry(
    func: Callable,
    max_retries: int = 3,
    base_delay: float = 2.0,
    max_delay: float = 32.0,
    jitter: bool = True,
    retry_on_exceptions: List[str] = None
) -> Any:
    """
    Execute function with exponential backoff retry logic
    
    Args:
        func: Function to execute
        max_retries: Maximum number of retry attempts (default: 3)
        base_delay: Base delay in seconds (default: 2.0)
        max_delay: Maximum delay in seconds (default: 32.0)
        jitter: Add random jitter to delay (default: True)
        retry_on_exceptions: List of exception codes to retry on
        
    Returns:
        Result from successful function execution
        
    Raises:
        BedrockResilienceError: If all retries exhausted
    """
    if retry_on_exceptions is None:
        retry_on_exceptions = ['ThrottlingException', 'TooManyRequestsException']
    
    last_exception = None
    
    for attempt in range(max_retries + 1):
        try:
            result = func()
            
            if attempt > 0:
                logger.info(f"✅ Retry successful on attempt {attempt + 1}")
            
            return result
            
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', '')
            error_message = e.response.get('Error', {}).get('Message', '')
            
            last_exception = e
            
            # Check if this is a retryable error
            if error_code not in retry_on_exceptions:
                logger.error(f"Non-retryable error: {error_code} - {error_message}")
                raise
            
            # If this was the last attempt, raise
            if attempt >= max_retries:
                logger.error(f"❌ All {max_retries} retries exhausted for {error_code}")
                break
            
            # Calculate delay with exponential backoff
            delay = min(base_delay * (2 ** attempt), max_delay)
            
            # Add jitter to prevent thundering herd
            if jitter:
                delay = delay * (0.5 + random.random())
            
            logger.warning(
                f"⚠️  Attempt {attempt + 1}/{max_retries + 1} failed with {error_code}. "
                f"Retrying in {delay:.2f}s... Error: {error_message}"
            )
            
            time.sleep(delay)
        
        except Exception as e:
            logger.error(f"Unexpected error during retry: {str(e)}", exc_info=True)
            raise
    
    # All retries exhausted
    raise BedrockResilienceError(
        f"Failed after {max_retries} retries. Last error: {last_exception}"
    )


def multi_region_fallback(
    func: Callable,
    primary_region: str = 'us-east-1',
    fallback_regions: Optional[List[str]] = None,
    max_retries_per_region: int = 3
) -> Any:
    """
    Execute function with multi-region fallback
    
    Tries primary region first with retries, then falls back to other regions
    
    Args:
        func: Function to execute (should accept region parameter)
        primary_region: Primary AWS region (default: us-east-1)
        fallback_regions: List of fallback regions (default: [us-west-2])
        max_retries_per_region: Max retries per region (default: 3)
        
    Returns:
        Result from successful function execution
        
    Raises:
        BedrockResilienceError: If all regions fail
    """
    if fallback_regions is None:
        fallback_regions = ['us-west-2']
    
    all_regions = [primary_region] + fallback_regions
    last_exception = None
    
    for region in all_regions:
        try:
            logger.info(f"🌍 Attempting Bedrock call in region: {region}")
            
            # Create a wrapper that passes the region to the function
            def region_func():
                return func(region)
            
            # Try with exponential backoff
            result = exponential_backoff_retry(
                region_func,
                max_retries=max_retries_per_region
            )
            
            if region != primary_region:
                logger.warning(f"⚠️  Using fallback region {region} (primary {primary_region} failed)")
            
            return result
            
        except (BedrockResilienceError, ClientError) as e:
            last_exception = e
            logger.error(f"❌ Region {region} failed: {str(e)}")
            
            # If this is the last region, raise
            if region == all_regions[-1]:
                break
            
            logger.info(f"🔄 Falling back to next region...")
            continue
        
        except Exception as e:
            logger.error(f"Unexpected error in region {region}: {str(e)}", exc_info=True)
            last_exception = e
            continue
    
    # All regions exhausted
    raise BedrockResilienceError(
        f"Failed in all regions {all_regions}. Last error: {last_exception}"
    )


def with_bedrock_resilience(
    func: Callable,
    enable_retry: bool = True,
    enable_multi_region: bool = True,
    primary_region: str = 'us-east-1',
    fallback_regions: Optional[List[str]] = None,
    max_retries: int = 3
) -> Any:
    """
    Wrapper that combines retry logic and multi-region fallback
    
    Args:
        func: Function to execute
        enable_retry: Enable exponential backoff retry (default: True)
        enable_multi_region: Enable multi-region fallback (default: True)
        primary_region: Primary AWS region (default: us-east-1)
        fallback_regions: List of fallback regions (default: [us-west-2])
        max_retries: Max retries per region (default: 3)
        
    Returns:
        Result from successful function execution
    """
    if enable_multi_region:
        return multi_region_fallback(
            func,
            primary_region=primary_region,
            fallback_regions=fallback_regions,
            max_retries_per_region=max_retries
        )
    elif enable_retry:
        return exponential_backoff_retry(func, max_retries=max_retries)
    else:
        return func()
