# Create a symlink to the password store in the home directory
```sh
ln -s ~/password-store ~/.password-store
```

# Autostart ssh-agent
```sh
systemctl --user enable --now ssh-agent.service
```