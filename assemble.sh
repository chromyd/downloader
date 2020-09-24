#!/bin/bash
#
# Assembles all parts based on the M3U8 file into a TS file

function die {
  echo $*
  exit 1
}

function get_base_name()
{
  if [ -e $1 ]
  then
    local FULL_BASE=$(basename $1)
    echo ${FULL_BASE%%.*}
  else
    echo Unnamed
  fi
}

INPUT=${1:-~/FirefoxDownloads/2020????-???@???}
test $(echo $INPUT | wc -w) -eq 1 || die "More than one M3U8 playlist found"

sed -i '' -e '/^https:/d' $INPUT

BASE_NAME=$(get_base_name $INPUT)

OUTPUT=$BASE_NAME.ts

cd $(dirname $INPUT) &&
echo Processing $INPUT to produce $OUTPUT in $(pwd) &&

test -s $OUTPUT || perl $(dirname $0)/decode.pl $INPUT $(grep -v '^#' $INPUT | wc -l) $OUTPUT &&
grep -v '^#' $INPUT | tr / _ | xargs rm &&
rm -f $INPUT *.key &&
ls $PWD/$OUTPUT
