// API Configuration
export const API_CONFIG = {
  // Base service endpoints
  HOTEL_API: import.meta.env.VITE_HOTEL_API || 'https://zttuy6f8bj.execute-api.us-east-1.amazonaws.com/dev',
  CART_API: import.meta.env.VITE_CART_API || 'http://localhost:3002',
  ORDER_API: import.meta.env.VITE_ORDER_API || 'https://vy2wiorpxl.execute-api.us-east-1.amazonaws.com/dev',
  PAYMENT_API: import.meta.env.VITE_PAYMENT_API || 'https://gupn3gch28.execute-api.us-east-1.amazonaws.com/dev',
  AGENT_API: import.meta.env.VITE_AGENT_API || 'https://bj623ttpd4.execute-api.us-east-1.amazonaws.com',
  
  // Workflow endpoints (Step Functions via API Gateway)
  WORKFLOWS: {
    HOTEL_BOOKING: 'https://w2t61gs2lj.execute-api.us-east-1.amazonaws.com/dev/workflows/hotel-booking',
    ORDER_PROCESSING: 'https://w2t61gs2lj.execute-api.us-east-1.amazonaws.com/dev/workflows/order-processing',
    PAYMENT_PROCESSING: 'https://w2t61gs2lj.execute-api.us-east-1.amazonaws.com/dev/workflows/payment-processing',
  }
}

// User ID for demo (in production, use authentication)
export const DEMO_USER_ID = 'demo-user-123'
