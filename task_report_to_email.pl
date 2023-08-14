#!/usr/bin/perl
use strict;
use warnings;

use JSON;
use DateTime::Format::ISO8601;
use IPC::Open2;

# written in collaboration with GPT-4 on 2023-05-03.
# This script takes the output of the taskwarrior filter on line 11 and sends it to the email
# address provided in the first command line argument, using neomutt, which obviously must be
# configured. There is probably more that can be done to format it correctly. Obviously, the two
# perl modules above are required. 

# Check if the recipient email address is provided
if (@ARGV < 1) {
    print "Usage: $0 recipient_email\n";
    exit 1;
}

my $recipient_email = $ARGV[0];

# Execute Taskwarrior command
my $task_cmd = "task status:pending project:w export";
# my $task_cmd = "task status:pending limit:page -idea -killlist project.not:h.buy export";
my $task_output;
open(my $task_fh, "-|", $task_cmd) or die "Can't execute Taskwarrior command: $!";
{
    local $/ = undef;
    $task_output = <$task_fh>;
}
close($task_fh);

# Process Taskwarrior output
my $tasks = decode_json($task_output);
my @sorted_tasks = sort { ($a->{scheduled} // "9999") cmp ($b->{scheduled} // "9999") } @$tasks;

# Compose email content
my $email_content = "Subject: Task Report\n\n";
for my $task (@sorted_tasks) {
    $email_content .= sprintf "%s - %s%s%s%s\n",
        $task->{description},
        $task->{project} // "-",
        $task->{scheduled} ? " - Scheduled: " . DateTime::Format::ISO8601->parse_datetime($task->{scheduled})->strftime("%Y-%m-%d %H:%M") : "",
        $task->{due} ? " - Due: " . DateTime::Format::ISO8601->parse_datetime($task->{due})->strftime("%Y-%m-%d %H:%M") : "",
        $task->{priority} ? " - Priority: " . $task->{priority} : "";
}

# Send email using Neomutt
my $neomutt_cmd = "neomutt -s \"Task Report\" $recipient_email";
my ($neomutt_in, $neomutt_out);
my $neomutt_pid = open2($neomutt_out, $neomutt_in, $neomutt_cmd) or die "Can't execute Neomutt command: $!";
print $neomutt_in $email_content;
close($neomutt_in);
waitpid($neomutt_pid, 0);

