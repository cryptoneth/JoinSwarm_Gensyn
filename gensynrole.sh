#!/usr/bin/env bash

# Colors
CYAN='\033[0;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

# ===============================
# BANNER
# ===============================
echo -e "${PURPLE}${BOLD}"
cat << "EOF"
_________                        __                 
\_   ___ \_______ ___.__._______/  |_  ____   ____  
/    \  \/\_  __ <   |  |\____ \   __\/  _ \ /    \ 
\     \____|  | \/\___  ||  |_> >  | (  <_> )   |  \
 \______  /|__|   / ____||   __/|__|  \____/|___|  /
        \/        \/     |__|                    \/

${YELLOW}                      :: Powered by Crypton :: 
${NC}
EOF

# === CONFIG ===
GO_VERSION="1.24.5"
GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"
GO_URL="https://golang.org/dl/${GO_TARBALL}"
GO_INSTALL_DIR="/usr/local"
CONFIG_PATH="telegram-config.json"
API_URL="https://gswarm.dev/api"

set -e

echo -e "${GREEN}📦 Crypton Swarm Full One-Click Installer${NC}"

# === Install jq ===
if ! command -v jq >/dev/null 2>&1; then
  echo -e "${BLUE}🔧 Installing jq...${NC}"
  sudo apt update -y
  sudo apt install -y jq
else
  echo -e "${GREEN}✅ jq is already installed${NC}"
fi

# === Go Version Check & Install ===
function install_go {
  echo -e "${BLUE}⬇️ Installing Go $GO_VERSION...${NC}"
  curl -LO "$GO_URL"
  sudo rm -rf ${GO_INSTALL_DIR}/go
  sudo tar -C ${GO_INSTALL_DIR} -xzf "$GO_TARBALL"
  rm "$GO_TARBALL"

  export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
  echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> "$HOME/.bashrc"
  echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> "$HOME/.profile"

  echo -e "${GREEN}✅ Go installed: $(/usr/local/go/bin/go version)${NC}"
}

function version_lt() {
  [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$2" ]
}

if command -v go >/dev/null 2>&1; then
  INSTALLED_GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
  echo -e "${CYAN}🔍 Detected Go version: $INSTALLED_GO_VERSION${NC}"
  if version_lt "$INSTALLED_GO_VERSION" "$GO_VERSION"; then
    echo -e "${YELLOW}⚠️ Go version is less than $GO_VERSION. Replacing...${NC}"
    sudo rm -rf "$GO_INSTALL_DIR/go"
    rm -rf "$HOME/go"
    install_go
  else
    echo -e "${GREEN}✅ Go version is sufficient.${NC}"
  fi
else
  install_go
fi

# Source updated PATH
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# === Install GSwarm ===
echo -e "${BLUE}⬇️ Installing GSwarm CLI...${NC}"
go install github.com/Deep-Commit/gswarm/cmd/gswarm@latest
echo -e "${GREEN}✅ GSwarm installed at: $(which gswarm)${NC}"

# === Telegram Bot Setup ===
echo
echo -e "${PURPLE}🤖 Telegram Bot Setup:${NC}"
echo "1. Open Telegram and search @BotFather"
echo "2. Send /newbot and follow the steps"
echo "3. Copy the bot token (format: 123456:ABC-DEF...)"
echo
read -p "Paste your bot token here: " BOT_TOKEN

echo
echo -e "${CYAN}📨 Now send any message to your bot in Telegram.${NC}"
read -p "Press Enter after sending the message..."

echo -e "${BLUE}📡 Fetching your chat ID...${NC}"
CHAT_ID=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates" \
  | jq -r '.result[-1].message.chat.id')

if [[ -z "$CHAT_ID" || "$CHAT_ID" == "null" ]]; then
  echo -e "${RED}❌ Failed to retrieve chat ID. Did you message the bot first?${NC}"
  exit 1
fi

mkdir -p "$(dirname "$CONFIG_PATH")"

cat > "$CONFIG_PATH" <<EOF
{
  "bot_token": "$BOT_TOKEN",
  "chat_id": "$CHAT_ID",
  "welcome_sent": true,
  "api_url": "$API_URL"
}
EOF

echo -e "${GREEN}✅ Configuration saved to $CONFIG_PATH${NC}"

# === Run GSwarm ===
echo
echo -e "${GREEN}🚀 Starting GSwarm monitor...${NC}"
gswarm
