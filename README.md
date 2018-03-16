# Manual page availability across major Unix releases
This repository maintains a
[curated data set](https://dspinellis.github.io/unix-history-man/data.zip)
and a [web site](https://dspinellis.github.io/unix-history-man/index.html)
tracking documented facilities (commands, system calls, library functions, etc)
across the major Unix releases tracked by the
[Unix history repository](https://github.com/dspinellis/unix-history-repo).
A file corresponding to each release contains records
with the manual page section, the name, and a URI
of the corresponding page (e.g. `1       date    Research-V4/man/man1/date.1`).
Where possible, the details are collected automatically from the
[Unix history repository](https://github.com/dspinellis/unix-history-repo).
In the remaining cases, the details have been hand-entered from printed
manuals, and are maintained through this repository.
A Perl script creates a
[web site](https://dspinellis.github.io/unix-history-man/index.html)
showing the availability of each facility on every tracked Unix release.
The raw data are available through
[this link](https://dspinellis.github.io/unix-history-man/data.zip).
