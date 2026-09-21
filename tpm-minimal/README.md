# tpm-minimal

A proof-of-concept snap showing how a **strictly-confined** application snap can
talk to the system **TPM** (Trusted Platform Module) on Ubuntu Core through the
[`tpm` snap interface](https://snapcraft.io/docs/tpm-interface).

This example is about **application-level TPM access** — reading PCRs, querying
capabilities, sealing/unsealing secrets, attestation, etc. It is **not** about
TPM-backed full-disk encryption / measured boot: that is a property of the
device *model grade* (`signed`/`secured` with UEFI Secure Boot), where snapd
seals the disk keys to the TPM for you, and needs no interface.

## What it does

- `tpm-minimal.tpm-info` — one-shot command: prints TPM fixed properties, the
  active PCR banks, and the SHA-256 PCR values (via `tpm2-tools`).
- `tpm-minimal.tpm-watch` — a `simple` daemon (disabled by default) that reads
  PCR 7 every `interval` seconds, to demonstrate a long-running confined service
  using the TPM.

Both talk to the kernel **TPM resource manager** at `/dev/tpmrm0` (the
multi-client-safe entrypoint) via the `TPM2TOOLS_TCTI=device:/dev/tpmrm0`
environment variable set in `snapcraft.yaml`.

## The interface

The `tpm` interface grants read/write to `/dev/tpm[0-9]*` and
`/dev/tpmrm[0-9]*`. In snapd's base declaration it has
`deny-auto-connection: true`, so it is **not** connected automatically — you
must connect it explicitly after install.

```yaml
plugs:
  tpm:
    interface: tpm
```

## Build

```bash
snapcraft            # or: snapcraft --use-lxd
```
Produces `tpm-minimal_0.1_<arch>.snap`.

## Install and connect (on an Ubuntu Core device with a TPM)

```bash
sudo snap install --dangerous tpm-minimal_0.1_amd64.snap
sudo snap connect tpm-minimal:tpm          # required - not auto-connected
```

## Smoke test

```bash
# One-shot capability + PCR read
tpm-minimal.tpm-info

# Start the watcher daemon and follow its log
sudo snap set tpm-minimal interval=10
sudo snap start --enable tpm-minimal.tpm-watch
sudo snap logs -f tpm-minimal.tpm-watch
```

Expected: `tpm-info` prints `TPM2_PT_*` fixed properties and a table of PCR
values; `tpm-watch` logs a PCR 7 digest every 10 seconds.

## Where to get a TPM to test against

Not every board has a discrete TPM. What matters to this snap is only that
`/dev/tpmrm0` exists — however it's provided:

- **QEMU + swtpm (easiest for verification).** Emulate a TPM 2.0 for a UC VM:

  ```
  sudo apt install swtpm
  mkdir -p /tmp/mytpm
  swtpm socket --tpm2 --tpmstate dir=/tmp/mytpm \
        --ctrl type=unixio,path=/tmp/mytpm/swtpm-sock &
  # add to your qemu-system-x86_64 line:
  #   -chardev socket,id=chrtpm,path=/tmp/mytpm/swtpm-sock \
  #   -tpmdev emulator,id=tpm0,chardev=chrtpm \
  #   -device tpm-tis,tpmdev=tpm0
  ```
  The guest then has `/dev/tpmrm0` and this snap works unchanged.

- **Intel NUC / most x86 with firmware TPM (Intel PTT).** Many boards have no
  discrete TPM but provide fTPM 2.0 in firmware. Enable it in BIOS (Security →
  "Intel Platform Trust Technology" / PTT), then confirm `ls -l /dev/tpm*`
  shows `/dev/tpm0` + `/dev/tpmrm0`.

- **NXP i.MX93 (and similar).** No discrete TPM and no simple firmware TPM: a
  `/dev/tpm0` there requires porting the **OP-TEE firmware TPM** (optee-ftpm +
  RPMB). The on-SoC EdgeLock Enclave is *not* a Linux `/dev/tpm`. Treat TPM on
  i.MX93 as a porting task, not a quick test — use QEMU or an Intel PTT box for
  exercising this example.

## Requirements & limitations

- The device must actually have a TPM (`/dev/tpmrm0` present). On a VM you can
  add an emulated TPM (e.g. QEMU `-tpmdev`/swtpm) to try it.
- `tpm2-tools` is pulled from the Ubuntu archive at build time; the version is
  whatever core26 (Ubuntu 26.04) ships.
- Strict confinement only — no classic mode needed.

## Extending

- Seal a secret to the current PCR state (`tpm2_create`/`tpm2_load` +
  `policy-pcr`) and unseal it only when the measured boot state matches.
- Use `tpm2_quote` for remote attestation.
- Swap `tpm2-tools` for direct `tpm2-tss` (`libtss2-*`) calls in a compiled app.
