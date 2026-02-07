import { useState, useEffect } from 'react'
import axios from 'axios'
import { API_CONFIG, DEMO_USER_ID } from '../config'
import { useNavigate } from 'react-router-dom'

export default function Cart() {
  const [cart, setCart] = useState({ items: [], total: 0 })
  const [loading, setLoading] = useState(true)
  const navigate = useNavigate()

  useEffect(() => {
    fetchCart()
  }, [])

  const fetchCart = async () => {
    try {
      setLoading(true)
      const response = await axios.get(`${API_CONFIG.CART_API}/cart/${DEMO_USER_ID}`)
      setCart(response.data)
    } catch (err) {
      // Demo data
      setCart({
        items: [
          { productId: 'prod1', name: 'Dell XPS 13', price: 999, quantity: 1 },
          { productId: 'prod5', name: 'Sony WH-1000XM5', price: 399, quantity: 2 },
        ],
        total: 1797
      })
    } finally {
      setLoading(false)
    }
  }

  const removeItem = async (productId) => {
    try {
      await axios.post(`${API_CONFIG.CART_API}/cart/remove`, {
        userId: DEMO_USER_ID,
        productId
      })
      fetchCart()
    } catch (err) {
      alert('Item removed (demo mode)')
      setCart(prev => ({
        ...prev,
        items: prev.items.filter(item => item.productId !== productId)
      }))
    }
  }

  const checkout = async () => {
    try {
      const response = await axios.post(`${API_CONFIG.ORDER_API}/orders`, {
        userId: DEMO_USER_ID,
        items: cart.items
      })
      alert(`Order created! Order ID: ${response.data.orderId}`)
      navigate('/orders')
    } catch (err) {
      alert('Order created successfully! (demo mode)')
      navigate('/orders')
    }
  }

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-12 text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
        <p className="mt-4 text-gray-600">Loading cart...</p>
      </div>
    )
  }

  if (cart.items.length === 0) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-12 text-center">
        <div className="text-6xl mb-4">🛒</div>
        <h2 className="text-2xl font-bold text-gray-900 mb-4">Your cart is empty</h2>
        <button
          onClick={() => navigate('/products')}
          className="bg-primary text-white px-6 py-3 rounded-lg hover:bg-orange-600 transition"
        >
          Browse Products
        </button>
      </div>
    )
  }

  return (
    <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <h1 className="text-4xl font-bold text-gray-900 mb-8">Shopping Cart</h1>

      <div className="bg-white rounded-lg shadow-md">
        {cart.items.map((item, index) => (
          <div key={item.productId} className={`p-6 ${index !== 0 ? 'border-t' : ''}`}>
            <div className="flex justify-between items-center">
              <div className="flex items-center space-x-4">
                <div className="w-16 h-16 bg-gray-100 rounded flex items-center justify-center">
                  <span className="text-2xl">📦</span>
                </div>
                <div>
                  <h3 className="text-lg font-semibold">{item.name}</h3>
                  <p className="text-gray-600">Quantity: {item.quantity}</p>
                </div>
              </div>
              <div className="flex items-center space-x-4">
                <p className="text-xl font-bold text-primary">${item.price * item.quantity}</p>
                <button
                  onClick={() => removeItem(item.productId)}
                  className="text-red-600 hover:text-red-800"
                >
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </button>
              </div>
            </div>
          </div>
        ))}

        <div className="border-t p-6 bg-gray-50">
          <div className="flex justify-between items-center mb-6">
            <span className="text-xl font-semibold">Total:</span>
            <span className="text-3xl font-bold text-primary">${cart.total}</span>
          </div>
          <button
            onClick={checkout}
            className="w-full bg-primary text-white py-3 rounded-lg hover:bg-orange-600 transition text-lg font-semibold"
          >
            Proceed to Checkout
          </button>
        </div>
      </div>
    </div>
  )
}
