#!/usr/bin/perl
# Porting dayplan.ksh to Perl

use strict;
use warnings;
use DateTime;

my $dayplans = '/home/lemon/Notes/journal/day_plans';

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
    foreach my $f (glob("$dayplans/*.txt")) {
        open my $fh, "<", $f or die "Cannot open that file";
        while (<$fh>) {
            if ($_ =~ /^(- \w.*)$/) { 
                push @quicknotes => "$1\n";
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


sub schoolblock {
    my $day = shift;
    if ($day =~ /Saturday|Sunday/) {
        return "";
    } else
    {
        return "
08:15 - 08:20 - Harvey to school
08:45 - 09:00 - Sophie to school
09:15 - 09:30 - Email";
    }
}

sub quoteblock {
    $" = "";
    my $quicknotes_ref =shift;
    my $qfiles_ref = shift;
    my $qnote_block;

    if (scalar @{$quicknotes_ref} == 0) {
        $qnote_block = "No quicknotes today.\n";
    } else
        {
            $qnote_block = "@{$quicknotes_ref}"."from:"."\n"."@{$qfiles_ref}";
        }
        return $qnote_block;
    }

sub headerblock {
    my $dt      = shift;
    my $d       = shift;
    my $y       = shift;
    my $weekday = shift;
    my $mname   = $dt->month_name;
    return "Goal for $weekday $d $mname $y: [replace this with your goal]
---
";
}

sub get_reminders_from_server {
    my ($y, $m, $d) = @_;
    my $reminders = qx(ssh bobbins remind ~/.reminders $y-$m-$d);
    $reminders =~ s/\s{2,}/\n/gs;
    $reminders =~ s/^Reminders.+\:\n//;
    return $reminders;
}


my ($quicknotes_ref, $qfiles_ref) = get_quicknotes_and_quickfiles();
print headerblock($date, $day, $year, $weekday);
