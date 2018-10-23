#!/usr/bin/env perl
#
# What: Display project based on search criteria (from UPPMAX project file)
# Auth: Wesley Schaal, wesley.schaal@farmbio.uu.se
# When: 2014-01-08
# Vers: 0.4
#
# ARG1: project code to find, eg: b2012255
# TODO: Could expand to name search, etc

use strict; use warnings; #use 5.010;
my $projfile = '/sw/uppmax/etc/projects';

my $projcode = shift or print("\nPlease tell me which project you want to see.\n"), exit(1);
open(P,'<',$projfile) or die('Cannot open project file');
local $/ = '';

while(<P>) { print,exit(0) if /^Name:\s+$projcode\s*$/migo; }
print "\nSorry, '$projcode' wasn't found in '$projfile'.\n";
