use strict;
use warnings;

my @tags;

foreach my $fn (glob "~/Notes/journal/*.md") {
    open my $FH, "<", $fn or die "Cannot open $fn";
    while (<$FH>) {
        while (/(\s:[A-Z]\w+)/g) {
            push @tags, $1;
        }
                
    }
}
my %truetags = map { $_, 1 } @tags;
my @trutags = keys %truetags;
print @trutags, "\n";
