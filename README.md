markdown

# Join Swarm Now

## Follow Us First!
Before getting started, make sure to follow the official accounts for updates and support:

- **Crypton**: [@0xCrypton_](https://x.com/0xCrypton_)
- **Gensyn AI (Official)**: [@gensynai](https://x.com/gensynai)

This setup guide will help you join the Gensyn Swarm network using a one-click automated script for Ubuntu servers. It's designed for ease—perfect for VPS users!

## Prerequisites
- A fresh Ubuntu server (20.04 or 22.04 LTS recommended) with SSH access.
- Root or sudo privileges.
- At least 4GB RAM, 20GB disk space, and internet access.
- (Optional) GPU for better performance—install NVIDIA drivers/CUDA separately if needed.

## Step-by-Step Installation

### Update the System
Run these commands to ensure your packages are up to date:

```bash
sudo apt update && sudo apt upgrade -y

Install Git (if not already installed)bash

sudo apt install git -y

Clone the RepositoryClone your GitHub repo to the server:bash

git clone https://github.com/cryptoneth/JoinSwarm_Gensyn.git

Navigate to the Repository DirectoryChange into the cloned directory (adjust if your main branch has a subfolder):bash

cd JoinSwarm_Gensyn

Make the Script ExecutableAssuming the script file is named install_swarm.sh (replace with the actual filename if different):bash

chmod +x install_swarm.sh

Run the ScriptExecute the script:bash

./install_swarm.sh

The script will display a logo and "JOIN SWARM NOW".
It will prompt if you've followed the Twitter account (press y to proceed).
It automates everything: dependencies, Docker, repo cloning, config edits, screen session, localtunnel for login, and model selection (uses Gensyn/Qwen2.5-0.5B-Instruct by default).
Once complete, it shows your userdata.json and unique Node Hello Info (e.g.,  Hello  [your-node-name]  [your-peer-id]!).
The process takes 10-30 minutes.Managing Your Swarm NodeAttach to the persistent screen session: screen -r swarm
Detach: Press Ctrl + A then D
Stop: Attach and press Ctrl + C (use cautiously)

