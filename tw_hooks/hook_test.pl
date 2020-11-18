use strict;
use warnings;
use JSON;
use Data::Dumper;

# a test hook in Perl for taskwarrior

# this must be JSON - this gets passed in my taskwarrior
my $added_task = <STDIN>;

my $hashref = decode_json $added_task;

my $original_description = $hashref->{description};

my $tags = $hashref->{tags};
print $tags->[1];
print "\n";

print Dumper($hashref);

$hashref->{description} =~ s/LEMON/BOLLOCKS/g;

my $output = encode_json $hashref;

# print $hashref->{"status"};
# print "\n";
# print $hashref->{scheduled};

print $output;

exit 0;
