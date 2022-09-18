#!/usr/bin/perl

use warnings;
use strict;
use feature qw(say);
use JSON;
use DateTime;
use DateTime::Format::ISO8601;
use Net::OpenSSH;


my @short_months = qw(January February March April May June July August September October November December);
#my @short_months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

# subs
sub parse_scheduled {
    my $sched_date = shift;
    return DateTime::Format::ISO8601->parse_datetime($sched_date);
}

my %token_regexes = (
    tdelta  => qr/\+(\d+)/,    # +INT (see remind man page)
    trepeat => qr/\*(\d+)/,    # *INT (see remind man page)
    delta   => qr/D\+(\d+)/,
    repeat  => qr/D\*(\d+)/,
);

my $added_task           = <STDIN>;
my $work_rem_file        = '~/.reminders/work.rem';
my $decoded_task         = decode_json $added_task;
my $original_description = ${$decoded_task}{description};
my $tdelta;
my $trepeat;
my $delta;
my $repeat;

if ( ( $original_description =~ m/$token_regexes{delta}/g ) ) {
    $delta = "+$1";
    $original_description =~
      s/$token_regexes{delta}//g;    # remove the delta token
}
else {
    $delta = "";
}

if ( ( $original_description =~ m/$token_regexes{repeat}/g ) ) {
    $repeat = "*$1";
    $original_description =~
      s/$token_regexes{repeat}//g;    # remove the repeat token
}
else {
    $repeat = "";
}

if ( ( $original_description =~ m/$token_regexes{tdelta}/g ) ) {
    $tdelta = "+$1"
      ; # corresponds to tdelta in remind: how many minutes prior to reminder it reminds
    $original_description =~
      s/$token_regexes{tdelta}//g;    # remove the delta time token
}
else {
    $tdelta = "";
}

if ( ( $original_description =~ m/$token_regexes{trepeat}/g ) ) {
    if ( $tdelta eq "" ) {
        die "Cannot have a repeat token without a delta token";
    }
    $trepeat = "*$1"
      ; # corresponds to trepeat in remind: how many minutes within tdelta it pings repeatedly
    $original_description =~
      s/$token_regexes{trepeat}//g;    # remove the delta time token
}
else {
    $trepeat = "";
}

my $tags = ${$decoded_task}{tags};     # alternative - not using -> in the ref
my $scheduled_dt;

if ( $decoded_task->{scheduled} and ( scalar grep { $_ eq "dft" } @{$tags} ) ) {
    $scheduled_dt   = parse_scheduled $decoded_task->{scheduled};
    # my @test_task = `task add Bobbins from Perl`;
    my $port        = 22;
    my $date        = $scheduled_dt->day();
    my $month       = $short_months[ $scheduled_dt->month() - 1 ];
    my $year        = $scheduled_dt->year();
    my $hr          = $scheduled_dt->hour();
    my $min         = $scheduled_dt->minute();
    my $time        = substr $scheduled_dt->hms(), 0,
      5;    # we do not want seconds in the time format
        # Convert it into Remind format with %" bits that mean you don't get the
        # shit in wyrd

    $original_description =~ s/\s+$//;    # trim white space from end of string
    my $remind_line =
"REM $date $month $year $delta $repeat AT $time $tdelta $trepeat MSG \%\"$original_description\%\" \%b\n";
    $remind_line =~ s/ +/ /g;

    # Log into remote server
    my $host = $ENV{"TW_HOOK_REMIND_REMOTE_HOST"}
      or die "Cannot get TW_HOOK_REMIND_REMOTE_HOST environment variable";
    my $user = $ENV{"TW_HOOK_REMIND_REMOTE_USER"}
      or die "Cannot get TW_HOOK_REMIND_REMOTE_USER environment variable";

    # use correct port
    if ( $host =~ m/.*\.xyz$/ ) { $port = 2222 }

    say "Trying to establish connection at $host:$port ...";
    my $ssh = Net::OpenSSH->new( $host, user => $user, port => $port );
    $ssh->error and die "Couldn't establish SSH connection: " . $ssh->error;

    # Check for presence or remind file
    if ( $ssh->test("ls $work_rem_file") != 1 ) {
        die "Cannot find $work_rem_file on $host.";
    }

    # If it is there, back it up
    $ssh->system("cp $work_rem_file $work_rem_file.bak")
      or die "Cannot create a back-up of remind file.";

    # Append the Remind formatted line to the original remind file
    $ssh->system( { stdin_data => $remind_line }, "cat >> $work_rem_file" )
      or die "Cannot append text: " . $ssh->error;

    # Get content of remind file
    my @out_file = $ssh->capture("cat $work_rem_file");

    print qq/
Contents of $work_rem_file on $host is now:\n/, @out_file;

    # TODO - we need to strip away the %:MIN syntax from the original
    # description - need to substitute it here!
    $decoded_task->{description} = $original_description;
    print encode_json $decoded_task;
    exit 0;
}
else {
    print $added_task;
    print("Add hook not used.\n");
    exit 0;
}

=pod

=head1 NAME

on-add_scheduled_work_task

=head1 SYNOPSIS

=over

=item C<task add Meaningless event at work +dft scheduled:2021-10-10>

This will create an untimed reminder for 10 October 2021.

=item C<task add Meaningless event at work D+2 +dft scheduled:2021-10-10>

This will create an untimed reminder for 10 October 2021 and remind you of it 2 days in advance.

=item C<task add Meaningless event at work D*2 +dft scheduled:2021-10-10>

This will create an untimed reminder for 10 October 2021 and every other day subsequently.

=item C<task add Meaningless event at work D*2 +dft scheduled:2021-10-10T10:00Z>

This will create a reminder for 10 October 2021 at 11:00BST and every other day subsequently at the same time.

=item C<task add Meaningless meeting at work +dft scheduled:2021-10-10T10:00Z>

This will create a reminder for 11:00BST for 10 October 2021.

=item C<task add Meaningless meeting at work +10 +dft scheduled:2021-10-10T10:00Z>

This will create a reminder for 11:00BST for 10 October 2021, and hassle you once 10 minutes before the meeting.

=item C<task add Meaningless meeting at work +10 *1 +dft scheduled:2021-10-10T10:00Z>

This will create a reminder for 11:00BST for 10 October 2021, and hassle you once 10 minutes before the meeting AND each minute 
from then until the start of the meeting.

=back

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

=head1 REMIND SYNTAX

C<REM [ONCE] [date_spec] [back] [delta] [repeat] [PRIORITY prio] [SKIP | BEFORE | AFTER] [OMIT omit_list] [OMITFUNC omit_function] [AT time
[tdelta] [trepeat]] [SCHED sched_function] [WARN warn_function] [UNTIL expiry_date] [SCANFROM scan_date | FROM start_date] [DURATION
duration] [TAG tag] E<lt>MSG | MSF | RUN | CAL | SATISFY | SPECIAL special | PS | PSFILEE<gt> body>

The elements we are interested in are:

=over

=item * delta (for advanced warning of the date)

=item * repeat (for repeating from the trigger date)

=item * tdelta (for advanced warning of the AT time)

=item * trepeat (for repeating the advanced reminder)

=back

=head2 Advance warning (delta)

For some reminders, it is appropriate to receive advance warning of the event. For example, you may wish to be reminded of someone's birthday
several days in advance. The delta portion of the REM command achieves this. It is specified as one or two "+" signs followed by a number n.
Again, the difference between the "+" and "++" forms will be explained under the OMIT keyword. Remind will trigger the reminder on computed
trigger date, as well as on each of the n days before the event. Here are some examples:

C<REM 6 Jan +5 MSG Remind me of birthday 5 days in advance.>

The above example would be triggered every 6th of January, as well as the 1st through 5th of January.

=head2 Recurring events (repeat)

However, events that do not repeat daily, weekly, monthly or yearly require another approach. The repeat component of the REM command fills this
need. To use it, you must completely specify a date (year, month and day, and optionally weekday.) The repeat component is an asterisk
followed by a number specifying the repetition period in days.

For example, suppose you get paid every second Wednesday, and your last payday was Wednesday, 28 October, 1992. You can use:

C<REM 28 Oct 1992 *14 MSG Payday>

This issues the reminder every 14 days, starting from the calculated trigger date. You can use delta and back with repeat. Note, however, that the
back is used only to compute the initial trigger date; thereafter, the reminder repeats with the specified period. Similarly, if you specify
a weekday, it is used only to calculate the initial date, and does not affect the repetition period.

=head1 REQUIRED TASKWARRIOR FORMAT

The hook is only triggered when a new task is added with a "dft" tag and is "scheduled".

=head2 Example using tdelta and trepeat (a remind command with AT/timed element)

The syntax for tdelta and trepeat must be included in the task description. It matches the equivalent remind syntax (+10 and *1).
These are removed from the description before saving and are used in the C<AT> clause in remind.

=over

=item

C<task add Meaningless meeting +10 *1 +dft scheduled:2021-10-09T10:00Z>

=back

The C<Z> is optional, but the time specified is in Zulu time, so take that into account. When in BST it will take an hour off.

Although this is a meaningless meeting, it is important enough to be reminded of it 10 minutes before 10am (C<+10>), with a repeat 
every minute (C<*1>) between the initial reminder and the time of the meeting itself.

The additional C<tdelta> and C<trepeat> tags (+10 and *1) are removed from the task description before either getting to remind
or to taskwarrior.

=head2 Example using delta (a remind command with advanced warning in days)

The only way that delta is different from tdelta inside the remind REM command is from it's placement: delta relates to the date aspect
whereas tdelta relates to time in the C<AT> clause. We wish to retain the use of "+" but we must distinguise it inside the task description
from tdelta so for delta we prefix with C<D>: e.g. C<D+10> which says that this must give us advance warning of 10 days. At this point, we
are only using one C<+>, not two because use of the C<OMIT> keyword is not yet implemented.

=over

=item

C<task add Meaningless meeting D+2 +dft scheduled:2021-10-09T10:00Z>

=back

This will pre-warn us 2 days in advance of the meaningless meeting scheduled to take place on 9 October 2021 at 11:00BST. The advance 
warning triggers will not trigger at the time of the meeting; instead the calendar will show that the meaningless meeting is happening in X days.

=head2 Example using repeat (a remind command which creates a repeating event)

This will set an event for the specified date/date and time and will repeat X days following.

=over

=item

C<task add Meaningless meeting D*2 +dft scheduled:2021-10-09T10:00Z>

=back

All tokens: C<delta>, C<repeat>, C<tdelta> and C<trepeat> can be mixed and matched in the C<task> description.

=cut

