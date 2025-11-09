#!/bin/bash

# CodeAssist Dependency Installation Script
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

set -e  # Exit on any error

# Function to print colored output
print_info() {
    echo -e "\e[1;34m[INFO]\e[0m $1"
}

print_success() {
    echo -e "\e[1;32m[SUCCESS]\e[0m $1"
}

print_warning() {
    echo -e "\e[1;33m[WARNING]\e[0m $1"
}

print_error() {
    echo -e "\e[1;31m[ERROR]\e[0m $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_info "Starting CodeAssist dependency installation..."

# Update system packages
print_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install system dependencies
print_info "Installing system dependencies..."
sudo apt install -y screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip python3 python3-pip python3-venv python3-dev lsof

# Install Node.js
print_info "Installing Node.js 22.x..."
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -
sudo apt install -y nodejs

# Install Yarn
print_info "Installing Yarn..."
curl -o- -L https://yarnpkg.com/install.sh | bash
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
source ~/.bashrc

# Install UV
print_info "Installing UV (Python package manager)..."
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env

# Handle Docker installation
print_info "Checking Docker installation..."
if command_exists docker; then
    print_warning "Docker is already installed on this system."
else
    print_info "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    sudo systemctl enable docker
    sudo systemctl start docker
    print_success "Docker installation completed."
fi

# Clean up existing Gensyn/CodeAssist containers (now after Docker is available)
print_info "Cleaning up existing Gensyn/CodeAssist containers..."
docker stop $(docker ps --filter "name=codeassist" -q) 2>/dev/null || true
docker rm $(docker ps -a --filter "name=codeassist" -q) 2>/dev/null || true
docker stop $(docker ps --filter "name=codeassist-ollama" -q) 2>/dev/null || true
docker rm $(docker ps -a --filter "name=codeassist-ollama" -q) 2>/dev/null || true
docker system prune -f 2>/dev/null || true
print_success "Gensyn/CodeAssist containers cleaned up."

# Free up required ports: 3000, 8000, 8001, 8008, 11434
print_info "Checking and freeing required ports: 3000, 8000, 8001, 8008, 11434"
PORTS=(3000 8000 8001 8008 11434)
for port in "${PORTS[@]}"; do
    print_info "Checking port $port..."
    pids=$(sudo lsof -ti:$port 2>/dev/null || echo "")
    if [ ! -z "$pids" ]; then
        print_warning "Port $port in use by PID(s): $pids. Stopping processes..."
        echo $pids | xargs sudo kill -9 2>/dev/null || true
        sleep 2  # Give time to release
    fi
    # Double-check
    remaining_pids=$(sudo lsof -ti:$port 2>/dev/null || echo "")
    if [ -z "$remaining_pids" ]; then
        print_success "Port $port is now free."
    else
        print_warning "Port $port could not be fully freed (remaining PIDs: $remaining_pids). Manual intervention may be needed."
    fi
done

# Verify installations
print_info "Verifying installations..."
echo "Node.js: $(node --version 2>/dev/null || echo 'Not installed')"
echo "Yarn: $(yarn --version 2>/dev/null || echo 'Not installed')"
echo "Docker: $(docker --version 2>/dev/null || echo 'Not installed')"
echo "UV: $(uv --version 2>/dev/null || echo 'Not installed')"

print_success "Dependencies installation completed!"

# Get public IP with timeout to avoid hanging
print_info "Detecting public IP..."
PUBLIC_IP=$(curl -s --max-time 10 ifconfig.me || echo "YOUR_VPS_IP")
if [ "$PUBLIC_IP" = "YOUR_VPS_IP" ]; then
    print_warning "Could not detect public IP automatically. Please replace YOUR_VPS_IP in the SSH command."
fi

echo ""
echo -e "\e[1;36m#2) Downloading the Code\e[0m"
echo -e "\e[1;34mTo download the code, simply clone the repository:\e[0m"
echo ""
echo -e "\e[1;32mgit clone https://github.com/gensyn-ai/codeassist.git\e[0m"
echo -e "\e[1;32mcd codeassist\e[0m"
echo -e "\e[1;32muv run run.py\e[0m"
echo ""
echo -e "\e[1;34mIf you run it on a VPS you need to run SSH from your local PC\e[0m"
echo -e "\e[1;32mssh -N -L 3000:localhost:3000 -L 8000:localhost:8000 -L 8008:localhost:8008 root@$PUBLIC_IP\e[0m"
echo ""
echo -e "\e[1;34mAfter establishing the SSH tunnel, go to \e[1;32mhttp://localhost:3000\e[0m\e[1;34m in your browser and use CodeAssist to register solutions for problems.\e[0m"
echo ""
echo -e "\e[1;34mAfter solving the problem, go back to the terminal, press Ctrl+C, and wait for it to finish pushing the data\e[0m"
