# FStreamServer

FStreamServer is a perl CGI script for controlling FStream on older Macs

## Installing

In terminal change to the FStreamServer directory and run:
`perl install.pl`

### Installing Apache2 (Requires brew)
Run command: `perl install.pl apache2`

This will install the following packages:

Package | Version | Brew | Compile
--- | --- | --- | ---
apr | v1.5.2 | :heavy_check_mark:  |
apr-util | v1.5.4 | :heavy_check_mark: |
gcc | v7.3.0 | :heavy_check_mark: |
nasm | v2.11.08 | :heavy_check_mark: |
pcre | v8.39 | :heavy_check_mark: |
apache2 | v2.4.41 | | :heavy_check_mark:


### Installing modperl (Requires brew)
Run command: `perl install.pl modperl`

## Compatibility
Tested hardware config: iMac G4 with 10.4.11 and apache2 with mod_perl

## FStream
[FStream](https://www.sourcemac.com/?page=fstream&lang=en) is a little WebRadio listener/recorder software for OS X.

The version I'm using (v1.4.2) isn't the main download I found it on WayBack Machine, therefor I'm distributing it in resources/ to ensure best compatibility.
