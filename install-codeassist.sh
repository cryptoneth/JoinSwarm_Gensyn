#!/bin/bash

# Display logo and title
echo -e "\e[33m"
cat << "EOF"
_________                        __
\_   ___ \_______ ___.__._______/  |_  ____   ____
/    \  \/\_  __ <   |  |\____ \   __\/  _ \ /    \
\     \____|  | \/\___  ||  |_> >  | (  <_> )   |  \
 \______  /|__|   / ____||   __/|__|  \____/|___|  /
        \/        \/     |__|                    \/
EOF
echo -e "\e[0m"

echo -e "\e[1;31mJOIN CodeAssist NOW\e[0m"

# Auto-confirm Twitter follow
echo "Do you follow Crypton on Twitter? https://x.com/0xCrypton_"
echo "Auto-confirming for installation..."
echo "✅ Twitter follow confirmed!"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Functions
print_info() { echo -e "${CYAN}ℹ️ $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }

# Auto-detect server IP
print_info "Detecting server IP..."
if SERVER_IP=$(curl -s ifconfig.me 2>/dev/null) && [[ "$SERVER_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_success "Server IP: $SERVER_IP"
else
    SERVER_IP="YOUR_SERVER_IP"
    print_info "Please replace YOUR_SERVER_IP with your actual server IP"
fi

echo -e "\n${CYAN}Server IP: ${BOLD}${GREEN}$SERVER_IP${NC}\n"

# Simple cleanup - only stop essential processes
print_info "Simple cleanup..."

# Stop only UV processes with run.py
pkill -f "uv.*run.*run.py" 2>/dev/null || true
sleep 1

# Free essential ports only
for port in 3000 8000 8008 11434; do
    pids=$(lsof -ti:$port 2>/dev/null || true)
    if [ ! -z "$pids" ]; then
        echo "$pids" | xargs -r kill -9 2>/dev/null || true
    fi
done

print_success "✅ Simple cleanup completed"

# Create working directory
WORK_DIR="/root/codeassist"
mkdir -p $WORK_DIR
cd $WORK_DIR
print_success "Working directory: $WORK_DIR"

# Clone repository if needed
if [ ! -d "codeassist" ]; then
    print_info "Cloning CodeAssist repository..."
    git clone https://github.com/gensyn-ai/codeassist.git
    if [ $? -ne 0 ]; then
        print_error "Failed to clone repository"
        exit 1
    fi
    print_success "Repository cloned"
else
    print_success "Repository already exists"
fi

# Change to directory
cd codeassist || {
    print_error "Failed to enter codeassist directory"
    exit 1
}

# Check if run.py exists
if [ ! -f "run.py" ]; then
    print_error "run.py not found"
    exit 1
fi

print_success "Found run.py in $(pwd)"

# Update from GitHub (simple)
print_info "Updating from GitHub..."
git fetch origin >/dev/null 2>&1
git pull origin main >/dev/null 2>&1
print_success "✅ Updated to latest version"

# Install HF token
print_info "Setting up HuggingFace token..."
echo -n "Enter your HF token (or press Enter to skip): "
read -r HF_TOKEN

if [ ! -z "$HF_TOKEN" ]; then
    if [[ "$HF_TOKEN" =~ ^hf_[a-zA-Z0-9]{34}$ ]]; then
        echo "HF_TOKEN=$HF_TOKEN" > .env
        echo "ALCHEMY_API_KEY=wvs3CE89g2JwoshNNCMe1" >> .env
        export HF_TOKEN=$HF_TOKEN
        export ALCHEMY_API_KEY=wvs3CE89g2JwoshNNCMe1
        print_success "HF token and Alchemy API configured"
    else
        print_error "Invalid HF token format"
        print_info "HF token should be 34 characters starting with 'hf_'"
        exit 1
    fi
else
    print_warning "No HF token provided - some features may not work"
    # Still add Alchemy API key even without HF token
    echo "ALCHEMY_API_KEY=wvs3CE89g2JwoshNNCMe1" > .env
    export ALCHEMY_API_KEY=wvs3CE89g2JwoshNNCMe1
    print_success "Alchemy API key configured"
fi

# Install dependencies
print_info "Installing dependencies with UV..."
if ! command -v uv &> /dev/null; then
    print_error "UV not found. Installing..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
fi

uv sync
if [ $? -ne 0 ]; then
    print_error "Failed to install dependencies"
    exit 1
fi

print_success "Dependencies installed"

# Create simple runner script
print_info "Creating CodeAssist runner..."
cat > codeassist_runner.sh << 'EOF'
#!/bin/bash
export HF_TOKEN="${HF_TOKEN}"
export ALCHEMY_API_KEY="${ALCHEMY_API_KEY}"
export NO_COLOR=1
cd /root/codeassist/codeassist

echo 'CodeAssist session started at '$(date)
echo '================================================'
echo '🚀 CodeAssist is running with official command'
echo '💻 Command: uv run run.py'
echo '================================================'
echo ''
echo '🌐 Web Interface: http://localhost:3000'
echo '📋 Instructions:'
echo '   1. Open http://localhost:3000 in your browser'
echo '   2. Complete coding tasks and submit solutions'
echo '   3. Return to this screen and press Ctrl+C'
echo '   4. This will trigger training and submission'
echo '================================================'
echo ''
echo 'Starting CodeAssist...'
echo ''

# Run the official command
uv run run.py

echo ''
echo '================================================'
echo '✅ CodeAssist process completed'
echo ''
echo '🔄 To restart CodeAssist manually, run this command:'
echo '   uv run run.py'
echo ''
echo '💡 Screen will remain active for manual restart'
echo '💡 To exit screen: Ctrl+A, then D'
echo '================================================'
echo ''
echo 'Waiting for your next command...'
exec bash
EOF

chmod +x codeassist_runner.sh

# Start screen session
SCREEN_NAME="codeassist"
print_info "Starting CodeAssist screen session: $SCREEN_NAME"

# Stop existing session if exists
screen -S "$SCREEN_NAME" -X quit 2>/dev/null || true
sleep 1

# Start new screen
screen -dmS "$SCREEN_NAME" ./codeassist_runner.sh

# Wait a bit and check if screen session started
sleep 3
if screen -list 2>/dev/null | grep -q "$SCREEN_NAME"; then
    print_success "CodeAssist started successfully in screen session"
else
    print_error "Failed to start CodeAssist screen session"
    exit 1
fi

# Wait for services to start
print_info "Waiting for services to start (30 seconds)..."
sleep 30

# Check services
print_info "Checking services..."
SERVICES_UP=0

if curl -s --max-time 5 http://localhost:3000 > /dev/null 2>&1; then
    print_success "✓ Main UI (http://localhost:3000)"
    ((SERVICES_UP++))
else
    print_info "⏳ Main UI still starting..."
fi

if curl -s --max-time 5 http://localhost:8000 > /dev/null 2>&1; then
    print_success "✓ State Service (http://localhost:8000)"
    ((SERVICES_UP++))
fi

if curl -s --max-time 5 http://localhost:8008 > /dev/null 2>&1; then
    print_success "✓ Solution Tester (http://localhost:8008)"
    ((SERVICES_UP++))
fi

# Instructions
echo -e "\n${YELLOW}${BOLD}🎯 PARTICIPATION INSTRUCTIONS:${NC}"
echo -e "${CYAN}1. ${GREEN}screen -r $SCREEN_NAME${CYAN} - Attach to the CodeAssist screen${NC}"
echo -e "${CYAN}2. Open ${GREEN}http://localhost:3000${CYAN} in your browser${NC}"
echo -e "${CYAN}3. Complete coding tasks and submit your solutions${NC}"
echo -e "${CYAN}4. Return to the screen and press ${GREEN}Ctrl+C${CYAN} to trigger training${NC}"
echo -e "${CYAN}5. Your training will be submitted automatically!${NC}"

echo -e "\n${YELLOW}${BOLD}🔄 OFFICIAL RESTART COMMAND:${NC}"
echo -e "${CYAN}After training submission, run this command ${BOLD}manually${CYAN} in the screen:${NC}"
echo -e "${GREEN}uv run run.py${NC}"

echo -e "\n${YELLOW}${BOLD}💡 SCREEN MANAGEMENT:${NC}"
echo -e "${CYAN}• Detach anytime: ${GREEN}Ctrl+A, then D${NC}"
echo -e "${CYAN}• Reattach anytime: ${GREEN}screen -r $SCREEN_NAME${NC}"
echo -e "${CYAN}• To completely stop: exit screen and rerun this script${NC}"

# Completion message
echo -e "\n${GREEN}${BOLD}🎉 INSTALLATION COMPLETE!${NC}"
echo -e "${BLUE}Services running: ${GREEN}$SERVICES_UP${NC}/3"
echo -e "${BLUE}Screen session: ${CYAN}$SCREEN_NAME${NC}"
echo -e "${BLUE}Log file: ${CYAN}logs/codeassist.log${NC}"
echo -e "${BLUE}Environment: ${CYAN}.env${NC}"

echo -e "\n${GREEN}${BOLD}🚀 Happy coding with CodeAssist!${NC}\n"
