#!/bin/bash

# Display the logo using heredoc to avoid escaping issues
cat << 'EOF'
_________                        __                 
\_   ___ \_______ ___.__._______/  |_  ____   ____  
/    \  \/\_  __ <   |  |\____ \   __\/  _ \ /    \ 
\     \____|  | \/\___  ||  |_> >  | (  <_> )   |  \
 \______  /|__|   / ____||   __/|__|  \____/|___|  /
        \/        \/     |__|                    \/
EOF

# Suggest following Twitter and ask confirmation
echo "Please follow me on X (Twitter) for updates: https://x.com/0xCrypton_"
read -p "Have you followed? (y/n): " followed
if [ "$followed" != "y" ]; then
    echo "No problem, continuing anyway..."
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Install Homebrew if not installed
if ! command_exists brew; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ $? -ne 0 ]; then
        echo "Homebrew installation failed. Please check your internet connection or permissions."
        exit 1
    fi
    echo "Homebrew installed successfully."
    # Follow Homebrew's post-install instructions automatically
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
    eval "$(/opt/homebrew/bin/brew shellenv)"
    # Reload shell
    source ~/.zshrc || source ~/.bash_profile
    # Verify installation
    if ! command_exists brew; then
        echo "Homebrew PATH not updated. Please restart your terminal and run this script again."
        exit 1
    fi
else
    echo "Homebrew is already installed. Updating..."
    brew update
fi

# Step 2: Clone the repo if not exists
REPO_DIR="$HOME/blockassist"
if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning the BlockAssist repo..."
    git clone https://github.com/gensyn-ai/blockassist.git "$REPO_DIR"
else
    echo "Repo already cloned. Pulling latest changes..."
    cd "$REPO_DIR"
    git pull
fi

# Change to the repo directory
cd "$REPO_DIR" || exit

# Step 3: Run setup.sh for Java installation
echo "Running setup.sh to install Java 1.8..."
./setup.sh
read -p "Java installation may require downloads or approvals. Did it complete successfully? (y/n): " java_done
while [ "$java_done" != "y" ]; do
    echo "Re-running setup.sh..."
    ./setup.sh
    read -p "Did it complete now? (y/n): " java_done
done

# Step 4: Install pyenv if not installed
if ! command_exists pyenv; then
    echo "Installing pyenv..."
    brew install pyenv
    # Initialize pyenv
    echo 'eval "$(pyenv init -)"' >> ~/.zshrc
    source ~/.zshrc
else
    echo "pyenv is already installed."
fi

# Step 5: Install Python 3.10
if ! pyenv versions | grep -q "3.10"; then
    echo "Installing Python 3.10..."
    pyenv install 3.10
else
    echo "Python 3.10 is already installed."
fi

# Set local Python version
pyenv local 3.10

# Step 6: Install required Python packages
echo "Installing psutil, readchar, and rich..."
pyenv exec pip install psutil readchar rich

# Step 7: Install Node.js if not installed
if ! command_exists node; then
    echo "Installing Node.js..."
    brew install node
else
    echo "Node.js is already installed. Version: $(node --version)"
fi

# Step 8: Install Yarn if not installed
if ! command_exists yarn; then
    echo "Installing Yarn..."
    npm install -g yarn
else
    echo "Yarn is already installed. Version: $(yarn --version)"
fi

# Step 9: Clear port 3000 if occupied
echo "Checking and clearing port 3000..."
PORT_PID=$(lsof -i :3000 -t 2>/dev/null)
if [ ! -z "$PORT_PID" ]; then
    echo "Killing process on port 3000 (PID: $PORT_PID)..."
    kill -9 "$PORT_PID" 2>/dev/null
else
    echo "Port 3000 is free."
fi

# Step 10: Flush DNS cache (common fix for localhost issues)
echo "Flushing DNS cache..."
sudo dscacheutil -flushcache 2>/dev/null
sudo killall -HUP mDNSResponder 2>/dev/null || true

# Final Step: Run the program
echo "All setup complete! Starting BlockAssist... Follow any prompts for Hugging Face token, login, etc."
pyenv exec python run.py
