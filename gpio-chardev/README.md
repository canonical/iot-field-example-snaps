# gpio-chardev

A proof-of-concept showing how an application snap drives GPIO on Ubuntu Core
through the modern **`gpio-chardev`** interface (libgpiod / character device),
plus the **gadget** side that exposes the lines.

This example has two parts:

| Directory        | What it is                                                        |
| ---------------- | ----------------------------------------------------------------- |
| `consumer/`      | Application snap that uses the GPIO lines (`gpio-chardev` plug).   |
| `example-gadget/`| A `pc` gadget (amd64/UC26) with a matching `gpio-chardev` slot.    |

## Why gpio-chardev (and not `gpio`)

The legacy `gpio` interface uses the kernel **sysfs** GPIO ABI
(`/sys/class/gpio/...`), which is deprecated and **removed on UC26+** — a `gpio`
example would not work on a current device. `gpio-chardev` uses the character
device ABI (via the kernel `gpio-aggregator` + configfs) and is the supported
interface going forward. It needs **snapd 2.72+** (UC24+ for the kernel
support). The two cannot be connected at the same time.

## How it works

1. The **gadget** declares which chip and lines to expose, in `gadget.yaml`:

   ```yaml
   slots:
     example-gpio:
       interface: gpio-chardev
       source-chip: [gpiochip0]   # your chip's label (see `gpiodetect`)
       lines: 0-3                 # comma list and/or inclusive ranges
   ```

2. The **consumer** declares a plug of the same interface:

   ```yaml
   plugs:
     example-gpio:
       interface: gpio-chardev
   ```

3. On connection, snapd's `snap-gpio-helper` exports *only* those lines to the
   consumer as a dedicated character device at
   `/dev/snap/gpio-chardev/<slot>/...`. The consumer's libgpiod tools
   (`gpiodetect`, `gpioinfo`, `gpioset`, `gpioget`) operate on that node and
   cannot touch any other lines.

## Consumer commands

- `gpio-chardev-consumer.detect` — list exported nodes and run `gpiodetect`.
- `gpio-chardev-consumer.blink <offset> [count] [sec]` — pulse a line.
- `gpio-chardev-consumer.toggle` — daemon (disabled by default) that toggles a
  line every `interval` seconds (`snap set ... line=<n> interval=<s>`).

## Build

```bash
# Consumer app snap
cd consumer && snapcraft            # -> gpio-chardev-consumer_0.1_amd64.snap

# Example gadget (pulls the official pc gadget, adds the slot)
cd ../example-gadget && snapcraft   # -> gpio-chardev-example-gadget_0.1_amd64.snap
```

## Using it on a device

The gadget must be the device's gadget (baked into the image, or the running
gadget refreshed to one carrying the slot). Then:

```bash
sudo snap install --dangerous gpio-chardev-consumer_0.1_amd64.snap

# Connect the plug to the gadget slot (not auto-connected):
sudo snap connect gpio-chardev-consumer:example-gpio \
     gpio-chardev-example-gadget:example-gpio

gpio-chardev-consumer.detect
gpio-chardev-consumer.blink 0 5 1
```

Find your real chip label and line offsets with `gpiodetect` / `gpioinfo` on
the device, and update `source-chip` / `lines` in the gadget accordingly.

## Using it on a real board (e.g. NXP FRDM-i.MX93)

The `example-gadget` here is the amd64 `pc` gadget — it will **not** run on an
arm64 board. On a board like the FRDM-i.MX93 you already have your own kernel +
gadget snaps, so add the slot to **your** gadget instead of using this one.

1. **Kernel:** the `gpio-chardev` interface needs the kernel `gpio-aggregator`
   with configfs. Confirm your kernel snap has it (or build with it =y):

   ```
   zcat /proc/config.gz | grep -E 'GPIO_AGGREGATOR|CONFIGFS_FS'
   # want: CONFIG_GPIO_AGGREGATOR=y (or =m) and CONFIG_CONFIGFS_FS=y
   ```

2. **Find the real chip label + lines** on the booted board:

   ```
   gpiodetect                 # e.g. "43810080.gpio" (i.MX93 GPIO2) - label, not name
   gpioinfo <chip>            # pick the line offsets wired to your EXPI header pins
   ```

3. **Add the slot to your gadget's `gadget.yaml`** (see `example-gadget/snap/slots.yaml`),
   using that label and your lines, e.g.:

   ```yaml
   slots:
     example-gpio:
       interface: gpio-chardev
       source-chip: [43810080.gpio]   # your i.MX93 chip label from gpiodetect
       lines: 0-3                      # EXPI header lines you wired
   ```

   Rebuild/refresh your gadget so the slot is present (`snap connections` /
   `snap interface gpio-chardev` will show it).

4. **Install the arm64 consumer and connect** (build the consumer for arm64 -
   its snapcraft.yaml already declares `arm64` under `platforms:`):

   ```
   sudo snap install --dangerous gpio-chardev-consumer_0.1_arm64.snap
   sudo snap connect gpio-chardev-consumer:example-gpio <your-gadget>:example-gpio
   gpio-chardev-consumer.detect
   gpio-chardev-consumer.blink 0 5 1   # wire an LED to that EXPI pin to see it
   ```

## Requirements & limitations

- **snapd 2.72+** and **UC24+** (needs the `gpio-aggregator` configfs kernel
  support). On UC26 this is the interface to use.
- Slots can only be declared by a **gadget** snap.
- The `example-gadget` here is the upstream `pc` gadget with the slot added, so
  it targets amd64 UC26. For another board, add the same `slots:` block to that
  board's gadget rather than using this one.
- Requires real GPIO hardware to do anything visible; on a generic amd64 VM
  there may be no usable GPIO chip even though the interface connects.

## Extending

- Expose multiple slots (e.g. one per functional group of lines) so different
  consumer snaps get least-privilege access to just their lines.
- Replace the libgpiod CLI wrappers with a compiled app linking `libgpiod`.
