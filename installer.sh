#!/bin/bash

# ===================== COLORS =====================
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

bold() { echo -e "\033[1m$1\033[0m"; }

# ===================== TERMUX DEPENDENCIES =====================
clear
bold "Installing essential packages... Please watch the process!"
sleep 3
pkg update -y
pkg upgrade -y
pkg install -y wget tar dialog git nodejs python clang make pkg-config openssl curl unzip jq gzip tur-repo code-server

# ===================== RUN COPILOT INSTALL =====================
clear
sleep 3
bold "\nRunning Copilot setup..."
curl -fsSL https://raw.githubusercontent.com/sunpix/howto-install-copilot-in-code-server/refs/heads/main/install-copilot.sh | bash

# ===================== FINAL MESSAGE =====================
echo -e "${GREEN}✔ Installation complete!${NC}"
echo -e "${RED}⚠️ Remember to change your password in:${NC} ${YELLOW}/data/data/com.termux/files/home/.config/code-server/config.yaml${NC}"
echo -e "${GREEN}Run ${CYAN}code-server${GREEN} to start your server.${NC}"
