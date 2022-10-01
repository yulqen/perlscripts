#!/usr/bin/perl
# Porting dayplan.ksh to Perl

use strict;
use warnings;
use DateTime;
use JSON;

my $dayplans = '/home/lemon/Notes/journal/day_plans';
#my $dayplans = "/tmp/dayplans";

sub parse_args {
    my $numargs  = $#ARGV + 1;
    my @weekdays = qw(Monday Tuesday Wednesday Thursday Friday Saturday Sunday);
    if ($numargs == 1) {
        my ($y, $m, $d) = $ARGV[0] =~ /(\d\d\d\d)-(\d\d)-(\d\d)/;
        my $dt = DateTime->new(
            year  => $y,
            month => $m,
            day   => $d
        );
        my $weekday = $weekdays[$dt->day_of_week - 1];
        return ($dt, $d, $m, $y, $weekday);
    }
    else {
        my $dt      = DateTime->today;
        my $d       = $dt->day;
        my $m       = $dt->month;
        my $y       = $dt->year;
        my $weekday = $weekdays[$dt->day_of_week - 1];
        return ($dt, $d, $m, $y, $weekday);
    }
}

my ($date, $day, $month, $year, $weekday) = parse_args();


sub get_quicknotes_and_quickfiles {
    my @quicknotes;
    my @qfiles;
    foreach my $f (glob("$dayplans/*")) {
        open my $fh, "<", $f or die "Cannot open f";
        while (<$fh>) {
            if ($_ =~ /^- (.*)$/) { 
                push @quicknotes => "- $1\n";
                push @qfiles => "$f\n";
            };
        }
    }
    my %riddups = map { $_, "" } @quicknotes;
    @quicknotes = keys %riddups;
    my %riddfiles = map { $_, "" } @qfiles;
    @qfiles = keys %riddfiles;
    return (\@quicknotes, \@qfiles);
}

sub headerblock {
    my $dt      = shift;
    my $d       = shift;
    my $y       = shift;
    my $weekday = shift;
    my $mname   = $dt->month_name;
    return "# $weekday $d $mname $y\n
";
}

sub qnoteblock {
    $" = "";
    my $quicknotes_ref =shift;
    my $qfiles_ref = shift;
    my $qnote_block;

    if (scalar @{$quicknotes_ref} == 0) {
        $qnote_block = "## Quicknotes:\nNo quicknotes today.\n";
    } else
        {
            unshift @$quicknotes_ref, "## Quicknotes:\n";
            $qnote_block = "@{$quicknotes_ref}"."from:"."\n"."@{$qfiles_ref}";
        }
    return $qnote_block;
}

sub schoolblock {
    my $day = shift;
    if ($day =~ /Saturday|Sunday/) {
        return "";
    } else
    {
        return "
08:15 - 08:20 - Harvey to school
08:45 - 09:00 - Sophie to school 
09:15 - 09:30 - Email ";
    }
}

sub twblock {
    my ($y, $m, $d, $project, $type) = @_;
    $m = sprintf("%02d", $m);
    $d = sprintf("%02d", $d);
    my $json = JSON->new->allow_nonref;
    my $tw= qx(task project:$project status:pending $type:$y-$m-$d export);
    my @output;
    push @output, "## Taskwarrior $type - $project:\n";
    if ($tw eq "") {
        push @output, "* No tasks";
        push @output, "\n";
        return @output;
    } else
    {
        my $text = $json->decode( $tw );
        foreach my $h (@{$text}) {
            push @output, sprintf ("* %-16s: %s\n", ${$h}{'project'}, ${$h}{'description'});
        }
        push @output, "\n";
        return @output;
    }
}

sub remindersblock {
    my ($y, $m, $d) = @_;
    my $reminders = qx(ssh bobbins remind ~/.reminders $y-$m-$d);
    $reminders =~ s/\s{2,}/\n/gs;
    $reminders =~ s/^Reminders.+\:\n//;
    my @rems = split /\n/, $reminders;
    my @out_rems;
    foreach my $r (@rems) {
        my $s = sprintf("* %s\n", $r);
        push @out_rems, $s;
    }
    unshift @out_rems, "\n## Reminders:\n";
    return @out_rems;
}

sub timeblock {
    return "
09:30 - 10:00 - 
10:00 - 11:00 - 
11:00 - 12:00 - 
12:15 - 13:00 - Lunch 
13:00 - 14:00 - 
14:00 - 15:00 - 
15:00 - 16:00 - 
16:00 - 17:00 - 
";
}

sub generate_text {
    my ($quicknotes_ref, $qfiles_ref) = get_quicknotes_and_quickfiles();
    return
        headerblock($date, $day, $year, $weekday),
        twblock($year, $month, $day, "w", "sched"),
        twblock($year, $month, $day, "h", "sched"),
        twblock($year, $month, $day, "w", "due"),
        twblock($year, $month, $day, "h", "due"),
        qnoteblock($quicknotes_ref, $qfiles_ref),
        remindersblock($year, $month, $day),
        schoolblock($day),
        timeblock;
}


sub write_file {
    my $f  = shift;
    my $dt = shift;

    open( FH, ">$f");
    print FH generate_text;
    my $today = DateTime->today;
    if ($today != $dt) {
        printf (FH "\nWARNING: This dayplan was generated in advance on %d-%02d-%d. Reminders and quicknotes may not be up to date.", $today->year,  $today->month,  $today->day);
    }
    
    close FH;
    exec("vim", "$f");
}

sub main {
    my $today_planner = sprintf("%s/%d-%02d-%02d.md", $dayplans, $year ,$month, $day);

    if (-e $today_planner) {
        exec("vim",  "$today_planner");
    } else
    {
        write_file($today_planner, $date);
    }
}

main();
