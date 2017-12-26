#!/bin/bash
#
# Makes a script to decrypt and concatenate all parts based on the M3U8 file

INPUT=${1:-~/ChromeDownloads/*.m3u8}

cd $(dirname $INPUT)
echo Processing $INPUT in $(pwd)

perl $(dirname $0)/ms.pl $INPUT $(grep -v '^#' $INPUT | wc -l)
