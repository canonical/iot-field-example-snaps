# IoT Field example snaps

## Overview

This repository contains a collection of snaps created by the Devices Field
team. They are not generally recommended for production but instead act as
proof-of-concept examples for accomplishing particular tasks.

Each subdirectory is a different example, each with their own accompanying
READMEs which explain what they do, how they function, build instructions, and
potential limitations or ways to extend behavior.

## Snaps

### automount-actions

automount-actions is an example snap for acknowledging snaps and their
assertions on a device. The snaps and assertions are provided by a block device
(e.g. a USB stick). This device is automatically mounted and checked for the
correct files, and those files are then processed using the snapd REST API.

### one-codebase-many-snaps

one-codebase-many-snaps shows how one could have a single repository build
multiple different snaps. The project uses a Makefile for demonstration purposes
but this could be extended to any build system or even scripting.

### qt-imx

qt-imx is a PoC snap for how to include proprietary graphics libraries and Qt
for displaying graphical elements to a display. The example specifically targets
the i.MX platform from NXP, but can be modified to cover other platforms.

### using-docker

using-docker contains a collection of minimal tooling (written as very trivial
shell scripts) and a comprehensive `snapcraft.yaml` to showcase what
orchestrating various Docker containers on an Ubuntu Core system might look
like.

## Contributing

You should sign the [Canonical contributor license agreement](https://ubuntu.com/legal/contributors).

Commits should be formatted as such:

* Entire message should read as:

```
<{example,file/folder} name>: short and sweet description

Further details if required

Signed-off-by: <author name> <author email>
```

* Include a signoff for each commit using `git commit -s`
    * To amend prior commits with a signoff, do `git rebase --signoff
      HEAD~<number of commits>`

* You should use `<example name>` if you are specifically adding an entire example
snap.

* If you are modifying the root of the repository (e.g. modifying/adding
`.github`, `/README.md`, etc.), you should use one of `github`, `README`,
`gitignore`, `LICENSE`, etc.

* If you are adding something to a particular file, it would be sufficient to say
`<file/folder name>: short and sweet description` and include an elaboration of
what is being added to which example in further details.

* Commits should attempt to be atomic though PRs need not be restricted to a
single folder or file, as long as the content change can be logically grouped.

Please follow the Issue and PR template as best as possible.
