#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);
use JSON;
use DateTime;
use DateTime::Format::ISO8601;

# a test hook in Perl for taskwarrior

my @short_months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @days_of_week = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);

# this must be JSON - this gets passed in my taskwarrior
my $added_task = <STDIN>;

my $hashref = decode_json $added_task;

sub parse_scheduled
{
    my $sched_date = shift;
    return DateTime::Format::ISO8601->parse_datetime($sched_date);
}

if ($hashref->{scheduled}) {
    my $scheduled_dt = parse_scheduled $hashref->{scheduled};
    print "Scheduled Date:\n";
    print "---------------\n";
    print "Year is: ".$scheduled_dt->year() . "\n";
    print "Month is: ".$scheduled_dt->month() . "\n";
    print "Month again is: ".$short_months[$scheduled_dt->month()-1] . "\n";
    print "Day is: ".$scheduled_dt->day() . "\n";
    # O
    # # wday() is builtin?
    # https://stackoverflow.com/questions/10919585/extract-day-of-week-using-perl-and-mysql-date-format
    # https://metacpan.org/pod/Time::Piece
    print "Day of week is: ".$days_of_week[$scheduled_dt->day_of_week() % 7] . "\n";
    print "Quarter is: ".$scheduled_dt->quarter(). "\n";
    print "\n";
}

# if ($hashref->{scheduled}) {
#     my $sched_date = $hashref->{scheduled};
#     my $year = substr $sched_date, 0, 4;
#     my $month = substr $sched_date, 4, 2;
#     my $day = substr $sched_date, 6, 2;

#     my $dt = DateTime->new(
#         year        => $year,
#         month       => $month,
#         day         => $day,
#         time_zone   => 'Europe/London',
#     );

#     print "Year is: $dt->year" . "\n";
#     print "Month is: $dt->month" . "\n";
#     print "Day is: $dt->$day" . "\n";
#     print "\n";
# }

my $original_description = ${$hashref}{description};
# my $original_description = $hashref->{description}; # alternative (and
# preferred)

my $tags = ${$hashref}{tags}; # alternative - not using -> in the ref

$hashref->{description} = "DfT Task: " . $original_description if scalar grep {$_ eq "dft" } @{$tags};
# same as
# $hashref->{description} = "DfT Task: " . $original_description if scalar grep {$_ eq "dft" } @$tags;
# You don't need the {} brackets! see perlreftut - The Rest section near the
# end.

my $output = encode_json $hashref;

print $output;

exit 0;
