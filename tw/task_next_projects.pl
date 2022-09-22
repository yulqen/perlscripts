use warnings;
use strict;
use JSON;
use Data::Dumper;

my $json = JSON->new->allow_nonref;

sub pending_work {
    my $tw = qx(task project:w status:pending export);
    my $text = $json->decode( $tw );
    foreach my $h (@{$text}) {
        printf ("%-16s: %s\n", ${$h}{'project'}, ${$h}{'description'});
    }
}

sub pending_home {
    my $tw = qx(task project:h status:pending export);
    my $text = $json->decode( $tw );
    foreach my $h (@{$text}) {
        printf ("%-16s: %s\n", ${$h}{'project'}, ${$h}{'description'});
    }
}

sub sched_today_work {
    my $tw = qx(task project:w status:pending sched:today export);
    my $text = $json->decode( $tw );
    foreach my $h (@{$text}) {
        printf ("%-16s: %s\n", ${$h}{'project'}, ${$h}{'description'});
    }
}

sub due_today_work {
    my $tw = qx(task project:w status:pending due:today export);
    my $text = $json->decode( $tw );
    foreach my $h (@{$text}) {
        printf ("%-16s: %s\n", ${$h}{'project'}, ${$h}{'description'});
    }
}

print "Work Due Today:\n-----\n";
due_today_work();

print "Work Sched Today:\n-----\n";
sched_today_work();

print "Work:\n-----\n";
pending_work();

print "\nHome:\n-----\n";
pending_home();
