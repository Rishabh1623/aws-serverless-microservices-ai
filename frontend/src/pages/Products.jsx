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
      // Generic demo product catalog (no copyright issues)
      setProducts([
        // Laptops
        { id: 'prod1', name: 'UltraBook Pro 13', price: 999, category: 'Laptops', stock: 15, description: 'Ultra-portable laptop with stunning 13.4" display, Intel Core i7, 16GB RAM' },
        { id: 'prod2', name: 'ProBook Elite 14', price: 1999, category: 'Laptops', stock: 8, description: 'Professional laptop with advanced chip, 18GB RAM, 512GB SSD' },
        { id: 'prod3', name: 'FlexBook 360', price: 1299, category: 'Laptops', stock: 12, description: '2-in-1 convertible laptop with 13.5" OLED touchscreen' },
        { id: 'prod4', name: 'BusinessBook X1', price: 1499, category: 'Laptops', stock: 10, description: 'Business laptop with premium keyboard, Intel Core i7, 16GB RAM' },
        { id: 'prod5', name: 'GameBook Ultra', price: 1799, category: 'Laptops', stock: 6, description: 'Gaming laptop with RTX graphics, AMD Ryzen 9, 165Hz display' },
        { id: 'prod6', name: 'SlimBook Air', price: 1099, category: 'Laptops', stock: 14, description: 'Elegant laptop with 13.5" touchscreen, Intel Core i5' },
        
        // Smartphones
        { id: 'prod7', name: 'SmartPhone Pro Max', price: 1099, category: 'Smartphones', stock: 25, description: 'Premium smartphone with titanium design, advanced chip, 48MP camera' },
        { id: 'prod8', name: 'Galaxy Pro Ultra', price: 1299, category: 'Smartphones', stock: 20, description: 'Flagship phone with stylus, 200MP camera, AI features' },
        { id: 'prod9', name: 'PixelPhone Pro', price: 999, category: 'Smartphones', stock: 18, description: 'Pure Android experience with best-in-class AI photography' },
        { id: 'prod10', name: 'SpeedPhone 12', price: 799, category: 'Smartphones', stock: 22, description: 'Flagship phone with latest processor, 120Hz AMOLED display' },
        { id: 'prod11', name: 'SmartPhone Standard', price: 799, category: 'Smartphones', stock: 30, description: 'Standard flagship with dynamic display, advanced chip' },
        { id: 'prod12', name: 'FoldPhone Pro', price: 1799, category: 'Smartphones', stock: 8, description: 'Foldable phone with 7.6" main display, multitasking powerhouse' },
        
        // Tablets
        { id: 'prod13', name: 'TabletPro 12.9"', price: 1299, category: 'Tablets', stock: 12, description: 'Powerful tablet with advanced chip, Retina XDR display' },
        { id: 'prod14', name: 'TabletAir 10.9"', price: 599, category: 'Tablets', stock: 20, description: 'Versatile tablet with M1 chip, 10.9" display, stylus support' },
        { id: 'prod15', name: 'AndroidTab S9', price: 799, category: 'Tablets', stock: 15, description: 'Android tablet with stylus, 11" AMOLED display, desktop mode' },
        { id: 'prod16', name: 'ProTab 2-in-1', price: 999, category: 'Tablets', stock: 10, description: '2-in-1 tablet with Intel Core i5, Windows 11, keyboard compatible' },
        
        // Audio
        { id: 'prod17', name: 'NoiseCancel Pro XM5', price: 399, category: 'Audio', stock: 30, description: 'Industry-leading noise cancellation, 30-hour battery, premium sound' },
        { id: 'prod18', name: 'EarBuds Pro 2', price: 249, category: 'Audio', stock: 40, description: 'Active noise cancellation, spatial audio, USB-C charging' },
        { id: 'prod19', name: 'QuietSound Ultra', price: 429, category: 'Audio', stock: 25, description: 'Premium headphones with immersive audio, world-class ANC' },
        { id: 'prod20', name: 'StudioSound Pro', price: 349, category: 'Audio', stock: 28, description: 'Wireless headphones with lossless audio, 40-hour battery' },
        { id: 'prod21', name: 'TrueWireless Buds Pro', price: 229, category: 'Audio', stock: 35, description: 'True wireless earbuds with intelligent ANC, 360 audio' },
        { id: 'prod22', name: 'PowerSound Speaker', price: 179, category: 'Audio', stock: 45, description: 'Portable Bluetooth speaker, IP67 waterproof, 20-hour playtime' },
        
        // Smartwatches
        { id: 'prod23', name: 'SmartWatch Pro 9', price: 429, category: 'Smartwatches', stock: 22, description: 'Advanced health tracking, always-on display, latest chip' },
        { id: 'prod24', name: 'FitWatch Pro 6', price: 299, category: 'Smartwatches', stock: 18, description: 'Wear OS smartwatch with advanced sleep tracking, AMOLED display' },
        { id: 'prod25', name: 'SportWatch Elite', price: 699, category: 'Smartwatches', stock: 10, description: 'Premium multisport GPS watch with solar charging, rugged design' },
        { id: 'prod26', name: 'HealthWatch Pro', price: 249, category: 'Smartwatches', stock: 25, description: 'Health-focused smartwatch with stress management, ECG, SpO2' },
        
        // Cameras
        { id: 'prod27', name: 'MirrorCam Pro A7', price: 2499, category: 'Cameras', stock: 8, description: 'Full-frame mirrorless camera, 33MP, 4K 60fps video' },
        { id: 'prod28', name: 'ProCam R6 Mark II', price: 2399, category: 'Cameras', stock: 6, description: 'Professional mirrorless with 24MP, 40fps burst, 6K video' },
        { id: 'prod29', name: 'ClassicCam X-T5', price: 1699, category: 'Cameras', stock: 10, description: 'APS-C mirrorless with 40MP, classic design, film simulations' },
        { id: 'prod30', name: 'ActionCam Hero', price: 399, category: 'Cameras', stock: 20, description: 'Action camera with 5.3K video, advanced stabilization, waterproof' },
        
        // Gaming
        { id: 'prod31', name: 'GameStation 5', price: 499, category: 'Gaming', stock: 15, description: 'Next-gen console with 4K gaming, ultra-fast SSD, haptic controller' },
        { id: 'prod32', name: 'GameBox Series X', price: 499, category: 'Gaming', stock: 12, description: 'Powerful console with 4K 120fps, game subscription, quick resume' },
        { id: 'prod33', name: 'HybridPlay OLED', price: 349, category: 'Gaming', stock: 25, description: 'Hybrid console with 7" OLED screen, enhanced audio, 64GB storage' },
        { id: 'prod34', name: 'PortablePlay Deck', price: 649, category: 'Gaming', stock: 10, description: 'Handheld gaming PC with 512GB SSD, runs full PC games' },
        { id: 'prod35', name: 'VR Headset Pro 3', price: 499, category: 'Gaming', stock: 14, description: 'VR headset with mixed reality, 4K+ display, wireless freedom' },
        
        // Accessories
        { id: 'prod36', name: 'ProMouse Wireless', price: 99, category: 'Accessories', stock: 40, description: 'Premium wireless mouse with 8K DPI, quiet clicks, ergonomic design' },
        { id: 'prod37', name: 'MechKeyboard Pro', price: 109, category: 'Accessories', stock: 35, description: 'Wireless mechanical keyboard with hot-swappable switches, RGB' },
        { id: 'prod38', name: 'PowerBank 20K', price: 49, category: 'Accessories', stock: 60, description: 'Portable charger with 20,000mAh capacity, 22.5W fast charging' },
        { id: 'prod39', name: 'FastDrive SSD 2TB', price: 199, category: 'Accessories', stock: 30, description: 'Rugged portable SSD, IP65 rated, 1050MB/s read speed' },
        { id: 'prod40', name: 'StreamControl Deck', price: 149, category: 'Accessories', stock: 18, description: 'Content creation controller with 15 LCD keys, customizable actions' },
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
                  {product.category === 'Laptops' ? '💻' : 
                   product.category === 'Smartphones' ? '📱' : 
                   product.category === 'Tablets' ? '📱' : 
                   product.category === 'Audio' ? '🎧' : 
                   product.category === 'Smartwatches' ? '⌚' : 
                   product.category === 'Cameras' ? '📷' : 
                   product.category === 'Gaming' ? '🎮' : 
                   product.category === 'Accessories' ? '⌨️' : '📦'}
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
