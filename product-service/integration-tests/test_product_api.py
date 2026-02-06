import os
import requests
import pytest
import time

API_ENDPOINT = os.environ.get('API_ENDPOINT', '')

@pytest.fixture
def api_base_url():
    """Get the API base URL from environment"""
    if not API_ENDPOINT:
        pytest.skip("API_ENDPOINT not set")
    return API_ENDPOINT.rstrip('/')

@pytest.fixture
def test_product_id():
    """Generate unique test product ID"""
    return f"test-product-{int(time.time())}"

def test_get_product_not_found(api_base_url, test_product_id):
    """Test getting a non-existent product"""
    url = f"{api_base_url}/products/{test_product_id}"
    response = requests.get(url, timeout=10)
    
    assert response.status_code == 404
    data = response.json()
    assert 'error' in data

def test_list_all_products(api_base_url):
    """Test listing all products"""
    url = f"{api_base_url}/products"
    response = requests.get(url, timeout=10)
    
    assert response.status_code == 200
    data = response.json()
    assert 'products' in data
    assert 'count' in data
    assert isinstance(data['products'], list)

def test_list_products_with_limit(api_base_url):
    """Test listing products with limit parameter"""
    url = f"{api_base_url}/products?limit=5"
    response = requests.get(url, timeout=10)
    
    assert response.status_code == 200
    data = response.json()
    assert data['count'] <= 5

def test_list_products_by_category(api_base_url):
    """Test listing products by category"""
    url = f"{api_base_url}/products?category=electronics"
    response = requests.get(url, timeout=10)
    
    assert response.status_code == 200
    data = response.json()
    assert 'products' in data
    assert data['category'] == 'electronics'

def test_api_response_format(api_base_url):
    """Test API response format and headers"""
    url = f"{api_base_url}/products"
    response = requests.get(url, timeout=10)
    
    assert response.status_code == 200
    assert response.headers['Content-Type'] == 'application/json'
    assert 'Access-Control-Allow-Origin' in response.headers

def test_invalid_limit_parameter(api_base_url):
    """Test invalid limit parameter"""
    url = f"{api_base_url}/products?limit=invalid"
    response = requests.get(url, timeout=10)
    
    assert response.status_code == 400
    data = response.json()
    assert 'error' in data
