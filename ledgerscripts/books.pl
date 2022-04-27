#!/usr/bin/env perl
# This script will check ledger budger file and look for any transactions
# with either SEJLB or HWLB in the line. These must be manually added and
# indicate a transaction involving one of the children buying a book. The 
# script will reprint that block, adding an additional line that calculates
# half the cost of the time and subtracts it from their virtual account - 
# we pay half, they pay half.
# 
# Outputs to STDOUT so you will have to redirect it somwhere. 
#
# DO NOT REDIRECT BACK TO THE FILE ITSELF

use strict;
use warnings;
 
# sets 'paragraph mode' or 'slurp mode' see perlvar on $/
# basically sets empty lines as a terminator when set like this
local $/ = "";

my @infile = <>;

my $child_asset_line = 
    "(Assets:Child:CHILD)\t\t-£COST\n    Assets:Current:HSBC\t\t\t£ORIGINAL\n";

for my $block (@infile) {
    my $child;
    if ($block =~ /(SEJLB|HWLB)/ms) {
        if ($1 eq "HWLB") { $child = "Harvey"} else { $child = "Sophie" };
        (my $cost) = ($block =~ /£(\d+\.\d+)/);
        (my $cat) = ($block =~ /(\w+\:\w+)/);
        chomp $block;
        $block =~ s/( SEJLB| HWLB)//g;
        print $block;
        $child_asset_line =~ s/CHILD/$child/;
        my $halve = sprintf("%.2f", ($cost / 2));
        $child_asset_line =~ s/COST/$halve/;
        $child_asset_line =~ s/ORIGINAL/$cost/;
        print "\n". "   " . $child_asset_line . "\n";
    } else { print $block; }
}
