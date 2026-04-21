import { useState, useEffect } from 'react'
import axios from 'axios'
import { API_CONFIG, DEMO_USER_ID } from '../config'
import { triggerHotelBooking } from '../services/workflowService'

export default function Products() {
  const [products, setProducts] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedCategory, setSelectedCategory] = useState('All')
  const [sortBy, setSortBy] = useState('name')
  const [bookingModal, setBookingModal] = useState({ show: false, hotel: null })
  const [bookingForm, setBookingForm] = useState({
    checkIn: '',
    checkOut: '',
    guests: 2,
    guestName: '',
    guestEmail: ''
  })
  const [bookingInProgress, setBookingInProgress] = useState(false)

  useEffect(() => {
    fetchProducts()
  }, [])

  const fetchProducts = async () => {
    try {
      setLoading(true)
      const response = await axios.get(`${API_CONFIG.HOTEL_API}/hotels`)
      setProducts(response.data.hotels || response.data.products || [])
      setError(null)
    } catch (err) {
      setError('Failed to load hotels. Using demo data.')
      // Demo hotel data - Generic fictional names for demo purposes
      setProducts([
        // Paris Hotels
        { id: 'hotel1', name: 'Le Parisien Luxury Hotel', price: 299, category: 'Paris', stock: 5, description: 'Luxury 5-star hotel in the heart of Paris with Eiffel Tower views', imageUrl: 'https://images.unsplash.com/photo-1549294413-26f195200c16?w=400&h=300&fit=crop' },
        { id: 'hotel2', name: 'Marais Boutique Inn', price: 189, category: 'Paris', stock: 8, description: 'Charming boutique hotel in historic Marais district', imageUrl: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=400&h=300&fit=crop' },
        { id: 'hotel3', name: 'Paris Executive Suites', price: 249, category: 'Paris', stock: 12, description: 'Modern business hotel near La Défense with conference facilities', imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&h=300&fit=crop' },
        
        // London Hotels
        { id: 'hotel4', name: 'Westminster Palace Hotel', price: 349, category: 'London', stock: 6, description: 'Elegant hotel near Buckingham Palace with afternoon tea service', imageUrl: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=400&h=300&fit=crop' },
        { id: 'hotel5', name: 'Thames Riverside Inn', price: 199, category: 'London', stock: 10, description: 'Riverside hotel with stunning Thames and Tower Bridge views', imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400&h=300&fit=crop' },
        { id: 'hotel6', name: 'Covent Garden Plaza', price: 279, category: 'London', stock: 7, description: 'Stylish hotel in vibrant Covent Garden theater district', imageUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400&h=300&fit=crop' },
        
        // New York Hotels
        { id: 'hotel7', name: 'Manhattan Plaza Hotel', price: 399, category: 'New York', stock: 4, description: 'Iconic luxury hotel in Midtown Manhattan near Times Square', imageUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400&h=300&fit=crop' },
        { id: 'hotel8', name: 'Brooklyn Heights Inn', price: 229, category: 'New York', stock: 9, description: 'Modern hotel in Brooklyn with Manhattan skyline views', imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&h=300&fit=crop' },
        { id: 'hotel9', name: 'Central Park View Suites', price: 449, category: 'New York', stock: 3, description: 'Premium suites overlooking Central Park', imageUrl: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=400&h=300&fit=crop' },
        
        // Tokyo Hotels
        { id: 'hotel10', name: 'Ginza Imperial Hotel', price: 329, category: 'Tokyo', stock: 8, description: 'Traditional Japanese luxury hotel in Ginza district', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400&h=300&fit=crop' },
        { id: 'hotel11', name: 'Shibuya Sky Hotel', price: 189, category: 'Tokyo', stock: 15, description: 'Contemporary hotel in bustling Shibuya with rooftop bar', imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400&h=300&fit=crop' },
        { id: 'hotel12', name: 'Asakusa Temple Inn', price: 159, category: 'Tokyo', stock: 12, description: 'Traditional ryokan-style hotel near Senso-ji Temple', imageUrl: 'https://images.unsplash.com/photo-1549294413-26f195200c16?w=400&h=300&fit=crop' },
        
        // Dubai Hotels
        { id: 'hotel13', name: 'Marina Bay Luxury Resort', price: 499, category: 'Dubai', stock: 6, description: 'Ultra-luxury hotel with private beach and Arabian Gulf views', imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=400&h=300&fit=crop' },
        { id: 'hotel14', name: 'Downtown Dubai Plaza', price: 379, category: 'Dubai', stock: 8, description: 'Modern hotel near Dubai Mall and Burj Khalifa', imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&h=300&fit=crop' },
        { id: 'hotel15', name: 'Palm Island Resort', price: 549, category: 'Dubai', stock: 4, description: 'Exclusive resort on Palm Jumeirah with water park access', imageUrl: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400&h=300&fit=crop' },
        
        // Barcelona Hotels
        { id: 'hotel16', name: 'Gothic Quarter Inn', price: 219, category: 'Barcelona', stock: 10, description: 'Historic hotel in medieval Gothic Quarter near Las Ramblas', imageUrl: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=400&h=300&fit=crop' },
        { id: 'hotel17', name: 'Sagrada View Suites', price: 269, category: 'Barcelona', stock: 7, description: 'Modern suites with Gaudí architecture views', imageUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400&h=300&fit=crop' },
        { id: 'hotel18', name: 'Barceloneta Beach Resort', price: 299, category: 'Barcelona', stock: 9, description: 'Beachfront resort with Mediterranean cuisine', imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400&h=300&fit=crop' },
        
        // Singapore Hotels
        { id: 'hotel19', name: 'Marina Bay Sky Hotel', price: 429, category: 'Singapore', stock: 5, description: 'Iconic hotel with rooftop infinity pool and city views', imageUrl: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400&h=300&fit=crop' },
        { id: 'hotel20', name: 'Sentosa Island Resort', price: 349, category: 'Singapore', stock: 8, description: 'Tropical resort on Sentosa Island with beach access', imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&h=300&fit=crop' },
        { id: 'hotel21', name: 'Orchard Plaza Hotel', price: 259, category: 'Singapore', stock: 11, description: 'Shopping district hotel on famous Orchard Road', imageUrl: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=400&h=300&fit=crop' },
        
        // Rome Hotels
        { id: 'hotel22', name: 'Colosseum View Inn', price: 289, category: 'Rome', stock: 6, description: 'Historic hotel with ancient Colosseum views', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400&h=300&fit=crop' },
        { id: 'hotel23', name: 'Vatican City Suites', price: 249, category: 'Rome', stock: 9, description: 'Elegant suites near Vatican City and St. Peter\'s Basilica', imageUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400&h=300&fit=crop' },
        { id: 'hotel24', name: 'Trastevere Boutique Hotel', price: 199, category: 'Rome', stock: 12, description: 'Charming hotel in bohemian Trastevere neighborhood', imageUrl: 'https://images.unsplash.com/photo-1549294413-26f195200c16?w=400&h=300&fit=crop' },
        
        // Sydney Hotels
        { id: 'hotel25', name: 'Sydney Harbour View Hotel', price: 379, category: 'Sydney', stock: 7, description: 'Waterfront hotel with Opera House and Harbour Bridge views', imageUrl: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400&h=300&fit=crop' },
        { id: 'hotel26', name: 'Bondi Beach Resort', price: 299, category: 'Sydney', stock: 10, description: 'Beachfront resort at famous Bondi Beach', imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400&h=300&fit=crop' },
        { id: 'hotel27', name: 'Darling Harbour Suites', price: 329, category: 'Sydney', stock: 8, description: 'Modern suites in entertainment district', imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&h=300&fit=crop' },
        
        // Amsterdam Hotels
        { id: 'hotel28', name: 'Canal House Inn', price: 259, category: 'Amsterdam', stock: 6, description: 'Historic canal house hotel in Jordaan district', imageUrl: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=400&h=300&fit=crop' },
        { id: 'hotel29', name: 'Museum Quarter Hotel', price: 229, category: 'Amsterdam', stock: 9, description: 'Boutique hotel near Van Gogh and Rijksmuseum', imageUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400&h=300&fit=crop' },
        { id: 'hotel30', name: 'Amsterdam Central Plaza', price: 199, category: 'Amsterdam', stock: 13, description: 'Modern hotel near Central Station and Dam Square', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400&h=300&fit=crop' },
      ])
    } finally {
      setLoading(false)
    }
  }

  const addToCart = async (product) => {
    // Open booking modal instead of direct add to cart
    setBookingModal({ show: true, hotel: product })
    // Set default dates (7 days from now for 3 nights)
    const checkIn = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
    const checkOut = new Date(Date.now() + 10 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
    setBookingForm({
      checkIn,
      checkOut,
      guests: 2,
      guestName: '',
      guestEmail: ''
    })
  }

  const handleBooking = async () => {
    if (!bookingForm.guestName || !bookingForm.guestEmail) {
      alert('Please fill in all guest details')
      return
    }

    setBookingInProgress(true)
    try {
      // Trigger hotel booking workflow
      const workflowData = {
        hotelId: bookingModal.hotel.id,
        roomId: `room-${bookingModal.hotel.id}-001`,
        userId: DEMO_USER_ID,
        checkIn: bookingForm.checkIn,
        checkOut: bookingForm.checkOut,
        guestName: bookingForm.guestName,
        guestEmail: bookingForm.guestEmail,
        guests: bookingForm.guests
      }

      await triggerHotelBooking(workflowData)
      
      alert(`✅ Booking confirmed for ${bookingModal.hotel.name}!\nWorkflow started successfully.`)
      setBookingModal({ show: false, hotel: null })
    } catch (err) {
      console.error('Booking error:', err)
      alert('❌ Booking failed. Please try again.')
    } finally {
      setBookingInProgress(false)
    }
  }

  // Get unique categories
  const categories = ['All', ...new Set(products.map(p => p.category))]

  // Filter and sort products
  let filteredProducts = products.filter(p =>
    (p.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    p.category.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (p.description && p.description.toLowerCase().includes(searchTerm.toLowerCase()))) &&
    (selectedCategory === 'All' || p.category === selectedCategory)
  )

  // Sort products
  filteredProducts = filteredProducts.sort((a, b) => {
    if (sortBy === 'price-low') return a.price - b.price
    if (sortBy === 'price-high') return b.price - a.price
    if (sortBy === 'name') return a.name.localeCompare(b.name)
    return 0
  })

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-4 border-primary mx-auto mb-4"></div>
          <p className="text-xl text-gray-600">Loading amazing hotels...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-5xl font-bold text-gray-900 mb-2">Hotel Search</h1>
          <p className="text-gray-600 text-lg">Discover amazing hotels for your next adventure</p>
        </div>
        
        {error && (
          <div className="bg-yellow-50 border-l-4 border-yellow-400 p-4 mb-6 rounded-r-lg">
            <div className="flex">
              <div className="flex-shrink-0">
                <span className="text-2xl">⚠️</span>
              </div>
              <div className="ml-3">
                <p className="text-yellow-700 font-medium">{error}</p>
              </div>
            </div>
          </div>
        )}

        {/* Search and Filters */}
        <div className="bg-white rounded-xl shadow-md p-6 mb-8">
          <div className="grid md:grid-cols-3 gap-4">
            {/* Search */}
            <div className="md:col-span-2 relative">
              <input
                type="text"
                placeholder="Search hotels by destination, name, or description..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full px-4 py-3 pl-12 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent transition"
              />
              <svg className="absolute left-4 top-3.5 w-6 h-6 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>

            {/* Sort */}
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              className="px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent transition"
            >
              <option value="name">Sort by Name</option>
              <option value="price-low">Price: Low to High</option>
              <option value="price-high">Price: High to Low</option>
            </select>
          </div>

          {/* Category Filter */}
          <div className="mt-4 flex flex-wrap gap-2">
            {categories.map(category => (
              <button
                key={category}
                onClick={() => setSelectedCategory(category)}
                className={`px-4 py-2 rounded-full font-medium transition-all duration-200 ${
                  selectedCategory === category
                    ? 'bg-primary text-white shadow-lg transform scale-105'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {category}
              </button>
            ))}
          </div>
        </div>

        {/* Results Count */}
        <div className="mb-6 flex justify-between items-center">
          <p className="text-gray-600">
            Showing <span className="font-semibold text-gray-900">{filteredProducts.length}</span> hotels
          </p>
        </div>

      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredProducts.map(product => (
          <div key={product.id || product.productId} className="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1">
            <div className="h-64 bg-gradient-to-br from-gray-50 to-gray-100 flex items-center justify-center overflow-hidden">
              {product.imageUrl ? (
                <img 
                  src={product.imageUrl} 
                  alt={product.name}
                  className="w-full h-full object-cover"
                  onError={(e) => {
                    e.target.style.display = 'none'
                    e.target.nextSibling.style.display = 'flex'
                  }}
                />
              ) : null}
              <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-blue-50 to-purple-50" style={{display: product.imageUrl ? 'none' : 'flex'}}>
                <span className="text-7xl">🏨</span>
              </div>
            </div>
            <div className="p-6">
              <div className="flex justify-between items-start mb-2">
                <h3 className="text-xl font-semibold text-gray-900 line-clamp-2">{product.name}</h3>
                <span className="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded-full whitespace-nowrap ml-2">
                  {product.category}
                </span>
              </div>
              {product.description && (
                <p className="text-sm text-gray-600 mb-3 line-clamp-2">{product.description}</p>
              )}
              <div className="flex justify-between items-center mb-4">
                <p className="text-3xl font-bold text-primary">${product.price}<span className="text-sm text-gray-600">/night</span></p>
                <span className={`text-sm px-3 py-1 rounded-full ${
                  product.stock > 10 ? 'bg-green-100 text-green-800' : 
                  product.stock > 0 ? 'bg-yellow-100 text-yellow-800' : 
                  'bg-red-100 text-red-800'
                }`}>
                  {product.stock > 0 ? `${product.stock} rooms` : 'Fully booked'}
                </span>
              </div>
              <button
                onClick={() => addToCart(product)}
                disabled={product.stock === 0}
                className={`w-full py-3 rounded-lg font-semibold transition-all duration-200 ${
                  product.stock > 0
                    ? 'bg-primary text-white hover:bg-orange-600 hover:shadow-lg transform hover:scale-105'
                    : 'bg-gray-300 text-gray-500 cursor-not-allowed'
                }`}
              >
                {product.stock > 0 ? '🏨 Book Now' : 'Fully Booked'}
              </button>
            </div>
          </div>
        ))}
      </div>

      {filteredProducts.length === 0 && (
        <div className="text-center py-20 bg-white rounded-xl shadow-md">
          <div className="text-6xl mb-4">🔍</div>
          <p className="text-gray-600 text-xl mb-2">No hotels found</p>
          <p className="text-gray-500">Try adjusting your search or filters</p>
          <button
            onClick={() => {
              setSearchTerm('')
              setSelectedCategory('All')
            }}
            className="mt-6 bg-primary text-white px-6 py-3 rounded-lg hover:bg-orange-600 transition"
          >
            Clear Filters
          </button>
        </div>
      )}

      {/* Booking Modal */}
      {bookingModal.show && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-2xl max-w-md w-full p-6">
            <div className="flex justify-between items-start mb-4">
              <div>
                <h2 className="text-2xl font-bold text-gray-900">Book Hotel</h2>
                <p className="text-gray-600">{bookingModal.hotel?.name}</p>
              </div>
              <button
                onClick={() => setBookingModal({ show: false, hotel: null })}
                className="text-gray-400 hover:text-gray-600"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Check-in Date</label>
                <input
                  type="date"
                  value={bookingForm.checkIn}
                  onChange={(e) => setBookingForm({...bookingForm, checkIn: e.target.value})}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary"
                  min={new Date().toISOString().split('T')[0]}
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Check-out Date</label>
                <input
                  type="date"
                  value={bookingForm.checkOut}
                  onChange={(e) => setBookingForm({...bookingForm, checkOut: e.target.value})}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary"
                  min={bookingForm.checkIn}
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Number of Guests</label>
                <input
                  type="number"
                  value={bookingForm.guests}
                  onChange={(e) => setBookingForm({...bookingForm, guests: parseInt(e.target.value)})}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary"
                  min="1"
                  max="10"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Guest Name</label>
                <input
                  type="text"
                  value={bookingForm.guestName}
                  onChange={(e) => setBookingForm({...bookingForm, guestName: e.target.value})}
                  placeholder="John Doe"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Guest Email</label>
                <input
                  type="email"
                  value={bookingForm.guestEmail}
                  onChange={(e) => setBookingForm({...bookingForm, guestEmail: e.target.value})}
                  placeholder="john@example.com"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary"
                />
              </div>

              <div className="bg-gray-50 p-4 rounded-lg">
                <div className="flex justify-between text-sm mb-2">
                  <span className="text-gray-600">Price per night:</span>
                  <span className="font-semibold">${bookingModal.hotel?.price}</span>
                </div>
                <div className="flex justify-between text-lg font-bold text-primary">
                  <span>Total:</span>
                  <span>${bookingModal.hotel?.price * Math.max(1, Math.ceil((new Date(bookingForm.checkOut) - new Date(bookingForm.checkIn)) / (1000 * 60 * 60 * 24)))}</span>
                </div>
              </div>

              <button
                onClick={handleBooking}
                disabled={bookingInProgress}
                className="w-full bg-primary text-white py-3 rounded-lg font-semibold hover:bg-orange-600 transition disabled:bg-gray-400 disabled:cursor-not-allowed"
              >
                {bookingInProgress ? 'Processing...' : 'Confirm Booking'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
    </div>
  )
}
