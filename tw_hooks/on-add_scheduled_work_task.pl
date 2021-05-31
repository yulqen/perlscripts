#!/usr/bin/perl

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
    $tdelta = "+$1"; # corresponds to tdelta in remind: how many minutes prior to reminder it reminds
    $original_description =~ s/$token_regexes{tdelta}//g; # remove the delta time token
} else {
    $tdelta = "";
};

if (($original_description =~ m/$token_regexes{trepeat}/g)) {
    if ($tdelta eq "") { die "Cannot have a repeat token without a delta token" };
    $trepeat = "*$1"; # corresponds to trepeat in remind: how many minutes within tdelta it pings repeatedly
    $original_description =~ s/$token_regexes{trepeat}//g; # remove the delta time token
} else {
    $trepeat = "";
};

my $tags = ${$decoded_task}{tags}; # alternative - not using -> in the ref
my $scheduled_dt;

if ($decoded_task->{scheduled} and (scalar grep {$_ eq "dft" } @{$tags})) {
    $scheduled_dt = parse_scheduled $decoded_task->{scheduled};
    my $port = 22;
    my $date = $scheduled_dt->day();
    my $month = $short_months[$scheduled_dt->month()-1];
    my $year = $scheduled_dt->year();
    my $hr = $scheduled_dt->hour();
    my $min = $scheduled_dt->minute();
    my $time = substr $scheduled_dt->hms(), 0, 5; # we do not want seconds in the time format
    # Convert it into Remind format with %" bits that mean you don't get the
    # shit in wyrd
    my $remind_line = "REM $date $month $year AT $time $tdelta $trepeat MSG \%\"$original_description\%\" \%b\n";
    $remind_line =~ s/ +/ /g;
    
    # Log into remote server
    my $host = $ENV{"TW_HOOK_REMIND_REMOTE_HOST"} or die "Cannot get TW_HOOK_REMIND_REMOTE_HOST environment variable";
    my $user = $ENV{"TW_HOOK_REMIND_REMOTE_USER"} or die "Cannot get TW_HOOK_REMIND_REMOTE_USER environment variable";
    
    # use correct port
    if ($host eq "16693433.xyz") { $port = 2222 };

    say "Trying to establish connection at $host:$port ...";
    my $ssh = Net::OpenSSH->new($host, user => $user, port => $port);
    $ssh->error and die "Couldn't establish SSH connection: " . $ssh->error;

    # Check for presence or remind file
    if ($ssh->test("ls $work_rem_file") != 1) { die "Cannot find $work_rem_file on $host."};

    # If it is there, back it up
    $ssh->system("cp $work_rem_file $work_rem_file.bak") or die "Cannot create a back-up of remind file."; 

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
#  print encode_json $decoded_task; 
   print("Add hook not used.\n");
   exit 0;
}

=pod

=head1 NAME

on-add_scheduled_work_task

=head1 DESCRIPTION

This is a Taskwarrior hook for interacting with the remind calendar on a remote server. It currently only
works under a specific set of circumstances which will be explained here.

The current implementation will add a remind item for a taskwarrior item which has the tag "dft" and is "scheduled"
for a time and date.

=head1 PREREQUISITES

=over

=item * A remote server and its IP address or domain name with remind already set up, and ssh access to it.

=item * Taskwarrior - with this perl script at ~/.task/hooks/on-add_scheduled_work_task.pl

=item * An environment variable TW_HOOK_REMIND_REMOTE_HOST set with the IP address or domain name of the remote server which hosts remind.

=item * An environment variable TW_HOOK_REMIND_REMOTE_USER set with the username on the remote server which ssh requires to log in.

=item * The following perl dependences: JSON, Net::OpenSSH, DateTime and DateTime::Format::ISO8601 installed.

=back

=head1 REQUIRED TASKWARRIOR FORMAT

The hook is only triggered when a new task is added with a "dft" tag and is "scheduled".

Here is a full example, which includes a remind C<tdelta> and C<trepeat>:

=over 8

=item

C<task add Meaningless meeting +10 *1 +dft scheduled:2021-10-09T10:00Z>

=back

The C<Z> is optional, but the time specified is in Zulu time, so take that into account. When in BST it will take an hour off.

Although this is a meaningless meeting, it is important enough to be reminded of it 10 minutes before 10am (C<+10>), with a repeat 
every minute (C<*1>) between the initial reminder and the time of the meeting itself.

The additional C<tdelta> and C<trepeat> tags (+10 and *1) are removed from the task description before either getting to remind
or to taskwarrior.

=cut

