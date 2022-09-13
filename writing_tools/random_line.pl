use strict;
use warnings;
use English;
use Regexp::Common qw(URI);
use feature qw(say);

# How to read each file in a directory $dir

my $numargs = $#ARGV + 1;

if ($numargs != 1) {
    say "Pass a search term. All lines in the journal will be matched and URLs quoted will be extracted.";
    exit;
}


my @targetlines;
my $searchterm = $ARGV[0];
my @urls;

my $dir = '/home/lemon/Notes/journal';
foreach my $f (glob("$dir/*.md")) {
    # printf "%s\n", $f;
    open my $fh, "<", $f or die "Cannot open that file '$f': $OS_ERROR";
    while (<$fh>) {
        if ($_ =~ m/$searchterm/) {
            # printf "  %s", $_;
            push @targetlines, $_; 
        }
    }
    close $fh or die "can't read close file '$f': $OS_ERROR";
}

foreach my $line (@targetlines) {
    # if ($line =~ /(http.*$)/) {
    if ($line =~ m/$RE{URI}{HTTP}{-scheme => qr<https?>}{-keep}/) {
        my$t = $1;
        $t =~ s/\.$//; # remove the fullstop if it has one at the end
        print "Saving: $t\n";
        push @urls => $t
    }
}
