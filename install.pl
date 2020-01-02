#!/usr/bin/env perl -w
# install.pl - FStreamServer Install script
# Usage: ./install.pl <target>
#
# Target     -   Description
#------------------------------------------------
# apache2    -   Installs apache v2.4.41
# modperl    -   Installs modperl
# (none)     -   Installs FStreamServer v0.5
#------------------------------------------------
# apache2 Note:
#   apache2 target requires a newer gcc version than what shipped
#   with OS X 10.4.11 Tiger.
#   This target will identifiy the $PATH gcc version and upgrade with brew
#   if it matches the shipped version: 4.0.1 (Apple Computer, Inc. build 5370)
#
# Written by Aaron Blakely <aaron@ephasic.org>
# Copyright 2019 (C) Aaron Blakely

use strict;
use warnings;

# Software versions
my $APACHE_VER  = "2.4.41";
my $APR_VER     = "1.5.2";
my $APRUTIL_VER = "1.5.4_1";

if ($^O !~ /darwin/) {
  print "NOTE: This script is intended to run on OS X!!!\n";
}

if (`whoami` !~ /root/ && !$ENV{DEBUGINSTALL}) {
  die "Error: Installer requires root!\n";
}

my $brewpath = "";

sub checkDependencie {
  my ($name) = @_;

  my @path = split(":", $ENV{PATH});
  foreach my $t (@path) {
    if (-e "$t/brew" && -x "$t/brew") {
      $brewpath = $t."/brew";
    }
    if (-e "$t/$name" && -x "$t/$name") {
      return 1;
    }
  }

  return 0;
}

sub gccNeedsUpdate {
  my @gccver = `gcc -v`;

  if ($gccver[-1] eq "gcc version 4.0.1 (Apple Computer, Inc. build 5370") {
    return 1;
  }

  return 0;
}

sub systemAsUser {
  my ($cmd) = @_;

  my $user = `osascript fstream.scpt getUser`;
  chomp $user;

  system "su - $user -c '$cmd'";
}

my $mode = shift;
if (!$mode) {
  print "Installing FStreamServer...\n";

} elsif ($mode eq "apache2") {
  die "brew is not installed!\n" unless checkDependencie("brew");

  my $instr = "";

  if (!checkDependencie("wget")) {
    print "wget wasn't found, adding to install list.\n";
    $instr = $instr." wget"; # you can thank me later :-)
  }
  if (!checkDependencie("apr-1-config") || !-e "/usr/local/Cellar/apr/$APR_VER/bin/apr-1-config") {
    print "apr $APR_VER wasn't found, adding to install list.\n";
    $instr = $instr.' apr@'.$APR_VER;
  }
  if (!checkDependencie("apu-1-config") || !-e "/usr/local/Cellar/apr-util/$APRUTIL_VER/bin/apu-1-config") {
    print "apr-util $APRUTIL_VER wasn't found, adding to install list.\n";
    $instr = $instr.' apr-util@'.$APRUTIL_VER;
  }

  print "Installing$instr\n";
  systemAsUser("$brewpath install$instr");

  exit;
  print "Installing Apache2...\n";
  system "wget https://www-us.apache.org/dist//httpd/httpd-$APACHE_VER.tar.gz -O httpd.tar.gz";

  if (-e "httpd.tar.gz") { print "Gunzipping httpd.tar.gz...\n"; system "gunzip httpd.tar.gz"; }
  if (-e "httpd.tar") { print "Decompressing httpd.tar...\n"; system "tar xvf httpd.tar"; }

  if (gccNeedsUpdate()) {
    print "\n\nFound gcc but it's too old, installing a new one with brew!\n";
    print "This will *probably* take a *LONG* time\n\n"; # gmp built in 77 mins on my iMac G4 (700mhz, 512mb ram - hello 2002)
    systemAsUser("$brewpath install gcc");
  }

  die "Error extracting httpd.tar\n" unless (-e "./httpd-$APACHE_VER/configure");
  system "./httpd-$APACHE_VER/configure -prefix=/Applications/Apache2 -enable-module=most -enable-shared=max --with-apr=/usr/local/Cellar/apr/$APR_VER/ --with-apr-util=/usr/local/Cellar/apr-util/$APRUTIL_VER/";
} else {
  die "$mode is not an install target!\n";
}
