#!/usr/bin/env perl
# Copyright 2020 (C) Aaron Blakely <aaron@ephasic.org>
$|=1;

use lib '/Applications/FStreamServer/lib';
use FStream;
use CGI;
use strict;
use warnings;
use CGI::Carp('fatalsToBrowser');

print "Content-type: text/html\n\n";

my $q = CGI->new;
my $FStream = FStream->new();

my $action = $q->param("action");

if ($action) {
  if ($action eq "start") {
    $FStream->startPlaying();
  } elsif ($action eq "stop") {
    $FStream->stopPlaying();
  }
}

my %np = $FStream->getNowPlaying();
my $urlstr = join(":", @{$np{url}});

print <<DOC;

<!DOCTYPE html>
<html >
<head>
  <meta charset="UTF-8">
  <title>FStreamServer v1.0</title>
      <link rel="stylesheet" href="css/style.css">
</head>

<body>
  <link href="https://fonts.googleapis.com/css?family=Josefin+Sans" rel="stylesheet">

<div class="music_player">
  <div class="artist_img">
  <img src="/imgs/icon.png">
  </div>
  <div class="time_slider">

    <i class="fa fa-volume-off minvol"></i>
    <input type="range" value="0">
    <i class="fa fa-volume-up maxvol"></i>

  </div>
  <div class="now_playing">
    <i class="fa fa-music" aria-hidden="true"></i>

    <p> streaming </p>
    <i id="recordButton" class="fa fa-circle recordBtn" aria-hidden="true"></i>
  </div>

  <div class="music_info">
    <br />
    <h2 id="songTitle">$np{title}</h2>

    <p id="songArtist" class="song_title">$np{artist}</p>
    <br /><br />

      <p id="songURL" class="date"><a href="$urlstr"></a> $urlstr</p>
  </div>
  <div class="controllers">

    <i class="fa fa-fast-backward" aria-hidden="true"></i>
    <i id="ppButton" class="fa fa-play" aria-hidden="true"></i>
    <i class="fa fa-fast-forward" aria-hidden="true"></i>
  </div>
</div>
<div class="song_list" style="display:none">
  <br />
  <table>
    <tr>
      <th class="dark">Folder</th>
      <th class="dark">Station</th>
    </tr>
    <tr>
      <td>Rap</td>
      <td><a href="#">Memphis Rap</a></td>
    </tr>
  </table>
  </div>
  <script src='https://cdnjs.cloudflare.com/ajax/libs/jquery/3.1.0/jquery.min.js'></script>

    <script src="js/index.js"></script>

</body>
</html>
DOC
