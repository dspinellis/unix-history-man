# Manual page availability across major Unix releases
This repository maintains a database and a
[web site](https://dspinellis.github.io/unix-history-man/index.html)
of manual page availability
across the major Unix releases tracked by the
[Unix history repository](https://github.com/dspinellis/unix-history-repo).
This documents the evolution of Unix facilities across releases.
A file corresponding to each release contains records
with the manual page section and the corresponding page (e.g. `man1/cat.1`).
Where possible, the details are collected automatically from the source
code distribution through the
[Unix history repository](https://github.com/dspinellis/unix-history-repo).
In the remaining cases, the details have been hand-entered from printed
manuals and maintained through this repository.
A Perl script creates a
[web site](https://dspinellis.github.io/unix-history-man/index.html)
showing the availability of a facility on each Unix release.
