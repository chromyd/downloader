#!/bin/bash
#
# Decrypt and concatenates all parts based on the M3U8 file, then invokes post-processing

INPUT=${1:-~/ChromeDownloads/*.m3u8}
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

grep "^\[silence" $SILENCE_RAW > $SILENCE &&

# If the stream does not end in silence then
# Add a final silence_start to the slience file, ensuring last segment is kept.
tail -1 $SILENCE | grep -q silence_end &&
echo "[silencedetect @ FINAL] silence_start: $(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $OUTPUT)" >> $SILENCE


echo "Creating break-free segments..." &&

# Split into segments without ad breaks. Drop the first segment.
cat $SILENCE | F='-codec copy -v error' FULL_TRACK=$OUTPUT perl -ne '
INIT { $ss=0; $se=0; }
  if (/silence_start: (\S+)/) { $ss=$1; $ctr+=1; if ($se != 0) { printf "ffmpeg -nostdin -i $ENV{FULL_TRACK} -ss %f -t %f $ENV{F} -y b_%03d.ts\n", $se, ($ss-$se), $ctr; } }
  if (/silence_end: (\S+)/) { $se=$1; }
'| sh &&

echo "Merging break-free segments..." &&
FINAL_TS=${2:-final}.ts

echo ffmpeg -v 16 -i \"$(echo "concat:$(ls b_*ts | paste -s -d\| -)")\" -c copy $FINAL_TS | sh &&

echo "Re-encoding audio..." &&
FINAL_MP4=${2:-final}.mp4

ffmpeg -v error -i $FINAL_TS -c copy -bsf:a aac_adtstoasc $FINAL_MP4 &&

echo "Removing intermediate files..." &&

rm -f *.m3u8 *.key *_*.ts *raw.txt $FINAL_TS &&

echo Done
