// API Configuration
// Update these URLs after deploying to AWS
export const API_CONFIG = {
  HOTEL_API: import.meta.env.VITE_HOTEL_API || 'http://localhost:3001',
  CART_API: import.meta.env.VITE_CART_API || 'http://localhost:3002',
  ORDER_API: import.meta.env.VITE_ORDER_API || 'http://localhost:3003',
  PAYMENT_API: import.meta.env.VITE_PAYMENT_API || 'http://localhost:3004',
  AGENT_API: import.meta.env.VITE_AGENT_API || 'http://localhost:3005',
}

// User ID for demo (in production, use authentication)
export const DEMO_USER_ID = 'demo-user-123'
