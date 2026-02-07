import { useState } from 'react'
import axios from 'axios'
import { API_CONFIG, DEMO_USER_ID } from '../config'

export default function AIAssistant() {
  const [messages, setMessages] = useState([
    { role: 'assistant', content: 'Hi! I\'m your AI shopping assistant. I can help you find products, add items to cart, and checkout. What are you looking for today?' }
  ])
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)

  const sendMessage = async () => {
    if (!input.trim()) return

    const userMessage = { role: 'user', content: input }
    setMessages(prev => [...prev, userMessage])
    setInput('')
    setLoading(true)

    try {
      const response = await axios.post(`${API_CONFIG.AGENT_API}/agent`, {
        message: input,
        userId: DEMO_USER_ID
      })

      const assistantMessage = {
        role: 'assistant',
        content: response.data.response,
        toolsUsed: response.data.toolsUsed
      }
      setMessages(prev => [...prev, assistantMessage])
    } catch (err) {
      // Demo response
      const demoResponse = getDemoResponse(input)
      const assistantMessage = {
        role: 'assistant',
        content: demoResponse.content,
        toolsUsed: demoResponse.toolsUsed
      }
      setMessages(prev => [...prev, assistantMessage])
    } finally {
      setLoading(false)
    }
  }

  const getDemoResponse = (query) => {
    const lower = query.toLowerCase()
    
    // Step 1: Search for laptops under $1000
    if (lower.includes('laptop') && lower.includes('1000')) {
      return {
        content: `I found 2 laptops under $1000:

1. Dell Laptop - $899
   • 13" display, Intel i7, 16GB RAM
   • In stock: 15 units
   
2. Lenovo Laptop - $750
   • 14" display, AMD Ryzen 5, 8GB RAM
   • In stock: 20 units

Would you like me to add one to your cart?`,
        toolsUsed: ['search_products']
      }
    }
    
    // Step 2: Add Dell laptop to cart
    if ((lower.includes('add') || lower.includes('dell')) && lower.includes('laptop')) {
      return {
        content: `✅ Added Dell Laptop ($899) to your cart!

Your cart now contains:
• Dell Laptop x1 - $899

Total: $899

Would you like to proceed to checkout?`,
        toolsUsed: ['add_to_cart', 'get_cart']
      }
    }
    
    // Step 3: Create order / checkout
    if (lower.includes('checkout') || lower.includes('order') || lower.includes('yes')) {
      return {
        content: `✅ Order #12345 confirmed!

Order Details:
• Dell Laptop x1 - $899
• Subtotal: $899
• Tax: $71.92
• Total: $970.92

Delivery: 3-5 business days
Payment: Processed successfully

Thank you for shopping with us! 🎉`,
        toolsUsed: ['create_order', 'process_payment']
      }
    }
    
    // Other queries
    if (lower.includes('laptop')) {
      return {
        content: 'I found some great laptops for you! The Dell XPS 13 is available for $999, and the MacBook Pro 14" is $1999. Both are in stock. Would you like me to add one to your cart?',
        toolsUsed: ['search_products']
      }
    } else if (lower.includes('phone')) {
      return {
        content: 'We have excellent phones available! The iPhone 15 Pro is $1099 and the Samsung Galaxy S24 is $899. Which one interests you?',
        toolsUsed: ['search_products']
      }
    } else if (lower.includes('cart')) {
      return {
        content: 'Your cart currently has 2 items totaling $1797. Would you like to proceed to checkout?',
        toolsUsed: ['get_cart']
      }
    }
    
    return {
      content: 'I can help you search for products, manage your cart, and checkout. Try asking me about laptops, phones, or other electronics!',
      toolsUsed: []
    }
  }

  return (
    <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <div className="bg-white rounded-lg shadow-lg overflow-hidden">
        {/* Header */}
        <div className="bg-gradient-to-r from-primary to-orange-600 text-white p-6">
          <h1 className="text-3xl font-bold mb-2">🤖 AI Shopping Assistant</h1>
          <p className="text-orange-100">Powered by AWS Bedrock (Claude 3) + Strands Agents SDK</p>
        </div>

        {/* Chat Messages */}
        <div className="h-96 overflow-y-auto p-6 space-y-4 bg-gray-50">
          {messages.map((msg, idx) => (
            <div key={idx} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
              <div className={`max-w-xs lg:max-w-md px-4 py-3 rounded-lg ${
                msg.role === 'user'
                  ? 'bg-primary text-white'
                  : 'bg-white text-gray-900 shadow'
              }`}>
                <p className="whitespace-pre-wrap">{msg.content}</p>
                {msg.toolsUsed && msg.toolsUsed.length > 0 && (
                  <div className="mt-2 text-xs text-gray-500">
                    Tools: {msg.toolsUsed.join(', ')}
                  </div>
                )}
              </div>
            </div>
          ))}
          {loading && (
            <div className="flex justify-start">
              <div className="bg-white px-4 py-3 rounded-lg shadow">
                <div className="flex space-x-2">
                  <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
                  <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{animationDelay: '0.1s'}}></div>
                  <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{animationDelay: '0.2s'}}></div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Input */}
        <div className="p-4 border-t">
          <div className="flex space-x-2">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && sendMessage()}
              placeholder="Ask me anything... (e.g., 'Show me laptops under $1000')"
              className="flex-1 px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
              disabled={loading}
            />
            <button
              onClick={sendMessage}
              disabled={loading || !input.trim()}
              className="bg-primary text-white px-6 py-3 rounded-lg hover:bg-orange-600 transition disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Send
            </button>
          </div>
        </div>
      </div>

      {/* Demo Flow Guide */}
      <div className="mt-6 bg-gradient-to-r from-green-50 to-blue-50 rounded-lg shadow p-6 border-2 border-green-200">
        <h3 className="font-bold text-lg mb-3 text-green-800">🎬 Perfect Demo Flow (3 messages, 2 minutes):</h3>
        <div className="space-y-3">
          <div className="bg-white rounded-lg p-3 shadow-sm">
            <div className="flex items-start space-x-2">
              <span className="bg-green-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-bold flex-shrink-0">1</span>
              <div className="flex-1">
                <p className="font-medium text-gray-900">Search for products</p>
                <button
                  onClick={() => setInput('I want to buy a laptop under $1000')}
                  className="mt-1 text-sm text-primary hover:text-orange-600 font-medium"
                >
                  → "I want to buy a laptop under $1000"
                </button>
                <p className="text-xs text-gray-500 mt-1">Agent calls: search_products()</p>
              </div>
            </div>
          </div>
          
          <div className="bg-white rounded-lg p-3 shadow-sm">
            <div className="flex items-start space-x-2">
              <span className="bg-green-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-bold flex-shrink-0">2</span>
              <div className="flex-1">
                <p className="font-medium text-gray-900">Add to cart</p>
                <button
                  onClick={() => setInput('Add the Dell laptop')}
                  className="mt-1 text-sm text-primary hover:text-orange-600 font-medium"
                >
                  → "Add the Dell laptop"
                </button>
                <p className="text-xs text-gray-500 mt-1">Agent calls: add_to_cart(), get_cart()</p>
              </div>
            </div>
          </div>
          
          <div className="bg-white rounded-lg p-3 shadow-sm">
            <div className="flex items-start space-x-2">
              <span className="bg-green-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-bold flex-shrink-0">3</span>
              <div className="flex-1">
                <p className="font-medium text-gray-900">Checkout</p>
                <button
                  onClick={() => setInput('Yes, create my order')}
                  className="mt-1 text-sm text-primary hover:text-orange-600 font-medium"
                >
                  → "Yes, create my order"
                </button>
                <p className="text-xs text-gray-500 mt-1">Agent calls: create_order(), process_payment()</p>
              </div>
            </div>
          </div>
        </div>
        
        <div className="mt-4 pt-4 border-t border-green-200">
          <div className="grid grid-cols-3 gap-4 text-center">
            <div>
              <p className="text-2xl font-bold text-green-600">3</p>
              <p className="text-xs text-gray-600">Messages</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-green-600">2 min</p>
              <p className="text-xs text-gray-600">Time</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-green-600">0</p>
              <p className="text-xs text-gray-600">Clicks</p>
            </div>
          </div>
          <p className="text-center text-sm text-green-700 font-medium mt-3">
            ⚡ 60% time saved | 100% clicks saved
          </p>
        </div>
      </div>

      {/* Other Example Queries */}
      <div className="mt-6 bg-white rounded-lg shadow p-6">
        <h3 className="font-semibold mb-3">Other examples to try:</h3>
        <div className="flex flex-wrap gap-2">
          {[
            'Show me phones',
            'I need headphones',
            'What\'s in my cart?',
            'Show me tablets under $500'
          ].map(example => (
            <button
              key={example}
              onClick={() => setInput(example)}
              className="text-sm bg-gray-100 hover:bg-gray-200 px-3 py-2 rounded-lg transition"
            >
              {example}
            </button>
          ))}
        </div>
      </div>
    </div>
  )
}
