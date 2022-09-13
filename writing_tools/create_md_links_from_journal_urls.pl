use strict;
use warnings;
use English;
use Regexp::Common qw(URI);
use LWP::UserAgent;
use HTML::TreeBuilder 5 -weak;
use HTML::HeadParser;
use feature qw(say);

# How to read each file in a directory $dir

my $numargs = $#ARGV + 1;

sub usage {
    say "Pass a search term or -all. All lines in the journal will be matched and URLs quoted will be extracted, or -all will do all URLs..";
    exit;
}

if ($numargs != 1) {
    usage();
}


my @targetlines;
my $searchterm = $ARGV[0];

my @urls;

my $dir = '/home/lemon/Notes/journal';

foreach my $f (glob("$dir/*.md")) {
    # printf "%s\n", $f;
    open my $fh, "<", $f or die "Cannot open that file '$f': $OS_ERROR";
    while (<$fh>) {
        if ($searchterm eq "-all") {
            push @targetlines, $_;
        }
        else {
            if ($_ =~ m/$searchterm/) {
                # printf "  %s", $_;
                push @targetlines, $_; 
            }
        }
    }
    close $fh or die "can't read close file '$f': $OS_ERROR";
}

sub striptime {
    my $url = shift;
    $url =~ s/\?t=\d*//;
    return $url;
}

#
# Let's interact with the World Wide Web!
my $ua = LWP::UserAgent->new;
$ua->agent("Mozilla/8.0");

foreach my $line (@targetlines) {
    # if ($line =~ /(http.*$)/) {
    if ($line =~ m/$RE{URI}{HTTP}{-scheme => qr<https?>}{-keep}/) {
        my$t = $1;
        $t =~ s/\.$//; # remove the fullstop if it has one at the end
        push @urls => striptime($t)
    }
}

# get rid of duplicates from array or urls
# see perlfaq4
my %riddups = map { $_, 1 } @urls;
my @uniqueurls = keys %riddups;

sub create_mdlink {
    my ($url, $title) = @_;
    return "[".$title."]"."(".$url.")"

}

foreach my $url (@uniqueurls) {
        my $req = HTTP::Request->new(GET => $url);
        $req->header(Accept => "text/html");
        my $res = $ua->request($req);
        my $p = HTML::HeadParser->new;
        $p->parse($res->content) and print "not finished";
        my $title = $p->header('Title');
        print create_mdlink($url, $title), "\n";
}
