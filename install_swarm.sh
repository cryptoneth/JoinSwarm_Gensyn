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

echo -e "\e[1;31mJOIN SWARM NOW\e[0m"

# Ask if following Twitter
echo "Do you follow Crypton on Twitter? https://x.com/0xCrypton_"
read -p "Press y if you followed: " follow
if [ "$follow" != "y" ] && [ "$follow" != "Y" ]; then
    echo "Please follow and try again."
    exit 1
fi

# Ask for new install or restart
read -p "New install or restart stopped one? (1 for new, 2 for restart): " choice
if [ "$choice" != "1" ] && [ "$choice" != "2" ]; then
    echo "Invalid choice. Please enter 1 or 2."
    exit 1
fi

# Robust cleanup of any existing swarm screen session
echo "Checking for existing swarm screen session..."
screen -wipe  # Wipe detached sessions
if screen -list | grep -q "swarm"; then
    echo "Existing swarm session found. Closing it..."
    screen -S swarm -X quit
    sleep 2
    # Force kill if still exists
    if screen -list | grep -q "swarm"; then
        echo "Force killing remaining swarm session..."
        pkill -f "SCREEN -S swarm"
        sleep 2
    fi
fi

if [ "$choice" = "1" ]; then
    echo "Starting new install. Cleaning up previous files..."
    # Clean up rl-swarm directory if exists - ensure it's fully removed
    if [ -d "rl-swarm" ]; then
        echo "Removing previous rl-swarm directory..."
        rm -rf rl-swarm
        # Double-check removal
        if [ -d "rl-swarm" ]; then
            echo "Warning: rl-swarm directory still exists after removal attempt."
        else
            echo "rl-swarm directory removed successfully."
        fi
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

    # Install Docker
    echo "Installing Docker..."
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg lsb-release -y
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    sudo systemctl start docker
    sudo systemctl enable docker

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

else
    echo "Restarting stopped install..."
    if [ ! -d "rl-swarm" ]; then
        echo "rl-swarm directory not found. Please run new install first."
        exit 1
    fi
    cd rl-swarm || exit

    # Create screen session
    echo "Creating screen session 'swarm'..."
    screen -dmS swarm

    # Execute commands inside screen (activate venv)
    screen -S swarm -X stuff "cd $(pwd)\n"
    screen -S swarm -X stuff "source .venv/bin/activate || . .venv/bin/activate\n"

    # No need to edit config again, assuming it's already done

fi

# Common part: Run docker inside screen
screen -S swarm -X stuff "docker compose run --rm --build -Pit swarm-cpu\n"

# Enable logging for screen to monitor output
screen -S swarm -X logfile /tmp/swarm.log
screen -S swarm -X log

# Wait for Docker to build and server to start listening on port 3000 with timeout
echo "Please wait... Docker is building and installing. This may take a few minutes until the server is ready for login."
timeout=30  # 5 minutes timeout (300 seconds / 10)
counter=0
while ! ss -tlnp | grep -q :3000; do
    if [ $counter -ge $timeout ]; then
        echo "Timeout reached. Server not ready. Check screen logs: screen -r swarm"
        exit 1
    fi
    echo "Checking... Server not ready yet. Please wait... ($((counter * 10))s elapsed)"
    sleep 10
    counter=$((counter + 1))
done
echo "Server ready! Now setting up the tunnel."

# Now, outside screen, set up localtunnel
echo "Setting up localtunnel..."

# Install localtunnel if not already
if ! command -v lt &> /dev/null; then
    sudo npm install -g localtunnel
fi

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

# Function to wait for a specific prompt in screen log and get user input
wait_for_prompt() {
  local prompt_pattern="$1"
  local user_prompt="$2"
  local response
  echo "Waiting for prompt: $user_prompt"
  while true; do
    if tail -n 50 /tmp/swarm.log | grep -q "$prompt_pattern"; then
      echo "$user_prompt"
      read -p "Enter your response (press Enter for default): " response
      if [ -z "$response" ]; then
        screen -S swarm -X stuff "\n"
      else
        screen -S swarm -X stuff "$response\n"
      fi
      break
    fi
    sleep 2
  done
}

# Handle interactive prompts after login
echo "Login complete. Handling interactive prompts..."

# First prompt: Hugging Face push
wait_for_prompt "push models you train in the RL swarm to the Hugging Face Hub" ">> Would you like to push models to Hugging Face Hub? [y/N]"

# Second prompt: Model name
wait_for_prompt "Enter the name of the model you want to use in huggingface repo/name format" ">> Enter model name (or Enter for default):"

# Third prompt: AI Prediction Market
wait_for_prompt "your model to participate in the AI Prediction Market" ">> Participate in AI Prediction Market? [Y/n]"

# Wait for node to be fully ready by checking for Hello line in log
echo "Waiting for node to be fully ready..."
while ! tail -n 100 /tmp/swarm.log | grep -q '🐱 Hello 🐈 \[.*\] 🦮 \[.*\]!'; do
    echo "Node not ready yet. Waiting..."
    sleep 10
done
echo "Node ready! Displaying information."

# Display userdata.json and node info
echo "Installation complete."
echo "Userdata.json content:"
cat "$(pwd)/userdata.json"

# Capture node info from screen log
tail -n 100 /tmp/swarm.log > node_info.txt

# Extract and display the specific Hello line
hello_line=$(grep -o '🐱 Hello 🐈 \[.*\] 🦮 \[.*\]!' node_info.txt | tail -1)
if [ -n "$hello_line" ]; then
    echo "Node Hello Info:"
    echo "$hello_line"
else
    echo "Node Hello Info not found. Check screen manually."
    tail -n 50 node_info.txt
fi

echo "You can manage the screen session with: screen -r swarm"
echo "All done! Goodbye!"
