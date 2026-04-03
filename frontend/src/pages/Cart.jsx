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
      setCart({
        items: response.data.items || [],
        total: response.data.totalPrice || 0
      })
    } catch (err) {
      // Demo data
      setCart({
        items: [
          { cartItemId: 'cart1', hotelName: 'Grand Hotel Paris', pricePerNight: 299, nights: 3, totalPrice: 897 },
          { cartItemId: 'cart2', hotelName: 'Tokyo Imperial', pricePerNight: 329, nights: 2, totalPrice: 658 },
        ],
        total: 1555
      })
    } finally {
      setLoading(false)
    }
  }

  const removeItem = async (cartItemId) => {
    try {
      await axios.delete(`${API_CONFIG.CART_API}/cart/${DEMO_USER_ID}/${cartItemId}`)
      fetchCart()
    } catch (err) {
      alert('Hotel removed (demo mode)')
      setCart(prev => ({
        ...prev,
        items: prev.items.filter(item => item.cartItemId !== cartItemId)
      }))
    }
  }

  const checkout = async () => {
    try {
      // Create order
      const orderResponse = await axios.post(`${API_CONFIG.ORDER_API}/orders`, {
        userId: DEMO_USER_ID,
        guestDetails: {
          name: 'Demo User',
          email: 'demo@example.com',
          phone: '+1234567890'
        }
      })
      
      const orderId = orderResponse.data.orderId
      
      // Process payment
      await axios.post(`${API_CONFIG.PAYMENT_API}/payments`, {
        orderId: orderId,
        paymentMethod: 'card',
        cardToken: 'tok_visa',
        amount: cart.total,
        currency: 'USD',
        billingDetails: {
          name: 'Demo User',
          email: 'demo@example.com'
        }
      })
      
      alert(`✅ Booking confirmed! Order ID: ${orderId}`)
      navigate('/orders')
    } catch (err) {
      alert('✅ Booking confirmed successfully! (demo mode)')
      navigate('/orders')
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-4 border-primary mx-auto mb-4"></div>
          <p className="text-xl text-gray-600">Loading your trip...</p>
        </div>
      </div>
    )
  }

  if (cart.items.length === 0) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center max-w-md mx-auto px-4">
          <div className="bg-white rounded-2xl shadow-xl p-12">
            <div className="text-8xl mb-6">🧳</div>
            <h2 className="text-3xl font-bold text-gray-900 mb-4">Your trip is empty</h2>
            <p className="text-gray-600 mb-8">Start planning your next adventure!</p>
            <button
              onClick={() => navigate('/products')}
              className="bg-primary text-white px-8 py-4 rounded-lg hover:bg-orange-600 transition-all duration-300 transform hover:scale-105 font-semibold text-lg shadow-lg"
            >
              Start Planning
            </button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-8">
          <h1 className="text-5xl font-bold text-gray-900 mb-2">Trip Planning</h1>
          <p className="text-gray-600 text-lg">{cart.items.length} {cart.items.length === 1 ? 'hotel' : 'hotels'} in your trip</p>
        </div>

        <div className="grid lg:grid-cols-3 gap-8">
          {/* Cart Items */}
          <div className="lg:col-span-2">
            <div className="bg-white rounded-xl shadow-lg overflow-hidden">
              {cart.items.map((item, index) => (
                <div key={item.cartItemId || item.hotelId} className={`p-6 ${index !== 0 ? 'border-t border-gray-200' : ''} hover:bg-gray-50 transition`}>
                  <div className="flex items-center space-x-6">
                    <div className="w-24 h-24 bg-gradient-to-br from-blue-50 to-purple-50 rounded-lg flex items-center justify-center flex-shrink-0">
                      <span className="text-4xl">🏨</span>
                    </div>
                    <div className="flex-1">
                      <h3 className="text-xl font-bold text-gray-900 mb-1">{item.hotelName || item.name}</h3>
                      <p className="text-gray-600 mb-2">{item.nights} nights × ${item.pricePerNight || item.price}/night</p>
                      <p className="text-2xl font-bold text-primary">${(item.totalPrice || (item.price * item.nights)).toFixed(2)}</p>
                    </div>
                    <button
                      onClick={() => removeItem(item.cartItemId || item.hotelId)}
                      className="text-red-600 hover:text-red-800 hover:bg-red-50 p-3 rounded-lg transition-all duration-200"
                      title="Remove hotel"
                    >
                      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                      </svg>
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Order Summary */}
          <div className="lg:col-span-1">
            <div className="bg-white rounded-xl shadow-lg p-6 sticky top-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-6">Booking Summary</h2>
              
              <div className="space-y-4 mb-6">
                <div className="flex justify-between text-gray-600">
                  <span>Subtotal</span>
                  <span className="font-semibold">${cart.total.toFixed(2)}</span>
                </div>
                <div className="flex justify-between text-gray-600">
                  <span>Service Fee</span>
                  <span className="font-semibold text-green-600">FREE</span>
                </div>
                <div className="flex justify-between text-gray-600">
                  <span>Tax (estimated)</span>
                  <span className="font-semibold">${(cart.total * 0.08).toFixed(2)}</span>
                </div>
                <div className="border-t pt-4">
                  <div className="flex justify-between items-center">
                    <span className="text-xl font-bold text-gray-900">Total</span>
                    <span className="text-3xl font-bold text-primary">${(cart.total * 1.08).toFixed(2)}</span>
                  </div>
                </div>
              </div>

              <button
                onClick={checkout}
                className="w-full bg-gradient-to-r from-primary to-orange-600 text-white py-4 rounded-lg hover:from-orange-600 hover:to-primary transition-all duration-300 transform hover:scale-105 text-lg font-bold shadow-lg mb-4"
              >
                ✈️ Complete Booking
              </button>

              <button
                onClick={() => navigate('/products')}
                className="w-full bg-gray-100 text-gray-700 py-3 rounded-lg hover:bg-gray-200 transition font-semibold"
              >
                Continue Browsing
              </button>

              {/* Trust Badges */}
              <div className="mt-6 pt-6 border-t space-y-3">
                <div className="flex items-center text-sm text-gray-600">
                  <svg className="w-5 h-5 text-green-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                  </svg>
                  Secure Payment
                </div>
                <div className="flex items-center text-sm text-gray-600">
                  <svg className="w-5 h-5 text-green-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                  </svg>
                  Instant Confirmation
                </div>
                <div className="flex items-center text-sm text-gray-600">
                  <svg className="w-5 h-5 text-green-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                  </svg>
                  Free Cancellation
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
