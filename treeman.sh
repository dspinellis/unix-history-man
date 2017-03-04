#!/usr/bin/env bash
#
# List manual pages in FreeBSD trees
#

here=$(pwd)

cd $HOME/u/import

all_refs="386BSD-0.0 386BSD-0.1 386BSD-0.1-patchkit
  BSD-4_3_Net_2 BSD-4_3_Reno BSD-4_4 BSD-4_4_Lite1 BSD-4_4_Lite2
  $(git tag -l | grep FreeBSD ; git branch -l | grep FreeBSD-release )"

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
  out=$(echo $ref | sed 's|/|_|g;s/-release//;s/-releng//;/FreeBSD/s/_/-/')

  {
    # List files that look like man pages
    git ls-tree --name-only -r $ref |
    # Remove old reference files
    grep -v '^\.ref' |
    # Find name ending in .1-9
    grep '\.[1-9]$' |
    while read f ; do
      # Look for manual troff commands
      if ! git show $ref:$f | egrep -q '^\.(\\"|S[Hh])' ; then
	type=$(git show $ref:$f | file -)
	# See if file(1) thinks its troff
	if ! expr match "$type" '.*troff' >/dev/null ; then
	  continue
	fi
      fi
      echo $f
    done |
    # Change path/name.x to manx/name.x
    sed -n 's/.*\/\([^/]*\.\)\([1-9]\)$/man\2\/\1\2/p'

    # Also list cross-linked man pages
    git ls-tree --name-only -r $ref |
    # Remove old reference files
    grep -v '^\.ref' |
    # Find Makefiles
    grep Makefile |
    # List their contents
    sed "s|^|$ref:|" |
    xargs git show |
    join_backslash |
    # Output linked man pages
    sed -rn '/^[ \t]*MLINKS/ { s/.*=//; s/[ \t]+/\n/g; p; }' |
    # Remove relative paths
    sed 's/^.*\///g' |
    # Remove entries with embedded variables
    grep -v -e '\$' -e '^$' |
    # Change name.x to manx/name.x
    sed -n 's/\([^/]*\.\)\([1-9]\)$/man\2\/\1\2/p'
  } |
  # Remove non-man pages
  egrep -v -e /Makefile -e BUGS -e makewhatis.sed -e man\\.template \
    -e man0/ -e tools/ -e ^manroff -e manx/asmt.cat -e manx/asmt.x \
    -e ^docket -e manx/toc -e ^nroff-all |
  sort -u >$here/$out
done

# Remove duplicate and empty files
cd $here
rm *-Import FreeBSD-11.0.1 FreeBSD-2.1.6 FreeBSD-4.6.2 FreeBSD-5.2.1
