# todo: make this script more robust
#!/bin/bash

# add rpm fusion repos

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
sudo dnf copr enable alternateved/cliphist -y
sudo dnf copr enable rafatosta/zapzap -y

curl -fsSl https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | sudo tee /etc/yum.repos.d/cloudflare-warp.repo
sudo dnf install cloudflare-warp -y
sudo warp-cli registration new -y
sudo warp-cli connect

# update system
sudo dnf upgrade --refresh -y

# install packages
sudo dnf install hyprland hyprlock -y
sudo dnf install dotnet-sdk-9.0 -y dotnet-runtime-9.0 aspnetcore-runtime-9.0 -y #https://developer.fedoraproject.org/tech/languages/dotnet/dotnetcore.html
sudo dnf install golang -y
sudo dnf install php php-cli php-fpm -y
sudo dnf install git git-lfs fastfetch -y
sudo dnf install cliphist wl-copy wl-paste pavucontrol wl-clipboard wtype grim slurp -y
sudo dnf install zapzap -y

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
source ~/.bashrc
nvm install node
nvm use node
npm install -g @google/gemini-cli
npm install -g @openai/codex
