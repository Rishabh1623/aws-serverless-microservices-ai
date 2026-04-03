"""
Production-grade resilience patterns for Lambda functions
Includes: Circuit Breaker, Retry with Exponential Backoff, Bulkhead Pattern
"""

import time
import random
import functools
from datetime import datetime, timedelta
from typing import Callable, Any, Optional
from enum import Enum


class CircuitState(Enum):
    """Circuit breaker states"""
    CLOSED = "closed"      # Normal operation
    OPEN = "open"          # Failing, reject requests
    HALF_OPEN = "half_open"  # Testing if service recovered


class CircuitBreaker:
    """
    Circuit Breaker pattern implementation
    Prevents cascading failures by failing fast when a service is down
    """
    
    def __init__(
        self,
        failure_threshold: int = 5,
        recovery_timeout: int = 60,
        expected_exception: type = Exception,
        name: str = "circuit_breaker"
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.expected_exception = expected_exception
        self.name = name
        
        self.failure_count = 0
        self.last_failure_time = None
        self.state = CircuitState.CLOSED
    
    def call(self, func: Callable, *args, **kwargs) -> Any:
        """Execute function with circuit breaker protection"""
        
        if self.state == CircuitState.OPEN:
            if self._should_attempt_reset():
                self.state = CircuitState.HALF_OPEN
                print(f"Circuit breaker {self.name}: Attempting reset (HALF_OPEN)")
            else:
                raise Exception(f"Circuit breaker {self.name} is OPEN. Service unavailable.")
        
        try:
            result = func(*args, **kwargs)
            self._on_success()
            return result
        
        except self.expected_exception as e:
            self._on_failure()
            raise e
    
    def _should_attempt_reset(self) -> bool:
        """Check if enough time has passed to attempt reset"""
        if self.last_failure_time is None:
            return True
        
        return (datetime.now() - self.last_failure_time).seconds >= self.recovery_timeout
    
    def _on_success(self):
        """Handle successful call"""
        if self.state == CircuitState.HALF_OPEN:
            print(f"Circuit breaker {self.name}: Service recovered (CLOSED)")
        
        self.failure_count = 0
        self.state = CircuitState.CLOSED
    
    def _on_failure(self):
        """Handle failed call"""
        self.failure_count += 1
        self.last_failure_time = datetime.now()
        
        if self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN
            print(f"Circuit breaker {self.name}: Threshold reached (OPEN)")


def circuit_breaker(
    failure_threshold: int = 5,
    recovery_timeout: int = 60,
    expected_exception: type = Exception,
    name: str = None
):
    """
    Decorator for circuit breaker pattern
    
    Usage:
        @circuit_breaker(failure_threshold=3, recovery_timeout=30)
        def call_external_service():
            # Your code here
            pass
    """
    def decorator(func: Callable) -> Callable:
        breaker_name = name or func.__name__
        breaker = CircuitBreaker(
            failure_threshold=failure_threshold,
            recovery_timeout=recovery_timeout,
            expected_exception=expected_exception,
            name=breaker_name
        )
        
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            return breaker.call(func, *args, **kwargs)
        
        return wrapper
    return decorator


def retry_with_backoff(
    max_attempts: int = 3,
    base_delay: float = 1.0,
    max_delay: float = 60.0,
    exponential_base: float = 2.0,
    jitter: bool = True,
    exceptions: tuple = (Exception,)
):
    """
    Retry decorator with exponential backoff and jitter
    
    Args:
        max_attempts: Maximum number of retry attempts
        base_delay: Initial delay in seconds
        max_delay: Maximum delay in seconds
        exponential_base: Base for exponential backoff
        jitter: Add random jitter to prevent thundering herd
        exceptions: Tuple of exceptions to catch and retry
    
    Usage:
        @retry_with_backoff(max_attempts=3, base_delay=1.0)
        def call_api():
            # Your code here
            pass
    """
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            attempt = 0
            
            while attempt < max_attempts:
                try:
                    return func(*args, **kwargs)
                
                except exceptions as e:
                    attempt += 1
                    
                    if attempt >= max_attempts:
                        print(f"Max retry attempts ({max_attempts}) reached for {func.__name__}")
                        raise e
                    
                    # Calculate delay with exponential backoff
                    delay = min(base_delay * (exponential_base ** (attempt - 1)), max_delay)
                    
                    # Add jitter to prevent thundering herd
                    if jitter:
                        delay = delay * (0.5 + random.random())
                    
                    print(f"Retry attempt {attempt}/{max_attempts} for {func.__name__} after {delay:.2f}s")
                    time.sleep(delay)
            
            return None
        
        return wrapper
    return decorator


class Bulkhead:
    """
    Bulkhead pattern implementation
    Isolates resources to prevent cascading failures
    """
    
    def __init__(self, max_concurrent: int = 10, name: str = "bulkhead"):
        self.max_concurrent = max_concurrent
        self.name = name
        self.current_count = 0
    
    def execute(self, func: Callable, *args, **kwargs) -> Any:
        """Execute function with bulkhead protection"""
        
        if self.current_count >= self.max_concurrent:
            raise Exception(f"Bulkhead {self.name}: Max concurrent executions ({self.max_concurrent}) reached")
        
        self.current_count += 1
        
        try:
            result = func(*args, **kwargs)
            return result
        finally:
            self.current_count -= 1


def bulkhead(max_concurrent: int = 10, name: str = None):
    """
    Decorator for bulkhead pattern
    
    Usage:
        @bulkhead(max_concurrent=5)
        def process_request():
            # Your code here
            pass
    """
    def decorator(func: Callable) -> Callable:
        bulkhead_name = name or func.__name__
        bulkhead_instance = Bulkhead(max_concurrent=max_concurrent, name=bulkhead_name)
        
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            return bulkhead_instance.execute(func, *args, **kwargs)
        
        return wrapper
    return decorator


def timeout(seconds: int):
    """
    Timeout decorator for functions
    
    Usage:
        @timeout(30)
        def long_running_task():
            # Your code here
            pass
    """
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            import signal
            
            def timeout_handler(signum, frame):
                raise TimeoutError(f"Function {func.__name__} timed out after {seconds} seconds")
            
            # Set the signal handler
            signal.signal(signal.SIGALRM, timeout_handler)
            signal.alarm(seconds)
            
            try:
                result = func(*args, **kwargs)
            finally:
                signal.alarm(0)  # Disable the alarm
            
            return result
        
        return wrapper
    return decorator


# Example usage combining patterns
@circuit_breaker(failure_threshold=3, recovery_timeout=30, name="hotel_service")
@retry_with_backoff(max_attempts=3, base_delay=1.0)
@bulkhead(max_concurrent=10)
def call_hotel_service(hotel_id: str, check_in: str, check_out: str):
    """
    Example function with all resilience patterns applied
    """
    import requests
    
    response = requests.post(
        "https://hotel-service.example.com/bookings",
        json={"hotelId": hotel_id, "checkIn": check_in, "checkOut": check_out},
        timeout=10
    )
    
    response.raise_for_status()
    return response.json()
