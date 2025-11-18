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
sudo dnf copr enable alternateved/cliphist -y

# update system
sudo dnf upgrade --refresh -y

# install packages
sudo dnf install golang -y
sudo dnf install php php-cli php-fpm -y
sudo dnf install git git-lfs fastfetch -y
sudo dnf install cliphist wl-copy wl-paste pavucontrol wl-clipboard wtype grim slurp -y

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash