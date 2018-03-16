#!/usr/bin/env bash
#
# Create a timeline of the releases through the commit log
#
# Copyright 2017-2018 Diomidis Spinellis
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

GIT='git --git-dir=unix-history-repo'

cd data
refs=(386BSD-0.0 386BSD-0.1 remotes/origin/386BSD-0.1-patchkit Bell-32V
  BSD* Research*)
cd ..

test -d unix-history-repo/ || exit 1

refs=(${refs[@]}
  $($GIT tag -l | grep FreeBSD ; $GIT branch -al | grep FreeBSD-release ) )

for ref in ${refs[@]} ; do
  expr $ref : '.*-Import' >/dev/null && continue
  # Output file name
  out=$(echo $ref | sed 's|remotes/origin/||;s|/|_|g;s/-release//;s/-releng//;/FreeBSD/s/_/-/')
  echo -n "$out "
  $GIT log -n 1 --format=%at "$ref" --
done |
while read name date ; do
  echo $name $(date -d @$date +'%Y %m %d')
done |
sed '
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
sort -u |
sort -k2n -k3n -k4n >data/timeline
