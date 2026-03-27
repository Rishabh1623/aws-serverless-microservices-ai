import { Link } from 'react-router-dom'

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-50 to-white">
      {/* Hero Section with Animation */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
        <div className="text-center mb-16 animate-fade-in">
          <div className="inline-block mb-4">
            <span className="bg-primary/10 text-primary px-4 py-2 rounded-full text-sm font-semibold">
              🚀 Powered by AWS Serverless
            </span>
          </div>
          <h1 className="text-6xl font-bold text-gray-900 mb-6 leading-tight">
            AI-Powered Travel Platform
            <br />
            <span className="text-primary">Book Hotels with Intelligence</span>
          </h1>
          <p className="text-xl text-gray-600 mb-10 max-w-3xl mx-auto">
            Production-grade serverless travel platform with AWS Bedrock AI assistant, 
            real-time hotel availability, and intelligent booking management
          </p>
          <div className="flex justify-center space-x-4">
            <Link 
              to="/products" 
              className="bg-primary text-white px-8 py-4 rounded-lg hover:bg-orange-600 transition-all duration-300 transform hover:scale-105 hover:shadow-xl font-semibold text-lg"
            >
              🏨 Browse Hotels
            </Link>
            <Link 
              to="/ai-assistant" 
              className="bg-gradient-to-r from-blue-600 to-purple-600 text-white px-8 py-4 rounded-lg hover:from-blue-700 hover:to-purple-700 transition-all duration-300 transform hover:scale-105 hover:shadow-xl font-semibold text-lg"
            >
              🤖 AI Travel Assistant
            </Link>
          </div>
        </div>

        {/* Stats Section */}
        <div className="grid md:grid-cols-4 gap-6 mb-16">
          <StatCard number="500+" label="Hotels" icon="🏨" />
          <StatCard number="50+" label="Destinations" icon="🌍" />
          <StatCard number="99.9%" label="Uptime SLA" icon="✅" />
          <StatCard number="<100ms" label="API Response" icon="🚀" />
        </div>

        {/* Architecture Overview */}
        <div className="bg-white rounded-2xl shadow-xl p-10 mb-12 border border-gray-100">
          <h2 className="text-4xl font-bold text-gray-900 mb-8 text-center">
            Enterprise Architecture
          </h2>
          <div className="grid md:grid-cols-3 gap-8">
            <ArchitectureCard
              icon="🏗️"
              title="Microservices"
              items={[
                "Hotel Service",
                "Booking Service", 
                "Payment Service",
                "Order Service"
              ]}
            />
            <ArchitectureCard
              icon="🤖"
              title="AI Agents"
              items={[
                "Travel Assistant (Bedrock)",
                "Hotel Recommendations",
                "MCP Observability",
                "Natural Language Booking"
              ]}
            />
            <ArchitectureCard
              icon="🛡️"
              title="Production Features"
              items={[
                "DLQ + Error Handling",
                "CloudWatch Alarms",
                "X-Ray Tracing",
                "SNS Notifications"
              ]}
            />
          </div>
        </div>

        {/* Features Grid */}
        <h2 className="text-4xl font-bold text-gray-900 mb-8 text-center">
          Platform Features
        </h2>
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6 mb-16">
          <FeatureCard
            icon="🏨"
            title="Hotel Search"
            description="500+ hotels across 50+ destinations with real-time availability"
            link="/products"
            gradient="from-blue-500 to-blue-600"
          />
          <FeatureCard
            icon="🧳"
            title="Trip Planning"
            description="Plan your perfect trip with AI recommendations"
            link="/cart"
            gradient="from-green-500 to-green-600"
          />
          <FeatureCard
            icon="🤖"
            title="AI Travel Assistant"
            description="Natural language hotel booking powered by Claude 3"
            link="/ai-assistant"
            gradient="from-purple-500 to-purple-600"
          />
          <FeatureCard
            icon="📋"
            title="Booking Management"
            description="Real-time booking status and history"
            link="/orders"
            gradient="from-orange-500 to-orange-600"
          />
        </div>

        {/* Tech Stack */}
        <div className="bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 text-white rounded-2xl shadow-2xl p-10">
          <h2 className="text-4xl font-bold mb-8 text-center">
            Technology Stack
          </h2>
          <div className="grid md:grid-cols-3 gap-8">
            <TechStackCard
              title="Backend Services"
              items={[
                "AWS Lambda (Python 3.11)",
                "API Gateway (HTTP APIs)",
                "DynamoDB (NoSQL)",
                "EventBridge (Events)",
                "SQS/SNS (Messaging)"
              ]}
            />
            <TechStackCard
              title="AI & Observability"
              items={[
                "AWS Bedrock (Claude 3)",
                "Strands Agents SDK",
                "Model Context Protocol",
                "CloudWatch Logs/Metrics",
                "X-Ray Distributed Tracing"
              ]}
            />
            <TechStackCard
              title="Infrastructure"
              items={[
                "Terraform (IaC)",
                "CodePipeline (CI/CD)",
                "Docker (Lambda Layers)",
                "S3 (Static Hosting)",
                "CloudFormation"
              ]}
            />
          </div>
        </div>
      </div>
    </div>
  )
}

function StatCard({ number, label, icon }) {
  return (
    <div className="bg-white rounded-xl shadow-lg p-6 text-center transform hover:scale-105 transition-all duration-300 border border-gray-100">
      <div className="text-3xl mb-2">{icon}</div>
      <div className="text-3xl font-bold text-primary mb-1">{number}</div>
      <div className="text-gray-600 font-medium">{label}</div>
    </div>
  )
}

function ArchitectureCard({ icon, title, items }) {
  return (
    <div className="text-center">
      <div className="text-5xl mb-4">{icon}</div>
      <h3 className="text-2xl font-bold mb-4 text-gray-900">{title}</h3>
      <ul className="space-y-2 text-gray-600">
        {items.map((item, i) => (
          <li key={i} className="flex items-center justify-center">
            <span className="text-primary mr-2">✓</span>
            {item}
          </li>
        ))}
      </ul>
    </div>
  )
}

function FeatureCard({ icon, title, description, link, gradient }) {
  return (
    <Link 
      to={link} 
      className="group bg-white rounded-xl shadow-lg p-6 hover:shadow-2xl transition-all duration-300 transform hover:-translate-y-2 border border-gray-100"
    >
      <div className={`w-16 h-16 bg-gradient-to-br ${gradient} rounded-xl flex items-center justify-center text-3xl mb-4 group-hover:scale-110 transition-transform duration-300`}>
        {icon}
      </div>
      <h3 className="text-xl font-bold mb-2 text-gray-900">{title}</h3>
      <p className="text-gray-600">{description}</p>
      <div className="mt-4 text-primary font-semibold flex items-center">
        Explore <span className="ml-2 group-hover:translate-x-2 transition-transform">→</span>
      </div>
    </Link>
  )
}

function TechStackCard({ title, items }) {
  return (
    <div>
      <h3 className="text-xl font-bold mb-4 text-primary">{title}</h3>
      <ul className="space-y-3">
        {items.map((item, i) => (
          <li key={i} className="flex items-start">
            <span className="text-green-400 mr-3 mt-1">✓</span>
            <span className="text-gray-300">{item}</span>
          </li>
        ))}
      </ul>
    </div>
  )
}
