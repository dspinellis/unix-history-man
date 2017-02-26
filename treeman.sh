#!/bin/sh
#
# List manual pages in FreeBSD trees
#

here=$(pwd)

cd $HOME/u/import

refs="386BSD-0.0 386BSD-0.1 386BSD-0.1-patchkit
  $(git tag -l | grep FreeBSD ; git branch -l | grep FreeBSD-release )"


for ref in $refs ; do
  # Output file name
  out=$(echo $ref | sed 's|/|_|g;s/-release//;s/-releng//;s/_/-/')
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
    # Change name to manx/foo.x
    echo $f | sed -n 's/.*\/\([^/]*\.\)\([1-9]\)$/man\2\/\1\2/p'
  done |
  sort -u >$here/$out
done

rm *-Import
