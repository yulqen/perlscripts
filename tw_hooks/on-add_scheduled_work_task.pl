#!/bin/env perl

use warnings;
use strict;
use feature qw(say);
use JSON;
use DateTime;
use DateTime::Format::ISO8601;
use Net::OpenSSH;


my @short_months = qw(January February March April May June July August September October November December);

# subs
sub parse_scheduled
{
    my $sched_date = shift;
    return DateTime::Format::ISO8601->parse_datetime($sched_date);
}
 
# ALGORITHM
# Parse the scheduled attribute from TW

my %token_regexes = (
    tdelta => qr/\+(\d+)/, # +INT (see remind man page)
    trepeat => qr/\*(\d+)/, # *INT (see remind man page)
);



my $added_task = <STDIN>;
my $work_rem_file = '~/.reminders/work.rem';
my $decoded_task = decode_json $added_task;
my $original_description = ${$decoded_task}{description};
my $tdelta;
my $trepeat;

if (($original_description =~ m/$token_regexes{tdelta}/g)) {
    $tdelta = "+$1";
    $original_description =~ s/$token_regexes{tdelta}//g; # remove the delta time token
} else {
    $tdelta = "";
};

if (($original_description =~ m/$token_regexes{trepeat}/g)) {
    if ($tdelta eq "") { die "Cannot have a repeat token without a delta token" };
    $trepeat = "*$1";
    $original_description =~ s/$token_regexes{trepeat}//g; # remove the delta time token
} else {
    $trepeat = "";
};

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
    my $remind_line = "REM $date $month $year AT $time $tdelta $trepeat MSG $original_description \%b\n";
    $remind_line =~ s/ +/ /g;
    
    # Log into remote server
    
    my $host = $ENV{"TW_HOOK_REMIND_REMOTE_HOST"} or die "Cannot get TW_HOOK_REMIND_REMOTE_HOST environment variable";
    my $user = $ENV{"TW_HOOK_REMIND_REMOTE_USER"} or die "Cannot get TW_HOOK_REMIND_REMOTE_USER environment variable";

    my $ssh = Net::OpenSSH->new($host, user => $user);
    $ssh->error and die "Couldn't establish SSH connection: " . $ssh->error;

    # Check for presece or remind file
    if ($ssh->test("ls $work_rem_file") != 1) { die "Cannot find $work_rem_file on $host."};

    # If it is there, back it up
    $ssh->system("cp $work_rem_file $work_rem_file.bak"); 

    # Append the Remind formatted line to the original remind file
    $ssh->system({stdin_data => $remind_line}, "cat >> $work_rem_file") or die "Cannot append text: " . $ssh->error;

    # Get content of remind file
    my @out_file = $ssh->capture("cat $work_rem_file");


    print qq/
Contents of $work_rem_file on $host is now:\n/,
    @out_file;

    # TODO - we need to strip away the %:MIN syntax from the original
    # description - need to substitute it here!
    $decoded_task->{description} = $original_description;
    print encode_json $decoded_task;
    exit 0;
} else {
   print encode_json $decoded_task; 
   exit 0;
}




