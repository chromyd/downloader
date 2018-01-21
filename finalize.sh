#!/bin/bash
#
# Decrypts and concatenates all parts based on the M3U8 file, then invokes post-processing

function find_game_start()
{
	local INPUT=$1
	local RANGE=780
	local POS=300
	local REF_AT=0
	local GOALIE_AT=0

	while [ $POS -lt $RANGE ];
	do
		local TEXT=$(ffmpeg -v fatal -nostdin -ss $POS -i $INPUT -vframes 1 -f image2 - | tesseract stdin stdout 2>/dev/null)
		echo $TEXT | egrep -qi 'officials|referee|linesman|linesmen' && REF_AT=$POS
		echo $TEXT | egrep -qi 'losses|shutouts|crawford|forsberg|glass' && GOALIE_AT=$POS
		let 'POS += 1'
	done

	if [ $((REF_AT - GOALIE_AT)) -gt 42 -a $GOALIE_AT -gt 0 -o $REF_AT -eq 0 ];
	then
	echo Game start G: $GOALIE_AT 1>&2
	  echo $GOALIE_AT
	else
	echo Game start R: $REF_AT 1>&2
	  echo $REF_AT
	fi
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

function get_broadcast_end()
{
  ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $1
}

INPUT=${1:-~/ChromeDownloads/*.m3u}

BASE_NAME=$(get_base_name $INPUT)

FINAL_MP4=$BASE_NAME.mp4
SILENCE_RAW=silence_raw.txt
SILENCE=silence.txt

OUTPUT=$BASE_NAME.ts

cd $(dirname $INPUT) &&
echo Processing $INPUT to produce $FINAL_MP4 &&

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

# Merge consecutive silences exceeding specific length (interpreted as ads within intermissions) and extend their duration to the preset lengths
GAME_END=$(get_broadcast_end $OUTPUT) perl -ne '
INIT {
  $delayed_ss = $delayed_se = $iidx = 0;
  @intermission_durations = (1080, 1080, (900) x 20);
}
{
	if (/^silence_start: (\S+) \| silence_end: (\S+) \| silence_duration: (\S+)/) {
		if ($3 > 116) {
			if ($delayed_ss == 0) {
				$delayed_ss = $1;
			}
			$delayed_se = $2;
		}
		else {
			if ($delayed_ss == 0) {
				print $_;
			}
			else {
			  $break_duration = $delayed_se - $delayed_ss;
			  if ($break_duration > $intermission_durations[$iidx]) {
			    die "Excessive break detected at $delayed_ss lasting $break_duration seconds";
			  }
			  if ($break_duration > $intermission_durations[$iidx] - 200 && $delayed_ss + $intermission_durations[$iidx] + 100 < $ENV{GAME_END}) {
			    $break_duration = $intermission_durations[$iidx] - 20;
  				++$iidx;
			  }
				printf "silence_start: %.2f | silence_end: %.2f | silence_duration: %.3f (delayed)\n", $delayed_ss, $delayed_ss + $break_duration, $break_duration;
				print $_;
			}
			$delayed_ss = 0;
		}
	}
}' |

# Split into segments without ad breaks.
OUTPUT=$OUTPUT GAME_START=$(find_game_start $OUTPUT) perl -ne '
use List::Util ("max");
INIT { $last_se = 0; $index = 0; }
{
	if (/^silence_start: (\S+) \| silence_end: (\S+) \| silence_duration: (\S+)/) {
		$ss = $1;
		if ($last_se != 0) {
			$gs = max($last_se, $ENV{GAME_START});
			printf "ffmpeg -nostdin -i $ENV{OUTPUT} -ss %.2f -t %.2f -c copy -v error -y b_%03d.ts\n", $gs, ($ss - $gs), $index++;
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
((MONTH >= 4 && MONTH < 9)) && LENGTH=14400 || LENGTH=7200
echo ffmpeg -v 16 -i \"$(echo "concat:$(ls b_*ts | paste -s -d\| -)")\" -c copy -y -t $LENGTH $FINAL_MP4 | sh &&

echo "Removing intermediate files..." &&

rm -f $INPUT *.key *_*.ts *.txt &&

test $(ls | wc -l) -ne 2 && echo WARNING: working directory contains other files!!
