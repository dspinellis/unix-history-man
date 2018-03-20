# The history of documented Unix facilities
A [timeline visualization](https://dspinellis.github.io/unix-history-man/index.html),
a [curated data set](https://dspinellis.github.io/unix-history-man/data.zip), and
a [repository](https://github.com/dspinellis/unix-history-man)
detailing the evolution of 15,596 unique documented facilities
(commands, system calls, library functions, device drivers, etc.)
across 93 major Unix releases tracked by the
[Unix history repository](https://github.com/dspinellis/unix-history-repo).


## Example records
A file corresponding to each release contains tab-separated records
with the manual page section (1–9), the name,
and, if available, a URI of the corresponding page.
In total, the set contains data about 193,781 unique URIs,
identifying 48,250 distinct manual page instances.
The raw data are available through
[this link](https://dspinellis.github.io/unix-history-man/data.zip).
Below are some records from the data set.
```

1       date    Research-V4/man/man1/date.1
2       open    Research-V3/man/man2/open.2
2       socket  BSD-4_2/usr/man/man2/socket.2
2       jail    FreeBSD-release/4.11.0/lib/libc/sys/jail.2
3s      fopen   Research-V7/usr/man/man3/fopen.3s
4       vga     386BSD-0.1-patchkit/usr/src/usr.sbin/keymap/lib/co.4
5       vgafont 386BSD-0.1-patchkit/usr/src/usr.sbin/keymap/lib/vgafont.5
6       tetris  BSD-4_4_Lite2/usr/src/games/tetris/tetris.6
7       c78     FreeBSD-release/9.0.0/share/man/man7/c99.7
8       dump    Research-V4/man/man8/dump.8
9       VFS     FreeBSD-release/2.2.0/share/man/man9/VFS.9
```

## Construction
Where possible, the details are collected automatically from the
[Unix history repository](https://github.com/dspinellis/unix-history-repo).
In the remaining cases, the details have been hand-entered from printed
manuals.
(The [Third Edition](https://github.com/dspinellis/unix-v3man) and
the [Fourth Edition](https://github.com/dspinellis/unix-v4man)
manuals were recreated from their 1970s source code.)
A Perl script creates the
[timeline visualization web site](https://dspinellis.github.io/unix-history-man/index.html)
showing the availability timeline of each facility
on every tracked Unix release.
The scripts and the curated data are available and are
maintained in the
[history of documented Unix facilities repository](https://github.com/dspinellis/unix-history-man).

## Related publications
* Diomidis Spinellis. [Documented Unix facilities over 48 years](https://www.dmst.aueb.gr/dds/pubs/conf/2018-MSR-Unix-man/html/unix-man.pdf).  In
*MSR '18: Proceedings of the 15th Conference on Mining Software Repositories*.
Association for Computing Machinery, May 2018. doi:10.1145/3196398.3196476
* Diomidis Spinellis.
[A repository of Unix History and evolution](http://www.dmst.aueb.gr/dds/pubs/jrnl/2016-EMPSE-unix-history/html/unix-history.html).
Empirical Software Engineering, 22(3):1372–1404, 2017.
[doi:10.1007/s10664-016-9445-5](http://dx.doi.org/10.1007/s10664-016-9445-5)
