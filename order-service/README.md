# Order Service

Manages order lifecycle from creation to completion/cancellation.

## Features

- ✅ Create order from cart
- ✅ Get order details
- ✅ List user orders
- ✅ Cancel order with refund
- ✅ Order state management
- ✅ Event-driven notifications
- ✅ X-Ray tracing
- ✅ CloudWatch metrics

## Order States

```
pending_payment → confirmed → completed
                     ↓
                 cancelled
```

## API Endpoints

### Create Order
```bash
POST /orders
{
  "userId": "user123",
  "guestDetails": {
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890"
  },
  "promoCode": "SUMMER20"
}
```

### Get Order
```bash
GET /orders/{orderId}
```

### List User Orders
```bash
GET /orders/user/{userId}?status=confirmed&limit=10
```

### Cancel Order
```bash
PATCH /orders/{orderId}/cancel
{
  "reason": "Changed plans"
}
```

## Events Published

- `Order Created` - When order is created
- `Order Cancelled` - When order is cancelled
- `Order Completed` - When booking is completed

## Testing

```bash
pytest tests/ -v
```

## Deployment

```bash
cd terraform/order-service/dev
terraform init
terraform apply
```
