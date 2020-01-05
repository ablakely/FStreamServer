package FStream;

#
# FStream.pm - AppleScript Interface to FStream
#
# Copyright 2020 (C) Aaron Blakely <aaron@ephasic.org>
# Distributed as part of FStreamServer:
#  http://github.com/ablakely/FStreamServer
#

sub new {
  my ($class) = @_;
  my $self = {};

  return bless($self, $class);
}

sub osascript {
  my @tmp = map {("-e '",  $_, "'")} split(/\n/, $_[0]);
  my $prog = "@tmp";

  return `osascript $prog`;
}

sub stopPlaying {
osascript <<END;
  tell application "FStream"
    stopPlaying
  end tell
END
}

sub startPlaying {
osascript <<END;
  tell application "FStream"
    startPlaying
  end tell
END
}

sub getNowPlaying {
  my %NP;
  my $npraw = osascript <<END;
set stdout to ""

tell application "FStream"
  set currentTitle to playingTitle
  set currentArtist to playingArtist
  set currentURL to playingURL

  set stdout to stdout & currentTitle & ":" & currentArtist &  ":" & currentURL
end tell

copy stdout to stdout
END

  my ($title, $artist, @tmp) = split(":", $npraw);
  $NP{title} = $title;
  $NP{artist} = $artist;
  @{$NP{url}} = @tmp;

  return %NP;
}

sub getUser {
  my $tmp = osascript <<END;
tell application "FStream"
  copy short user name of (system info) to stdout
end tell
END
  chomp $tmp;
  return $tmp;
}

sub setVolume {
  my ($self, $val) = @_;
  return osascript "set volume output volume $val\n";
}

sub getVolume {
  return osascript "copy output volume of (get volume settings) to stdout\n";
}

1;
