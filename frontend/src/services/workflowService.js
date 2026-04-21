import { API_CONFIG } from '../config'

/**
 * Workflow Service - Handles Step Functions workflow executions
 */

/**
 * Trigger hotel booking workflow
 */
export const triggerHotelBooking = async (bookingData) => {
  try {
    const response = await fetch(API_CONFIG.WORKFLOWS.HOTEL_BOOKING, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(bookingData)
    })

    if (!response.ok) {
      throw new Error(`Workflow failed: ${response.statusText}`)
    }

    return await response.json()
  } catch (error) {
    console.error('Hotel booking workflow error:', error)
    throw error
  }
}

/**
 * Trigger order processing workflow
 */
export const triggerOrderProcessing = async (orderData) => {
  try {
    const response = await fetch(API_CONFIG.WORKFLOWS.ORDER_PROCESSING, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(orderData)
    })

    if (!response.ok) {
      throw new Error(`Workflow failed: ${response.statusText}`)
    }

    return await response.json()
  } catch (error) {
    console.error('Order processing workflow error:', error)
    throw error
  }
}

/**
 * Trigger payment processing workflow
 */
export const triggerPaymentProcessing = async (paymentData) => {
  try {
    const response = await fetch(API_CONFIG.WORKFLOWS.PAYMENT_PROCESSING, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(paymentData)
    })

    if (!response.ok) {
      throw new Error(`Workflow failed: ${response.statusText}`)
    }

    return await response.json()
  } catch (error) {
    console.error('Payment processing workflow error:', error)
    throw error
  }
}
