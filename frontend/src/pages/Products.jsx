import { useState, useEffect } from 'react'
import axios from 'axios'
import { API_CONFIG, DEMO_USER_ID } from '../config'

export default function Products() {
  const [products, setProducts] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [searchTerm, setSearchTerm] = useState('')

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
        { id: 'prod1', name: 'Dell XPS 13', price: 999, category: 'Laptops', stock: 15 },
        { id: 'prod2', name: 'MacBook Pro 14"', price: 1999, category: 'Laptops', stock: 8 },
        { id: 'prod3', name: 'iPhone 15 Pro', price: 1099, category: 'Phones', stock: 25 },
        { id: 'prod4', name: 'Samsung Galaxy S24', price: 899, category: 'Phones', stock: 20 },
        { id: 'prod5', name: 'Sony WH-1000XM5', price: 399, category: 'Audio', stock: 30 },
        { id: 'prod6', name: 'iPad Pro 12.9"', price: 1299, category: 'Tablets', stock: 12 },
      ])
    } finally {
      setLoading(false)
    }
  }

  const addToCart = async (product) => {
    try {
      await axios.post(`${API_CONFIG.CART_API}/cart/add`, {
        userId: DEMO_USER_ID,
        productId: product.id,
        quantity: 1
      })
      alert(`Added ${product.name} to cart!`)
    } catch (err) {
      alert('Added to cart (demo mode)')
    }
  }

  const filteredProducts = products.filter(p =>
    p.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    p.category.toLowerCase().includes(searchTerm.toLowerCase())
  )

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-12 text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
        <p className="mt-4 text-gray-600">Loading products...</p>
      </div>
    )
  }

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <div className="mb-8">
        <h1 className="text-4xl font-bold text-gray-900 mb-4">Product Catalog</h1>
        
        {error && (
          <div className="bg-yellow-50 border-l-4 border-yellow-400 p-4 mb-4">
            <p className="text-yellow-700">{error}</p>
          </div>
        )}

        <div className="relative">
          <input
            type="text"
            placeholder="Search products..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
          />
          <svg className="absolute right-3 top-3 w-6 h-6 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </div>
      </div>

      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredProducts.map(product => (
          <div key={product.id} className="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-xl transition">
            <div className="h-48 bg-gradient-to-br from-gray-100 to-gray-200 flex items-center justify-center">
              <span className="text-6xl">📦</span>
            </div>
            <div className="p-6">
              <div className="flex justify-between items-start mb-2">
                <h3 className="text-xl font-semibold text-gray-900">{product.name}</h3>
                <span className="text-sm bg-gray-100 text-gray-600 px-2 py-1 rounded">{product.category}</span>
              </div>
              <p className="text-2xl font-bold text-primary mb-4">${product.price}</p>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">Stock: {product.stock}</span>
                <button
                  onClick={() => addToCart(product)}
                  className="bg-primary text-white px-4 py-2 rounded-lg hover:bg-orange-600 transition"
                >
                  Add to Cart
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {filteredProducts.length === 0 && (
        <div className="text-center py-12">
          <p className="text-gray-600 text-lg">No products found matching "{searchTerm}"</p>
        </div>
      )}
    </div>
  )
}
