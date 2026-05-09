#!/bin/bash
# Build Lambda Layer with heavy dependencies
# This layer contains: Strands Agents SDK, Anthropic, Pydantic, OpenTelemetry
# Layer is built once and reused across deployments

set -e

echo "📦 Building Lambda Layer with dependencies..."

# Create layer directory structure
LAYER_DIR="$(pwd)/layer"
rm -rf "$LAYER_DIR"
mkdir -p "$LAYER_DIR/python"

# Install all heavy dependencies into layer
echo "Installing dependencies into layer..."
pip3 install \
  strands-agents \
  anthropic \
  pydantic \
  opentelemetry-api \
  opentelemetry-sdk \
  opentelemetry-instrumentation-threading \
  -t "$LAYER_DIR/python/" \
  --upgrade

# Create layer zip
echo "Creating layer zip..."
cd "$LAYER_DIR"
zip -r ../layer.zip python/ -x "*.pyc" "*__pycache__*"

cd ..
echo "✅ Layer created: layer.zip"
echo "📊 Layer size: $(du -h layer.zip | cut -f1)"
echo ""
echo "Note: Layer will be uploaded to Lambda via Terraform"
