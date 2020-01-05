#!/usr/bin/env perl -w
# install.pl - FStreamServer Install script
# Usage: ./install.pl <target>
#
# Target       -   Description
#------------------------------------------------
# all          -   Installs all targets
# apache2      -   Installs apache v2.4.41
# modperl      -   Installs mod_perl v2.0.11
# (none)       -   Installs FStreamServer v0.5
# apacheconfig -   Enables mod_perl in httpd.conf
#------------------------------------------------
# apache2 Note:
#   apache2 target requires a newer gcc version than what shipped
#   with OS X 10.4.11 Tiger.
#   This target will identifiy the $PATH gcc version and upgrade with brew v7.3.0
#   if it matches the shipped version: 4.0.1 (Apple Computer, Inc. build 5370)
#
# modperl Note:
#    This will brew perl v5.22.0
#
# Written by Aaron Blakely <aaron@ephasic.org>
# Copyright 2019-2020 (C) Aaron Blakely

use lib ".";
use lib "./lib";

use FStream;
use strict;
use warnings;

my $mode = shift;

# Software versions
my $APACHE_VER  = "2.4.41";
my $APR_VER     = "1.5.2";
my $APRUTIL_VER = "1.5.4_1";
my $GCC_VER     = "7.3.0";
my $PCRE_VER    = "8.39";
my $NASM_VER    = "2.11.08";
my $MODPERL_VER = "2.0.11";
my $PERL_VER    = "5.22.0";

if ($^O !~ /darwin/) {
  print "NOTE: This script is intended to run on OS X!!!\n";
}

if (`whoami` !~ /root/ && !$ENV{DEBUGINSTALL}) {
  die "Error: Installer requires root!\n";
}

my $BDIR   = $ENV{PWD};
my $DLDIR  = $ENV{PWD}."/resources";
my $WWWDIR = $ENV{PWD}."/www";
my $LIBDIR = $ENV{PWD}."/lib";

my $FStream = FStream->new();
my $USER = $FStream->getUser();

sub checkDependencie {
  my ($name, $rmode) = @_;

  my @path = split(":", $ENV{PATH});
  foreach my $t (@path) {
    if (-e "$t/$name" && -x "$t/$name") {
      if (!$rmode) {
        return 1;
      } else {
        return "$t/$name";
      }
    }
  }

  return 0;
}

sub gccNeedsUpdate {
  my @gccver = `gcc -v 2>&1`;

  print "System GCC Version: ".$gccver[-1]."\n";
  if ($gccver[-1] eq "gcc version 4.0.1 (Apple Computer, Inc. build 5370)") {
    if (!-e "/usr/local/Cellar/gcc/$GCC_VER/bin/gcc-7") {
      return 1;
    }
  }

  return 0;
}

sub systemAsUser {
  my ($cmdUP, $rmode) = @_;

  my $user = $USER;

  if ($rmode) {
    return $user;
  }

  my @tmp = split(" ", $cmdUP);
  $tmp[0] = checkDependencie($tmp[0], 1);

  my $cmd = join(" ", @tmp);
  system "su - $user -c '$cmd'";
}

sub compileApache2 {
  # Setup our compile env
  $ENV{CC}     = "/usr/local/Cellar/gcc/$GCC_VER/bin/gcc-7";
  $ENV{CPP}    = $ENV{CC}." -E";
  my $CFGARGS  = "--with-apr=/usr/local/Cellar/apr/$APR_VER/";
  $CFGARGS    .= " --with-apr-util=/usr/local/Cellar/apr-util/$APRUTIL_VER/";
  $CFGARGS    .= " --with-pcre=/usr/local/Cellar/pcre/$PCRE_VER";

  my $oldPWD   = $ENV{PWD};
  chdir "$DLDIR/httpd-$APACHE_VER";
  system "./configure -prefix=/Applications/Apache2 -enable-module=most -enable-shared=max $CFGARGS";

  print "Patching libtool config\n";
  system "cp $DLDIR/libtool /usr/local/Cellar/apr/1.5.2/libexec/build-1/libtool";

  print "\n\nCompiling Apache2 this will take a *long* time\n\n";
  system "make && echo 'Finished make -- Installing' && make install && echo 'Cleaning up build' && make clean";
}

sub installApache2 {
  die "brew is not installed!\n" unless checkDependencie("brew");

  my $instr = "";

  if (!checkDependencie("wget")) {
    print "wget wasn't found, adding to install list.\n";
    $instr = $instr." wget"; # you can thank me later :-)
  }
  if (!checkDependencie("apr-1-config") && !-e "/usr/local/Cellar/apr/$APR_VER/bin/apr-1-config") {
    print "apr $APR_VER wasn't found, adding to install list.\n";
    $instr = $instr." $DLDIR/apr.rb";
  }
  if (!checkDependencie("apu-1-config") && !-e "/usr/local/Cellar/apr-util/$APRUTIL_VER/bin/apu-1-config") {
    print "apr-util $APRUTIL_VER wasn't found, adding to install list.\n";
    $instr = $instr." $DLDIR/apr-util.rb";
  }
  if (!checkDependencie("pcre-config") && !-e "/usr/local/Cellar/pcre/$PCRE_VER/bin/pcre-config") {
    $instr = $instr." $DLDIR/pcre.rb";
  }

  if ($instr ne "") { print "Installing$instr\n"; systemAsUser("brew install$instr");}

  if (gccNeedsUpdate()) {
    print "\n\nFound gcc but it's too old, installing a new one with brew!\n";
    print "This will *probably* take a *LONG* time\n\n"; # gmp built in 77 mins on my iMac G4 (700mhz, 512mb ram - hello 2002)
    systemAsUser("brew install $DLDIR/gcc.rb $DLDIR/nasm.rb");
  }

  if (-e "$DLDIR/httpd.tar" && !-e "/Applications/Apache2/bin") {
    compileApache2();
  }

  unless (-e "$DLDIR/httpd.tar") {
    print "Installing Apache2...\n";
    system("wget https://www-us.apache.org/dist//httpd/httpd-$APACHE_VER.tar.gz -O $DLDIR/httpd.tar.gz");
    if (-e "$DLDIR/httpd.tar.gz" && !-e "$DLDIR/httpd.tar") {
      print "Gunzipping httpd.tar.gz...\n";
      system("gunzip $DLDIR/httpd.tar.gz");
    }

    if (-e "$DLDIR/httpd.tar") {
      print "Decompressing httpd.tar...\n";
      system("tar xf $DLDIR/httpd.tar -C $DLDIR");
      if (!-e "$DLDIR/httpd-$APACHE_VER/configure") {
          die "Error extracting httpd.tar\n";
      }
    }

    compileApache2();
    system "chown -R "
  }
}

sub installModPerl {
  unless (-e "$DLDIR/mod_perl.tar") {
    system "wget https://www-us.apache.org/dist/perl/mod_perl-$MODPERL_VER.tar.gz -O $DLDIR/mod_perl.tar.gz";
    if (-e "$DLDIR/mod_perl.tar.gz" && !-e "$DLDIR/mod_perl.tar") {
      print "Gunzipping mod_perl.tar.gz...\n";
      system "gunzip $DLDIR/mod_perl.tar.gz";
    }

    if (-e "$DLDIR/mod_perl.tar") {
      print "Decompressing mod_perl.tar...\n";
      system "tar xf $DLDIR/mod_perl.tar -C $DLDIR";
      if (!-e "$DLDIR/mod_perl-$MODPERL_VER/Makefile.pl") {
        die "Error extracting mod_perl.tar\n";
      }
    }

    if ($] == "5.008006" && !-e "/usr/local/Cellar/perl/$PERL_VER/") {
      print "Detected outdate perl, using brew to install a new one!\n";
      print "This will take a *long* time\n\n";
      systemAsUser("brew install $DLDIR/perl.rb");
    }

    my $apxsPath = "/Applications/Apache2/bin/apxs";
    chdir "$DLDIR/mod_perl-$MODPERL_VER";
    system "/usr/local/Cellar/perl/5.22.0/bin/perl  $DLDIR/mod_perl-$MODPERL_VER/Makefile.PL MP_APXS=$apxsPath MP_APR_CONFIG=/usr/local/Cellar/apr/$APR_VER/bin/apr-1-config";
    print "\n\nCompiling mod_perl...\n\n";
    system "make";
    systemAsUser("make test");

    print "Installing mod_perl...\n";
    system "make install";

    fixApacheConfig();
  }
}

sub fixApacheConfig {
  open(my $fh, "</Applications/Apache2/conf/httpd.conf") or die "Cannot read httpd.conf: $!\n";
  my @tmpConf = <$fh>;
  close($fh) or die "hmm".$!;

  my @conf;
  my $appendModPerlCFG = 1;

  my $user = $USER;

  for (my $i = 0; $i < scalar(@tmpConf); $i++) {
    if ($tmpConf[$i] =~ /^User (.*)$/) {
      if ($1 ne $user) {
        print "httpd.conf:$i: User is set to $1 ... changing to $user\n";
        $conf[$i] = "User $user\n";
      } else {
        $conf[$i] = $tmpConf[$i];
      }
    } elsif ($tmpConf[$i] =~ /^Group (.*)$/) {
      if ($1 ne $user) {
        print "httpd.conf:$i: Group is set to $1 ... changing to $user\n";
        $conf[$i] = "Group $user\n";
      } else {
        $conf[$i] = $tmpConf[$i];
      }
    } elsif ($tmpConf[$i] =~ /^DocumentRoot \"(.*)\"$/) {
      if ($1 ne $WWWDIR) {
        print "httpd.conf:$i: DocumentRoot is set to $1 ... changing to $WWWDIR\n";
        $conf[$i] = "DocumentRoot \"$WWWDIR\"\n";
        $conf[++$i] = "<Directory \"$WWWDIR\">\n";
      } else {
        $conf[$i] = $tmpConf[$i];
      }
    } elsif ($tmpConf[$i] =~ /^Listen (.*)$/) {
      if ($1 ne "8080") {
        print "httpd.conf:$i: Port is set to $1 ... changing to 8080\n";
        $conf[$i] = "Listen 8080\n";
      } else {
        $conf[$i] = $tmpConf[$i];
      }
    } elsif ($tmpConf[$i] =~ /#- mod_perl auto install for FStreamServer -#/) {
      $appendModPerlCFG = 0;
      $conf[$i] = $tmpConf[$i];
    } else {
      $conf[$i] = $tmpConf[$i];
    }
  }

  if ($appendModPerlCFG) {
    print "Enabling mod_perl for *.pl/*.cgi\n";
    push(@conf, (
      "#- mod_perl auto install for FStreamServer -#\n",
      "LoadModule perl_module modules/mod_perl.so\n",
      '<Files ~ "\.(pl|cgi)$">'."\n",
      '  SetHandler perl-script'."\n",
      '  PerlResponseHandler ModPerl::Registry'."\n",
      '  PerlOptions +ParseHeaders'."\n",
      '  Options +ExecCGI'."\n",
      '  Order allow,deny'."\n",
      '  Allow from all'."\n",
      #'  PerlSendHeader On'."\n",
      '</Files>'."\n"
    ));
  }

  open($fh, ">/Applications/Apache2/conf/httpd.conf") or die $!;
  for (my $i = 0; $i < scalar(@conf); $i++) {
    print $fh $conf[$i] unless (!$conf[$i]);
  }
  close($fh) or die $!;
}

sub installFStreamServer {
  if (!-e "/Applications/FStream.app") {
    print "FStream not installed, copying to /Applications...\n";
    system "cp -r $DLDIR/FStream.app /Applications/";
    system "chown -R aaron /Applications/FStream.app";
  }

  if (!-e "/Applications/FStreamServer") {
    print "Moving files...\n";
    system "mv $BDIR /Applications/";
    system "chown -R aaron /Applications/FStreamServer";
  }
}


if (!$mode) {
  print "Installing FStreamServer...\n";
  installFStreamServer();
} elsif ($mode eq "apacheconfig") {
  print "Modifying Apache httpd.conf...\n";
  fixApacheConfig();
} elsif ($mode eq "apache2") {
  print "Installing Apache2...\n";
  installApache2();
} elsif ($mode eq "modperl") {
  print "Installing mod_perl...\n";
  installModPerl();
} elsif ($mode eq "clean") {
  system "rm -r $DLDIR/httpd-$APACHE_VER $DLDIR/httpd.tar $DLDIR/httpd.tar.gz $DLDIR/mod_perl-$PERL_VER $DLDIR/mod_perl.tar";
} elsif ($mode eq "all") {
  print "Installing all targets...\n";
  installApache2();
  installModPerl();
  installFStreamServer();
  fixApacheConfig();
} else {
  die "$mode is not an install target!\n";
}
