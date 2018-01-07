#!/bin/bash
#
# Decrypts and concatenates all parts based on the M3U8 file, then invokes post-processing

function find_game_start()
{
	local INPUT=$1
	local FROM=$2
	local RANGE=480
	local IDX=0
	local REF_AT=0
	local GOALIE_AT=0

	while [ $IDX -lt $RANGE ];
	do
		local POS=$((FROM + IDX))
		local TEXT=$(ffmpeg -v fatal -nostdin -ss $POS -i $INPUT -vframes 1 -f image2 - | tesseract stdin stdout 2>/dev/null)
		echo $TEXT | egrep -qi 'officials|referee|linesman|linesmen' && REF_AT=$POS
		echo $TEXT | egrep -qi 'losses|shutouts|crawford|forsberg|glass' && GOALIE_AT=$POS
		let 'IDX += 1'
	done

	if [ $((REF_AT - GOALIE_AT)) -gt 42 -a $GOALIE_AT -gt 0 -o $REF_AT -eq 0 ];
	then
	  echo $GOALIE_AT
	else
	  echo $REF_AT
	fi
}

INPUT=${2:-~/ChromeDownloads/*.m3u8}
FINAL_MP4=${1:-final}.mp4
SILENCE_RAW=silence_raw.txt
SILENCE=silence.txt

OUTPUT=all.ts

cd $(dirname $INPUT) &&
echo Processing $INPUT to produce $FINAL_MP4 &&

test -s $OUTPUT || perl $(dirname $0)/decode.pl $INPUT $(grep -v '^#' $INPUT | wc -l) $OUTPUT &&

# The following ad-break processing is inspired by https://github.com/caseyfw/nhldl/blob/master/nhldl.sh

echo "Detecting blank commercial breaks..." &&
# Detect silences that indicate ads.
# |& not working on osx 10.10.5 converted to two stage

ffmpeg -nostats -i $OUTPUT -filter_complex "[0:a]silencedetect=n=-50dB:d=10[outa]" -map [outa] -f s16le -y /dev/null &> $SILENCE_RAW &&

FROM=$(grep -m 1 silence_end $SILENCE_RAW | cut -f 5 -d ' ' | awk '{printf "%d\n",$0}') &&

echo "Detecting game start & Creating break-free segments..." &&
grep "^\[silence" $SILENCE_RAW | sed "s/^\[silencedetect.*\] //" > $SILENCE &&

# If the stream does not end in silence then
# Add a final silence_start to the slience file, ensuring last segment is kept.
(tail -1 $SILENCE | grep -q silence_end &&
echo "silence_start: $(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $OUTPUT)" >> $SILENCE || true) &&

# Merge silence lines into single line for each silence segment
awk '
BEGIN { line = "" }
/silence_start/ { line = $0 }
/silence_end/ { print line " | " $0; line = "" }
END { if (line != "") print line " | silence_end: 0 | silence_duration: 0" }
' $SILENCE |

# Merge consecutive silences exceeding specific length (interpreted as ads within intermissions) and extend their duration to the preset lengths
perl -ne '
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
			  if ($break_duration > $intermission_durations[$iidx] - 300) {
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
		else {
			printf "ffmpeg -nostdin -i $ENV{OUTPUT} -ss %.2f -t %.2f -c copy -v error -y b_%03d.ts\n", $ss, 120, 900;
		}
		$last_se = $2;
	}
	else {
		die "ERROR: found non-matching line: $_";
	}
}' |
sh &&

for i in {901..999}
do
  ln b_900.ts b_$i.ts || exit
done

echo "Merging break-free segments..." &&

echo ffmpeg -v 16 -i \"$(echo "concat:$(ls b_*ts | paste -s -d\| -)")\" -c copy -y -t 14400 $FINAL_MP4 | sh &&

echo "Removing intermediate files..." &&

rm -f *.m3u8 *.key *_*.ts *.txt &&

echo Done
