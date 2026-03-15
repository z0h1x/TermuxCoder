#!/bin/bash

# ===================== COLORS =====================
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
    bash -c "$cmd" >/dev/null 2>&1 &
    local pid=$!
    spinner $pid
    wait $pid
}

# ===================== TERMUX DEPENDENCIES =====================
bold "Installing essential packages..."
run_with_spinner "pkg update -y && pkg upgrade -y && pkg install -y wget tar dialog git nodejs python clang make pkg-config openssl curl unzip jq tur-repo code-server"
echo -e "${GREEN}✔ Done!${NC}"

# ===================== PATHS =====================
CS_BIN="$PREFIX/share/code-server/bin"
MENU_FILE="$HOME/zohir"
LAUNCHER="$PREFIX/bin/vscode"

# ===================== CREATE MENU =====================
cat > "$MENU_FILE" << 'EOF'
#!/bin/bash

CS_BIN="$PREFIX/share/code-server/bin"
PASSWORD_FILE="$HOME/.cs_password"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ===================== GET PASSWORD =====================
if [ ! -f "$PASSWORD_FILE" ]; then
    echo -e "${CYAN}Enter a password for your Code-Server:${NC}"
    read -s -p "Password: " USER_PASSWORD
    echo
    echo "$USER_PASSWORD" > "$PASSWORD_FILE"
else
    USER_PASSWORD=$(cat "$PASSWORD_FILE")
fi

while true; do
    clear
    echo -e "\${CYAN}==============================\${NC}"
    echo -e "\${MAGENTA}      z0h1x Code-Server Menu      \${NC}"
    echo -e "\${CYAN}==============================\${NC}"
    echo -e "1 - Start Code-Server"
    echo -e "2 - Show Verbose (Debug logs)"
    echo -e "3 - Stop Code-Server"
    echo -e "0 - Exit (stop server as well)"
    echo -ne "\nChoice: "
    read CHOICE

    case \$CHOICE in
        1)
            clear
            echo -e "\${YELLOW}Starting Code-Server...${NC}"
            cd "\$CS_BIN"
            export PASSWORD="$USER_PASSWORD"
            nohup ./code-server > ~/code-server.log 2>&1 &
            echo -e "\${GREEN}Code-Server running at http://localhost:8080${NC}"
            read -p "Press Enter to return to menu..."
            ;;
        2)
            clear
            echo -e "\${CYAN}Debug Mode (Press Ctrl+C to stop)...${NC}"
            cd "\$CS_BIN"
            export PASSWORD="$USER_PASSWORD"
            ./code-server
            echo -e "\${GREEN}Code-Server stopped.${NC}"
            read -p "Press Enter to return to menu..."
            ;;
        3)
            clear
            echo -e "\${RED}Stopping Code-Server...${NC}"
            pkill -f code-server || true
            echo "Stopped (if running)."
            read -p "Press Enter to return to menu..."
            ;;
        0)
            clear
            echo -e "\${RED}Stopping Code-Server and exiting...${NC}"
            pkill -f code-server || true
            exit 0
            ;;
        *)
            echo -e "\${RED}Invalid option!${NC}"
            sleep 1
            ;;
    esac
done
EOF

chmod +x "$MENU_FILE"

# ===================== CREATE LAUNCHER =====================
cat > "$LAUNCHER" << EOF
#!/bin/bash
bash "$MENU_FILE"
EOF

chmod +x "$LAUNCHER"

bold "\n✅ Installation complete!"
echo -e "${GREEN}Type 'vscode' to open the control panel.${NC}\n"
