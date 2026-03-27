import { Link } from 'react-router-dom'
import { useState } from 'react'

export default function Navbar() {
  const [cartCount] = useState(0)

  return (
    <nav className="bg-secondary text-white shadow-lg">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex items-center space-x-8">
            <Link to="/" className="flex items-center">
              <span className="text-2xl font-bold text-primary">✈️ TravelAI</span>
              <span className="text-xl ml-2">Platform</span>
            </Link>
            
            <div className="hidden md:flex space-x-4">
              <Link to="/products" className="hover:text-primary transition px-3 py-2 rounded-md">
                🏨 Hotels
              </Link>
              <Link to="/ai-assistant" className="hover:text-primary transition px-3 py-2 rounded-md">
                🤖 AI Travel Assistant
              </Link>
              <Link to="/orders" className="hover:text-primary transition px-3 py-2 rounded-md">
                📋 Bookings
              </Link>
            </div>
          </div>

          <div className="flex items-center space-x-4">
            <Link to="/cart" className="relative hover:text-primary transition flex items-center">
              <span className="text-2xl">🧳</span>
              {cartCount > 0 && (
                <span className="absolute -top-2 -right-2 bg-primary text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">
                  {cartCount}
                </span>
              )}
            </Link>
          </div>
        </div>
      </div>
    </nav>
  )
}
