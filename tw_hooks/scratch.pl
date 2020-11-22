use warnings;
use strict;
use feature qw(say);
use JSON;
use DateTime;
use DateTime::Format::ISO8601;


my @short_months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

# subs
sub parse_scheduled
{
    my $sched_date = shift;
    return DateTime::Format::ISO8601->parse_datetime($sched_date);
}
 
# ALGORITHM
# Parse the scheduled attribute from TW

my $added_task = <STDIN>;
my $decoded_task = decode_json $added_task;
my $original_description = ${$decoded_task}{description};
my $tags = ${$decoded_task}{tags}; # alternative - not using -> in the ref
my $scheduled_dt;

if ($decoded_task->{scheduled} and (scalar grep {$_ eq "dft" } @{$tags})) {
    $scheduled_dt = parse_scheduled $decoded_task->{scheduled};
    my $date = $scheduled_dt->day();
    my $month = $short_months[$scheduled_dt->month()-1];
    my $year = $scheduled_dt->year();
    my $hr = $scheduled_dt->hour();
    my $min = $scheduled_dt->minute();
    my $time = $scheduled_dt->hms();
    # Convert it into Remind format
    my $remind_line = "REM $date $month $year AT $time $original_description";
    print $remind_line;
} else {
   print encode_json $decoded_task; 
}


# Log into remote server
# Check for presece or remind file
# If it is there, back it up
# Append the Remind formatted line to the original remind file


