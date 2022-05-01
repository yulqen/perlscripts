#!/usr/bin/env perl
#
# This groups a transaction description to an expense category
# and prints to STDOUT to piping and or filtering elsewhere.
#
# The objective is for the output file to be used as a reference
# for another script which applies expense categories to new
# unprocessed budget files automatically.

use strict;
use warnings;

local $/ = ""; # switch to paragraph mode (allow use of /m modifier below)

while (<>) {
    # we only want true expenses, no income, rebates, pocket money, etc
    # Not all undesirable cases will be found based on this so be warned!
    next if (/Pocket Money|Income|Assets|[Rr]ebate|Unknown/);
    next if (/-£/);
    if (/\d{4}.*\* (.*)$/m) { print $1 . "@" };
    if (/Expenses:(.*)£/) { my $cat = $1; $cat =~ s/\s*$//; print $cat . "\n" };
}
