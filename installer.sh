#!/bin/bash

# ===================== COLORS =====================
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

bold() { echo -e "\033[1m$1\033[0m"; }

# ===================== TERMUX DEPENDENCIES =====================
bold "Installing essential packages... Please watch the process!"
pkg update -y
pkg upgrade -y
pkg install -y wget tar dialog git nodejs python clang make pkg-config openssl curl unzip jq tur-repo code-server

echo -e "${GREEN}✔ Installation complete!${NC}"
echo -e "${RED}⚠️ Remember to change your password in:${NC} ${YELLOW}/data/data/com.termux/files/home/.config/code-server/config.yaml${NC}"
echo -e "${GREEN}Run ${CYAN}code-server${GREEN} to start your server.${NC}"
