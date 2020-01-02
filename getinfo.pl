#!/usr/bin/env perl

use strict;
use warnings;

my $np = `osascript fstream.scpt np`;
chomp $np;

my ($title, $artist, $album, @url) = split(":", $np);
my $urlstr = join(":", @url);

print <<END;
Title:  $title
Artist: $artist
Album:  $album
URL:    $urlstr
END
