# Join Swarm Now

## Follow Us First!
Before getting started, make sure to follow the official accounts for updates and support:

- **Crypton**: [@0xCrypton_](https://x.com/0xCrypton_)
- **Gensyn AI (Official)**: [@gensynai](https://x.com/gensynai)

This setup guide will help you join the Gensyn Swarm network using a one-click automated script for Ubuntu servers. It's designed for ease perfect for VPS users!

## Step-by-Step Installation

Video :  https://x.com/0xCrypton_/status/1977739674396524821

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

Video : https://x.com/0xCrypton_/status/1977739674396524821



```bash

bash <(curl -sL https://raw.githubusercontent.com/CodeDialect/gswarm-role/main/gswarm.sh)

```

Gensyn Dashboard : https://dashboard.gensyn.ai/

Write Your EOA

===============================================

# BlockAssist For ***JUST FOR MAC USERS

VIDEO : https://x.com/0xCrypton_/status/1978421790239346884

1 - install xcode on your mac if you didn't 

```bash

xcode-select --install

```

2 - now run the script

```bash

git clone https://github.com/cryptoneth/JoinSwarm_Gensyn.git

cd JoinSwarm_Gensyn

chmod +x blockassist.sh

./blockassist.sh

```

3 - get your huggingface token 

https://huggingface.co/settings/tokens


4 - Start

```bash
cd
cd blockassist
pyenv exec python run.py

```

4 - watch the video to continue

====================================================

# CodeAssist 

1 - get your huggingface token 

https://huggingface.co/settings/tokens

2 - now run the script

```bash

cd 
rm -r JoinSwarm_Gensyn
rm -r codeassist
screen -X Codeassist -S quit

git clone https://github.com/cryptoneth/JoinSwarm_Gensyn.git

cd JoinSwarm_Gensyn

chmod +x codeassist_installer.sh
./codeassist_installer.sh
```

now head to screen and wait till installation proccess finish.

```
screen -r Codeassist

cd codeassist
uv run run.py

```

After just Copy Your SSH Code and use it in your windows/mac terminal

then go to http://localhost:3000

solve the problems

then go back to screen and submit your solutions via crtl+C

Check your participation on https://dashboard.gensyn.ai

# Enjoy Being SWARM, gSWARM

====================================================







