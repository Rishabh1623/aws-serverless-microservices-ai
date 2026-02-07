import { Link } from 'react-router-dom'

export default function Home() {
  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      {/* Hero Section */}
      <div className="text-center mb-16">
        <h1 className="text-5xl font-bold text-gray-900 mb-4">
          AWS Serverless Microservices
        </h1>
        <p className="text-xl text-gray-600 mb-8">
          Production-grade e-commerce platform with AI-powered shopping assistant
        </p>
        <div className="flex justify-center space-x-4">
          <Link to="/products" className="bg-primary text-white px-8 py-3 rounded-lg hover:bg-orange-600 transition">
            Browse Products
          </Link>
          <Link to="/ai-assistant" className="bg-secondary text-white px-8 py-3 rounded-lg hover:bg-gray-800 transition">
            Try AI Assistant
          </Link>
        </div>
      </div>

      {/* Architecture Overview */}
      <div className="bg-white rounded-lg shadow-lg p-8 mb-12">
        <h2 className="text-3xl font-bold text-gray-900 mb-6">Architecture Highlights</h2>
        <div className="grid md:grid-cols-3 gap-6">
          <div className="border-l-4 border-primary pl-4">
            <h3 className="text-xl font-semibold mb-2">7 Microservices</h3>
            <p className="text-gray-600">Product, Cart, Payment, Order, Shopping Agent, Troubleshooting Agent, MCP Server</p>
          </div>
          <div className="border-l-4 border-primary pl-4">
            <h3 className="text-xl font-semibold mb-2">AI-Powered</h3>
            <p className="text-gray-600">AWS Bedrock with Claude 3 and Strands Agents SDK</p>
          </div>
          <div className="border-l-4 border-primary pl-4">
            <h3 className="text-xl font-semibold mb-2">Production-Ready</h3>
            <p className="text-gray-600">DLQ, CloudWatch Alarms, X-Ray Tracing, SNS Alerts</p>
          </div>
        </div>
      </div>

      {/* Features Grid */}
      <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
        <FeatureCard
          icon="🛍️"
          title="Product Catalog"
          description="Browse and search products with real-time inventory"
          link="/products"
        />
        <FeatureCard
          icon="🛒"
          title="Shopping Cart"
          description="Add, remove, and manage items in your cart"
          link="/cart"
        />
        <FeatureCard
          icon="🤖"
          title="AI Assistant"
          description="Natural language shopping with AI agent"
          link="/ai-assistant"
        />
        <FeatureCard
          icon="📊"
          title="Admin Dashboard"
          description="DevOps troubleshooting with AI"
          link="/admin"
        />
      </div>

      {/* Tech Stack */}
      <div className="bg-gradient-to-r from-secondary to-gray-700 text-white rounded-lg shadow-lg p-8">
        <h2 className="text-3xl font-bold mb-6">Technology Stack</h2>
        <div className="grid md:grid-cols-2 gap-6">
          <div>
            <h3 className="text-xl font-semibold mb-3">Backend</h3>
            <ul className="space-y-2">
              <li>✅ AWS Lambda (Python 3.11)</li>
              <li>✅ API Gateway (HTTP APIs)</li>
              <li>✅ DynamoDB (NoSQL)</li>
              <li>✅ AWS Bedrock (Claude 3)</li>
              <li>✅ CloudWatch + X-Ray</li>
            </ul>
          </div>
          <div>
            <h3 className="text-xl font-semibold mb-3">Infrastructure</h3>
            <ul className="space-y-2">
              <li>✅ Terraform (IaC)</li>
              <li>✅ CodePipeline (CI/CD)</li>
              <li>✅ Strands Agents SDK</li>
              <li>✅ Model Context Protocol</li>
              <li>✅ SNS/SQS (Messaging)</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  )
}

function FeatureCard({ icon, title, description, link }) {
  return (
    <Link to={link} className="bg-white rounded-lg shadow-md p-6 hover:shadow-xl transition">
      <div className="text-4xl mb-3">{icon}</div>
      <h3 className="text-xl font-semibold mb-2">{title}</h3>
      <p className="text-gray-600">{description}</p>
    </Link>
  )
}
