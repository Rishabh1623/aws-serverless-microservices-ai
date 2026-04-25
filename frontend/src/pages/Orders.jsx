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
      // Fetch real bookings from Hotel Service API
      const response = await axios.get(`${API_CONFIG.HOTEL_API}/bookings?userId=${DEMO_USER_ID}`)
      
      // Transform bookings to match the order format
      const bookings = response.data.bookings || []
      const transformedOrders = bookings.map(booking => ({
        orderId: booking.bookingId,
        userId: booking.userId,
        items: [{
          hotelName: booking.hotelName || 'Hotel',
          roomType: booking.roomType || 'Room',
          checkIn: booking.checkIn,
          checkOut: booking.checkOut,
          nights: booking.nights || calculateNights(booking.checkIn, booking.checkOut),
          pricePerNight: booking.totalPrice / (booking.nights || 1),
          totalPrice: booking.totalPrice
        }],
        totalPrice: booking.totalPrice,
        status: booking.status,
        createdAt: booking.createdAt,
        paymentStatus: booking.paymentStatus || 'completed',
        guestDetails: {
          name: booking.guestName,
          email: booking.guestEmail
        }
      }))
      
      setOrders(transformedOrders)
    } catch (err) {
      console.error('Error fetching bookings:', err)
      setOrders([])
    } finally {
      setLoading(false)
    }
  }

  const calculateNights = (checkIn, checkOut) => {
    if (!checkIn || !checkOut) return 1
    const start = new Date(checkIn)
    const end = new Date(checkOut)
    return Math.ceil((end - start) / (1000 * 60 * 60 * 24))
  }

  const getStatusColor = (status) => {
    switch (status) {
      case 'completed': return 'bg-green-100 text-green-800'
      case 'confirmed': return 'bg-blue-100 text-blue-800'
      case 'pending': return 'bg-yellow-100 text-yellow-800'
      case 'cancelled': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-12 text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
        <p className="mt-4 text-gray-600">Loading bookings...</p>
      </div>
    )
  }

  if (orders.length === 0) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-12 text-center">
        <div className="text-6xl mb-4">📦</div>
        <h2 className="text-2xl font-bold text-gray-900 mb-4">No bookings yet</h2>
        <p className="text-gray-600 mb-6">Start exploring hotels to see your bookings here</p>
        <a href="/products" className="bg-primary text-white px-6 py-3 rounded-lg hover:bg-orange-600 transition inline-block">
          Browse Hotels
        </a>
      </div>
    )
  }

  return (
    <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <h1 className="text-4xl font-bold text-gray-900 mb-8">Booking History</h1>

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
                {order.guestDetails && (
                  <p className="text-sm text-gray-600 mt-1">
                    👤 {order.guestDetails.name} • {order.guestDetails.email}
                  </p>
                )}
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
                    <h4 className="font-medium">🏨 {item.hotelName || item.name}</h4>
                    <p className="text-sm text-gray-600">
                      {item.nights || item.quantity} nights × ${item.pricePerNight || item.price}/night
                    </p>
                    {item.checkIn && item.checkOut && (
                      <p className="text-xs text-gray-500 mt-1">
                        📅 {item.checkIn} to {item.checkOut}
                      </p>
                    )}
                  </div>
                  <p className="font-semibold">${(item.totalPrice || (item.price * item.quantity)).toFixed(2)}</p>
                </div>
              ))}

              <div className="mt-6 pt-6 border-t flex justify-between items-center">
                <span className="text-lg font-semibold">Total:</span>
                <span className="text-2xl font-bold text-primary">${(order.totalPrice || order.total).toFixed(2)}</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
