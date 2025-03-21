#!/bin/bash
set -e

function info {
    COLOR='\033[0;33m' # YELLOW
    NC='\033[0m' # No COLOR
    echo -e "${COLOR}$1${NC}"
}

function warn {
    COLOR='\033[1;31m' # COLOR
    NC='\033[0m' # No COLOR
    echo -e "${COLOR}$1${NC}"
}

info "Welcome to linux-setup-script"

TIMEZONES=$(timedatectl list-timezones)
TMP_FILE=$(mktemp)
#CURRENT_TZ=$(timedatectl show -p Timezone --value 2>/dev/null || echo "Europe/Warsaw")
#
while IFS= read -r tz; do
    echo "\"$tz\" \"\" " >> "$TMP_FILE"
done <<< "$TIMEZONES"
#
## Use whiptail to select timezone with search capability
TIMEZONE=$(whiptail --title "Timezone Selection" --menu "Choose your timezone (use arrow keys and initial typing to search):" 20 60 10 \
    --default-item "$CURRENT_TZ" \
    --file "$TMP_FILE" 3>&1 1>&2 2>&3)

rm -f "$TMP_FILE"
#
#if [ -z "$TIMEZONE" ]; then
#    echo "Timezone selection canceled. Using default: Europe/Warsaw"
#    TIMEZONE="Europe/Warsaw"
#fi
#info "Setting timezone to $TIMEZONE"
#sudo timedatectl set-timezone "$TIMEZONE"
#
#sudo apt-get update
#sudo apt-get -y upgrade
#sudo apt-get -y install avahi-daemon screen git jq samba qemu-guest-agent