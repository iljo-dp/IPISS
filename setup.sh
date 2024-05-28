#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Install Neovim
echo "Installing Neovim..."
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux64.tar.gz
sudo rm -rf nvim-linux64*


# Install Starship
echo "Installing Starship..."
curl -sS https://starship.rs/install.sh | sh

# Install Eza
echo "Installing Eza..."
sudo apt update
sudo apt install -y gpg
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update
sudo apt install -y eza

# Install Zellij
echo "Fetching the latest Zellij release information..."
latest_release=$(curl --silent "https://api.github.com/repos/zellij-org/zellij/releases/latest")
if [[ $? -ne 0 ]]; then
  echo "Error: Unable to fetch the latest release information from GitHub."
  exit 1
fi
asset_url=$(echo "$latest_release" | jq -r '.assets[] | select(.name == "zellij-x86_64-unknown-linux-musl.tar.gz") | .browser_download_url')
if [[ -z "$asset_url" || "$asset_url" == "null" ]]; then
  echo "Error: Unable to fetch the latest asset URL."
  exit 1
fi
echo "Latest asset URL: $asset_url"
echo "Downloading Zellij asset..."
curl -L "$asset_url" -o zellij-latest.tar.gz
echo "Extracting Zellij..."
tar -xvf zellij-latest.tar.gz
chmod +x zellij
echo "Moving Zellij binary to /usr/bin/zellij..."
sudo mv zellij /usr/bin/zellij
cd ..
rm -rf zellij-latest.tar.gz
echo "Zellij installation completed successfully."



# Install Fish and Bat
echo "Installing Fish and Bat..."
sudo apt install -y fish bat

# Change default shell to Fish for the current user
echo "Changing default shell to Fish..."
chsh -s /usr/bin/fish

# Install LaTeX packages
echo "Installing LaTeX packages..."
sudo apt install -y texlive-latex-base texlive-fonts-recommended texlive-fonts-extra texlive-latex-extra

# Install WezTerm
echo "Installing WezTerm..."
sudo apt install -y flatpak
flatpak install -y flathub org.wezfurlong.wezterm

# Install Thorium browser
echo "Installing Thorium browser..."
latest_thorium_url=$(curl -s https://api.github.com/repos/Alex313031/Thorium/releases/latest | grep "browser_download_url.*thorium-browser.*_AVX2\.deb" | cut -d '"' -f 4)
if [[ -z "$latest_thorium_url" ]]; then
  echo "Error: Unable to fetch the latest Thorium release URL."
  exit 1
fi
echo "Latest Thorium URL: $latest_thorium_url"
echo "Downloading Thorium browser..."
wget -q "$latest_thorium_url" -O thorium_latest.deb
echo "Installing Thorium browser..."
sudo apt install -y ./thorium_latest.deb
rm thorium_latest.deb
echo "Thorium installation completed successfully."

# Install Lazygit
echo "Installing Lazygit..."
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
rm lazygit.tar.gz lazygit

# Copy config files
echo "Copying config files..."
mkdir -p ~/.config
cp -r config/* ~/.config/


# Source the new Fish configuration
echo "Sourcing the new Fish configuration..."
if [ -f ~/.config/fish/config.fish ]; then
    source ~/.config/fish/config.fish
fi

echo "Setup complete!"

