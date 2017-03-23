#!/usr/bin/env bash
#
# Create a timeline of the releases
#

here=$(pwd)

refs=(386BSD-0.0 386BSD-0.1 386BSD-0.1-patchkit Bell-32V
  BSD* Research*)

cd $HOME/data/unix-history-repo

refs=(${refs[@]}
  $(git tag -l | grep FreeBSD ; git branch -l | grep FreeBSD-release ) )

for ref in ${refs[@]} ; do
  expr $ref : '.*-Import' >/dev/null && continue
  # Output file name
  out=$(echo $ref | sed 's|/|_|g;s/-release//;s/-releng//;/FreeBSD/s/_/-/')
  echo -n "$out "
  git log -n 1 --format=%at "$ref" --
done |
sort -k2n |
while read name date ; do
  echo $name $(date -d @$date +'%Y %m %d')
done |
sed '
# Based on ignoring unrelated commits
s/BSD-4_2 1988 03 09/BSD-4_2 1985 01 01/
# Make it appear before 32V, because this is how added facilities appear
s/BSD-2 1979 05 10/BSD-2 1979 05 01/
# Remove releases that are identical to their predecessors
/FreeBSD-2.1.6 /d
/FreeBSD-4.6.2/d
/FreeBSD-5.2.1/d
/FreeBSD-11.0.1/d
/BSD-4_3_Net_1/d
' >$here/timeline
