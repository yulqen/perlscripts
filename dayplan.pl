# Porting dayplan.ksh to Perl

use strict;
use warnings;
use DateTime;


my @quicknotes;
my @qfiles;
my ($dt, $d, $y, $m, $weekday);

my @weekdays = qw(Monday Tuesday Wednesday Thursday Friday Saturday Sunday);
my $dayplans = '/home/lemon/Notes/journal/day_plans';
my $numargs  = $#ARGV + 1;


# Go back and get short notes from past files
foreach my $f (glob("$dayplans/*.txt")) {
    open my $fh, "<", $f or die "Cannot open that file";
    while (<$fh>) {
        if ($_ =~ /^(- \w.*)$/) { 
            push @quicknotes => "$1\n";
            push @qfiles => "$f\n";
        };

    }
}
# deduplicate stuff
my %riddups = map { $_, "" } @quicknotes;
@quicknotes = keys %riddups;
my %riddfiles = map { $_, "" } @qfiles;
@qfiles = keys %riddfiles;

if ($numargs == 1) {
    ($y, $m, $d) = $ARGV[0] =~ /(\d\d\d\d)-(\d\d)-(\d\d)/;
    $dt = DateTime->new(
        year  => $y,
        month => $m,
        day   => $d
    );
    $weekday = $weekdays[$dt->day_of_week - 1];
}
else {
    $dt      = DateTime->now;
    $d       = $dt->day;
    $m       = $dt->month;
    $y       = $dt->year;
    $weekday = $weekdays[$dt->day_of_week - 1];
}

sub schoollines {
    my $day = shift;
    if ($day =~ /Saturday|Sunday/) {
        return "";
    } else
    {
        return "
08:15 - 08:20 - Harvey to school
08:45 - 09:00 - Sophie to school
09:15 - 09:30 - Email";
    }
}

my $reminders = qx(ssh bobbins remind ~/.reminders $y-$m-$d);
$reminders =~ s/\s{2,}/\n/gs;
$reminders =~ s/^Reminders.+\:\n//;

my $s = schoollines($weekday);

$" = "";

my $qnote_block;
if (scalar @quicknotes == 0) {
    $qnote_block = "No quicknotes today.\n";
} else
{
    $qnote_block = "@quicknotes"."from:"."\n"."@qfiles";
}


my $template = "Goal for $weekday: [replace this with your goal]
---

$qnote_block
Reminders:
---------
$reminders
$s
09:30 - 10:00 - 
10:00 - 11:00 - 
11:00 - 12:00 - 
12:15 - 13:00 - Lunch
13:00 - 14:00 - 
14:00 - 15:00 -
15:00 - 16:00 - 
16:00 - 17:00 -
";

my $today_planner = sprintf("%s/%d-%02d-%02d.txt", $dayplans,$y,$m,$d);

if (-e $today_planner) {
    exec("vim",  "$today_planner");
} else
{
    open( FH, ">$today_planner");
    print FH $template;
    close FH;
    exec("vim",  "$today_planner");
}
