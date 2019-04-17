#!/bin/bash
#
# Process a TS file by removing ad breaks and adding chapter metadata to an output MP4 file

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

OUTPUT=$1

BASE_NAME=$(get_base_name $OUTPUT)
INTER_MP4=inter.mp4
FINAL_MP4=$BASE_NAME.mp4

SILENCE_RAW=silence_raw.txt
SILENCE=silence.txt

cd $(dirname $OUTPUT) &&
echo Processing $OUTPUT to produce $FINAL_MP4 &&

# The following ad-break processing is inspired by https://github.com/caseyfw/nhldl/blob/master/nhldl.sh

echo "Detecting blank commercial breaks..." &&
# Detect silences that indicate ads.
# |& not working on osx 10.10.5 converted to two stage

ffmpeg -nostats -i $OUTPUT -filter_complex "[0:a]silencedetect=n=-50dB:d=10[outa]" -map [outa] -f s16le -y /dev/null &> $SILENCE_RAW &&

echo "Creating break-free segments..." &&
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
OUTPUT=$OUTPUT BASE_NAME=$BASE_NAME perl -ne '
use List::Util ("max");
INIT {
  $last_se = 0; $index = 0; $meta_ss = 0;
  open $fh_video, ">", "videos.txt" or die $!;
  open $fh_meta, ">", "meta.txt" or die $!;
  printf {$fh_meta} ";FFMETADATA1\ntitle=%s\n", $ENV{BASE_NAME};
}
{
	if (/^silence_start: (\S+) \| silence_end: (\S+) \| silence_duration: (\S+)/) {
		$ss = $1;
    $duration = $ss - $last_se;
    printf {$fh_video} "ffmpeg -nostdin -i $ENV{OUTPUT} -ss %.2f -t %.2f -c copy -v error -y b_%03d.ts\n", $last_se, $duration, $index++;
    printf {$fh_meta} "[CHAPTER]\nTIMEBASE=1/1000\nSTART=%d\nEND=%d\ntitle=Chapter %d\n", 1000 * $meta_ss, 1000 * ($meta_ss + $duration), $index;
    $meta_ss += $duration;
		$last_se = $2;
	}
	else {
		die "ERROR: found non-matching line: $_";
	}
}' &&

sh < videos.txt &&

for FILE in b_0*.ts
do
  ln $FILE b_1${FILE#b_0} && ln $FILE b_2${FILE#b_0} || exit
done

echo "Merging break-free segments..."

MONTH=$(date +%m)
((MONTH >= 4 && MONTH < 9)) && LENGTH=10800 || LENGTH=8100
echo ffmpeg -v 16 -i \"$(echo "concat:$(ls b_*ts | paste -s -d\| -)")\"  -c copy -y -t $LENGTH $INTER_MP4 | sh &&

echo "Adding metadata..." &&

ffmpeg -v 16 -i $INTER_MP4 -i meta.txt -map_metadata 1 -codec copy $FINAL_MP4 &&

echo "Removing intermediate files..." &&

rm -f $INTER_MP4 meta.txt videos.txt b_*.ts silence*.txt

#test $(ls | wc -l) -ne 2 && echo WARNING: working directory contains other files!!
