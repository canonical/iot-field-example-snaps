# pipewire-mixer

Runs **PipeWire + WirePlumber + pipewire-pulse as a strictly-confined system
daemon** on Ubuntu Core 26, so multiple snaps can share and mix audio. Clients
connect either natively (PipeWire) or over the PulseAudio-compatible socket.

Binaries come from the Ubuntu archive — **configuration only, no source
patches**. This is the config-only, WirePlumber-included realization of the
system-daemon model from `canonical/pipewire-snap` (branch `core-resurrection`).

Snaps in this example:

| Directory        | Snap                | Role                                         |
| ---------------- | ------------------- | -------------------------------------------- |
| `server/`        | `pipewire-mixer`    | PipeWire/WirePlumber/pipewire-pulse daemons. |
| `client-tone-a/` | `pw-client-tone-a`  | Toy client, 440 Hz tone.                     |
| `client-tone-b/` | `pw-client-tone-b`  | Toy client, 660 Hz tone.                     |

A PulseAudio equivalent is in `../pulseaudio-mixer`.

## Why core26

WirePlumber's `main-systemwide` profile (the system-daemon profile used here)
needs **wireplumber >= 0.5**. Noble's 0.4.17 is too old, so this targets
**core26**.

## Sockets (under `$SNAP_COMMON`)

| Socket                                   | Purpose                         | Mode |
| ---------------------------------------- | ------------------------------- | ---- |
| `$SNAP_COMMON/pipewire-0`                | PipeWire native                 | 0660 |
| `$SNAP_COMMON/pipewire-0-manager`        | PipeWire manager                | 0600 |
| `$SNAP_COMMON/pulse/native`              | PulseAudio compatibility        | 0660 |

These are the paths snapd's `pipewire` and `audio-playback` interfaces
whitelist for client snaps in system mode, so clients reach them at
`/var/snap/pipewire-mixer/common/...`.

## Daemons

Three `simple` daemons, ordered with `before:`/`after:`:
`pipewire` → then `wireplumber` (`-p main-systemwide`) and `pipewire-pulse`.
All `restart-condition: always`. Plus non-daemon tools: `pw-cli`, `pw-dump`,
`pw-top`, `wpctl`.

## Config drop-ins (`snap/local/etc/...`)

- `pipewire/pipewire.conf.d/90-core.conf` — disable `module.portal` and
  `module.jackdbus-detect` (no desktop/JACK D-Bus in a confined service).
- `pipewire/client.conf.d/90-core.conf` — `module.rt = false` (no rtkit here).
- `wireplumber/wireplumber.conf.d/90-core.conf` — intentionally near-empty;
  does **not** re-enable device reservation.

## Build

```bash
cd server           && snapcraft   # -> pipewire-mixer_<ver>_amd64.snap
cd ../client-tone-a && snapcraft   # -> pw-client-tone-a_0.1_amd64.snap
cd ../client-tone-b && snapcraft   # -> pw-client-tone-b_0.1_amd64.snap
```

## Run the mixing demo (Ubuntu Core 26, with audio hardware)

```bash
# Server
sudo snap install --dangerous pipewire-mixer_*.snap
sudo snap connect pipewire-mixer:alsa
sudo snap connect pipewire-mixer:hardware-observe
sudo snap start --enable pipewire-mixer.pipewire
sudo snap start --enable pipewire-mixer.wireplumber
sudo snap start --enable pipewire-mixer.pipewire-pulse

# Clients
sudo snap install --dangerous pw-client-tone-a_*.snap
sudo snap install --dangerous pw-client-tone-b_*.snap
sudo snap connect pw-client-tone-a:audio-playback pipewire-mixer:audio-playback
sudo snap connect pw-client-tone-b:audio-playback pipewire-mixer:audio-playback
sudo snap start pw-client-tone-a.play
sudo snap start pw-client-tone-b.play
```

Two tones (440 Hz + 660 Hz) play together = two confined snaps mixed by
PipeWire.

## How client snaps connect

- **PulseAudio-compatible (what the toy clients use):** plug `audio-playback`
  and set
  `PULSE_SERVER=unix:/var/snap/pipewire-mixer/common/pulse/native`.
- **Native PipeWire:** plug `pipewire` and set
  `PIPEWIRE_RUNTIME_DIR=/var/snap/pipewire-mixer/common` (socket
  `pipewire-0`).

## Smoke test

```bash
# WirePlumber sees the graph:
sudo pipewire-mixer.wpctl status

# Play a test file through the server (native):
sudo pipewire-mixer.pw-cli info all >/dev/null && echo "pipewire responding"

# While both tone clients run, list the streams being mixed:
sudo pipewire-mixer.pw-dump | grep -A2 -i 'node.name.*tone' | head
```

## Requirements & limitations

- Ubuntu Core 26 (wireplumber >= 0.5), snapd 2.71+.
- No session D-Bus: device reservation, portal, rtkit are deliberately off.
- Bluetooth (bluez) is out of scope here (a phase-2 addition).
- On a headless VM with no sound card there may be no real sink; the daemons
  still run and clients still connect, but you won't hear anything.

## Notes for maintainers

- Everything here is configuration only — if something ever *requires* a source
  patch to work, that's a stop-and-ask, not a silent fix.
- `alsa-ucm-conf` / `alsa-topology-conf` are staged so ALSA card profiles
  resolve inside confinement.
