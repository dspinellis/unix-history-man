#!/usr/bin/env bash
#
# List manual pages in FreeBSD trees
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

test -d unix-history-repo/ || exit 1

all_refs="386BSD-0.0 386BSD-0.1 386BSD-0.1-patchkit
  BSD-4_3_Net_2 BSD-4_3_Reno BSD-4_4 BSD-4_4_Lite1 BSD-4_4_Lite2
  $($GIT tag -l | grep FreeBSD
    $GIT branch -al |
      sed -n 's|remotes/origin/||;/FreeBSD-release/p' |
      sort -u)"

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

  # See if remote ref must be used
  uri_prefix=$ref
  if ! $GIT show $ref >/dev/null 2>&1 ; then
    ref=remotes/origin/$ref
  fi

  {
    # List files that look like man pages
    $GIT ls-tree --name-only -r $ref |
    # Remove old reference files and learn files
    grep -v -e '^\.ref' -e /learnlib/ -e /libdata/learn/ |
    # Find names ending in .1-9 optionally followed by a character
    egrep '\.[1-9][a-z]?$' |
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
    sed -nE 's|(.*\/)([^/]*)\.([1-9][a-z]?)$|\3\t\2\t'$uri_prefix'\/\1\2.\3|p'

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
    sed -rn '/^[ \t]*MLINKS/ { s/.*=[ \t]*//; s/[ \t]*#.*//; p; }' |
    # Print pairs of linked pages: existing linked
    awk '{for (i = 1; i <= NF; i += 2) print "MLINK", $i, $(i + 1)}' |
    # Remove relative paths
    sed 's/ .*\// /g' |
    # Remove entries with embedded variables and empty ones
    grep -v -e '\$' -e '^$'
  } |
  # Remove non-man pages
  egrep -v -e /Makefile -e BUGS -e makewhatis.sed -e man\\.template \
    -e man0/ -e tools/ -e ' manroff' -e manx/asmt.cat -e manx/asmt.x \
    -e ' docket' -e manx/toc -e ' nroff-all' -e '/[0-9].[0-9]$' \
    -e INST.FreeBSD-2 -e ipv6-patch-4 -e version5\\.9 |
  # List linked pages, adding the URIs if available
  awk '
    # Store defined paths as possible URIs to link
    !/^MLINK/ { uri[$2 "." $1] = $3; print }

    function reformat(x) { return gensub(/^(.*)\.([^.]*)$/, "\\2\t\\1", 1, x) }

    # Output URIs for linked pages
    /^MLINK/ && NF == 3 && $2 != $3 {

      # See if a trailing x must be added (required for FreeBSD curses .3x)
      if (!uri[$2] && uri[$2 "x"])
	$2 = $2 "x"

      if (uri[$2])
	# Output the linked page with the URI of the original
        print reformat($3) "\t" uri[$2]
      else {
	# Output both the linked and the original name w/o a URI
        print reformat($2)
        print reformat($3)
      }
    }' |
  sort -u >$out
done

# Remove duplicate and empty files
cd data
rm -f *-Import FreeBSD-11.0.1 FreeBSD-2.1.6 FreeBSD-4.6.2 FreeBSD-5.2.1
