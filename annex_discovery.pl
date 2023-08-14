#!/usr/bin/env perl

use strict;
use warnings;
use feature q(say);

open my $fh, "<", "/home/lemon/Documents/find_these_paths.txt" or die "Cannot open file";
while (<$fh>) {
    if ($_ =~ q[^/home/lemon/annex/(.*) \(1 copy\)]) {
        my $path = quotemeta($1);
        my $out = `git annex whereis $path`;
        say $out;
    }
}
