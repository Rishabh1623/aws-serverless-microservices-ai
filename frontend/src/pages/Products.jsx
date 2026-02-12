import { useState, useEffect } from 'react'
import axios from 'axios'
import { API_CONFIG, DEMO_USER_ID } from '../config'

export default function Products() {
  const [products, setProducts] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedCategory, setSelectedCategory] = useState('All')
  const [sortBy, setSortBy] = useState('name')

  useEffect(() => {
    fetchProducts()
  }, [])

  const fetchProducts = async () => {
    try {
      setLoading(true)
      const response = await axios.get(`${API_CONFIG.PRODUCT_API}/products`)
      setProducts(response.data.products || [])
      setError(null)
    } catch (err) {
      setError('Failed to load products. Using demo data.')
      // Demo data for testing without backend
      setProducts([
        { id: 'prod1', name: 'Dell XPS 13', price: 999, category: 'Laptops', stock: 15, description: 'Ultra-portable laptop with stunning display' },
        { id: 'prod2', name: 'MacBook Pro 14"', price: 1999, category: 'Laptops', stock: 8, description: 'Professional laptop with M3 Pro chip' },
        { id: 'prod3', name: 'iPhone 15 Pro', price: 1099, category: 'Phones', stock: 25, description: 'Latest iPhone with titanium design' },
        { id: 'prod4', name: 'Samsung Galaxy S24', price: 899, category: 'Phones', stock: 20, description: 'Flagship Android phone with AI features' },
        { id: 'prod5', name: 'Sony WH-1000XM5', price: 399, category: 'Audio', stock: 30, description: 'Industry-leading noise cancellation' },
        { id: 'prod6', name: 'iPad Pro 12.9"', price: 1299, category: 'Tablets', stock: 12, description: 'Powerful tablet with M2 chip' },
      ])
    } finally {
      setLoading(false)
    }
  }

  const addToCart = async (product) => {
    try {
      await axios.post(`${API_CONFIG.CART_API}/cart/add`, {
        userId: DEMO_USER_ID,
        productId: product.id || product.productId,
        quantity: 1,
        price: product.price,
        name: product.name
      })
      alert(`✅ ${product.name} added to cart!`)
    } catch (err) {
      alert('✅ Added to cart (demo mode)')
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
          <p className="text-xl text-gray-600">Loading amazing products...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-5xl font-bold text-gray-900 mb-2">Product Catalog</h1>
          <p className="text-gray-600 text-lg">Discover our curated selection of premium electronics</p>
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
                placeholder="Search products by name, category, or description..."
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
            Showing <span className="font-semibold text-gray-900">{filteredProducts.length}</span> products
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
                <span className="text-7xl">
                  {product.category === 'Electronics' || product.category === 'Laptops' ? '💻' : 
                   product.category === 'Phones' ? '📱' : 
                   product.category === 'Audio' ? '🎧' : 
                   product.category === 'Tablets' ? '📱' : '📦'}
                </span>
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
                <p className="text-3xl font-bold text-primary">${product.price}</p>
                <span className={`text-sm px-3 py-1 rounded-full ${
                  product.stock > 20 ? 'bg-green-100 text-green-800' : 
                  product.stock > 0 ? 'bg-yellow-100 text-yellow-800' : 
                  'bg-red-100 text-red-800'
                }`}>
                  {product.stock > 0 ? `${product.stock} in stock` : 'Out of stock'}
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
                {product.stock > 0 ? '🛒 Add to Cart' : 'Out of Stock'}
              </button>
            </div>
          </div>
        ))}
      </div>

      {filteredProducts.length === 0 && (
        <div className="text-center py-20 bg-white rounded-xl shadow-md">
          <div className="text-6xl mb-4">🔍</div>
          <p className="text-gray-600 text-xl mb-2">No products found</p>
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
    </div>
    </div>
  )
}
