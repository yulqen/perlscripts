#!/usr/bin/env perl

use warnings;
use strict;


open (my $cat_file, "<", "expense_categories") or die 
    "Can't open expense_categories file";

my %categories;

while (local $_ = <$cat_file>) {
    if (/(.*)@(.*)/) {
        $categories{$1} = $2;
    }
}
close $cat_file;

local $/ = ""; # switch to paragraph mode

while (my $block = <>) {
    if ($block =~ m/\d{4}.*\* (.*)\n.*(Expenses:.*)£/s) {
        while (my ($k, $v) = each %categories) {
            if ($k eq $1) {
                $block =~ s/$2/Expenses:$v/;
            };     
        }
        print $block;
    };
}
