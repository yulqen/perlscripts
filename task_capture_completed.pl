#!/usr/bin/env perl
 
use strict;
use warnings;
use autodie;
use feature qw(say);

my $project = $ARGV[0];

my $stuff = `task status:completed project:$project all`;

my @x = split(/\n/, $stuff);

# print "$_\n" foreach @x;

my %tasks;
my @taskids;
my $id;

foreach my $line (@x) {
    my @data = split / /, $line;
    if (defined($data[4])) {
            if ($data[4] =~ /\S{8}/) {
                $tasks{$data[4]} = (
                    [`task _get $data[4].description`,
                    `task _get $data[4].end`]
                )
        }
    }
}

while ( (my $key, my $value) = each %tasks ) {
    print "$key => @{ $value }\n";
}

