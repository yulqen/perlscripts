#!/usr/bin/env perl

use warnings;
use strict;

my $journal = "/home/lemon/Documents/Notes/journal";

my $line = `grep -R $ARGV[0] $journal | cut -f3- -d' '| fzf `;
chomp $line;

if ($line =~ m/(http.*)/) {
    print $1;
    # system('qutebrowser', $1);
}
