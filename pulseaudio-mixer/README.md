# pulseaudio-mixer

Shows how to run **PulseAudio as a shared sound server** on Ubuntu Core so that
**multiple independent snaps play audio at once and are mixed** to a single
output, using the `audio-playback` / `audio-record` interfaces.

Three snaps:

| Directory        | Snap                | Role                                              |
| ---------------- | ------------------- | ------------------------------------------------- |
| `server/`        | `pulseaudio-mixer`  | The sound server (provides the audio slots).      |
| `client-tone-a/` | `client-tone-a`     | Toy client, plays a 440 Hz tone.                  |
| `client-tone-b/` | `client-tone-b`     | Toy client, plays a 660 Hz tone.                  |

Running both clients at once produces two tones mixed together — proof that two
separately-confined snaps share one output through the server.

The server is adapted from the `pulseaudio-minimal-working` reference, moved to
**core26**. A PipeWire equivalent of this example is in `../pipewire-mixer`.

## How the sharing works

The `audio-playback` interface only lets a client reach a PulseAudio server
socket at a specific path. In "system mode" (a server snap, no user session)
that path is:

```
/var/snap/<server-snap>/common/pulse/native
```

So the server must place its native socket there. This example sets
`PULSE_RUNTIME_PATH=$SNAP_COMMON/pulse` on the server for exactly that reason
(the original minimal reference used `common/var/run/pulse`, which works for its
own bundled `pactl` but is **not** reachable by other snaps). Each client sets
`PULSE_SERVER=unix:/var/snap/pulseaudio-mixer/common/pulse/native`.

## Build

```bash
cd server        && snapcraft   # -> pulseaudio-mixer_<ver>_amd64.snap
cd ../client-tone-a && snapcraft # -> client-tone-a_0.1_amd64.snap
cd ../client-tone-b && snapcraft # -> client-tone-b_0.1_amd64.snap
```

## Run the mixing demo (on an Ubuntu Core 26 device with audio hardware)

```bash
# 1. Server
sudo snap install --dangerous pulseaudio-mixer_*.snap
sudo snap connect pulseaudio-mixer:alsa           # auto-starts the daemon
sudo snap connect pulseaudio-mixer:hardware-observe
sudo snap start pulseaudio-mixer.pulseaudio

# 2. Clients
sudo snap install --dangerous client-tone-a_*.snap
sudo snap install --dangerous client-tone-b_*.snap

# Connect each client's plug to the server's slot
sudo snap connect client-tone-a:audio-playback pulseaudio-mixer:audio-playback
sudo snap connect client-tone-b:audio-playback pulseaudio-mixer:audio-playback

# 3. Start both tones at once
sudo snap start client-tone-a.play
sudo snap start client-tone-b.play
```

You should hear a 440 Hz and a 660 Hz tone playing together.

## Smoke test / verifying the mix

```bash
# List the streams the server is mixing - you should see BOTH clients:
sudo pulseaudio-mixer.pactl list sink-inputs | grep -E 'index:|stream-name|application.name'
```

Two `sink-input` entries = two snaps being mixed into one sink.

## Requirements & limitations

- Ubuntu Core 26, real audio output (HDMI / analog). On a headless VM with no
  sound card PulseAudio loads `module-always-sink` (a null sink) so the daemon
  and mixing still work, but you won't hear anything.
- Strict confinement throughout.
- If a client can't reach the server, re-check the socket path and that the
  `audio-playback` connection is in `snap connections`.

## Extending

- Replace the toy tone clients with real apps (Firefox, mpv, a custom player):
  same pattern — plug `audio-playback`, set `PULSE_SERVER` to the server socket.
- Add `audio-record` connections for capture/mixing of inputs.
