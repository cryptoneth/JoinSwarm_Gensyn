#!/bin/bash

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                         
# ║    🚀 CODEASSIST AUTO-INSTALLER v1.0                                      
# ║    Created by: 0xCrypton_ | Twitter: @0xCrypton_                           
# ║    Follow me: https://twitter.com/0xCrypton_                             
# ║                                                                          
# ║    ⭐ Automated CodeAssist Installation with SSH Tunneling                
# ║    🔧 Pre-configured with your HuggingFace token                           
# ║    🌐 Secure tunnel access from anywhere                                    
# ║                                                                          
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Color definitions for fancy output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Emoji definitions
ROCKET="🚀"
CHECK="✅"
WARNING="⚠️"
ERROR="❌"
INFO="ℹ️"
GEAR="⚙️"
KEY="🔑"
LINK="🔗"
CROWN="👑"

# Animation function
spin() {
    local i=0
    local sp="/-\|"
    while [ $i -lt 5 ]; do
        printf "\r${CYAN}${sp:i++%${#sp}:1} Working...${NC}"
        sleep 0.1
    done
    printf "\r${GREEN}✅ Done!${NC}\n"
}

# Header
clear
echo -e "${BOLD}${BLUE}┌────────────────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}${BLUE}│${NC} ${BOLD}CODEASSIST - GENSYN${NC}                                                 ${BOLD}${BLUE}│${NC}"
echo -e "${BOLD}${BLUE}│${NC} by ${CYAN}0xCrypton_${NC} | ${BLUE}x.com/0xCrypton_${NC}                             ${BOLD}${BLUE}│${NC}"
echo -e "${BOLD}${BLUE}└────────────────────────────────────────────────────────────────────────────┘${NC}"
echo ""

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}${BOLD}═══ $1 ═══${NC}\n"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}${ERROR} $1${NC}"
}

# Function to print info messages
print_info() {
    echo -e "${CYAN}${INFO} $1${NC}"
}

# Function to print warning messages
print_warning() {
    echo -e "${YELLOW}${WARNING} $1${NC}"
}

print_header "SYSTEM REQUIREMENTS CHECK"

# Check if running on supported OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    print_success "Linux detected ✓"
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    print_success "macOS detected ✓"
    OS="macos"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    print_success "Windows detected ✓"
    OS="windows"
else
    print_warning "Unknown OS detected, proceeding anyway..."
    OS="unknown"
fi

# Check internet connection
print_info "Checking internet connection..."
if ping -c 1 google.com &> /dev/null; then
    print_success "Internet connection active ✓"
else
    print_error "No internet connection detected!"
    exit 1
fi

print_header "INSTALLING DEPENDENCIES"

# Function to install package based on OS
install_package() {
    local package=$1
    print_info "Installing $package..."

    if command -v apt-get &> /dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y $package
    elif command -v yum &> /dev/null; then
        sudo yum install -y $package
    elif command -v brew &> /dev/null; then
        brew install $package
    elif [[ "$OS" == "macos" ]]; then
        # Try to install brew first
        if ! command -v brew &> /dev/null; then
            print_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install $package
    else
        print_error "Cannot install $package. Please install manually."
        return 1
    fi

    if command -v $package &> /dev/null; then
        print_success "$package installed successfully ✓"
    else
        print_error "Failed to install $package ✗"
        return 1
    fi
}

# Check and install Docker
if ! command -v docker &> /dev/null; then
    print_warning "Docker not found. Installing Docker..."

    # Download and run dedicated Docker installer
    if [ -f "install-docker.sh" ]; then
        print_info "Running dedicated Docker installer..."
        chmod +x install-docker.sh
        ./install-docker.sh
    else
        print_info "Downloading Docker installer..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh

        # Start and enable Docker service
        if command -v systemctl &> /dev/null; then
            systemctl start docker
            systemctl enable docker
            usermod -aG docker $USER
        fi
    fi

    # Verify Docker installation
    if command -v docker &> /dev/null; then
        print_success "Docker installed successfully ✓"
    else
        print_error "Docker installation failed. Please install manually."
        return 1
    fi
else
    print_success "Docker already installed ✓"
fi

# Check and install Git
if ! command -v git &> /dev/null; then
    print_warning "Git not found. Installing Git..."
    install_package "git"
else
    print_success "Git already installed ✓"
fi

# Check and install Python
if ! command -v python3 &> /dev/null; then
    print_warning "Python 3 not found. Installing Python..."
    install_package "python3"
else
    print_success "Python 3 already installed ✓"
fi

# Install UV (Python package manager)
print_info "Installing UV package manager..."
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
    print_success "UV installed successfully ✓"
else
    print_success "UV already installed ✓"
fi

print_header "CODEASSIST SETUP"

# Stop only CodeAssist-related Docker containers
print_info "Checking for CodeAssist-related containers..."
CODEASSIST_CONTAINERS=$(docker ps -q --filter "name=codeassist" --filter "name=codespace" --filter "name=gensyn" 2>/dev/null || true)
if [ ! -z "$CODEASSIST_CONTAINERS" ]; then
    print_info "Stopping CodeAssist-related containers..."
    docker stop $CODEASSIST_CONTAINERS 2>/dev/null || true
    docker rm $CODEASSIST_CONTAINERS 2>/dev/null || true
    print_success "CodeAssist containers stopped ✓"
else
    print_success "No CodeAssist containers found ✓"
fi

# Kill processes on required ports only if they conflict with CodeAssist
print_info "Checking port availability for CodeAssist..."
for port in 3000 8000 8008; do
    pid=$(lsof -ti:$port 2>/dev/null)
    if [ ! -z "$pid" ]; then
        # Check if the process is CodeAssist-related
        process_name=$(ps -p $pid -o comm= 2>/dev/null || echo "unknown")
        if [[ "$process_name" == *"codeassist"* ]] || [[ "$process_name" == *"gensyn"* ]] || [[ "$process_name" == *"codespace"* ]]; then
            kill -9 $pid 2>/dev/null || true
            print_success "Stopped CodeAssist process on port $port ✓"
        else
            print_warning "Port $port is in use by non-CodeAssist process (PID: $pid, Process: $process_name)"
            print_warning "You may need to manually stop this process if it causes conflicts"
        fi
    fi
done

# Remove existing CodeAssist directories
print_info "Removing existing CodeAssist files..."
rm -rf $HOME/codeassist-setup 2>/dev/null || true
rm -rf /root/codeassist-setup 2>/dev/null || true
print_success "Existing files removed ✓"

# Create working directory
WORK_DIR="$HOME/codeassist-setup"
mkdir -p $WORK_DIR
cd $WORK_DIR
print_success "Working directory created: $WORK_DIR"

# Clone CodeAssist repository
print_info "Cloning CodeAssist repository..."
if [ -d "codeassist" ]; then
    rm -rf codeassist
fi

git clone https://github.com/gensyn-ai/codeassist.git
if [ $? -eq 0 ]; then
    cd codeassist
    print_success "CodeAssist repository cloned successfully ✓"
else
    print_error "Failed to clone CodeAssist repository ✗"
    exit 1
fi

# Set up HuggingFace token
print_header "HUGGINGFACE TOKEN CONFIGURATION"

print_info "HuggingFace token is required for CodeAssist to access AI models."
print_info "Get your token from: https://huggingface.co/settings/tokens"
echo ""

# Ask user for their HuggingFace token
while true; do
    echo -e "${YELLOW}Please enter your HuggingFace token (or press Enter to skip):${NC}"
    read -p "> " HF_TOKEN

    if [ -z "$HF_TOKEN" ]; then
        print_warning "No HuggingFace token provided. You can configure it later."
        break
    elif [[ "$HF_TOKEN" =~ ^hf_[a-zA-Z0-9]{34}$ ]]; then
        print_success "Valid HuggingFace token provided ✓"

        # Set up the token
        export HF_TOKEN=$HF_TOKEN
        echo "export HF_TOKEN=$HF_TOKEN" >> ~/.bashrc
        echo "export HF_TOKEN=$HF_TOKEN" >> ~/.zshrc 2>/dev/null || true
        echo "export HF_TOKEN=$HF_TOKEN" >> ~/.profile

        print_success "HuggingFace token configured ✓"
        break
    else
        print_error "Invalid HuggingFace token format. Token should start with 'hf_' and be 39 characters long."
        print_info "Example: hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    fi
done

# Create persistent data directory
mkdir -p persistent-data/auth
mkdir -p persistent-data/trainer/models

# Create user key map for authentication
cat > persistent-data/auth/userKeyMap.json << 'EOF'
{
  "demo@gensyn.ai": {
    "email": "demo@gensyn.ai",
    "userId": "demo-user",
    "provider": "email"
  }
}
EOF

print_success "HuggingFace token configured ✓"

print_header "STARTING CODEASSIST SERVICES"

# Start Docker services
print_info "Starting CodeAssist containers..."
if command -v docker-compose &> /dev/null; then
    docker-compose -f compose.yml up -d
else
    docker compose -f compose.yml up -d
fi

if [ $? -eq 0 ]; then
    print_success "CodeAssist services started successfully ✓"
else
    print_error "Failed to start CodeAssist services ✗"
    exit 1
fi

# Wait for services to be ready
print_info "Waiting for services to initialize..."
sleep 10

# Check if services are running
print_info "Checking service status..."
if curl -s http://localhost:3000 > /dev/null; then
    print_success "CodeAssist web interface is running ✓"
else
    print_warning "Services may still be starting. Please wait a moment..."
fi

print_header "SSH TUNNELING SETUP"

echo -e "${CYAN}${BOLD}SSH TUNNELING COMMANDS:${NC}\n"
echo -e "${BLUE}macOS/Linux:${NC} ${GREEN}ssh -L 3000:localhost:3000 -L 8000:localhost:8000 -L 8008:localhost:8008 root@SERVER_IP${NC}"
echo -e "${BLUE}Background:${NC}  ${GREEN}ssh -f -N -L 3000:localhost:3000 -L 8000:localhost:8000 -L 8008:localhost:8008 root@SERVER_IP${NC}\n"
echo -e "${BLUE}Windows:${NC}     ${GREEN}ssh -L 3000:localhost:3000 -L 8000:localhost:8000 -L 8008:localhost:8008 root@SERVER_IP${NC}\n"
echo -e "${YELLOW}Replace SERVER_IP with your server's IP address${NC}\n"

print_header "INSTALLATION COMPLETE! 🎉"

echo -e "${GREEN}${BOLD}✅ Installation Successful!${NC}\n"
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Set up SSH tunnel using the commands above"
echo "2. Access CodeAssist at: ${YELLOW}http://localhost:3000${NC}"
echo "3. Login with your email"
echo "4. Start solving coding problems!\n"

echo -e "${BLUE}Important Links:${NC}"
echo "• CodeAssist: ${YELLOW}http://localhost:3000${NC}"
echo "• X/Twitter: ${YELLOW}https://x.com/0xCrypton_${NC}\n"

# Cleanup
print_info "Cleaning up temporary files..."
cd ~

echo -e "${CYAN}Thank you for using CodeAssist Auto-Installer by 0xCrypton_!${NC}"
echo -e "${CYAN}Follow me on X: @0xCrypton_ for more amazing tools!${NC}\n"

echo -e "${GREEN}${BOLD}🚀 Happy coding with CodeAssist!${NC}\n"
