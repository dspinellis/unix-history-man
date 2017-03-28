# Manual page availability across major Unix releases
This repository maintains a database of manual page availability
across major Unix releases.
For each release a file contains the manual page section and the
corresponding page (e.g. `man1/cat.1`).
Where possible, the details are collected automatically from the source
code distribution through the
[Unix history repository](https://github.com/dspinellis/unix-history-repo).
In the remaining cases, the details are hand-entered from printed
manuals and maintained through this repository.
A Python script creates web-based tables showing the availability
of a facility on each Unix release.

