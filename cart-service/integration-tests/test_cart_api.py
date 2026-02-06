import os
import requests
import pytest
import time

# Get API endpoint from environment
API_ENDPOINT = os.environ.get('API_ENDPOINT', '')

@pytest.fixture
def api_base_url():
    """Get the API base URL from environment"""
    if not API_ENDPOINT:
        pytest.skip("API_ENDPOINT not set")
    return API_ENDPOINT.rstrip('/')

@pytest.fixture
def test_user_id():
    """Generate unique test user ID"""
    return f"test-user-{int(time.time())}"

@pytest.fixture
def test_product_id():
    """Generate unique test product ID"""
    return f"test-product-{int(time.time())}"

def test_add_item_to_cart(api_base_url, test_user_id, test_product_id):
    """Test adding an item to cart"""
    url = f"{api_base_url}/cart/add"
    payload = {
        "userId": test_user_id,
        "productId": test_product_id,
        "quantity": 2
    }
    
    response = requests.post(url, json=payload, timeout=10)
    
    assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
    data = response.json()
    assert 'message' in data
    assert data['message'] == 'Item added to cart'
    assert 'item' in data
    assert data['item']['userId'] == test_user_id
    assert data['item']['productId'] == test_product_id

def test_get_cart(api_base_url, test_user_id, test_product_id):
    """Test retrieving cart contents"""
    # First add an item
    add_url = f"{api_base_url}/cart/add"
    add_payload = {
        "userId": test_user_id,
        "productId": test_product_id,
        "quantity": 3
    }
    requests.post(add_url, json=add_payload, timeout=10)
    
    # Then retrieve the cart
    get_url = f"{api_base_url}/cart/{test_user_id}"
    response = requests.get(get_url, timeout=10)
    
    assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
    data = response.json()
    assert data['userId'] == test_user_id
    assert data['itemCount'] >= 1
    assert data['totalItems'] >= 3

def test_remove_item_from_cart(api_base_url, test_user_id, test_product_id):
    """Test removing an item from cart"""
    # First add an item
    add_url = f"{api_base_url}/cart/add"
    add_payload = {
        "userId": test_user_id,
        "productId": test_product_id,
        "quantity": 1
    }
    requests.post(add_url, json=add_payload, timeout=10)
    
    # Then remove it
    remove_url = f"{api_base_url}/cart/remove"
    remove_payload = {
        "userId": test_user_id,
        "productId": test_product_id
    }
    response = requests.delete(remove_url, json=remove_payload, timeout=10)
    
    assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
    data = response.json()
    assert 'message' in data
    assert data['message'] == 'Item removed from cart'

def test_add_cart_validation(api_base_url):
    """Test input validation for add cart"""
    url = f"{api_base_url}/cart/add"
    
    # Missing productId
    payload = {
        "userId": "test-user",
        "quantity": 1
    }
    response = requests.post(url, json=payload, timeout=10)
    assert response.status_code == 400
    
    # Invalid quantity
    payload = {
        "userId": "test-user",
        "productId": "test-product",
        "quantity": 0
    }
    response = requests.post(url, json=payload, timeout=10)
    assert response.status_code == 400

def test_get_empty_cart(api_base_url):
    """Test retrieving an empty cart"""
    url = f"{api_base_url}/cart/nonexistent-user-{int(time.time())}"
    response = requests.get(url, timeout=10)
    
    assert response.status_code == 200
    data = response.json()
    assert data['itemCount'] == 0
    assert data['totalItems'] == 0

def test_cart_workflow(api_base_url, test_user_id):
    """Test complete cart workflow"""
    product1 = f"product-1-{int(time.time())}"
    product2 = f"product-2-{int(time.time())}"
    
    # Add first item
    add_url = f"{api_base_url}/cart/add"
    requests.post(add_url, json={
        "userId": test_user_id,
        "productId": product1,
        "quantity": 2
    }, timeout=10)
    
    # Add second item
    requests.post(add_url, json={
        "userId": test_user_id,
        "productId": product2,
        "quantity": 1
    }, timeout=10)
    
    # Verify cart has 2 items
    get_url = f"{api_base_url}/cart/{test_user_id}"
    response = requests.get(get_url, timeout=10)
    data = response.json()
    assert data['itemCount'] == 2
    assert data['totalItems'] == 3
    
    # Remove first item
    remove_url = f"{api_base_url}/cart/remove"
    requests.delete(remove_url, json={
        "userId": test_user_id,
        "productId": product1
    }, timeout=10)
    
    # Verify cart has 1 item
    response = requests.get(get_url, timeout=10)
    data = response.json()
    assert data['itemCount'] == 1
    assert data['totalItems'] == 1
