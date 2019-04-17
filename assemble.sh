#!/bin/bash
#
# Assembles all parts based on the M3U8 file into a TS file

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

INPUT=${1:-~/ChromeDownloads/*.m3u*}

sed -i '' -e '/^https:/d' $INPUT

BASE_NAME=$(get_base_name $INPUT)

OUTPUT=$BASE_NAME.ts

cd $(dirname $INPUT) &&
echo Processing $INPUT to produce $OUTPUT &&

test -s $OUTPUT || perl $(dirname $0)/decode.pl $INPUT $(grep -v '^#' $INPUT | wc -l) $OUTPUT &&
grep -v '^#' $INPUT | tr / _ | xargs rm &&
rm -f $INPUT *.key &&
ls $PWD/$OUTPUT
