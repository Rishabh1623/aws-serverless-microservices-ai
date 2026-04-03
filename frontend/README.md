# Frontend - AWS Serverless Travel Platform

Modern React frontend for the serverless travel booking platform.

## Features

- 🏨 **Hotel Search** - Browse and search hotels
- 🧳 **Trip Planning** - Add/remove hotels from your trip
- 🤖 **AI Travel Assistant** - Natural language hotel booking with AWS Bedrock
- 📋 **Booking History** - View past bookings
- 📊 **Admin Dashboard** - DevOps troubleshooting with MCP

## Tech Stack

- **React 18** - UI framework
- **Vite** - Build tool (fast!)
- **Tailwind CSS** - Styling
- **React Router** - Navigation
- **Axios** - HTTP client

## Quick Start

### 1. Install Dependencies

```bash
cd frontend
npm install
```

### 2. Configure API Endpoints

Copy `.env.example` to `.env` and update with your AWS API Gateway URLs:

```bash
cp .env.example .env
```

Edit `.env`:
```
VITE_HOTEL_API=https://your-hotel-api.execute-api.us-east-1.amazonaws.com
VITE_AGENT_API=https://your-agent-api.execute-api.us-east-1.amazonaws.com
```

### 3. Run Development Server

```bash
npm run dev
```

Open http://localhost:5173

## Demo Mode

The frontend works in **demo mode** without backend APIs. It shows sample data so you can:
- Test the UI
- Record demos
- Show the interface

Once you deploy the backend to AWS, update the `.env` file with real API URLs.

## Build for Production

```bash
npm run build
```

Output in `dist/` folder.

## Deploy to AWS

### Option 1: S3 + CloudFront (Recommended)

```bash
# Build
npm run build

# Deploy to S3
aws s3 sync dist/ s3://your-bucket-name --delete

# Create CloudFront distribution (one-time)
aws cloudfront create-distribution \
  --origin-domain-name your-bucket-name.s3.amazonaws.com \
  --default-root-object index.html
```

### Option 2: AWS Amplify

```bash
# Install Amplify CLI
npm install -g @aws-amplify/cli

# Initialize
amplify init

# Add hosting
amplify add hosting

# Deploy
amplify publish
```

## Project Structure

```
frontend/
├── src/
│   ├── components/
│   │   └── Navbar.jsx
│   ├── pages/
│   │   ├── Home.jsx
│   │   ├── Products.jsx
│   │   ├── Cart.jsx
│   │   ├── AIAssistant.jsx
│   │   ├── AdminDashboard.jsx
│   │   └── Orders.jsx
│   ├── config.js          # API configuration
│   ├── App.jsx
│   ├── main.jsx
│   └── index.css
├── index.html
├── package.json
├── vite.config.js
└── tailwind.config.js
```

## Pages

### 1. Home (`/`)
- Architecture overview
- Feature highlights
- Tech stack showcase

### 2. Hotels (`/products`)
- Hotel catalog with search
- Add to trip functionality
- Real-time availability

### 3. Trip Planner (`/cart`)
- View trip items
- Remove hotels
- Complete booking

### 4. AI Assistant (`/ai-assistant`)
- Chat interface
- Natural language hotel booking
- Tool usage display

### 5. Bookings (`/orders`)
- Booking history
- Booking status tracking
- Confirmation details

### 6. Admin Dashboard (`/admin`)
- Troubleshooting interface
- MCP tools showcase
- System health checks

## Customization

### Colors

Edit `tailwind.config.js`:

```js
theme: {
  extend: {
    colors: {
      primary: '#FF9900',    // AWS Orange
      secondary: '#232F3E',  // AWS Dark Blue
    }
  }
}
```

### API Endpoints

Edit `src/config.js`:

```js
export const API_CONFIG = {
  HOTEL_API: 'your-url',
  AGENT_API: 'your-url',
}
```

## Demo Recording Tips

1. **Start with Home page** - Shows architecture
2. **Browse Hotels** - Show catalog and search
3. **Use AI Assistant** - Demonstrate natural language
4. **Check Trip Planner** - Show trip management
5. **Admin Dashboard** - Show troubleshooting
6. **Bookings** - Show booking history

## Troubleshooting

### Port already in use
```bash
# Kill process on port 5173
npx kill-port 5173

# Or use different port
npm run dev -- --port 3000
```

### CORS errors
Make sure your API Gateway has CORS enabled:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
```

### Build errors
```bash
# Clear cache
rm -rf node_modules dist
npm install
npm run build
```

## Cost

**Hosting Cost:**
- S3: ~$0.50/month (1GB storage)
- CloudFront: ~$1/month (10GB transfer)
- **Total: ~$1.50/month**

## License

MIT License - See LICENSE file
