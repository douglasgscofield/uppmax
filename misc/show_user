#!/usr/bin/env perl
#
# What: Display user based on search criteria (from UPPMAX users file)
# Auth: Wesley Schaal, wesley.schaal@farmbio.uu.se
# When: 2014-01-08
# Vers: 0.2
#
# ARG1: username "code" to find, eg: wesleys

use strict; use warnings; #use 5.010;
my $userfile = '/sw/uppmax/etc/users'; 

my $username = shift or print("\nPlease tell me which username you want to see\n"), exit(1);
open(P,'<',$userfile) or die('Cannot open users file');
local $/ = '';

while(<P>) { print,exit(0) if /^Username:\s+$username\s*$/migo; }
print "\nSorry, '$username' wasn't found in '$userfile'.\n";
