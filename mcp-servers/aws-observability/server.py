"""
AWS Observability MCP Server (Unified)

Single MCP server providing complete observability for AWS serverless microservices.
Combines CloudWatch Logs, CloudWatch Metrics, and AWS Services inspection.

Used by Troubleshooting Agent to diagnose and fix issues.
"""

import boto3
import time
import json
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
from mcp.server import Server

# Initialize MCP server
server = Server("aws-observability")

# Initialize AWS clients
logs_client = boto3.client('logs')
cloudwatch_client = boto3.client('cloudwatch')
lambda_client = boto3.client('lambda')
dynamodb_client = boto3.client('dynamodb')
codepipeline_client = boto3.client('codepipeline')
apigateway_client = boto3.client('apigatewayv2')


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

def parse_relative_time(time_str: str) -> int:
    """Parse relative time string to Unix timestamp (milliseconds)"""
    now = datetime.utcnow()
    
    if time_str.startswith('-'):
        time_str = time_str[1:]
    
    if time_str.endswith('h'):
        hours = int(time_str[:-1])
        start_time = now - timedelta(hours=hours)
    elif time_str.endswith('d'):
        days = int(time_str[:-1])
        start_time = now - timedelta(days=days)
    elif time_str.endswith('m'):
        minutes = int(time_str[:-1])
        start_time = now - timedelta(minutes=minutes)
    else:
        start_time = now - timedelta(hours=1)
    
    return int(start_time.timestamp() * 1000)


def wait_for_query_results(query_id: str, max_wait: int = 30) -> List[Dict]:
    """Wait for CloudWatch Insights query to complete"""
    start = time.time()
    
    while time.time() - start < max_wait:
        response = logs_client.get_query_results(queryId=query_id)
        status = response['status']
        
        if status == 'Complete':
            return response['results']
        elif status == 'Failed':
            raise Exception(f"Query failed: {response.get('statistics', {})}")
        
        time.sleep(1)
    
    raise TimeoutError(f"Query timed out after {max_wait} seconds")


# ============================================================================
# CLOUDWATCH LOGS TOOLS
# ============================================================================

@server.tool()
def query_logs(
    log_group: str,
    query: str,
    start_time: str = "-1h",
    limit: int = 100
) -> Dict[str, Any]:
    """
    Query CloudWatch Logs using CloudWatch Insights
    
    Args:
        log_group: Log group name (e.g., /aws/lambda/cart-service-dev)
        query: CloudWatch Insights query
        start_time: Relative time (e.g., -1h, -24h, -7d)
        limit: Maximum results
        
    Example:
        query_logs(
            "/aws/lambda/cart-service-dev",
            "fields @timestamp, @message | filter @message like /ERROR/",
            "-1h"
        )
    """
    try:
        start_ms = parse_relative_time(start_time)
        end_ms = int(datetime.utcnow().timestamp() * 1000)
        
        response = logs_client.start_query(
            logGroupName=log_group,
            startTime=start_ms,
            endTime=end_ms,
            queryString=query,
            limit=limit
        )
        
        results = wait_for_query_results(response['queryId'])
        
        formatted_results = []
        for result in results:
            entry = {field['field']: field['value'] for field in result}
            formatted_results.append(entry)
        
        return {
            'success': True,
            'results': formatted_results,
            'count': len(formatted_results),
            'log_group': log_group
        }
    except Exception as e:
        return {'success': False, 'error': str(e)}


@server.tool()
def search_errors(
    service: str,
    pattern: str = "ERROR",
    last: str = "1h",
    limit: int = 50
) -> Dict[str, Any]:
    """
    Search for errors in service logs
    
    Args:
        service: Service name (e.g., cart-service, product-service)
        pattern: Error pattern to search
        last: Time range (e.g., 1h, 24h)
        limit: Maximum results
        
    Example:
        search_errors("cart-service", "DynamoDB", "1h")
    """
    log_group = f"/aws/lambda/{service}"
    query = f"""
    fields @timestamp, @message, @logStream
    | filter @message like /{pattern}/
    | sort @timestamp desc
    | limit {limit}
    """
    return query_logs(log_group, query, f"-{last}", limit)


@server.tool()
def tail_logs(
    service: str,
    lines: int = 50
) -> Dict[str, Any]:
    """
    Get recent logs from service (like tail -f)
    
    Args:
        service: Service name
        lines: Number of lines
        
    Example:
        tail_logs("hotel-service", 100)
    """
    try:
        log_group = f"/aws/lambda/{service}"
        
        response = logs_client.filter_log_events(
            logGroupName=log_group,
            limit=lines,
            startTime=int((datetime.utcnow() - timedelta(minutes=5)).timestamp() * 1000)
        )
        
        logs = [{
            'timestamp': datetime.fromtimestamp(e['timestamp'] / 1000).isoformat(),
            'message': e['message']
        } for e in response['events']]
        
        return {'success': True, 'logs': logs, 'count': len(logs)}
    except Exception as e:
        return {'success': False, 'error': str(e)}


# ============================================================================
# CLOUDWATCH METRICS TOOLS
# ============================================================================

@server.tool()
def get_metrics(
    namespace: str,
    metric_name: str,
    dimensions: Dict[str, str],
    statistic: str = "Average",
    period: int = 300,
    last: str = "1h"
) -> Dict[str, Any]:
    """
    Get CloudWatch metrics
    
    Args:
        namespace: AWS namespace (e.g., AWS/Lambda)
        metric_name: Metric name (e.g., Duration, Errors)
        dimensions: Metric dimensions (e.g., {"FunctionName": "cart-service-dev"})
        statistic: Average, Sum, Maximum, Minimum
        period: Period in seconds
        last: Time range
        
    Example:
        get_metrics("AWS/Lambda", "Duration", {"FunctionName": "cart-service-dev"})
    """
    try:
        start_time = datetime.utcnow() - timedelta(hours=int(last.rstrip('h')))
        
        response = cloudwatch_client.get_metric_statistics(
            Namespace=namespace,
            MetricName=metric_name,
            Dimensions=[{'Name': k, 'Value': v} for k, v in dimensions.items()],
            StartTime=start_time,
            EndTime=datetime.utcnow(),
            Period=period,
            Statistics=[statistic]
        )
        
        datapoints = sorted(response['Datapoints'], key=lambda x: x['Timestamp'])
        avg = sum(d[statistic] for d in datapoints) / len(datapoints) if datapoints else 0
        
        return {
            'success': True,
            'datapoints': datapoints,
            'average': avg,
            'count': len(datapoints)
        }
    except Exception as e:
        return {'success': False, 'error': str(e)}


@server.tool()
def get_alarms(
    service: Optional[str] = None,
    state: str = "ALARM"
) -> Dict[str, Any]:
    """
    Get CloudWatch alarms
    
    Args:
        service: Filter by service name (optional)
        state: ALARM, OK, INSUFFICIENT_DATA
        
    Example:
        get_alarms("hotel-service", "ALARM")
    """
    try:
        kwargs = {'StateValue': state}
        if service:
            kwargs['AlarmNamePrefix'] = service
        
        response = cloudwatch_client.describe_alarms(**kwargs)
        
        alarms = [{
            'name': a['AlarmName'],
            'state': a['StateValue'],
            'reason': a['StateReason'],
            'timestamp': a['StateUpdatedTimestamp'].isoformat()
        } for a in response['MetricAlarms']]
        
        return {'success': True, 'alarms': alarms, 'count': len(alarms)}
    except Exception as e:
        return {'success': False, 'error': str(e)}


@server.tool()
def check_service_health(service: str) -> Dict[str, Any]:
    """
    Check overall service health (errors, duration, throttles)
    
    Args:
        service: Service name (e.g., hotel-service-dev)
        
    Example:
        check_service_health("hotel-service-dev")
    """
    try:
        # Check Lambda errors
        errors = get_metrics(
            "AWS/Lambda", "Errors",
            {"FunctionName": service},
            "Sum", 300, "1h"
        )
        
        # Check Lambda duration
        duration = get_metrics(
            "AWS/Lambda", "Duration",
            {"FunctionName": service},
            "Average", 300, "1h"
        )
        
        # Check throttles
        throttles = get_metrics(
            "AWS/Lambda", "Throttles",
            {"FunctionName": service},
            "Sum", 300, "1h"
        )
        
        error_count = errors.get('average', 0)
        health = 'healthy' if error_count < 1 else 'unhealthy'
        
        return {
            'success': True,
            'service': service,
            'health': health,
            'error_rate': error_count,
            'avg_duration_ms': duration.get('average', 0),
            'throttles': throttles.get('average', 0)
        }
    except Exception as e:
        return {'success': False, 'error': str(e)}


# ============================================================================
# AWS SERVICES TOOLS
# ============================================================================

@server.tool()
def get_lambda_function(function_name: str) -> Dict[str, Any]:
    """
    Get Lambda function configuration
    
    Args:
        function_name: Lambda function name
        
    Example:
        get_lambda_function("hotel-service-dev")
    """
    try:
        response = lambda_client.get_function(FunctionName=function_name)
        config = response['Configuration']
        
        return {
            'success': True,
            'name': config['FunctionName'],
            'runtime': config['Runtime'],
            'memory': config['MemorySize'],
            'timeout': config['Timeout'],
            'last_modified': config['LastModified'],
            'code_size': config['CodeSize']
        }
    except Exception as e:
        return {'success': False, 'error': str(e)}


@server.tool()
def get_dynamodb_table(table_name: str) -> Dict[str, Any]:
    """
    Get DynamoDB table details
    
    Args:
        table_name: DynamoDB table name
        
    Example:
        get_dynamodb_table("hotel-service-dev")
    """
    try:
        response = dynamodb_client.describe_table(TableName=table_name)
        table = response['Table']
        
        return {
            'success': True,
            'name': table['TableName'],
            'status': table['TableStatus'],
            'item_count': table['ItemCount'],
            'size_bytes': table['TableSizeBytes'],
            'billing_mode': table.get('BillingModeSummary', {}).get('BillingMode', 'PROVISIONED'),
            'read_capacity': table.get('ProvisionedThroughput', {}).get('ReadCapacityUnits'),
            'write_capacity': table.get('ProvisionedThroughput', {}).get('WriteCapacityUnits')
        }
    except Exception as e:
        return {'success': False, 'error': str(e)}


@server.tool()
def get_pipeline_execution(
    pipeline_name: str,
    status: Optional[str] = None
) -> Dict[str, Any]:
    """
    Get recent pipeline executions
    
    Args:
        pipeline_name: CodePipeline name
        status: Filter by status (Succeeded, Failed, InProgress)
        
    Example:
        get_pipeline_execution("hotel-service-pipeline", "Failed")
    """
    try:
        response = codepipeline_client.list_pipeline_executions(
            pipelineName=pipeline_name,
            maxResults=10
        )
        
        executions = response['pipelineExecutionSummaries']
        
        if status:
            executions = [e for e in executions if e['status'] == status]
        
        formatted = [{
            'id': e['pipelineExecutionId'],
            'status': e['status'],
            'start_time': e['startTime'].isoformat(),
            'trigger': e.get('trigger', {}).get('triggerType', 'Unknown')
        } for e in executions]
        
        return {
            'success': True,
            'pipeline': pipeline_name,
            'executions': formatted,
            'count': len(formatted)
        }
    except Exception as e:
        return {'success': False, 'error': str(e)}


@server.tool()
def list_services() -> Dict[str, Any]:
    """
    List all deployed services (Lambda functions)
    
    Returns:
        List of service names
        
    Example:
        list_services()
    """
    try:
        response = lambda_client.list_functions()
        
        services = [f['FunctionName'] for f in response['Functions']]
        
        return {
            'success': True,
            'services': services,
            'count': len(services)
        }
    except Exception as e:
        return {'success': False, 'error': str(e)}


if __name__ == "__main__":
    # Run MCP server
    import asyncio
    from mcp.server.stdio import stdio_server
    
    async def main():
        async with stdio_server() as (read_stream, write_stream):
            await server.run(
                read_stream,
                write_stream,
                server.create_initialization_options()
            )
    
    asyncio.run(main())
