#!/bin/bash

# CodeAssist Installation Script
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

# Function to clean up Docker containers and screen session
cleanup_environment() {
    print_info "Cleaning up environment..."

    # Stop all Docker containers
    docker stop $(docker ps -aq) 2>/dev/null || true
    docker system prune -af 2>/dev/null || true

    # Kill existing screen session
    screen -XS Codeassist quit 2>/dev/null || true

    print_success "Environment cleanup completed."
}

# Function to get Hugging Face token
get_huggingface_token() {
    echo -e "\n\e[1;36mHugging Face Token Required\e[0m"
    echo "This token is required for accessing AI models through CodeAssist."
    echo "You can get your token from: https://huggingface.co/settings/tokens"
    echo ""

    while true; do
        read -p "Please enter your Hugging Face token: " HF_TOKEN
        if [ ! -z "$HF_TOKEN" ]; then
            echo "Token received. You can also set it as environment variable HF_TOKEN for future runs."
            break
        else
            print_error "Token cannot be empty. Please try again."
        fi
    done
}

print_info "Starting CodeAssist installation outside screen session..."

# Get Hugging Face token first
echo -e "\n\e[1;36mHugging Face Token Required\e[0m"
echo "This token is required for accessing AI models through CodeAssist."
echo "You can get your token from: https://huggingface.co/settings/tokens"
echo ""

while true; do
    read -p "Please enter your Hugging Face token: " HF_TOKEN
    if [ ! -z "$HF_TOKEN" ]; then
        echo "Token received. You can also set it as environment variable HF_TOKEN for future runs."
        break
    else
        echo -e "\e[1;31m[ERROR]\e[0m Token cannot be empty. Please try again."
    fi
done

# Update system packages
print_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install system dependencies
print_info "Installing system dependencies..."
sudo apt install -y screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip python3 python3-pip python3-venv python3-dev

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
    print_info "Cleaning up Docker containers..."
    docker stop $(docker ps -aq) 2>/dev/null || true
    docker system prune -af 2>/dev/null || true
else
    print_info "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    sudo systemctl enable docker
    sudo systemctl start docker
    print_success "Docker installation completed."
fi

# Verify installations
print_info "Verifying installations..."
echo "Node.js: $(node --version 2>/dev/null || echo 'Not installed')"
echo "Yarn: $(yarn --version 2>/dev/null || echo 'Not installed')"
echo "Docker: $(docker --version 2>/dev/null || echo 'Not installed')"
echo "UV: $(uv --version 2>/dev/null || echo 'Not installed')"

# Handle codeassist directory
if [ -d "codeassist" ]; then
    print_info "Existing codeassist directory found, updating..."
    cd codeassist
    git pull
    cd ..
else
    print_info "Cloning fresh codeassist repository..."
    git clone https://github.com/gensyn-ai/codeassist.git
fi

# Clean up environment
print_info "Cleaning up environment..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker system prune -af 2>/dev/null || true
screen -XS Codeassist quit 2>/dev/null || true

print_success "Installation completed! Creating permanent screen session..."

# Create simple screen session
print_info "Creating screen session 'Codeassist'..."
screen -dmS Codeassist

print_success "Screen session 'Codeassist' created!"
echo ""
echo -e "\e[1;32m=== READY ===\e[0m"
echo ""
echo -e "\e[1;36mSCREEN:\e[0m"
echo "• Attach: screen -r Codeassist"
echo "• Detach: Ctrl+A then D"
echo ""
echo -e "\e[1;36mIN SCREEN:\e[0m"
echo "• cd codeassist"
echo "• uv run run.py"
echo ""
echo -e "\e[1;36mSSH TUNNEL:\e[0m"
echo "ssh -N -L 3000:localhost:3000 -L 8000:localhost:8000 -L 8008:localhost:8008 -L 8001:localhost:8001 root@YOUR_VPS_IP"
echo ""
echo -e "\e[1;32m✅ Ready to use!\e[0m"
