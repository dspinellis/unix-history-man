#!/usr/bin/env bash
#
# Create a timeline of the releases
#

here=$(pwd)

refs=(386BSD-0.0 386BSD-0.1 386BSD-0.1-patchkit
  BSD* Research*)

cd $HOME/u/import

refs=(${refs[@]}
  $(git tag -l | grep FreeBSD ; git branch -l | grep FreeBSD-release ) )

for ref in ${refs[@]} ; do
  # Output file name
  out=$(echo $ref | sed 's|/|_|g;s/-release//;s/-releng//;s/_/-/')
  echo -n "$out "
  git log -n 1 --format=%at "$ref" --
done |
sort -k2n |
while read name date ; do
  echo $name $(date -d @$date +'%Y %m %d')
done >$here/timeline
