#!/bin/bash

# Display logo and title
echo -e "\e[33m"
cat << "EOF"
   ___           _    _             _
  / __\ __ __ _| | _| |_ ___  _ __| |_ ___  _ __
 / /  | '__/ _` | |/ / __/ _ \| '__| __/ _ \| '_ \
/ /___| | | (_| |   <| || (_) | |  | || (_) | | | |
\____/|_|  \__,_|_|\_\\__\___/|_|   \__\___/|_| |_|

With Bee Logo: 🐝
EOF
echo -e "\e[0m"

echo -e "\e[1;31mJOIN SWARM NOW\e[0m"

# Ask if following Twitter
echo "Do you follow Crypton on Twitter? https://x.com/0xCrypton_"
read -p "Press y if you followed: " follow
if [ "$follow" != "y" ] && [ "$follow" != "Y" ]; then
    echo "Please follow and try again."
    exit 1
fi

# Step 1: Install Dependencies
echo "Installing dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y
sudo apt install python3 python3-pip python3-venv python3-dev -y
sudo apt update
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -
sudo apt install -y nodejs
node -v
npm install -g yarn
yarn -v
curl -o- -L https://yarnpkg.com/install.sh | bash
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
source ~/.bashrc

# Install Docker before creating screen
echo "Installing Docker..."
sudo apt update -y && sudo apt upgrade -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Step 2: Clone Repository
echo "Cloning repository..."
git clone https://github.com/gensyn-ai/rl-swarm/
cd rl-swarm || exit

# Create screen session
echo "Creating screen session 'swarm'..."
screen -dmS swarm

# Execute commands inside screen
screen -S swarm -X stuff "cd $(pwd)\n"
screen -S swarm -X stuff "python3 -m venv .venv\n"
screen -S swarm -X stuff "source .venv/bin/activate || . .venv/bin/activate\n"

# Automatically edit the config file using sed
echo "Editing config file automatically..."
config_file="/root/rl-swarm/rgym_exp/config/rg-swarm.yaml"
if [ -f "$config_file" ]; then
    sed -i 's/num_train_samples: .*/num_train_samples: 1/' "$config_file"
    sed -i 's/startup_timeout: .*/startup_timeout: 180/' "$config_file"
else
    # If file not in /root, assume current dir
    config_file="$(pwd)/rgym_exp/config/rg-swarm.yaml"
    sed -i 's/num_train_samples: .*/num_train_samples: 1/' "$config_file"
    sed -i 's/startup_timeout: .*/startup_timeout: 180/' "$config_file"
fi

# Run docker inside screen
screen -S swarm -X stuff "docker compose run --rm --build -Pit swarm-cpu\n"

# Now, outside screen, set up localtunnel
echo "Setting up localtunnel..."

# Install localtunnel
sudo npm install -g localtunnel

# Get password (VPS IP)
password=$(curl https://loca.lt/mytunnelpassword)
echo "Your tunnel password is: $password (which is your VPS IP)"

# Run localtunnel and get URL
lt --port 3000 > lt_output.log 2>&1 &
lt_pid=$!

# Wait a bit for URL to appear
sleep 5
url=$(grep -o 'https://[^ ]*' lt_output.log | head -1)
echo "Your tunnel URL is: $url"
echo "Go to this URL and login."

# Wait for login to complete by checking for userdata.json
echo "Waiting for login to complete..."
while [ ! -f "$(pwd)/userdata.json" ]; do
    sleep 10
done
echo "Login detected! userdata.json created."

# Automate answers to questions inside screen
# Assuming typical questions; adjust based on exact prompts if known
# For example:
screen -S swarm -X stuff "n\n"  # e.g., no to Hugging Face
screen -S swarm -X stuff "y\n"  # yes to proceed
# Add more as needed for complete automation

# Wait for installation to complete (adjust time as needed)
sleep 60

# Display userdata.json and node info
echo "Installation complete."
echo "Userdata.json content:"
cat "$(pwd)/userdata.json"

# Capture node info from screen (assuming it's logged)
screen -S swarm -X hardcopy node_info.txt
echo "Node info:"
cat node_info.txt

echo "You can manage the screen session with: screen -r swarm"
