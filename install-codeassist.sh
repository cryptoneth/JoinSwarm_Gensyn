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

# Ask if following Twitter
echo "Do you follow Crypton on Twitter? https://x.com/0xCrypton_"
read -p "Press y if you followed: " follow
if [ "$follow" != "y" ] && [ "$follow" != "Y" ]; then
    echo "Please follow and try again."
    exit 1
fi

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

# Auto-detect server IP
print_info "Detecting server IP..."
if SERVER_IP=$(curl -s ifconfig.me 2>/dev/null) && [[ "$SERVER_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_success "Server IP: $SERVER_IP"
else
    SERVER_IP="YOUR_SERVER_IP"
    print_info "Please replace YOUR_SERVER_IP with your actual server IP"
fi

echo -e "\n${CYAN}Server IP: ${BOLD}${GREEN}$SERVER_IP${NC}\n"

# Simple cleanup - only clean what's necessary
print_info "Cleaning up any existing CodeAssist processes..."

# Simple and safe process cleanup
pkill -f "uv.*run.*run.py" 2>/dev/null || true

# Kill any processes on our ports but be very specific
for port in 3000 8000 8008; do
    pids=$(lsof -ti:$port 2>/dev/null || true)
    if [ ! -z "$pids" ]; then
        print_info "Stopping processes on port $port..."
        echo "$pids" | xargs -r kill -TERM 2>/dev/null || true
        sleep 2
        echo "$pids" | xargs -r kill -9 2>/dev/null || true
    fi
done

print_success "Cleanup completed"

# Create working directory
WORK_DIR="/root/codeassist-setup"
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

# Install HF token
print_info "Setting up HuggingFace token..."
echo -n "Enter your HF token (or press Enter to skip): "
read -r HF_TOKEN

if [ ! -z "$HF_TOKEN" ]; then
    if [[ "$HF_TOKEN" =~ ^hf_[a-zA-Z0-9]{34}$ ]]; then
        echo "HF_TOKEN=$HF_TOKEN" > .env
        export HF_TOKEN=$HF_TOKEN
        print_success "HF token configured"
    else
        print_error "Invalid HF token format"
        exit 1
    fi
else
    print_warning "No HF token provided - some features may not work"
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

# Start CodeAssist
print_info "Starting CodeAssist..."
export HF_TOKEN=$HF_TOKEN

# Start in background with logging
nohup uv run run.py > codeassist.log 2>&1 &
CODEASSIST_PID=$!

if [ -z "$CODEASSIST_PID" ]; then
    print_error "Failed to start CodeAssist"
    exit 1
fi

print_success "CodeAssist started (PID: $CODEASSIST_PID)"

# Check if process is running
sleep 5
if kill -0 $CODEASSIST_PID 2>/dev/null; then
    print_success "Process is running"
else
    print_error "Process died immediately"
    print_info "Check logs: tail -f codeassist.log"
    exit 1
fi

# Wait for services to start
print_info "Waiting for services to start (30 seconds)..."
sleep 30

# Check services
print_info "Checking services..."
SERVICES_UP=0

if curl -s http://localhost:3000 > /dev/null 2>&1; then
    print_success "✓ Main UI (http://localhost:3000)"
    ((SERVICES_UP++))
else
    print_info "⏳ Main UI still starting..."
fi

if curl -s http://localhost:8000 > /dev/null 2>&1; then
    print_success "✓ State Service (http://localhost:8000)"
    ((SERVICES_UP++))
fi

if curl -s http://localhost:8008 > /dev/null 2>&1; then
    print_success "✓ Solution Tester (http://localhost:8008)"
    ((SERVICES_UP++))
fi

# SSH Commands
echo -e "\n${BLUE}${BOLD}🔗 SSH TUNNELING COMMANDS:${NC}"

echo -e "${YELLOW}📱 FOR ALL DEVICES:${NC}"
echo -e "${CYAN}Essential Services (Ports 3000, 8000, 8008):${NC}"
echo -e "${GREEN}ssh -L 3000:localhost:3000 -L 8000:localhost:8000 -L 8008:localhost:8008 root@$SERVER_IP${NC}"

echo -e "\n${YELLOW}🖥️ Windows (PowerShell/CMD):${NC}"
echo -e "${GREEN}ssh -L 3000:localhost:3000 -L 8000:localhost:8000 -L 8008:localhost:8008 root@$SERVER_IP${NC}"

echo -e "\n${YELLOW}🍎 macOS / 🐧 Linux (Terminal):${NC}"
echo -e "${GREEN}ssh -L 3000:localhost:3000 -L 8000:localhost:8000 -L 8008:localhost:8008 root@$SERVER_IP${NC}"

echo -e "\n${YELLOW}🔄 Background Mode (All Devices):${NC}"
echo -e "${GREEN}ssh -f -N -L 3000:localhost:3000 -L 8000:localhost:8000 -L 8008:localhost:8008 root@$SERVER_IP${NC}"

echo -e "\n${YELLOW}📡 Complete Access (All Ports):${NC}"
echo -e "${GREEN}ssh -L 3000:localhost:3000 -L 3002:localhost:3002 -L 3003:localhost:3003 -L 8000:localhost:8000 -L 8001:localhost:8001 -L 8008:localhost:8008 -L 11434:localhost:11434 root@$SERVER_IP${NC}"

echo -e "\n${CYAN}💡 After connecting, open: ${GREEN}http://localhost:3000${NC}"
echo -e "${CYAN}📱 Keep SSH connection open while using CodeAssist${NC}"

# Completion message
echo -e "\n${GREEN}${BOLD}🎉 INSTALLATION COMPLETE!${NC}"
echo -e "${BLUE}Services running: ${GREEN}$SERVICES_UP${NC}/3"
echo -e "${BLUE}Log file: ${CYAN}codeassist.log${NC}"
echo -e "${BLUE}PID file: ${CYAN}codeassist.pid${NC}"

echo -e "\n${GREEN}${BOLD}🚀 Happy coding with CodeAssist!${NC}\n"
