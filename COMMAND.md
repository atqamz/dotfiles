# Create a symlink to the password store in the home directory
```sh
ln -s ~/password-store ~/.password-store
```

# Autostart ssh-agent
```sh
systemctl --user enable --now ssh-agent.service
```

# Post-import .ssh and .gnupg
```sh
chown -R $USER:$USER ~/.ssh ~/.gnupg

chmod 700 ~/.ssh ~/.gnupg

chmod 600 ~/.ssh/id_* # Set SSH Public key permissions (rw-r--r--)
chmod 644 ~/.ssh/*.pub ~/.ssh/known_hosts ~/.ssh/config

find ~/.gnupg -type f -exec chmod 600 {} \;
find ~/.gnupg -type d -exec chmod 700 {} \;

restorecon -Rv ~/.ssh ~/.gnupg
```
