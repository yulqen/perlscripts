use warnings;
use strict;
use JSON;
use Data::Dumper;

my $json = JSON->new->allow_nonref;

sub pending_work {
    my $tw = qx(task project:w status:pending export);
    my $text = $json->decode( $tw );
    foreach my $h (@{$text}) {
        printf ("%s: %s\n", ${$h}{'uuid'}, ${$h}{'description'});
    }
}

sub pending_home {
    my $tw = qx(task project:h status:pending export);
    my $text = $json->decode( $tw );
    foreach my $h (@{$text}) {
        printf ("%s: %s\n", ${$h}{'uuid'}, ${$h}{'description'});
    }
}

print "Work:\n-----\n";
pending_work();


print "\nHome:\n-----\n";
pending_home();
