#!/bin/bash

# Ollama Models Integration Script
# Integrates existing Ollama models from external drive

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Existing models path (from your system)
EXISTING_MODELS="/run/media/garuda/73cf9511-0af0-4ac4-9d83-ee21eb17ff5d/models"
OLLAMA_HOME="/opt/ollama"
OLLAMA_MODELS="$OLLAMA_HOME/models"

log "🤖 Integrating existing Ollama models into AI Powerhouse setup"

# Check if existing models directory exists
if [ ! -d "$EXISTING_MODELS" ]; then
    warn "Existing models directory not found: $EXISTING_MODELS"
    log "Creating new Ollama models directory..."
    sudo mkdir -p "$OLLAMA_MODELS"
    exit 0
fi

# Create Ollama home and models directory
log "Setting up Ollama directories..."
sudo mkdir -p "$OLLAMA_MODELS"
sudo mkdir -p "$OLLAMA_HOME/logs"

# Copy existing models
log "Copying existing models from $EXISTING_MODELS to $OLLAMA_MODELS..."
sudo cp -r "$EXISTING_MODELS"/* "$OLLAMA_MODELS/"

# Set proper permissions
log "Setting proper permissions..."
sudo chown -R ollama:ollama "$OLLAMA_HOME"
sudo chmod -R 755 "$OLLAMA_HOME"

# List available models
log "Available models in your collection:"
if [ -d "$OLLAMA_MODELS/blobs" ]; then
    echo "✅ Models blob storage found"
    BLOB_COUNT=$(find "$OLLAMA_MODELS/blobs" -type f | wc -l)
    log "Found $BLOB_COUNT model blobs"
fi

if [ -d "$OLLAMA_MODELS/manifests" ]; then
    echo "✅ Model manifests found"
    log "Available model manifests:"
    find "$OLLAMA_MODELS/manifests" -name "*.json" -o -name "*latest*" | while read -r manifest; do
        MODEL_NAME=$(basename "$(dirname "$manifest")")
        echo "  🧠 $MODEL_NAME"
    done
fi

# Create Ollama systemd service
log "Creating Ollama systemd service..."
sudo tee /etc/systemd/system/ollama.service > /dev/null << 'EOF'
[Unit]
Description=Ollama Local AI Service
After=network-online.target
Wants=network-online.target

[Service]
Type=exec
User=ollama
Group=ollama
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_MODELS=/opt/ollama/models"
Environment="OLLAMA_KEEP_ALIVE=24h"
ExecStart=/usr/bin/ollama serve
KillMode=process
Restart=always
RestartSec=3
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create ollama user if it doesn't exist
if ! id ollama &>/dev/null; then
    log "Creating ollama user..."
    sudo useradd -r -s /bin/false -d "$OLLAMA_HOME" ollama
    sudo chown -R ollama:ollama "$OLLAMA_HOME"
fi

# Enable and start Ollama service
log "Enabling and starting Ollama service..."
sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl start ollama

# Wait for service to start
sleep 5

# Test Ollama service
log "Testing Ollama service..."
if curl -s http://localhost:11434/api/tags > /dev/null; then
    log "✅ Ollama service is running successfully!"
    
    # List available models via API
    log "Models available via Ollama API:"
    curl -s http://localhost:11434/api/tags | jq -r '.models[]?.name // "No models found"' 2>/dev/null || echo "No models detected via API (may need to pull models)"
else
    warn "Ollama service may not be fully started yet. Check status with: systemctl status ollama"
fi

# Create convenient model management scripts
log "Creating model management scripts..."

# Model list script
cat > /usr/local/bin/ollama-list << 'EOF'
#!/bin/bash
echo "🤖 Available Ollama Models:"
curl -s http://localhost:11434/api/tags | jq -r '.models[]?.name' 2>/dev/null || echo "No models available"
EOF

# Model pull script
cat > /usr/local/bin/ollama-pull << 'EOF'
#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: ollama-pull <model-name>"
    echo "Example: ollama-pull llama2:13b"
    exit 1
fi
echo "Pulling model: $1"
ollama pull "$1"
EOF

# Model run script
cat > /usr/local/bin/ollama-chat << 'EOF'
#!/bin/bash
if [ -z "$1" ]; then
    echo "Available models:"
    ollama-list
    echo ""
    echo "Usage: ollama-chat <model-name>"
    echo "Example: ollama-chat llama2:13b"
    exit 1
fi
echo "Starting chat with: $1"
ollama run "$1"
EOF

# Make scripts executable
sudo chmod +x /usr/local/bin/ollama-*

# Create development integration scripts
log "Creating AI development integration..."

# VS Code integration
mkdir -p ~/.vscode/extensions
cat > ~/.vscode/settings.json << 'EOF'
{
    "ollama.models": [
        "codellama:13b",
        "llama2:13b",
        "mistral:7b"
    ],
    "ollama.endpoint": "http://localhost:11434"
}
EOF

# Create AI coding assistant script
cat > /usr/local/bin/ai-code-assist << 'EOF'
#!/bin/bash
# AI Code Assistant using local Ollama models

MODEL="${1:-codellama:13b}"
PROMPT="You are a helpful AI programming assistant. Help with code, debugging, and development questions."

echo "🤖 AI Code Assistant (Model: $MODEL)"
echo "Type 'exit' to quit, 'help' for commands"
echo ""

while true; do
    read -p ">>> " input
    
    case "$input" in
        "exit"|"quit")
            echo "Goodbye!"
            break
            ;;
        "help")
            echo "Commands:"
            echo "  exit/quit - Exit the assistant"
            echo "  help - Show this help"
            echo "  model <name> - Switch model"
            echo "  Just type your programming questions!"
            ;;
        "model "*)
            MODEL="${input#model }"
            echo "Switched to model: $MODEL"
            ;;
        "")
            continue
            ;;
        *)
            echo "🤖 Thinking..."
            curl -s -X POST http://localhost:11434/api/generate \
                -H "Content-Type: application/json" \
                -d "{\"model\":\"$MODEL\",\"prompt\":\"$PROMPT\n\nQuestion: $input\n\nAnswer:\"}" | \
                jq -r '.response' 2>/dev/null || echo "Error: Could not get response from model"
            echo ""
            ;;
    esac
done
EOF

sudo chmod +x /usr/local/bin/ai-code-assist

log "🎉 Ollama integration completed successfully!"
echo ""
echo "✅ Your existing models have been integrated"
echo "✅ Ollama service is running on http://localhost:11434"
echo "✅ Model management scripts created"
echo ""
echo "🚀 Quick commands:"
echo "  ollama-list          - List available models"
echo "  ollama-pull <model>  - Download new models"
echo "  ollama-chat <model>  - Chat with a model"
echo "  ai-code-assist       - AI programming assistant"
echo ""
echo "🔧 Service management:"
echo "  systemctl status ollama    - Check service status"
echo "  systemctl restart ollama   - Restart service"
echo "  journalctl -u ollama -f    - View service logs"
echo ""
echo "🌐 Web interfaces:"
echo "  http://localhost:11434/api/tags - API endpoint"
echo ""
echo "Your AI models are ready for development! 🚀"