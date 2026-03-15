#!/bin/bash

# ===================== CONFIG =====================
# Auto-detect latest code-server release for ARM64
CS_URL=$(curl -s https://api.github.com/repos/coder/code-server/releases/latest \
  | grep browser_download_url | grep linux-arm64.tar.gz | cut -d '"' -f 4)

CS_FILE=$(basename "$CS_URL")
CS_DIR="${CS_FILE%.tar.gz}"

PASSWORD="zohir530"

HOME_DIR="/data/data/com.termux/files/home"
BIN_DIR="/data/data/com.termux/files/usr/bin"
MENU_FILE="$HOME_DIR/zohir"
LAUNCHER="$BIN_DIR/vscode"
# =================================================

# ===================== COLORS =====================
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[1;35m'
RED='\033[0;31m'
NC='\033[0m'

bold() { echo -e "\033[1m$1\033[0m"; }

progress_bar() {
    local duration=$1
    local text=$2
    local command=$3
    local width=30

    printf "\n%s\n" "$(bold "$text")"
    for i in $(seq 0 100); do
        local filled=$((i * width / 100))
        printf "\r\033[K[%-*s] %3d%%" "$width" "$(printf "%0.s█" $(seq 1 $filled))" "$i"
        sleep "$duration"
    done
    echo
    eval "$command" || echo -e "${YELLOW}⚠ Skipped / already done${NC}"
    echo -e "${GREEN}✔ Done${NC}\n"
}

# ===================== WELCOME =====================
clear
echo -e "${CYAN}"
bold "Welcome to ${MAGENTA}z0h1x${CYAN} Code Server Installer"
echo -e "${YELLOW}Latest Code-Server URL: ${CS_URL}${NC}\n"
bold "INSTALLING...\n"

# ===================== TERMUX DEPS =====================
if command -v proot-distro &>/dev/null; then
    echo -e "${GREEN}✔ proot-distro already installed${NC}\n"
else
    progress_bar 0.01 "Installing proot-distro" "pkg install -y proot-distro"
fi

if command -v dialog &>/dev/null; then
    echo -e "${GREEN}✔ dialog already installed${NC}\n"
else
    progress_bar 0.01 "Installing dialog" "pkg install -y dialog"
fi

# ===================== UBUNTU =====================
echo -e "${CYAN}Checking Ubuntu installation...${NC}"
if proot-distro list --installed 2>/dev/null | grep -qx "ubuntu"; then
    echo -e "${GREEN}✔ Ubuntu already installed — skipping${NC}\n"
else
    progress_bar 0.01 "Installing Ubuntu" "proot-distro install ubuntu"
fi

# ===================== DOWNLOAD & EXTRACT CODE SERVER =====================
progress_bar 0.01 "Downloading Code Server" "
cd \$HOME &&
if [ ! -d \"$CS_DIR\" ]; then
    wget -q \"$CS_URL\" &&
    tar --no-hard-links -xf \"$CS_FILE\" &&
    rm \"$CS_FILE\" &&
    chmod +x \"$CS_DIR/bin/code-server\"
else
    echo 'Code-server already exists'
fi
"

# ===================== UBUNTU DEPENDENCIES =====================
progress_bar 0.01 "Preparing Ubuntu environment" "
proot-distro login ubuntu -- bash -c '
apt update -y
apt upgrade -y
apt install -y wget tar curl jq gzip
'
"

# ===================== INSTALL GITHUB COPILOT =====================
proot-distro login ubuntu -- bash -c "
cd ~/$CS_DIR/bin
curl -fsSL https://raw.githubusercontent.com/sunpix/howto-install-copilot-in-code-server/refs/heads/main/install-copilot.sh | bash
"

# ===================== MENU SCRIPT =====================
cat > "$MENU_FILE" << EOF
#!/bin/bash

CS_DIR="$CS_DIR"
PASSWORD="$PASSWORD"

RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[0;33m'
BLUE='\\033[0;34m'
CYAN='\\033[0;36m'
NC='\\033[0m'

center_text() {
    local w=\$(tput cols)
    while IFS= read -r line; do
        printf "%*s%s\n" \$(((w-\${#line})/2)) "" "\$line"
    done
}

banner='
███████╗░█████╗░██╗░░██╗░░███╗░░██╗░░██╗
╚════██║██╔══██╗██║░░██║░████║░░╚██╗██╔╝
░░███╔═╝██║░░██║███████║██╔██║░░░╚███╔╝░
██╔══╝░░██║░░██║██╔══██║╚═╝██║░░░██╔██╗░
███████╗╚█████╔╝██║░░██║███████╗██╔╝╚██╗
╚══════╝░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝
'

while true; do
    clear
    echo -e "\${CYAN}"
    echo "\$banner" | center_text
    echo -e "\${NC}"

    choice=\$(dialog --stdout --menu "z0h1x Control Panel" 15 60 6 \
        1 "Start Code Server" \
        2 "Debug Mode (Verbose)" \
        3 "Stop Code Server" \
        4 "Exit")

    case \$choice in
        1)
            clear
            echo -e "\${YELLOW}Starting Code Server...\${NC}"
            proot-distro login ubuntu -- bash -c "
cd ~/\$CS_DIR/bin
export PASSWORD=\$PASSWORD
nohup ./code-server > ~/code-server.log 2>&1 &
"
            echo -e "\${GREEN}Running → http://localhost:8080\${NC}"
            read -p 'Press Enter...'
            ;;
        2)
            clear
            echo -e "\${BLUE}Debug Mode (Ctrl+C to stop)\${NC}"
            proot-distro login ubuntu -- bash -c "
cd ~/\$CS_DIR/bin
export PASSWORD=\$PASSWORD
./code-server
"
            ;;
        3)
            clear
            echo -e "\${RED}Stopping Code Server...\${NC}"
            proot-distro login ubuntu -- pkill -f code-server || true
            echo "Stopped (if running)."
            read -p 'Press Enter...'
            ;;
        4)
            clear
            exit 0
            ;;
    esac
done
EOF

chmod +x "$MENU_FILE"

# ===================== LAUNCHER =====================
cat > "$LAUNCHER" << EOF
#!/bin/bash
bash "$MENU_FILE"
EOF

chmod +x "$LAUNCHER"

bold "\n✅ Installation complete!"
echo -e "${GREEN}Type 'vscode' to open the control panel.${NC}\n"
