#!/usr/bin/env bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
BLUE='\033[1;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to clear screen and print Android ASCII Art & Main Banner
print_banner() {
    clear
    echo -e "${GREEN}"
    echo "          TB                      BT"
    echo "            TB                  BT"
    echo "              TB              BT"
    echo "              TBBBBBBBBBBBBBBBT"
    echo "           dBBBBBBBBBBBBBBBBBBBBb"
    echo "          dBBBBBBBBBBBBBBBBBBBBBBb"
    echo "          dBBBBb dBBBBBBBBBBb dBBBBb"
    echo "          MBBBBBBBBBBBBBBBBBBBBBBBBM"
    echo "          MBBBBBBBBBBBBBBBBBBBBBBBBM"
    echo ""
    echo "    dBb   MBBBBBBBBBBBBBBBBBBBBBBBBM   dBb"
    echo "   dBBBb  MBBBBBBBBBBBBBBBBBBBBBBBBM  dBBBb"
    echo "   MBBBBM MBBBBBBBBBBBBBBBBBBBBBBBBM  MBBBBM"
    echo "   MBBBBM MBBBBBBBBBBBBBBBBBBBBBBBBM  MBBBBM"
    echo "   MBBBBM MBBBBBBBBBBBBBBBBBBBBBBBBM  MBBBBM"
    echo "   qBBBBp MBBBBBBBBBBBBBBBBBBBBBBBBM  qBBBBp"
    echo "    qBBp  MBBBBBBBBBBBBBBBBBBBBBBBBM   qBBp"
    echo "          MBBBBBBBBBBBBBBBBBBBBBBBBM"
    echo "           qBBBBBBBBBBBBBBBBBBBBBBp"
    echo "            qBBBBBBBBBBBBBBBBBBBBp"
    echo "              MBBBBM     MBBBBM"
    echo "              MBBBBM     MBBBBM"
    echo "              MBBBBM     MBBBBM"
    echo "              MBBBBM     MBBBBM"
    echo "              qBBBBp     qBBBBp"
    echo "               qBBp       qBBp"
    echo -e "${NC}"
    echo -e "${CYAN}${BOLD}=================================================="
    echo -e "                    OSINTDROID                    "
    echo -e "==================================================${NC}"
    echo ""
}

# 1. Check if adb is installed
if ! command -v adb &> /dev/null; then
    print_banner
    echo -e "${RED}[!] Error: 'adb' is not installed on this system.${NC}"
    echo "    On Arch Linux, install it via: sudo pacman -S android-tools"
    exit 1
fi

# Start ADB server if not running
adb start-server &> /dev/null

print_banner
echo -e "${YELLOW}[*] Checking for connected devices...${NC}"

# 2. Check for connected device
DEVICE_ID=$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')

if [ -z "$DEVICE_ID" ]; then
    echo -e "${RED}[!] Error: No authorized Android device detected.${NC}"
    echo "    - Ensure USB Debugging is enabled on the device."
    echo "    - Check the device screen to accept the RSA prompt if prompted."
    exit 1
fi

# 3. Retrieve device details
DEVICE_NAME=$(adb shell settings get global device_name 2>/dev/null | tr -d '\r')
DEVICE_MODEL=$(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r')

# Fallback if device_name is null/empty
if [ -z "$DEVICE_NAME" ] || [ "$DEVICE_NAME" = "null" ]; then
    DEVICE_NAME=$(adb shell getprop ro.product.name 2>/dev/null | tr -d '\r')
fi

# Print device details
echo -e "${GREEN}[+] Device Found!${NC}"
echo -e "    ${BOLD}Device Name  :${NC} ${DEVICE_NAME:-Unknown}"
echo -e "    ${BOLD}Device Model :${NC} ${DEVICE_MODEL:-Unknown}"
echo -e "${CYAN}--------------------------------------------------${NC}"
echo ""

# 4. Interactive Menu (Instant Keypress)
while true; do
    echo -e "${MAGENTA}${BOLD}Select an option:${NC}"
    echo "1. List Registered Emails"
    echo "2. List Phone Contacts"
    echo "3. Call Logs"
    echo "4. SMS Log"
    echo "5. Exit"
    echo ""

    read -rn 1 -p "$(echo -e "${BLUE}${BOLD}Select option [1-5]: ${NC}")" CHOICE
    echo -e "\n"

    case $CHOICE in
        1)
            echo -e "${CYAN}${BOLD}=== Registered Emails ===${NC}"
            (
                echo -e "${YELLOW}Registered Emails${NC}"
                adb shell dumpsys account | grep -oP '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u
            ) | column -t
            echo ""
            ;;
        2)
            echo -e "${CYAN}${BOLD}=== Phone Contacts ===${NC}"
            (
                echo -e "${YELLOW}Name\tNumber${NC}"
                adb shell content query --uri content://com.android.contacts/data/phones --projection display_name:data1 | awk -F'[=,]' '{print $2 "\t" $4}'
            ) | column -t -s $'\t'
            echo ""
            ;;
        3)
            echo -e "${CYAN}${BOLD}=== Call Logs ===${NC}"
            (
                echo -e "${YELLOW}Date\tTime\tName\tNumber${NC}"
                adb shell content query --uri content://call_log/calls --projection name:number:date:type | awk -F'[=,]' '{
                    cmd = "date -d @" int($6/1000) " \"+%Y-%m-%d\t%H:%M:%S\""
                    cmd | getline d
                    close(cmd)
                    name = ($2 == "") ? "Unknown" : $2
                    print d "\t" name "\t" $4
                }'
            ) | column -t -s $'\t'
            echo ""
            ;;
        4)
            echo -e "${CYAN}${BOLD}=== SMS Log ===${NC}"
            PREFIX_LEN=58
            MAX_WIDTH=45
            INDENT=$(printf '%*s' "$PREFIX_LEN" "")

            printf "${YELLOW}%-12s %-10s %-8s %-16s %s${NC}\n" "Date" "Time" "Type" "Number" "Message"
            printf "%-12s %-10s %-8s %-16s %s\n" "----------" "--------" "------" "----------------" "-------------------------------------------"

            adb shell content query --uri content://sms --projection address:body:type:date | awk -v indent="$INDENT" -v w="$MAX_WIDTH" '{
                line = $0

                # Robustly extract fields accounting for commas inside message bodies
                if (match(line, /address=([^,]*)/, m)) address = m[1]; else address = "";
                if (match(line, /body=(.*), type=([0-9]+), date=([0-9]+)/, m)) {
                    body = m[1]
                    type_val = m[2]
                    date_val = m[3]
                } else {
                    body = ""; type_val = "1"; date_val = "0";
                }

                cmd = "date -d @" int(date_val/1000) " \"+%Y-%m-%d %H:%M:%S\""
                cmd | getline d
                close(cmd)
                if (d == "") d = "1970-01-01 00:00:00"

                type = (type_val == "1") ? "INBOX" : "SENT"
                prefix = sprintf("%-21s %-8s %-16s ", d, type, address)

                # Escape quotes safely and pipe into fmt for wrapping
                gsub(/"/, "\\\"", body)
                cmd_fmt = "echo \"" body "\" | fmt -w " w
                first = 1
                while ((cmd_fmt | getline line_fmt) > 0) {
                    if (first) {
                        print prefix line_fmt
                        first = 0
                    } else {
                        print indent line_fmt
                    }
                }
                close(cmd_fmt)
            }'
            echo ""
            ;;
        5)
            echo -e "${GREEN}Exiting OSINTDROID.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Invalid option: '$CHOICE'. Please press 1, 2, 3, 4, or 5.${NC}"
            echo ""
            ;;
    esac
done
```[cite: 1]
