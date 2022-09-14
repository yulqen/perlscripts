# Porting dayplan.ksh to Perl

use strict;
use warnings;
use DateTime;


my $numargs = $#ARGV + 1;
my $fp = "/tmp";

my ($dt, $d, $y, $m, $weekday);

my @weekdays = qw(Monday Tuesday Wednesday Thursday Friday Saturday Sunday);

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

my $reminders = qx(ssh bobbins remind ~/.reminders $y-$m-$d);
$reminders =~ s/\s{2,}/\n/gs;
$reminders =~ s/^Reminders.+\:\n//;

my $template = "
Goal for $weekday: [replace this with your goal]
---

Reminders:

$reminders

08:15 - 08:20 - Harvey to school
08:45 - 09:00 - Sophie to school
09:15 - 09:30 - Email 
09:30 - 10:00 - 
10:00 - 11:00 - 
11:00 - 12:00 - 
12:15 - 13:00 - Lunch
13:00 - 14:00 - 
14:00 - 15:00 -
15:00 - 16:00 - 
16:00 - 17:00 -
";

my $today_planner = sprintf("%s/%d-%02d-%02d.txt", $fp,$y,$m,$d);

if (-e $today_planner) {
    exec("vim",  "$today_planner");
} else
{
    open( FH, ">$today_planner");
    print FH $template;
    close FH;
    exec("vim",  "$today_planner");
}
