#!/bin/bash

# ===================== CONFIG =====================
HOME_DIR="$HOME"
BIN_DIR="/data/data/com.termux/files/usr/bin"
INSTALL_DIR="$HOME/.code-server"
MENU_FILE="$HOME_DIR/zohir"
LAUNCHER="$BIN_DIR/vscode"
PASSWORD="zohir530"
# =================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[1;35m'
RED='\033[0;31m'
NC='\033[0m'

bold() { echo -e "\033[1m$1\033[0m"; }

# ===================== SPINNER FUNCTION =====================
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    echo -n " "
    while kill -0 $pid 2>/dev/null; do
        for i in $(seq 0 3); do
            printf "\b${spinstr:i:1}"
            sleep $delay
        done
    done
    printf "\b"
}

run_with_spinner() {
    local cmd="$1"
    bash -c "$cmd" &
    local pid=$!
    spinner $pid
    wait $pid
}

# ===================== WELCOME =====================
clear
echo -e "${CYAN}"
bold "Welcome to ${MAGENTA}z0h1x${CYAN} Code Server Installer"
echo -e "${YELLOW}Auto-update enabled${NC}\n"
bold "INSTALLING / UPDATING...\n"

# ===================== TERMUX DEPENDENCIES =====================
echo -e "${YELLOW}Installing essential packages...${NC}"
run_with_spinner "pkg update -y && pkg upgrade -y && pkg install -y wget tar dialog git nodejs python clang make pkg-config openssl curl unzip jq"

# ===================== AUTO-CHECK LATEST CODE-SERVER =====================
echo -e "${YELLOW}Checking latest Code-Server version...${NC}"
CS_VERSION=$(curl -s https://api.github.com/repos/coder/code-server/releases/latest | jq -r '.tag_name' | sed 's/v//')
CS_DIR="code-server-${CS_VERSION}-linux-arm64"
CS_URL="https://github.com/coder/code-server/releases/download/v${CS_VERSION}/${CS_DIR}.tar.gz"
bold "Latest version: ${CS_VERSION}"

# ===================== CREATE INSTALL FOLDER =====================
echo -e "${YELLOW}Creating Code-Server folder...${NC}"
mkdir -p $INSTALL_DIR

# ===================== DOWNLOAD / UPDATE CODE SERVER =====================
echo -e "${YELLOW}Downloading / Updating Code-Server...${NC}"
cd $INSTALL_DIR
if [ ! -d "$CS_DIR" ]; then
    run_with_spinner "wget -q \"$CS_URL\" -O \"$CS_DIR.tar.gz\""
    tar -xzf "$CS_DIR.tar.gz" --hard-dereference --warning=no-unknown-keyword || true
else
    echo "Code-server already installed. Updating..."
    rm -rf $CS_DIR
    run_with_spinner "wget -q \"$CS_URL\" -O \"$CS_DIR.tar.gz\""
    tar -xzf "$CS_DIR.tar.gz" --hard-dereference --warning=no-unknown-keyword || true
fi

# ===================== MENU SCRIPT =====================
cat > "$MENU_FILE" << EOF
#!/bin/bash

CS_DIR="$INSTALL_DIR/$CS_DIR"
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
            cd "\$CS_DIR/bin"
            export PASSWORD=\$PASSWORD
            nohup ./code-server > ~/code-server.log 2>&1 &
            echo -e "\${GREEN}Running → http://localhost:8080\${NC}"
            read -p 'Press Enter...'
            ;;
        2)
            clear
            echo -e "\${BLUE}Debug Mode (Press Ctrl+C to stop)...${NC}"
            cd "\$CS_DIR/bin"
            export PASSWORD=\$PASSWORD
            ./code-server
            echo -e "\${GREEN}Code-Server stopped.${NC}"
            read -p "Press Enter to return to menu..."
            ;;
        3)
            clear
            echo -e "\${RED}Stopping Code Server...\${NC}"
            pkill -f code-server || true
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

bold "\n✅ Installation / Update complete!"
echo -e "${GREEN}Type 'vscode' to open the control panel.${NC}\n"
