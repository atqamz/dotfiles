# NVIDIA on Fedora Sway

Guide for replacing Nouveau with the proprietary NVIDIA driver on Fedora 43 (and
newer) when running Sway. Waybar’s GPU module in this repo assumes
`nvidia-smi` will be available.

## 1. Update + base packages

```sh
sudo dnf upgrade --refresh
sudo dnf install kernel-devel kernel-headers gcc make acpid dkms
```

## 2. Enable RPM Fusion

```sh
sudo dnf install \
  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```

## 3. Install the driver stack

```sh
sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda \
  xorg-x11-drv-nvidia-cuda-libs nvidia-vaapi-driver libva-nvidia-driver
```

- `akmod-nvidia` builds the kernel module for every kernel.
- CUDA libs include GBM/Wayland pieces needed by modern compositors.
- `nvidia-vaapi-driver` gives VA-API decode/encode.

## 4. Blacklist Nouveau + regenerate initramfs

`/etc/modprobe.d/disable-nouveau.conf`:

```
blacklist nouveau
options nouveau modeset=0
```

Then rebuild initramfs:

```sh
sudo dracut --force
```

## 5. Kernel parameters

Add `nvidia-drm.modeset=1 rd.driver.blacklist=nouveau modprobe.blacklist=nouveau` to every kernel:

```sh
sudo grubby --update-kernel=ALL --args="nvidia-drm.modeset=1 rd.driver.blacklist=nouveau modprobe.blacklist=nouveau"
```

(Use `kernelstub`/`bootctl` instead of `grubby` on systems without GRUB.)

## 6. Environment for Sway/Wayland

Set before launching Sway (e.g. in `~/.config/environment.d/nvidia.conf` or sourced script):

```sh
export WLR_NO_HARDWARE_CURSORS=1
export LIBVA_DRIVER_NAME=nvidia
```

Optional for PRIME offload laptops:

```sh
export __GLX_VENDOR_LIBRARY_NAME=nvidia
```

## 7. Reboot and verify

After reboot:

```sh
nvidia-smi
lsmod | grep nvidia
```

If Secure Boot is on, sign the module or disable SB temporarily so `akmod` modules load.

## 8. Making Waybar GPU module work

Once `nvidia-smi` prints data, the `bin/.local/bin/waybar_gpustatus` helper will start showing `{usage}% {temp}°C` automatically in Waybar. Without a working `nvidia-smi` binary the module intentionally shows `--% --°C`.

## Troubleshooting

- First boot after installing `akmod-nvidia` can take a few minutes while the module compiles. Let it finish.
- If Sway blackscreens, confirm the driver version is ≥535 and `nvidia-drm.modeset=1` is applied.
- PRIME/offload: install `xorg-x11-drv-nvidia-power` and use `nvidia-offload` wrapper for specific apps if you need Intel+NVIDIA switching.
