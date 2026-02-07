import { useState, useEffect } from 'react'
import axios from 'axios'
import { API_CONFIG, DEMO_USER_ID } from '../config'

export default function Orders() {
  const [orders, setOrders] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchOrders()
  }, [])

  const fetchOrders = async () => {
    try {
      setLoading(true)
      const response = await axios.get(`${API_CONFIG.ORDER_API}/orders/${DEMO_USER_ID}`)
      setOrders(response.data.orders || [])
    } catch (err) {
      // Demo data
      setOrders([
        {
          orderId: 'ORD-12345',
          userId: DEMO_USER_ID,
          items: [
            { name: 'Dell XPS 13', price: 999, quantity: 1 },
            { name: 'Sony WH-1000XM5', price: 399, quantity: 2 }
          ],
          total: 1797,
          status: 'completed',
          createdAt: new Date().toISOString(),
          paymentStatus: 'paid'
        },
        {
          orderId: 'ORD-12344',
          userId: DEMO_USER_ID,
          items: [
            { name: 'iPhone 15 Pro', price: 1099, quantity: 1 }
          ],
          total: 1099,
          status: 'processing',
          createdAt: new Date(Date.now() - 86400000).toISOString(),
          paymentStatus: 'paid'
        }
      ])
    } finally {
      setLoading(false)
    }
  }

  const getStatusColor = (status) => {
    switch (status) {
      case 'completed': return 'bg-green-100 text-green-800'
      case 'processing': return 'bg-yellow-100 text-yellow-800'
      case 'pending': return 'bg-gray-100 text-gray-800'
      case 'failed': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-12 text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
        <p className="mt-4 text-gray-600">Loading orders...</p>
      </div>
    )
  }

  if (orders.length === 0) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-12 text-center">
        <div className="text-6xl mb-4">📦</div>
        <h2 className="text-2xl font-bold text-gray-900 mb-4">No orders yet</h2>
        <p className="text-gray-600 mb-6">Start shopping to see your orders here</p>
        <a href="/products" className="bg-primary text-white px-6 py-3 rounded-lg hover:bg-orange-600 transition inline-block">
          Browse Products
        </a>
      </div>
    )
  }

  return (
    <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <h1 className="text-4xl font-bold text-gray-900 mb-8">Order History</h1>

      <div className="space-y-6">
        {orders.map(order => (
          <div key={order.orderId} className="bg-white rounded-lg shadow-md overflow-hidden">
            <div className="bg-gray-50 px-6 py-4 border-b flex justify-between items-center">
              <div>
                <h3 className="text-lg font-semibold">Order {order.orderId}</h3>
                <p className="text-sm text-gray-600">
                  {new Date(order.createdAt).toLocaleDateString('en-US', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                  })}
                </p>
              </div>
              <div className="text-right">
                <span className={`inline-block px-3 py-1 rounded-full text-sm font-medium ${getStatusColor(order.status)}`}>
                  {order.status.charAt(0).toUpperCase() + order.status.slice(1)}
                </span>
                <p className="text-sm text-gray-600 mt-1">Payment: {order.paymentStatus}</p>
              </div>
            </div>

            <div className="p-6">
              {order.items.map((item, idx) => (
                <div key={idx} className={`flex justify-between items-center ${idx !== 0 ? 'mt-4 pt-4 border-t' : ''}`}>
                  <div>
                    <h4 className="font-medium">{item.name}</h4>
                    <p className="text-sm text-gray-600">Quantity: {item.quantity}</p>
                  </div>
                  <p className="font-semibold">${item.price * item.quantity}</p>
                </div>
              ))}

              <div className="mt-6 pt-6 border-t flex justify-between items-center">
                <span className="text-lg font-semibold">Total:</span>
                <span className="text-2xl font-bold text-primary">${order.total}</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
