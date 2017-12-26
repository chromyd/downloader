use strict;
use warnings;
use autodie;

sub main() {
  my $keyfile;
  my $iv;

  my $done = 0;
  my $TOTAL = $ARGV[1];

  my $OUT_FILENAME="all.ts";

  open(my $in, '<', $ARGV[0]);
  open(my $out, '>', $OUT_FILENAME);

  while (<$in>) {
    chomp;

    if (/^#EXT-X-KEY.*\/([^"]*)".*IV=0x(.*)/) {
      $keyfile = "$1";
      $iv = "$2";
    }

    if (/^[^#]/) {
      ++$done;
      s/\//_/g;
      my $key = `cat $keyfile.key`;
      printf("AES Progress: %3d%%\r", 100 * $done/$TOTAL);
      print $out `openssl enc -d -aes-128-cbc -nopad -in $_ -K $key -iv $iv` || die;
    }
  }
  close($in);
  close($out);

  system("ffmpeg -hide_banner -v 16 -i $OUT_FILENAME -acodec copy -vcodec copy all.mp4") || die;
  system("rm *.m3u8 *.key *_*.ts") || die;
}

main()
