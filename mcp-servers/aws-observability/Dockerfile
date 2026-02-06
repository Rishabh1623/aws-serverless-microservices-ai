# Dockerfile for AWS Observability MCP Server
# Used for local testing and development

FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy server code
COPY server.py .

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV AWS_REGION=us-east-1

# Expose port (for local testing)
EXPOSE 8080

# Run MCP server
CMD ["python", "server.py"]
