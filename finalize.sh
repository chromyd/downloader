#!/bin/bash
#
# Decrypt and concatenates all parts based on the M3U8 file, then invokes post-processing

function find_game_start()
{
	local INPUT=$1
	local FROM=$2
	local GUESS=240
	local IDX=0

	while [ $IDX -lt $GUESS ];
	do
		local POS
		for POS in $(($GUESS + $FROM - $IDX)) $(($GUESS + $FROM + $IDX + 1))
		do
			ffmpeg -v fatal -nostdin -ss $POS -i $INPUT -vframes 1 -f image2 - |
			tesseract stdin stdout 2>/dev/null |
			egrep -qi 'officials|referee|linesman|linesmen' && echo $POS && return
		done
		let 'IDX += 1'
	done
	echo 0
}

INPUT=${2:-~/ChromeDownloads/*.m3u8}
OUTPUT=all.ts

cd $(dirname $INPUT)
echo Processing $INPUT in $(pwd)

perl $(dirname $0)/decode.pl $INPUT $(grep -v '^#' $INPUT | wc -l) $OUTPUT &&

# The following ad-break processing is inspired by https://github.com/caseyfw/nhldl/blob/master/nhldl.sh

echo "Detecting blank commercial breaks..."
# Detect silences that indicate ads.
# |& not working on osx 10.10.5 converted to two stage

SILENCE_RAW=silence_raw.txt
SILENCE=silence.txt

ffmpeg -nostats -i $OUTPUT -filter_complex "[0:a]silencedetect=n=-50dB:d=10[outa]" -map [outa] -f s16le -y /dev/null &> $SILENCE_RAW &&

FROM=$(grep -m 1 silence_end $SILENCE_RAW | cut -f 5 -d ' ' | awk '{printf "%d\n",$0}') &&

echo "Detecting game start & Creating break-free segments..." &&
grep "^\[silence" $SILENCE_RAW | sed "s/^\[silencedetect.*\] //" > $SILENCE &&

# If the stream does not end in silence then
# Add a final silence_start to the slience file, ensuring last segment is kept.
tail -1 $SILENCE | grep -q silence_end &&
echo "silence_start: $(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $OUTPUT)" >> $SILENCE

# Merge silence lines into single line for each silence segment
awk '
BEGIN { line = "" }
/silence_start/ { line = $0 }
/silence_end/ { print line " | " $0; line = "" }
END { if (line != "") print line " | silence_end: 0 | silence_duration: 0" }
' $SILENCE |

# Merge consecutive silences exceeding specific length (interpreted as ads within intermissions)
perl -ne '
INIT { $delayed_ss = $delayed_se = 0; }
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
				printf "silence_start: %.2f | silence_end: %.2f | silence_duration: %.3f (merged)\n", $delayed_ss, $delayed_se, ($delayed_se - $delayed_ss);
				print $_;
			}
			$delayed_ss = 0;
		}
	}
}' |

# Split into segments without ad breaks.
OUTPUT=$OUTPUT GAME_START=$(find_game_start $OUTPUT $FROM) perl -ne '
use List::Util ('max');
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

echo "Merging break-free segments..." &&
FINAL_MP4=${1:-final}.mp4

echo ffmpeg -v 16 -i \"$(echo "concat:$(ls b_*ts | paste -s -d\| -)")\" -c copy $FINAL_MP4 | sh &&

echo "Removing intermediate files..." &&

rm -f *.m3u8 *.key *_*.ts *.txt &&

echo Done
