#!/usr/bin/env bash
#
# Create a timeline of the releases
#

here=$(pwd)

cd data
refs=(386BSD-0.0 386BSD-0.1 remotes/origin/386BSD-0.1-patchkit Bell-32V
  BSD* Research*)
cd ..

cd unix-history-repo || exit 1

refs=(${refs[@]}
  $(git tag -l | grep FreeBSD ; git branch -al | grep FreeBSD-release ) )

for ref in ${refs[@]} ; do
  expr $ref : '.*-Import' >/dev/null && continue
  # Output file name
  out=$(echo $ref | sed 's|/|_|g;s/-release//;s/-releng//;/FreeBSD/s/_/-/')
  echo -n "$out "
  git log -n 1 --format=%at "$ref" --
done |
while read name date ; do
  echo $name $(date -d @$date +'%Y %m %d')
done |
sed '
s/remotes.origin_//
# Based on ignoring unrelated commits
s/BSD-4_2 1988 03 09/BSD-4_2 1985 01 01/
# Make 32V appear after the Seventh edition (1979 08 26)
s/Bell-32V 1979 05 03/Bell-32V 1979 08 28/
# Make BSD-2 appear before 32V, because this is how added facilities appear
s/BSD-2 1979 05 10/BSD-2 1979 08 27/
# Remove releases that are identical to their predecessors
/FreeBSD-2.1.6 /d
/FreeBSD-4.6.2/d
/FreeBSD-5.2.1/d
/FreeBSD-11.0.1/d
/BSD-4_3_Net_1/d
' |
sort -k2n -k3n -k4n >$here/timeline
