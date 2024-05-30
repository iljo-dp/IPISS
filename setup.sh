#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Privacy and Security Settings
configure_privacy() {
    echo "Configuring privacy settings..."
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
    echo "Configuring security settings..."
    gsettings set org.gnome.login-screen allowed-failures 100
    sudo systemctl mask cron.service
}

configure_mouse() {
    echo "Configuring mouse settings..."
    gsettings set org.gnome.desktop.peripherals.mouse accel-profile flat
}

configure_tmpfs() {
    echo "Configuring tmpfs ramdisk..."
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
    echo "Disabling Bluetooth autostart..."
    sudo sed -i 's/AutoEnable.*/AutoEnable = false/' /etc/bluetooth/main.conf
    sudo sed -i 's/FastConnectable.*/FastConnectable = false/' /etc/bluetooth/main.conf
    sudo sed -i 's/ReconnectAttempts.*/ReconnectAttempts = 1/' /etc/bluetooth/main.conf
    sudo sed -i 's/ReconnectIntervals.*/ReconnectIntervals = 1/' /etc/bluetooth/main.conf
}

configure_fail2ban() {
    sudo apt install -y fail2ban
    sudo mkdir -p /etc/fail2ban/
    sudo touch  /etc/fail2ban/jail.local
    echo "Configuring Fail2Ban..."
    echo -e "[DEFAULT]
ignoreip = 127.0.0.1/8 ::1
bantime = 3600
findtime = 600
maxretry = 5
enabled = true

[sshd]
enabled = true" | sudo tee /etc/fail2ban/jail.local
    sudo systemctl enable --now fail2ban
}

# Installation Functions
install_neovim() {
    echo "Installing Neovim..."
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf nvim-linux64.tar.gz
    sudo rm -rf nvim-linux64*
}

install_starship() {
    echo "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh
}

install_eza() {
    echo "Installing Eza..."
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
    echo "Fetching the latest Zellij release information..."
    latest_release=$(curl --silent "https://api.github.com/repos/zellij-org/zellij/releases/latest")
    asset_url=$(echo "$latest_release" | jq -r '.assets[] | select(.name == "zellij-x86_64-unknown-linux-musl.tar.gz") | .browser_download_url')

    if [[ -z "$asset_url" || "$asset_url" == "null" ]]; then
        echo "Error: Unable to fetch the latest asset URL."
        exit 1
    fi

    echo "Downloading Zellij asset..."
    curl -L "$asset_url" -o zellij-latest.tar.gz
    echo "Extracting Zellij..."
    tar -xvf zellij-latest.tar.gz
    chmod +x zellij
    sudo mv zellij /usr/bin/zellij
    rm zellij-latest.tar.gz
    echo "Zellij installation completed successfully."
}

install_fish_bat() {
    echo "Installing Fish and Bat..."
    sudo apt install -y fish bat ripgrep fzf htop powertop prelink preload gh

    echo "Changing default shell to Fish..."
    chsh -s /usr/bin/fish
}

install_latex() {
    echo "Installing LaTeX packages..."
    sudo apt install -y texlive-latex-base texlive-fonts-recommended texlive-fonts-extra texlive-latex-extra
}

install_flatpaks() {
    echo "Installing WezTerm..."
    sudo apt install -y flatpak
    flatpak install -y flathub org.wezfurlong.wezterm
	flatpak install flathub md.obsidian.Obsidian -y
   	flatpak install flathub com.jetbrains.IntelliJ-IDEA-Ultimate -y

}

install_thorium() {
    echo "Installing Thorium browser..."
    latest_thorium_url=$(curl -s https://api.github.com/repos/Alex313031/Thorium/releases/latest | grep "browser_download_url.*thorium-browser.*_AVX2\.deb" | cut -d '"' -f 4)

    if [[ -z "$latest_thorium_url" ]]; then
        echo "Error: Unable to fetch the latest Thorium release URL."
        exit 1
    fi

    echo "Downloading Thorium browser..."
    wget -q "$latest_thorium_url" -O thorium_latest.deb
    echo "Installing Thorium browser..."
    sudo apt install -y ./thorium_latest.deb
    rm thorium_latest.deb
    echo "Thorium installation completed successfully."
}

install_lazygit() {
    echo "Installing Lazygit..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit.tar.gz lazygit
}

copy_config_files() {
    echo "Copying config files..."
    mkdir -p ~/.config
    cp -r config/* ~/.config/
}

load_keybindings() {
    keybindings_file="./config/gnome_keybindings_backup.txt"

    if [ -f "$keybindings_file" ]; then
        dconf load /org/gnome/desktop/wm/keybindings/ < "$keybindings_file"
        echo "Keybindings loaded successfully."
    else
        echo "Keybindings file not found."
    fi
}

blacklist_modules() {
echo -e "
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
blacklist parport_pc" | sudo tee /etc/modprobe.d/nomisc.conf
}

btrfs_tweaks(){
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
    echo -e "Apply disk tweaks"
    sudo systemctl enable fstrim.timer
    sudo sed -i -e 's| defaults| rw,lazytime,relatime,commit=3600,delalloc,nobarrier,nofail,discard|g' /etc/fstab
    sudo sed -i -e 's| errors=remount-ro| rw,lazytime,relatime,commit=3600,delalloc,nobarrier,nofail,discard,errors=remount-ro|g' /etc/fstab
}
remove_unnecessary_packages() {
    echo "Removing unnecessary packages..."
    sudo apt purge -y thunderbird libreoffice-common firefox
    sudo apt autoremove -y
}
reduce_swappiness(){
    echo "Reducing swappiness..."
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
}

zswap_configuration() {
    echo "Configuring Zswap..."
    echo "zswap.enabled=1" | sudo tee -a /etc/default/grub
    echo "zswap.compressor=lz4" | sudo tee -a /etc/default/grub
    echo "zswap.max_pool_percent=20" | sudo tee -a /etc/default/grub
    echo "zswap.zpool=z3fold" | sudo tee -a /etc/default/grub
    sudo update-grub
}
# Main Function
main() {
    configure_privacy
    configure_security
    configure_mouse
    #This currently breaks some stuff, fixing it soon:tm:
    configure_tmpfs
    disable_bluetooth_autostart
    configure_fail2ban
    install_neovim
    install_starship
    install_eza
    install_zellij
    install_fish_bat
    install_latex
    install_flatpaks
    install_thorium
    install_lazygit
    blacklist_modules
    #Uncomment this if you use btrfs
    #btrfs_tweaks
    disk_tweaks
    remove_unnecessary_packages
    reduce_swappiness
    #zswap_configuration
    copy_config_files
    load_keybindings
    echo "Setup complete!"
}

main
