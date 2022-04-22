#!/usr/bin/env perl
 
use strict;
use warnings;
use autodie;
use feature qw(say);

my $project = $ARGV[0];

my $stuff = `task status:completed project:$project all`;

my @x = split(/\n/, $stuff);

# print "$_\n" foreach @x;

my @taskids;
my $id;

foreach my $line (@x) {
    my @data = split / /, $line;
    if (defined($data[4])) {
            if ($data[4] =~ /\S{8}/) {
                push @taskids, ($data[4])
        }
    }
}

foreach (@taskids) {
    my $desc = `task _get $_.description`;
    chomp $desc;
    my $end = `task _get $_.end`;
    $end = substr($end, 0, -1);
    $end =~ s/T/ /;
    printf "%s: %-50s\t%s\n", ($_, $desc, $end)
}

say "Found " .  scalar @taskids . " tasks.";
