#!/bin/bash

set -e

# Check if the script is run as root
if [ "$EUID" -eq 0 ]; then
  echo "Please run this script without sudo."
  exit 1
fi

# Log function for better readability
log() {
  echo -e "\033[1;32m$1\033[0m"
}

# Privacy and Security Settings
configure_privacy() {
  log "Configuring privacy settings..."
  gsettings set org.gnome.system.location enabled false
  gsettings set org.gnome.desktop.privacy disable-camera true
  gsettings set org.gnome.desktop.privacy disable-microphone true
  gsettings set org.gnome.desktop.privacy remember-recent-files false
  gsettings set org.gnome.desktop.privacy hide-identity true
  gsettings set org.gnome.desktop.privacy report-technical-problems false
  gsettings set org.gnome.desktop.privacy send-software-usage-stats false
  gsettings set org.gnome.desktop.media-handling autorun-never true
}

configure_security() {
  log "Configuring security settings..."
  gsettings set org.gnome.login-screen allowed-failures 100
  sudo systemctl mask cron.service
}

configure_mouse() {
  log "Configuring mouse settings..."
  gsettings set org.gnome.desktop.peripherals.mouse accel-profile flat
}

configure_tmpfs() {
  log "Configuring tmpfs ramdisk..."
  sudo sed -i '/^tmpfs/d' /etc/fstab
  echo -e "tmpfs /var/tmp tmpfs nodiratime,nodev,nosuid,mode=1777,size=500m 0 0
tmpfs /var/log tmpfs nodiratime,nodev,nosuid,mode=1777,size=500m 0 0
tmpfs /var/run tmpfs nodiratime,nodev,nosuid,mode=1777,size=1g 0 0
tmpfs /var/lock tmpfs nodiratime,nodev,nosuid,mode=1777,size=500m 0 0
tmpfs /var/cache tmpfs nodiratime,nodev,nosuid,mode=1777,size=2g 0 0
tmpfs /var/volatile tmpfs nodiratime,nodev,nosuid,mode=1777,size=500m 0 0
tmpfs /var/spool tmpfs nodiratime,nodev,nosuid,mode=1777,size=500m 0 0
tmpfs /media tmpfs nodiratime,nodev,nosuid,mode=1777,size=500m 0 0
tmpfs /dev/shm tmpfs nodiratime,nodev,nosuid,mode=1777,size=500m 0 0" | sudo tee -a /etc/fstab
}

disable_bluetooth_autostart() {
  log "Disabling Bluetooth autostart..."
  sudo sed -i 's/AutoEnable.*/AutoEnable = false/' /etc/bluetooth/main.conf
  sudo sed -i 's/FastConnectable.*/FastConnectable = false/' /etc/bluetooth/main.conf
  sudo sed -i 's/ReconnectAttempts.*/ReconnectAttempts = 1/' /etc/bluetooth/main.conf
  sudo sed -i 's/ReconnectIntervals.*/ReconnectIntervals = 1/' /etc/bluetooth/main.conf
}

configure_fail2ban() {
  log "Configuring Fail2Ban..."
  sudo apt install -y fail2ban
  sudo mkdir -p /etc/fail2ban/
  sudo tee /etc/fail2ban/jail.local > /dev/null <<EOL
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1
bantime = 3600
findtime = 600
maxretry = 5
enabled = true

[sshd]
enabled = true
EOL
  sudo systemctl enable --now fail2ban
}

# Installation Functions
install_neovim() {
  log "Installing Neovim..."
  cd ~/Downloads
  wget -O nvim-linux64.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz"
  sudo rm -rf /usr/local/bin/nvim  # Remove any existing binary to avoid conflicts
  sudo tar -C /usr/local/bin -xzf nvim-linux64.tar.gz --strip-components=2 nvim-linux64/bin/nvim
}

install_starship() {
  log "Installing Starship..."
  curl -sS https://starship.rs/install.sh | sh
}

install_eza() {
  log "Installing Eza..."
  sudo apt update
  sudo apt install -y gpg
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt update
  sudo apt install -y eza
}

install_zellij() {
  log "Installing Zellij..."
  latest_release=$(curl --silent "https://api.github.com/repos/zellij-org/zellij/releases/latest")
  asset_url=$(echo "$latest_release" | jq -r '.assets[] | select(.name == "zellij-x86_64-unknown-linux-musl.tar.gz") | .browser_download_url')

  if [[ -z "$asset_url" || "$asset_url" == "null" ]]; then
    echo "Error: Unable to fetch the latest asset URL."
    exit 1
  fi

  curl -L "$asset_url" -o zellij-latest.tar.gz
  tar -xvf zellij-latest.tar.gz
  chmod +x zellij
  sudo mv zellij /usr/bin/zellij
  rm zellij-latest.tar.gz
}

install_normal_programs() {
  log "Installing Fish and Bat..."
  sudo apt install -y fish bat ripgrep fzf htop powertop prelink preload gh jq wget curl
  chsh -s /usr/bin/fish
}

install_latex() {
  log "Installing LaTeX packages..."
  sudo apt install -y texlive-latex-base texlive-fonts-recommended texlive-fonts-extra texlive-latex-extra
}

install_flatpaks() {
  log "Installing Flatpaks..."
  sudo apt install -y flatpak
  flatpak install -y flathub org.wezfurlong.wezterm
  flatpak install flathub md.obsidian.Obsidian -y
  flatpak install flathub com.jetbrains.IntelliJ-IDEA-Ultimate -y
}

install_thorium() {
  log "Installing Thorium browser..."
  latest_thorium_url=$(curl -s https://api.github.com/repos/Alex313031/Thorium/releases/latest | grep "browser_download_url.*thorium-browser.*_AVX2\.deb" | cut -d '"' -f 4)

  if [[ -z "$latest_thorium_url" ]]; then
    echo "Error: Unable to fetch the latest Thorium release URL."
    exit 1
  fi

  wget -q "$latest_thorium_url" -O thorium_latest.deb
  sudo apt install -y ./thorium_latest.deb
  rm thorium_latest.deb
}

install_lazygit() {
  log "Installing Lazygit..."
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit /usr/local/bin
  rm lazygit.tar.gz lazygit
}

copy_config_files() {
  log "Copying config files..."
  mkdir -p ~/.config
  cp -r config/* ~/.config/
}

load_keybindings() {
  log "Loading keybindings..."
  keybindings_file="./config/gnome_keybindings_backup.txt"

  if [ -f "$keybindings_file" ]; then
    dconf load /org/gnome/desktop/wm/keybindings/ < "$keybindings_file"
  else
    echo "Keybindings file not found."
  fi
}

blacklist_modules() {
  log "Blacklisting modules..."
  sudo tee /etc/modprobe.d/nomisc.conf > /dev/null <<EOL
blacklist mac_hid
blacklist parport_pc
blacklist parport
blacklist lp
blacklist ppdev
blacklist floppy
blacklist arkfb
blacklist aty128fb
blacklist atyfb
blacklist radeonfb
blacklist cyber2000fb
blacklist pcmcia
blacklist yenta_socket
blacklist ax25
blacklist netrom
blacklist x25
blacklist appletalk
blacklist parport
blacklist parport_pc
EOL
}

btrfs_tweaks() {
  log "Running Btrfs tweaks..."
  sudo systemctl enable btrfs-scrub@home.timer
  sudo systemctl enable btrfs-scrub@-.timer
  sudo btrfs property set / compression lz4
  sudo btrfs property set /home compression lz4
  sudo btrfs filesystem defragment -r -v -clz4 /
  sudo chattr +c /
  sudo btrfs filesystem defragment -r -v -clz4 /home
  sudo chattr +c /home
  sudo btrfs balance start -musage=0 -dusage=50 /
  sudo btrfs balance start -musage=0 -dusage=50 /home
  sudo chattr +C /swapfile
}

disk_tweaks() {
  log "Applying disk tweaks..."
  sudo systemctl enable fstrim.timer
  sudo sed -i -e 's| defaults| rw,lazytime,relatime,commit=3600,delalloc,nobarrier,nofail,discard|g' /etc/fstab
  sudo sed -i -e 's| errors=remount-ro| rw,lazytime,relatime,commit=3600,delalloc,nobarrier,nofail,discard,errors=remount-ro|g' /etc/fstab
}

remove_unnecessary_packages() {
  log "Removing unnecessary packages..."
  sudo apt purge -y thunderbird libreoffice-common firefox
  sudo apt autoremove -y
}

reduce_swappiness() {
  log "Reducing swappiness..."
  echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
  sudo sysctl -p
}

zswap_configuration() {
  log "Configuring Zswap..."
  echo "zswap.enabled=1" | sudo tee -a /etc/default/grub
  echo "zswap.compressor=lz4" | sudo tee -a /etc/default/grub
  echo "zswap.max_pool_percent=20" | sudo tee -a /etc/default/grub
  echo "zswap.zpool=z3fold" | sudo tee -a /etc/default/grub
  sudo update-grub
}

# Main Function
main() {
  install_normal_programs
  configure_privacy
  configure_security
  configure_mouse
  disable_bluetooth_autostart
  configure_fail2ban
  install_neovim
  install_starship
  install_eza
  install_zellij
  install_latex
  install_flatpaks
  install_thorium
  install_lazygit
  disk_tweaks
  remove_unnecessary_packages
  copy_config_files
  load_keybindings

  # Ask the user if they want to run experimental tweaks
  read -p "Do you want to run experimental tweaks? (y/N): " run_experimental
  if [[ "$run_experimental" == "y" || "$run_experimental" == "Y" ]]; then
    configure_tmpfs
    blacklist_modules
    zswap_configuration
    reduce_swappiness
  fi
  
  read -p "Do you want to run BTRFS tweaks? (y/N): " run_btrfs
  if [[ "$run_btrfs" == "y" || "$run_btrfs" == "Y" ]]; then
    btrfs_tweaks
  fi

  log "Setup complete!"
}

main
