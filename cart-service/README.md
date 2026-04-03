# Cart Service

Manages user shopping cart with temporary holds and price calculations.

## Features

- ✅ Add items to cart with 15-minute TTL
- ✅ View cart with total price
- ✅ Remove items from cart
- ✅ Apply promo codes
- ✅ Automatic cleanup (DynamoDB TTL)
- ✅ X-Ray tracing
- ✅ CloudWatch metrics

## API Endpoints

### Add to Cart
```bash
POST /cart/add
{
  "userId": "user123",
  "hotelId": "hotel-001",
  "roomId": "room-001",
  "checkIn": "2024-06-15",
  "checkOut": "2024-06-20",
  "guests": 2
}
```

### Get Cart
```bash
GET /cart/{userId}
```

### Remove from Cart
```bash
DELETE /cart/{userId}/{cartItemId}
```

### Apply Promo Code
```bash
POST /cart/{userId}/promo
{
  "promoCode": "SUMMER20"
}
```

## DynamoDB Table

```
Table: cart-items
├── PK: cartItemId (String)
├── GSI: userId-index
├── TTL: ttl (15 minutes)
└── Attributes:
    ├── userId
    ├── hotelId
    ├── roomId
    ├── checkIn
    ├── checkOut
    ├── totalPrice
    └── status
```

## Testing

```bash
pytest tests/ -v
```

## Deployment

```bash
cd terraform/cart-service/dev
terraform init
terraform apply
```
