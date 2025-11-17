# todo: make this script more robust
#!/bin/bash

# add rpm fusion repos

# set /etc/dnf/dnf.conf to include fastestmirror and max_parallel_downloads



# copr repos
sudo dnf copr enable alternateved/cliphist -y

# update system
sudo dnf upgrade --refresh -y

# install packages
sudo dnf install cliphist wl-copy wl-paste pavucontrol wl-clipboard wtype grim slurp -y