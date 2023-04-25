#!/usr/bin/env perl

opendir(DIR, ".") || die "Can't open directory: $!\n";

while (my $file = readdir(DIR)) {
    if ($file =~ /(\d{4})_(\d{2})_(\d{2})\.md$/) {
        my $new_name = "$1-$2-$3.md";
        rename($file, $new_name) || die "Can't rename file '$file': $!\n";
    }
}

closedir(DIR);

