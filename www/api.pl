#!/usr/bin/env perl
# Copyright 2020 (C) Aaron Blakely <aaron@ephasic.org>

$|=1;

use lib '/Applications/FStreamServer/lib';

use CGI;
use strict;
use FStream;
use warnings;
use CGI::Carp('fatalsToBrowser');

print "Content-type: application/json\n\n";

my $q = CGI->new;
my $FStream = FStream->new();

my $action = $q->param("action");

if ($action) {
  if ($action eq "start") {
    $FStream->startPlaying();
    print "{ \"status\" : \"PLAYING\" }\n";
  } elsif ($action eq "stop") {
    $FStream->stopPlaying();
    print "{ \"status\" : \"NOTPLAYING\" }\n";
  } elsif ($action eq "getNP") {
    my %np = $FStream->getNowPlaying();
    my $SURL = join(":", @{$np{url}});
    chomp $SURL;

    my $vol = $FStream->getVolume();
    chomp $vol;

    if ($np{title}) {
      print "{ \"status\": \"ok\", \"volume\": \"$vol\", \"title\": \"$np{title}\", \"artist\": \"$np{artist}\", \"streamURL\": \"$SURL\" }\n";
    } else {
      print "{ \"volume\": \"$vol\",\"status\" : \"NOTPLAYING\" }\n";
    }
  } elsif ($action eq "setVolume") {
    my $val = $q->param("volume");

    if (defined $val) {
      my $volstr = "$val";
      $FStream->setVolume($volstr);
      print "{ \"status\" : \"ok\", \"volume\" : \"$val\" }\n";
    }
  } elsif ($action eq "getVolume") {
    my $vol = $FStream->getVolume();
    chomp $vol;

    print "{ \"status\" : \"ok\", \"volume\" : \"$vol\" }\n";
  } else {
    print "{ \"status\" : \"not ok\" }\n";
  }
}
