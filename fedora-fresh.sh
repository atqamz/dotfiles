# todo: make this script more robust
#!/bin/bash

# install rpm fusion repos
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

sudo dnf update @core -y
sudo dnf install rpmfusion-\*-appstream-data -y

# set /etc/dnf/dnf.conf to include fastestmirror and max_parallel_downloads
# but check if they are already set
if ! grep -q '^fastestmirror=' /etc/dnf/dnf.conf; then
    echo 'fastestmirror=True' | sudo tee -a /etc/dnf/dnf.conf
fi
if ! grep -q '^max_parallel_downloads=' /etc/dnf/dnf.conf; then
    echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf
fi

# copr repos
sudo dnf copr enable solopasha/hyprland -y
sudo dnf install hyprland hyprlock hypridle hyprpolkitagent -y

# install git and fastfetch
sudo dnf install git git-lfs fastfetch -y

# update system
sudo dnf upgrade --refresh -y

# cloudflare warp
curl -fsSl https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | sudo tee /etc/yum.repos.d/cloudflare-warp.repo
sudo dnf install cloudflare-warp -y
# sudo warp-cli registration new -y
# sudo warp-cli connect

# install dotnet sdk and runtimes
sudo dnf install dotnet-sdk-9.0 -y dotnet-runtime-9.0 aspnetcore-runtime-9.0 -y #https://developer.fedoraproject.org/tech/languages/dotnet/dotnetcore.html
# install packages

# install go
sudo dnf install golang -y

# install php
sudo dnf install php php-cli php-fpm -y

# install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup update

# install nodejs, gemini-cli and codex-cli
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
source ~/.bashrc
nvm install node
nvm use node
npm install -g @google/gemini-cli
npm install -g @openai/codex

# install other packages
sudo dnf install cliphist wl-copy wl-paste pavucontrol wl-clipboard wtype grim slurp -y

# install fonts
sudo dnf install google-noto-sans-fonts google-noto-serif-fonts google-noto-emoji-fonts jetbrains-mono-fonts -y
