#!/usr/bin/env bash
#
# List manual pages in FreeBSD trees
#

GIT='git --git-dir=unix-history-repo'

test unix-history-repo || exit 1

all_refs="386BSD-0.0 386BSD-0.1 386BSD-0.1-patchkit
  BSD-4_3_Net_2 BSD-4_3_Reno BSD-4_4 BSD-4_4_Lite1 BSD-4_4_Lite2
  $($GIT tag -l | grep FreeBSD ; $GIT branch -l | grep FreeBSD-release )"

refs=${1:-$all_refs}

# Join backslash-terminated lines
join_backslash()
{
  sed  '
  : again
  /\\$/ {
      N
      s/\\\n//
      t again
  }
  ' "$@"
}

export -f join_backslash

for ref in $refs ; do
  # Output file name
  out=data/$(echo $ref | sed 's|/|_|g;s/-release//;s/-releng//;/FreeBSD/s/_/-/')

  {
    # List files that look like man pages
    $GIT ls-tree --name-only -r $ref |
    # Remove old reference files
    grep -v '^\.ref' |
    # Find name ending in .1-9
    grep '\.[1-9]$' |
    while read f ; do
      # Look for manual troff commands
      if ! $GIT show $ref:$f | egrep -q '^\.(\\"|S[Hh])' ; then
	type=$($GIT show $ref:$f | file -)
	# See if file(1) thinks its troff
	if ! expr match "$type" '.*troff' >/dev/null ; then
	  continue
	fi
      fi
      echo $f
    done |
    # Change path/name.x to x name URI
    sed -n 's|\(.*\/\)\([^/]*\)\.\([1-9]\)$|\3\t\2\t'$ref'\/\1\2.\3|p'

    # Also list cross-linked man pages
    $GIT ls-tree --name-only -r $ref |
    # Remove old reference files
    grep -v '^\.ref' |
    # Find Makefiles
    grep Makefile |
    # List their contents
    sed "s|^|$ref:|" |
    xargs $GIT show |
    join_backslash |
    # Output linked man pages
    sed -rn '/^[ \t]*MLINKS/ { s/.*=[ \t]*//; p; }' |
    # Print pairs of linked pages: existing linked
    awk '{for (i = 1; i <= NF; i += 2) print "MLINK", $i, $(i + 1)}' |
    # Remove relative paths
    sed 's/ .*\///g' |
    # Remove entries with embedded variables
    grep -v -e '\$' -e '^$'
  } |
  # Remove non-man pages
  egrep -v -e /Makefile -e BUGS -e makewhatis.sed -e man\\.template \
    -e man0/ -e tools/ -e ^manroff -e manx/asmt.cat -e manx/asmt.x \
    -e ^docket -e manx/toc -e ^nroff-all -e '/[0-9].[0-9]$' \
    -e 'INST.FreeBSD-2' -e 'ipv6-patch-4' -e 'version5\.9' |
  # Add the URIs of linked pages
  awk '!/^MLINK/ { uri[$2 "." $1] = $3; print }
  /^MLINK/ && uri[$2] { print gensub(/^(.*)\.([^.]*)$/, "\\2\t\\1\t", 1, $3) uri[$2]}' |
  sort -u >$out
done

# Remove duplicate and empty files
cd data
rm -f *-Import FreeBSD-11.0.1 FreeBSD-2.1.6 FreeBSD-4.6.2 FreeBSD-5.2.1
