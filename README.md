# Join Swarm Now

## Follow Us First!
Before getting started, make sure to follow the official accounts for updates and support:

- **Crypton**: [@0xCrypton_](https://x.com/0xCrypton_)
- **Gensyn AI (Official)**: [@gensynai](https://x.com/gensynai)

This setup guide will help you join the Gensyn Swarm network using a one-click automated script for Ubuntu servers. It's designed for ease perfect for VPS users!

## Step-by-Step Installation

Video :

### Update the System
Run these commands to ensure your packages are up to date:

```bash

cd

rm -r JoinSwarm_Gensyn

sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/lib/dpkg/lock
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock

sudo dpkg --configure -a
sudo apt update

sudo apt update && sudo apt upgrade -y

sudo apt install git -y

git clone https://github.com/cryptoneth/JoinSwarm_Gensyn.git

cd JoinSwarm_Gensyn

chmod +x install_swarm.sh

./install_swarm.sh

```

The process takes 10-30 minutes.Managing Your Swarm NodeAttach to the persistent screen session: screen -r swarm

Detach: Press Ctrl + A then D

Stop: Attach and press Ctrl + C (use cautiously)


# SwarmRole

Video : 



```bash

bash <(curl -sL https://raw.githubusercontent.com/CodeDialect/gswarm-role/main/gswarm.sh)

```

Gensyn Dashboard : https://dashboard.gensyn.ai/

Write Your EOA


# Enjoy Being SWARM, gSWARM

