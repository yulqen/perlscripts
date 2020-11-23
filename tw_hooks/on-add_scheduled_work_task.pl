#!/bin/env perl

use warnings;
use strict;
use feature qw(say);
use JSON;
use DateTime;
use DateTime::Format::ISO8601;
use Net::OpenSSH;


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
my $work_rem_file = '~/.reminders/work.rem';
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
    my $remind_line = "REM $date $month $year AT $time MSG $original_description \%b\n";
    
    # Log into remote server
    
    my $host = $ENV{"TW_HOOK_REMIND_REMOTE_HOST"} or die "Cannot get TW_HOOK_REMIND_REMOTE_HOST environment variable";
    my $user = "lemon";

    my $ssh = Net::OpenSSH->new($host, user => $user);
    $ssh->error and die "Couldn't establish SSH connection: " . $ssh->error;

    # Check for presece or remind file
    if ($ssh->test("ls $work_rem_file") != 1) { die "Cannot find $work_rem_file on $host."};

    # If it is there, back it up
    $ssh->system("cp $work_rem_file $work_rem_file.bak"); 

    # Append the Remind formatted line to the original remind file
    $ssh->system({stdin_data => $remind_line}, "cat >> ~/.reminders/work.rem") or die "Cannot append text: " . $ssh->error;
    
    # Reset the back up
    # $ssh->system("mv $work_rem_file.bak $work_rem_file"); 
    # $decoded_task->{"Description"} = "Cocks";

    print "Trumpets\n";
    print encode_json $decoded_task;
    exit 0;
} else {
   print encode_json $decoded_task; 
   exit 0;
}




