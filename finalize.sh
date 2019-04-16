# This file is now obsolete - see assemble.sh and process.sh
# Add the next function to bash_functions for easy post-processing:
#
function finalize() {
        sh ~/ws/freestream/assemble.sh
        sh ~/ws/freestream/process.sh ~/ChromeDownloads/2019*.ts
        mv -v ~/ChromeDownloads/*.mp4 ~/nhl
        find ~/ChromeDownloads/*.ts -size +1G | xargs -I {} mv -v {} ~/nhl/ts
}

#!/bin/bash
#
# Decrypts and concatenates all parts based on the M3U8 file, then invokes post-processing
#
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

function get_broadcast_end()
{
  ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $1
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
FINAL_MP4=$BASE_NAME.mp4

SILENCE_RAW=silence_raw.txt
SILENCE=silence.txt

OUTPUT=$BASE_NAME.ts
URL=url.txt

cd $(dirname $INPUT) &&
echo Processing $INPUT to produce $FINAL_MP4 &&

test -r $URL && get_missing_segments &&
test -s $OUTPUT || perl $(dirname $0)/decode.pl $INPUT $(grep -v '^#' $INPUT | wc -l) $OUTPUT &&

# The following ad-break processing is inspired by https://github.com/caseyfw/nhldl/blob/master/nhldl.sh

echo "Detecting blank commercial breaks..." &&
# Detect silences that indicate ads.
# |& not working on osx 10.10.5 converted to two stage

ffmpeg -nostats -i $OUTPUT -filter_complex "[0:a]silencedetect=n=-50dB:d=10[outa]" -map [outa] -f s16le -y /dev/null &> $SILENCE_RAW &&

echo "Detecting game start & Creating break-free segments..." &&
grep "^\[silence" $SILENCE_RAW | sed "s/^\[silencedetect.*\] //" > $SILENCE &&

# If the stream does not end in silence then
# Add a final silence_start to the slience file, ensuring last segment is kept.
(tail -1 $SILENCE | grep -q silence_end &&
echo "silence_start: $(get_broadcast_end $OUTPUT)" >> $SILENCE || true) &&

# Merge silence lines into single line for each silence segment
awk '
BEGIN { line = "" }
/silence_start/ { line = $0 }
/silence_end/ { print line " | " $0; line = "" }
END { if (line != "") print line " | silence_end: 0 | silence_duration: 0" }
' $SILENCE |

# Split into segments without ad breaks.
OUTPUT=$OUTPUT perl -ne '
use List::Util ("max");
INIT { $last_se = 0; $index = 0; }
{
	if (/^silence_start: (\S+) \| silence_end: (\S+) \| silence_duration: (\S+)/) {
		$ss = $1;
		if ($last_se != 0) {
			printf "ffmpeg -nostdin -i $ENV{OUTPUT} -ss %.2f -t %.2f -c copy -v error -y b_%03d.ts\n", $last_se, ($ss - $last_se), $index++;
		}
		$last_se = $2;
	}
	else {
		die "ERROR: found non-matching line: $_";
	}
}' |
sh &&

for FILE in b_0*.ts
do
  ln $FILE b_1${FILE#b_0} && ln $FILE b_2${FILE#b_0} || exit
done

echo "Merging break-free segments..."

MONTH=$(date +%m)
((MONTH >= 4 && MONTH < 9)) && LENGTH=15300 || LENGTH=8100
echo ffmpeg -v 16 -i \"$(echo "concat:$(ls b_*ts | paste -s -d\| -)")\" -c copy -y -t $LENGTH $FINAL_MP4 | sh &&

echo "Removing intermediate files..." &&

rm -f $INPUT *.key *_*.ts *.txt $URL &&

test $(ls | wc -l) -ne 2 && echo WARNING: working directory contains other files!!
