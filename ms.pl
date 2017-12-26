use strict;
use warnings;
use autodie;

sub main() {
  my $keyfile;
  my $iv;

  my $done = 0;
  my $TOTAL = $ARGV[1];

  my $OUT_FILENAME="all.ts";

  #print "Expecting $TOTAL files\n";

  open(my $in, '<', $ARGV[0]);
  open(my $out, '>', $OUT_FILENAME);

  while (<$in>) {

    if (/^#EXT-X-KEY.*\/([^"]*)".*IV=0x(.*)/) {
      $keyfile = "$1";
      $iv = "$2";
    }

    if (/^[^#]/) {
      ++$done;
      s/\//_/g;
      #print "Extract with $keyfile $iv from $_";
      printf("Progress: %3d%%\r", 100 * $done/$TOTAL);
      print $out `ls $_` || die;
    }
  }
  close($in);
  close($out);
}

main()
