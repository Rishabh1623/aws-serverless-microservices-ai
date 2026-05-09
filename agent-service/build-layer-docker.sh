#!/bin/bash
# Build Lambda Layer using Docker with Amazon Linux
# This ensures binary compatibility with Lambda runtime

set -e

echo "🐳 Building Lambda Layer using Docker (Amazon Linux)..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Installing Docker..."
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    echo "✅ Docker installed. Please log out and log back in, then run this script again."
    exit 1
fi

# Create layer directory
LAYER_DIR="$(pwd)/layer-docker"
rm -rf "$LAYER_DIR"
mkdir -p "$LAYER_DIR"

# Create requirements file for layer
cat > "$LAYER_DIR/requirements.txt" << 'EOF'
strands-agents>=0.1.0
anthropic>=0.39.0
pydantic>=2.0.0
opentelemetry-api>=1.30.0
opentelemetry-sdk>=1.30.0
opentelemetry-instrumentation-threading>=0.51b0
EOF

# Build using official AWS Lambda Python 3.10 Docker image
echo "📦 Installing dependencies in Lambda-compatible environment..."
docker run --rm \
  --entrypoint /bin/bash \
  -v "$LAYER_DIR":/var/task \
  public.ecr.aws/lambda/python:3.10 \
  -c "pip install -r /var/task/requirements.txt -t /var/task/python/ --no-cache-dir && rm /var/task/requirements.txt"

# Create layer zip
echo "📦 Creating layer zip..."
cd "$LAYER_DIR"
zip -r ../layer.zip python/ -q

cd ..
rm -rf "$LAYER_DIR"

echo "✅ Layer created: layer.zip"
echo "📊 Layer size: $(du -h layer.zip | cut -f1)"
echo ""
echo "Note: This layer was built using Docker with Amazon Linux, ensuring 100% compatibility with Lambda"
