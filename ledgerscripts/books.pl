#!/usr/bin/env perl

use strict;
use warnings;
 
# sets 'paragraph mode' or 'slurp mode' see perlvar on $/
# basically sets empty lines as a terminator when set like this
local $/ = "";

open (my $outfile, ">", "/tmp/toss.txt")
    or die "Can't open output file.";

my @infile = <>;

my $child_asset_line = "(Assets:Child:CHILD)\t\t£COST\n";

for my $block (@infile) {
    my $child;
    if ($block =~ /(SEJLB|HWLB).*Books.*(\d+\.\d+)/s) {
        if ($1 eq "HWLB") { $child = "Harvey"} else { $child = "Sophie" };
        (my $cost) = ($block =~ /£(\d+\.\d+)/);
        (my $cat) = ($block =~ /(\w+\:\w+)/);
        chomp $block;
        print $outfile $block;
        $child_asset_line =~ s/CHILD/$child/;
        my $halve = sprintf("%.2f", ($cost / 2));
        $child_asset_line =~ s/COST/$halve/;
        print $outfile "\n". "   " . $child_asset_line . "\n";
    } else { print $outfile $block; }
}

close $outfile;

