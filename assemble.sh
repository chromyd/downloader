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

function get_missing_segments()
{
	echo "Checking for missing segments..."
	for x in $(grep -v '^#' $INPUT)
	do
		test -r ${x//\//_} || ( echo ${x//_/\/}: && /usr/bin/curl -# -o ${x//\//_} $(cat $URL)$x ) || exit 1
	done
}

INPUT=${1:-~/ChromeDownloads/*.m3u}

sed -i '' -e '/^https:/d' $INPUT

BASE_NAME=$(get_base_name $INPUT)

OUTPUT=$BASE_NAME.ts
URL=url.txt

cd $(dirname $INPUT) &&
echo Processing $INPUT to produce $OUTPUT &&

test -r $URL && get_missing_segments &&
test -s $OUTPUT || perl $(dirname $0)/decode.pl $INPUT $(grep -v '^#' $INPUT | wc -l) $OUTPUT &&
grep -v '^#' $INPUT | tr / _ | xargs rm &&
rm -f $INPUT *.key url*.txt &&
ls $PWD/$OUTPUT
