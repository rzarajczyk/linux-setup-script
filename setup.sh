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

whiptail --title "Linux Setup Script" --msgbox "Welcome to linux-setup-script on $(hostname -f)\n\nSystem will be updated now" 10 60

#sudo apt-get update
#sudo apt-get -y upgrade
#sudo apt-get -y install avahi-daemon screen git jq samba qemu-guest-agent

TIMEZONES=$(timedatectl list-timezones)
TMP_FILE=$(mktemp)
CURRENT_TZ="Europe/Warsaw"

echo $TMP_FILE
echo $CURRENT_TZ

# Create menu options for whiptail
MENU_OPTIONS=()
while IFS= read -r tz; do
    MENU_OPTIONS+=("$tz" "")
done <<< "$TIMEZONES"

#
## Use whiptail to select timezone with search capability
TIMEZONE=$(whiptail --title "Timezone Selection" --menu \
    "Choose your timezone (use arrow keys and type to search):" \
    20 60 10 --default-item "$CURRENT_TZ" \
    "${MENU_OPTIONS[@]}" 3>&1 1>&2 2>&3)

if [ -z "$TIMEZONE" ]; then
    warn "Timezone selection canceled. Quitting."
    exit 1
fi
info "Setting timezone to $TIMEZONE"
sudo timedatectl set-timezone "$TIMEZONE"

### ===============================================================
export DEBIAN_FRONTEND=noninteractive

info "Installing Docker..."

if ! command -v docker &> /dev/null
then
  # Docker
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  sudo sh /tmp/get-docker.sh
  sudo sh -eux <<EOF
# Install newuidmap & newgidmap binaries
sudo apt-get install -y uidmap
EOF
  dockerd-rootless-setuptool.sh install
  docker context use rootless
  echo 'echo "" >> ~/.bashrc' >> ~/.bashrc
  echo 'export DOCKER_HOST=unix:///run/user/1000/docker.sock' >> ~/.bashrc
  sudo sh -c 'echo "net.ipv4.ip_unprivileged_port_start=80" >> /etc/sysctl.conf'
  sudo sysctl --system
  sudo setcap cap_net_bind_service=ep $(which rootlesskit)
  systemctl --user restart docker
else
  echo "Docker already installed"
fi

sudo apt-get install -y docker-compose-plugin docker-compose