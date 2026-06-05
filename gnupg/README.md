# gnupg

GnuPG agent configuration. Stows into `~/.gnupg/`.

`gpg-agent.conf` enables `enable-ssh-support`, so gpg-agent also serves as the
SSH agent — point `SSH_AUTH_SOCK` at `$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh`
(done in `hypr/.config/hypr/hyprland.lua`; bash falls back to
`gpgconf --list-dirs agent-ssh-socket` on a bare tty). The personal SSH
identity is the `[A]` authentication subkey of the personal GPG key, not a
standalone on-disk private key.

## sshcontrol (machine-local, one-time)

gpg-agent only offers an auth subkey over SSH if its **keygrip** is listed in
`~/.gnupg/sshcontrol`. That file is machine-local state, not version-controlled
and not stowed, so on a fresh machine (after importing the personal secret key)
append the keygrip once:

```sh
gpg --batch --with-keygrip -K <key-id>   # find the [A] subkey's Keygrip
echo <keygrip> >> ~/.gnupg/sshcontrol
```

Then `ssh-add -l` lists the key and ssh can authenticate with it. On NixOS the
declarative equivalent is `services.gpg-agent.sshKeys = [ "<keygrip>" ];`.

## Dependencies

- gnupg
- pinentry-gnome3 (the program named in `gpg-agent.conf`)
