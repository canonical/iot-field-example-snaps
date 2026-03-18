# PulseAudio Snap for Ubuntu Core 24

A minimal PulseAudio sound server snap for Ubuntu Core 24, built using Ubuntu deb packages. Tested and working on Raspberry Pi 5 with both HDMI and 3.5mm audio outputs.

## Purpose

Provides audio-playback and audio-record interfaces for applications like Firefox on Ubuntu Core 24.

## Architecture

- **Base**: core24 (Ubuntu 24.04 LTS)
- **Snap Name**: pulseaudio
- **Version**: 16.1+dfsg1-2ubuntu10.1 (automatically adopted from package)
- **Packages**: Uses official Ubuntu 24.04 (Noble) PulseAudio packages
- **Platforms**: ARM64 (Raspberry Pi 4/5) and AMD64
- **Build**: Cross-compilation supported from AMD64 to ARM64
- **Confinement**: Strict

## Building

### Option 1: Remote Build via Launchpad (Recommended)

```bash
# Install snapcraft
sudo snap install snapcraft --classic

# Clone or navigate to the project
cd pulseaudio-minimal-working

# Build remotely for ARM64 using Launchpad
snapcraft remote-build --launchpad-accept-public-upload

# Output: pulseaudio_16.1+dfsg1-2ubuntu10.1_arm64.snap
```

### Option 2: Local Build

```bash
# Install snapcraft and lxd
sudo snap install snapcraft --classic
sudo snap install lxd
sudo lxd init --auto

# Build using LXD container
cd pulseaudio-minimal-working
snapcraft --use-lxd

# Or build in destructive mode (faster, but modifies system)
snapcraft --destructive-mode

# Output: pulseaudio_16.1+dfsg1-2ubuntu10.1_arm64.snap (or amd64)
```

## Installation on Ubuntu Core 24

### Complete Setup Process

```bash
# 1. Install the snap
sudo snap install --dangerous pulseaudio_16.1+dfsg1-2ubuntu10.1_arm64.snap

# 2. Connect ALSA interface (auto-starts and enables the service)
sudo snap connect pulseaudio:alsa

# 3. Start the service (if not already started by ALSA connection)
sudo snap start pulseaudio

# 4. Verify service is running
snap services pulseaudio
# Should show: enabled and active

# 5. List audio devices
sudo pulseaudio.pactl list sinks short
# Should show your HDMI and 3.5mm jack outputs

# 6. Connect Firefox to PulseAudio
sudo snap connect firefox:audio-playback pulseaudio:audio-playback
sudo snap connect firefox:audio-record pulseaudio:audio-record

# 7. Verify all connections
snap connections pulseaudio
```

## Usage with Firefox

### Launching Firefox with Audio Support

Due to the custom socket location used by this snap, Firefox needs to be launched with the `PULSE_SERVER` environment variable:

```bash
# Kiosk mode (fullscreen)
sudo PULSE_SERVER=unix:/var/snap/pulseaudio/common/var/run/pulse/native WAYLAND_DISPLAY=wayland-0 snap run firefox --kiosk "https://www.youtube.com"

# Normal mode
sudo PULSE_SERVER=unix:/var/snap/pulseaudio/common/var/run/pulse/native WAYLAND_DISPLAY=wayland-0 snap run firefox
```

### Switching Audio Outputs

```bash
# List available sinks
sudo pulseaudio.pactl list sinks short
# Example output:
# 0    alsa_output.platform-bcm2835_audio.stereo-fallback      (HDMI)
# 1    alsa_output.platform-bcm2835_audio.stereo-fallback.2    (3.5mm jack)

# Switch to HDMI (sink 0)
sudo pulseaudio.pactl set-default-sink 0

# Switch to 3.5mm jack (sink 1)
sudo pulseaudio.pactl set-default-sink 1

# Verify the change
sudo pulseaudio.pactl info | grep "Default Sink"
```

### Creating a Firefox Launcher Alias (Optional)

To simplify launching Firefox with audio, add this to `~/.bash_aliases`:

```bash
alias firefox-audio='sudo PULSE_SERVER=unix:/var/snap/pulseaudio/common/var/run/pulse/native WAYLAND_DISPLAY=wayland-0 snap run firefox'
alias firefox-kiosk='sudo PULSE_SERVER=unix:/var/snap/pulseaudio/common/var/run/pulse/native WAYLAND_DISPLAY=wayland-0 snap run firefox --kiosk'
```

Then reload: `source ~/.bashrc`

Now you can simply use:
```bash
firefox-kiosk "https://www.youtube.com"
```

## Available Commands

- `pulseaudio.pulseaudio` - PulseAudio daemon (runs as systemd service)
- `pulseaudio.pactl` - PulseAudio control utility

### Audio Management Commands

```bash
# List all sinks (outputs)
sudo pulseaudio.pactl list sinks short

# List all sources (inputs)
sudo pulseaudio.pactl list sources short

# Set default sink
sudo pulseaudio.pactl set-default-sink <sink-id>

# Adjust volume (0-65536, where 65536 = 100%)
sudo pulseaudio.pactl set-sink-volume 0 50000

# Mute/unmute
sudo pulseaudio.pactl set-sink-mute 0 toggle

# Get detailed info
sudo pulseaudio.pactl info
```

## Interfaces

### Plugs (What PulseAudio Connects To)

- `alsa` - Access to ALSA sound hardware (required)
- `network` - Network access for PulseAudio protocol
- `network-bind` - Bind to network sockets
- `hardware-observe` - Observe hardware information

### Slots (What PulseAudio Provides)

- `audio-playback` - Provides audio playback to other snaps (e.g., Firefox)
- `audio-record` - Provides audio recording to other snaps

## Hooks

### connect-plug-alsa

Automatically starts and enables the PulseAudio service when the ALSA interface is connected.

### install

Creates the runtime directory structure at `$SNAP_COMMON/var/run/pulse` during snap installation.

## Troubleshooting

### Check Service Status

```bash
# Check if service is running
snap services pulseaudio
# Should show: enabled and active

# View service logs
sudo journalctl -u snap.pulseaudio.pulseaudio -n 50 --no-pager

# Check real-time logs
sudo journalctl -u snap.pulseaudio.pulseaudio -f
```

### Verify Socket Creation

```bash
# Check if PulseAudio socket exists
sudo ls -la /var/snap/pulseaudio/common/var/run/pulse/

# Should show:
# srwxrwxrwx 1 root root 0 <date> native
# -rw------- 1 root root 5 <date> pid
```

### Check Interface Connections

```bash
# List all connections
snap connections pulseaudio

# Verify ALSA is connected
snap connections pulseaudio | grep alsa

# Verify Firefox is connected
snap connections pulseaudio | grep firefox
```

### Enable Debug Mode

```bash
# Create debug flag
sudo mkdir -p /var/snap/pulseaudio/current/config
sudo touch /var/snap/pulseaudio/current/config/debug

# Restart service
sudo snap restart pulseaudio.pulseaudio

# View verbose logs
sudo journalctl -u snap.pulseaudio.pulseaudio -f
```

### Common Issues

**"Connection refused" when running pactl:**
- Ensure service is active: `snap services pulseaudio`
- Check socket exists: `sudo ls -la /var/snap/pulseaudio/common/var/run/pulse/native`
- Verify ALSA is connected: `snap connections pulseaudio | grep alsa`
- Check logs: `sudo journalctl -u snap.pulseaudio.pulseaudio -n 50`

**No audio output from Firefox:**
- Ensure you're using the `PULSE_SERVER` environment variable in the Firefox launch command
- Check that Firefox audio interfaces are connected: `snap connections pulseaudio | grep firefox`
- Verify sinks are detected: `sudo pulseaudio.pactl list sinks short`
- Try switching the default sink: `sudo pulseaudio.pactl set-default-sink 1`

**Only seeing "auto_null" sink:**
- ALSA interface may not be connected: `sudo snap connect pulseaudio:alsa`
- Check ALSA permissions in logs: `sudo journalctl -u snap.pulseaudio.pulseaudio -n 50`
- Ensure hardware is physically connected (HDMI cable or headphones)

**Service won't start:**
- Check logs for errors: `sudo journalctl -u snap.pulseaudio.pulseaudio -n 50`
- Verify ALSA interface connection: `sudo snap connect pulseaudio:alsa`
- Try manually starting: `sudo snap start pulseaudio.pulseaudio`

## Project Structure

```
pulseaudio-minimal-working/
├── snap/
│   ├── snapcraft.yaml           # Snap build configuration
│   └── hooks/
│       ├── connect-plug-alsa    # Auto-start on ALSA connection
│       └── install              # Create runtime directories
├── src/
│   ├── bin/
│   │   ├── pulseaudio           # PulseAudio daemon wrapper
│   │   └── client-wrapper       # Client utility wrapper (pactl)
│   └── etc/
│       └── pulse/
│           ├── default.pa       # Server configuration
│           └── client.conf      # Client configuration
├── README.md
└── .gitignore
```

## Technical Details

### Socket Communication

- **Daemon socket location**: `$SNAP_COMMON/var/run/pulse/native`
- **Runtime path**: Set via `PULSE_RUNTIME_PATH` environment variable
- **Client configuration**: Uses `PULSE_RUNTIME_PATH` from environment, no hardcoded paths

### Module Loading

- **Module directory**: Dynamically detected during build (`pulse-16.1+dfsg1/modules`)
- **Path substitution**: Build process replaces `_pa_modules_dir` placeholder with actual directory name
- **Library path**: Includes PulseAudio module directory in `LD_LIBRARY_PATH`

### Version Management

- **Dynamic versioning**: Version automatically extracted from PulseAudio deb package
- **Epoch stripping**: Removes Debian epoch prefix (e.g., `1:`) from version string
- **Result**: Clean snap filenames without colons (e.g., `pulseaudio_16.1+dfsg1-2ubuntu10.1_arm64.snap`)

### Why Firefox Needs PULSE_SERVER

The standard snapd `audio-playback` interface expects PulseAudio to be at standard system locations (`/run/user/*/pulse/native`). This snap uses a custom socket location (`$SNAP_COMMON/var/run/pulse/native`) for better snap isolation. Firefox must be explicitly told where to find the socket via the `PULSE_SERVER` environment variable.

## Testing

### Verified Working On

- **Device**: Raspberry Pi 5
- **OS**: Ubuntu Core 24
- **Audio Outputs**:
  - ✅ HDMI audio
  - ✅ 3.5mm headphone jack
- **Applications**:
  - ✅ Firefox snap (with `PULSE_SERVER` variable)
  - ✅ pulseaudio.pactl commands

## License

GPL-2.0+

## Contributing

This snap was created for testing audio functionality on Ubuntu Core 24 with Firefox snap on Raspberry Pi 5 devices.

For issues or improvements, please refer to the project repository: https://github.com/Cruzh3r2107/pulseaudio-minimal-working
