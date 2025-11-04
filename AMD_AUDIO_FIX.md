# AMD Realtek ALC897 Audio Crackling Fix - Fedora 43

## Problem
- **Symptom:** Loud crackling/broken noise from laptop speakers
- **Started:** After Hyprland installation
- **Affects:** Both Linux and Windows (hardware-level issue)
- **Hardware:** Realtek ALC897 codec on AMD Rembrandt platform (Desktop codec in laptop)

## Root Cause
ALC897 is a desktop codec being used in laptop with aggressive power management causing sleep/wake crackling.

## Solution Applied

### Configuration File: `/etc/modprobe.d/alsa-base.conf`
```bash
# Audio fix for Realtek ALC897 codec
options snd-hda-intel power_save=0 power_save_controller=0 position_fix=1 bdl_pos_adj=32
options snd-hda-codec-realtek model=auto
```

### What Each Fix Does:
1. **power_save=0** - Disables power saving (prevents codec sleep/wake pops)
2. **power_save_controller=0** - Disables controller power management
3. **position_fix=1** - Uses LPIB position fix (better timing for AMD HDA)
4. **bdl_pos_adj=32** - Increases buffer (reduces underruns)
5. **model=auto** - Forces auto model detection for ALC897

### Installation Steps:
```bash
sudo tee /etc/modprobe.d/alsa-base.conf > /dev/null << 'EOF'
# Audio fix for Realtek ALC897 codec
options snd-hda-intel power_save=0 power_save_controller=0 position_fix=1 bdl_pos_adj=32
options snd-hda-codec-realtek model=auto
EOF

sudo dracut -f --kver $(uname -r)
```

### Runtime Fix (immediate, before reboot):
```bash
echo 0 | sudo tee /sys/module/snd_hda_intel/parameters/power_save
echo N | sudo tee /sys/module/snd_hda_intel/parameters/power_save_controller
```

### Verification:
```bash
# Check applied parameters
cat /sys/module/snd_hda_intel/parameters/power_save  # Should be 0
cat /sys/module/snd_hda_intel/parameters/power_save_controller  # Should be N
cat /sys/module/snd_hda_intel/parameters/position_fix  # Should show 1

# Test audio
speaker-test -t wav -c 2 -l 1
```

## Status
- ✅ Configuration files created
- ✅ Initramfs rebuilt
- ✅ Runtime parameters applied
- ⏳ **Requires REBOOT for full effect**

## Hardware Details
```
Audio Device: 03:00.6 Audio device [0403]: AMD Family 17h/19h/1ah HD Audio Controller [1022:15e3]
Codec: Realtek ALC897
Driver: snd_hda_intel
Mixer: Realtek ALC897
```

## References
- Kernel module: `snd_hda_intel`
- Related: [Hyprland caelestia-shell-fedora](https://github.com/NullNaveen/caelestia-shell-fedora)
