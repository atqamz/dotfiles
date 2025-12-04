# todo: make this script more robust
#!/bin/bash

# set /etc/dnf/dnf.conf to include fastestmirror and max_parallel_downloads
# but check if they are already set
if ! grep -q '^fastestmirror=' /etc/dnf/dnf.conf; then
    echo 'fastestmirror=True' | sudo tee -a /etc/dnf/dnf.conf
fi
if ! grep -q '^max_parallel_downloads=' /etc/dnf/dnf.conf; then
    echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf
fi

# rpm fusion repos
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# update system
sudo dnf update --refresh -y
sudo dnf update @core -y
sudo dnf update kernel -y
sudo dnf install rpmfusion-\*-appstream-data -y

# essential packages for wifi
sudo dnf install \
    linux-firmware \
    iw \
    iwlwifi-mvm-firmware \
    iwlwifi-dvm-firmware \
    NetworkManager-wifi -y

# essential packages for audio
sudo dnf install \
    pavucontrol \
    pipewire \
    pipewire-alsa \
    pipewire-pulseaudio \
    wireplumber \
    alsa-sof-firmware \
    alsa-plugins-pulseaudio \
    alsa-ucm-conf \
    alsa-utils -y

# essential packages for video
sudo dnf install \
    akmod-nvidia \
    xorg-x11-drv-nvidia \
    xorg-x11-drv-nvidia-cuda \
    vulkan-nvidia -y

sudo dnf install \
    ffmpeg \
    ffmpeg-libs.i686 \
    ffmpeg-libs.x86_64 -y

# essential packages for bluetooth
sudo dnf install \
    bluez \
    bluez-tools \
    bluez-libs \
    blueman -y

# essential packages for printing
sudo dnf install \
    cups \
    system-config-printer -y

# essential packages for battery management
sudo dnf install \
    tlp \
    tlp-rdw -y

sudo systemctl enable tlp
sudo systemctl start tlp

# hardware monitoring tools
sudo dnf install \
    upower \
    pciutils \
    usbutils \
    lm_sensors -y

# brightness and media controls
sudo dnf install \
    brightnessctl \
    playerctl -y

# file system support
sudo dnf install \
    gvfs \
    udisks2 \
    ntfs-3g -y

# hyprland
sudo dnf copr enable solopasha/hyprland -y
sudo dnf install \
    hyprland \
    hyprlock \
    hypridle \
    hyprpolkitagent -y

# git and fastfetch
sudo dnf install \
    git \
    git-lfs \
    fastfetch -y

# fonts
sudo dnf install \
    fontawesome-fonts-all \
    google-noto-sans-fonts \
    google-noto-serif-fonts \
    google-noto-emoji-fonts \
    jetbrains-mono-fonts -y

# cloudflare warp
curl -fsSl https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | sudo tee /etc/yum.repos.d/cloudflare-warp.repo
sudo dnf install cloudflare-warp -y
# sudo warp-cli registration new -y
# sudo warp-cli connect

# docker
sudo dnf install \
    dnf-plugins-core -y
sudo dnf config-manager \
    --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin -y

sudo systemctl enable docker
sudo systemctl start docker
sudo groupadd docker
sudo usermod -aG docker $USER
# newgrp docker

# dotnet sdk and runtimes
# https://developer.fedoraproject.org/tech/languages/dotnet/dotnetcore.html
sudo dnf install \
    dotnet-sdk-9.0 \
    dotnet-runtime-9.0 \
    aspnetcore-runtime-9.0 -y

# go
sudo dnf install golang -y

# php
sudo dnf install php php-cli php-fpm -y

# rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup update

# nodejs, gemini-cli and codex-cli
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
source ~/.bashrc
nvm install node
nvm use node
npm install -g @google/gemini-cli
npm install -g @openai/codex

# install other packages
sudo dnf install \
    htop \
    btop \
    nvtop \
    cliphist \
    wl-copy \
    wl-paste \
    pavucontrol \
    cliphist \
    wl-clipboard \
    wtype \
    grim \
    slurp -y