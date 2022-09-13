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
    say "Pass a search term. All lines in the journal will be matched and URLs quoted will be extracted.";
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
        if ($_ =~ m/$searchterm/) {
            # printf "  %s", $_;
            push @targetlines, $_; 
        }
    }
    close $fh or die "can't read close file '$f': $OS_ERROR";
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
        # print "Saving: $t\n";
        # push @urls => $t
        my $req = HTTP::Request->new(GET => $t);
        $req->header(Accept => "text/html");
        my $res = $ua->request($req);
        my $p = HTML::HeadParser->new;
        $p->parse($res->content) and print "not finished";
        print $p->header('Title'), "\n";
        # my $root = HTML::TreeBuilder->new_from_content($res->content);
        # my $title = $root->look_down('_tag' => 'title');
        # my $value = $title->attr('value');
    }
}


# foreach my $url (@urls) {
#     print $url;
#     my $req = HTTP::Request->new(GET => $url);
#     $req->header(Accept => "text/html");
#     my $res = $ua->request($req);

#     my $root = HTML::TreeBuilder->new_from_content($req->content);

#     print $root;
#     # my @elements = $root->look_down(_tag => "title");
#     # foreach my $thing (@elements) {
#     #     print $thing->as_text, "\n";
#     # }
# }






# if ($res->is_success) {
#     $tree->parse($res->as_string);
# }
# else {
#     print $res->status_line, "\n";
# }

