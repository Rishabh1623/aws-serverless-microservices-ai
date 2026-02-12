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
              <span className="text-2xl font-bold text-primary">AWS</span>
              <span className="text-xl ml-2">Serverless Shop</span>
            </Link>
            
            <div className="hidden md:flex space-x-4">
              <Link to="/products" className="hover:text-primary transition px-3 py-2 rounded-md">
                Products
              </Link>
              <Link to="/ai-assistant" className="hover:text-primary transition px-3 py-2 rounded-md">
                🤖 AI Assistant
              </Link>
              <Link to="/orders" className="hover:text-primary transition px-3 py-2 rounded-md">
                Orders
              </Link>
            </div>
          </div>

          <div className="flex items-center space-x-4">
            <Link to="/cart" className="relative hover:text-primary transition">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
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
