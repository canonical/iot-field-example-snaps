# IoT Field example snaps

## Overview

This branch contains the daemon-control snap utilizing the core18 as its base snap. It is  created by the Devices Field
team. They are not generally recommended for production but instead act as
proof-of-concept examples for accomplishing particular tasks.

Each subdirectory is a different example, each with their own accompanying
READMEs which explain what they do, how they function, build instructions, and
potential limitations or ways to extend behavior.

## Snaps

###daemon-control

daemon-control is a demonstration of how to orchestrate daemon startup between
snaps. the controlled-daemon can be any snap which provides daemons, and the
controller-daemon shows how one snap could control those daemons.

This example should be considered a solution until cross-snap daemon startup
ordering is supported by snapd.

##Contributing

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
