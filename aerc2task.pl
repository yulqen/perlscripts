#!/usr/bin/env perl

# this script is used to pipe an email from aerc using pipe -m ./aerc2task.pl to taskwarrior

foreach my $line (<STDIN>) {
    chomp;
    if ($line =~ /^Subject/) {
        print "Received: $line\n";
        my @task_split = split(/Subject: /, $line);
        $task = @task_split[1];
        $task =~ s/TASK//g;
        $task =~ s/WATCH//g;
        print "So task is: $task\n";
        system("task add $task") == 0 or die "Calling taskwarrrior failed: $?";
    }
}

