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

export DEBIAN_FRONTEND=noninteractive

whiptail --title "Linux Setup Script" --msgbox "Welcome to linux-setup-script on $(hostname -f)" 10 60

if whiptail --title "Update system" --yesno "Do you want to update the system?\n\nThis will run apt-get to update and install software." 10 60; then
  sudo apt-get update
  sudo apt-get -y upgrade
  sudo apt-get -y install avahi-daemon screen git jq samba qemu-guest-agent
fi

TIMEZONES=$(timedatectl list-timezones)
CURRENT_TZ="Europe/Warsaw"

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

if [ -n "$TIMEZONE" ]; then
  info "Setting timezone to $TIMEZONE"
  sudo timedatectl set-timezone "$TIMEZONE"
fi

### ===============================================================
if whiptail --title "Docker" --yesno "Do you want to install Docker and Docker Compose." 10 60; then
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
fi

if whiptail --title "Zigbee Permissions Fix" --yesno "Do you want to apply Zigbee Permissions Fix?\n\nThis will modify /etc/subgid to allow access to Zigbee devices." 10 60; then
    # See: https://github.com/moby/moby/issues/43019#issuecomment-1062199525
    sudo bash -c 'for USER in /home/*; do
        USER=$(basename "$USER")
        if ! grep -q "^$USER:20:1$" /etc/subgid; then
          echo "$USER:20:1" >> /etc/subgid
        fi
    done'
fi

### ===============================================================
info "Checking if SSH key should be installed..."

if whiptail --title "SSH Key Setup" --yesno "Do you want to add an SSH public key to authorized_keys file?" 10 60; then
    # Create .ssh directory if it doesn't exist
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    # Ask user to paste their public SSH key
    SSH_KEY=$(whiptail --title "SSH Key Input" --inputbox "Paste your PUBLIC SSH key below:" 10 70 3>&1 1>&2 2>&3)

    if [ -n "$SSH_KEY" ]; then
        # Append the key to authorized_keys
        echo "$SSH_KEY" >> ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
        info "SSH key has been added to authorized_keys."
    else
        info "No SSH key provided, skipping."
    fi
fi

info "Setup completed successfully on $(hostname -f)"