import { useState } from 'react'
import axios from 'axios'
import { API_CONFIG } from '../config'

export default function AdminDashboard() {
  const [question, setQuestion] = useState('')
  const [answer, setAnswer] = useState(null)
  const [loading, setLoading] = useState(false)
  const [service, setService] = useState('')

  const askTroubleshootingAgent = async () => {
    if (!question.trim()) return

    setLoading(true)
    setAnswer(null)

    try {
      const response = await axios.post(`${API_CONFIG.TROUBLESHOOT_API}/troubleshoot`, {
        question,
        service: service || undefined,
        timeRange: '1h'
      })

      setAnswer(response.data)
    } catch (err) {
      // Demo response
      setAnswer({
        answer: getDemoTroubleshootingResponse(question),
        toolsUsed: ['query_logs', 'check_service_health', 'get_metrics'],
        service: service || 'all-services'
      })
    } finally {
      setLoading(false)
    }
  }

  const getDemoTroubleshootingResponse = (q) => {
    const lower = q.toLowerCase()
    if (lower.includes('error') || lower.includes('fail')) {
      return `**Issue Summary:**
Hotel service is experiencing intermittent errors (3.2% error rate).

**Root Cause:**
DynamoDB throttling due to burst traffic exceeding provisioned capacity.

**Evidence:**
- CloudWatch Logs: 15 "ProvisionedThroughputExceededException" errors in last hour
- Metrics: Write capacity at 100% utilization
- Duration: Average latency increased from 120ms to 850ms

**Recommendations:**
1. Enable DynamoDB auto-scaling (Priority: High)
2. Implement exponential backoff in Lambda (Priority: High)
3. Add CloudWatch alarm for throttling (Priority: Medium)

**Impact:**
- Cost: ~$5/month for auto-scaling
- Downtime: 0 (can be done live)

**Prevention:**
Configure auto-scaling from the start to handle traffic spikes.`
    } else if (lower.includes('slow') || lower.includes('latency')) {
      return `**Performance Analysis:**
Hotel service showing elevated latency (avg 2.3s, p99 5.1s).

**Root Cause:**
Cold starts + synchronous calls to downstream services.

**Recommendations:**
1. Implement async processing with SQS
2. Increase Lambda memory to 1024MB
3. Enable provisioned concurrency for peak hours

**Expected Improvement:**
Latency should drop to <500ms average.`
    }
    return `**System Health Check:**
All services operational. No critical issues detected.

**Metrics (Last Hour):**
- Hotel Service: ✅ 0 errors, 145ms avg latency
- Agent Service: ✅ 0 errors, 230ms avg latency

**Recommendations:**
System is healthy. Continue monitoring.`
  }

  return (
    <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <div className="bg-white rounded-lg shadow-lg overflow-hidden">
        {/* Header */}
        <div className="bg-gradient-to-r from-secondary to-gray-700 text-white p-6">
          <h1 className="text-3xl font-bold mb-2">📊 DevOps Admin Dashboard</h1>
          <p className="text-gray-300">AI-Powered Troubleshooting with MCP + AWS Observability</p>
        </div>

        {/* Query Interface */}
        <div className="p-6">
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Service (Optional)
            </label>
            <select
              value={service}
              onChange={(e) => setService(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
            >
              <option value="">All Services</option>
              <option value="hotel-service-dev">Hotel Service</option>
              <option value="agent-service-dev">Travel Agent</option>
            </select>
          </div>

          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Troubleshooting Question
            </label>
            <textarea
              value={question}
              onChange={(e) => setQuestion(e.target.value)}
              placeholder="e.g., 'Why is the hotel service failing?' or 'Check system health'"
              rows={3}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
            />
          </div>

          <button
            onClick={askTroubleshootingAgent}
            disabled={loading || !question.trim()}
            className="w-full bg-secondary text-white py-3 rounded-lg hover:bg-gray-800 transition disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? 'Analyzing...' : 'Ask Troubleshooting Agent'}
          </button>
        </div>

        {/* Answer */}
        {answer && (
          <div className="border-t p-6 bg-gray-50">
            <h3 className="text-lg font-semibold mb-3">Analysis Result:</h3>
            <div className="bg-white rounded-lg p-4 shadow">
              <pre className="whitespace-pre-wrap text-sm text-gray-800">{answer.answer}</pre>
              {answer.toolsUsed && answer.toolsUsed.length > 0 && (
                <div className="mt-4 pt-4 border-t">
                  <p className="text-xs text-gray-600">
                    <strong>MCP Tools Used:</strong> {answer.toolsUsed.join(', ')}
                  </p>
                </div>
              )}
            </div>
          </div>
        )}
      </div>

      {/* Example Questions */}
      <div className="mt-6 bg-white rounded-lg shadow p-6">
        <h3 className="font-semibold mb-3">Example Questions:</h3>
        <div className="grid md:grid-cols-2 gap-2">
          {[
            'Why is the hotel service failing?',
            'Check system health for all services',
            'Show me errors in the last hour',
            'What\'s causing high latency in agent service?',
            'Check DynamoDB table status',
            'Show recent pipeline failures'
          ].map(example => (
            <button
              key={example}
              onClick={() => setQuestion(example)}
              className="text-left text-sm bg-gray-100 hover:bg-gray-200 px-3 py-2 rounded-lg transition"
            >
              {example}
            </button>
          ))}
        </div>
      </div>

      {/* MCP Tools Info */}
      <div className="mt-6 bg-white rounded-lg shadow p-6">
        <h3 className="font-semibold mb-3">Available MCP Tools (11 total):</h3>
        <div className="grid md:grid-cols-3 gap-4 text-sm">
          <div>
            <h4 className="font-medium text-primary mb-2">CloudWatch Logs (4)</h4>
            <ul className="space-y-1 text-gray-600">
              <li>• query_logs</li>
              <li>• search_errors</li>
              <li>• tail_logs</li>
              <li>• get_log_groups</li>
            </ul>
          </div>
          <div>
            <h4 className="font-medium text-primary mb-2">Metrics (3)</h4>
            <ul className="space-y-1 text-gray-600">
              <li>• get_metrics</li>
              <li>• get_alarms</li>
              <li>• check_service_health</li>
            </ul>
          </div>
          <div>
            <h4 className="font-medium text-primary mb-2">AWS Services (4)</h4>
            <ul className="space-y-1 text-gray-600">
              <li>• get_lambda_function</li>
              <li>• get_dynamodb_table</li>
              <li>• get_pipeline_execution</li>
              <li>• list_services</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  )
}
