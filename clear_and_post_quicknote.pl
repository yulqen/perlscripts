#!/usr/bin/env -S perl -w

use 5.010;
use warnings;
use strict;
use DateTime;
use File::Copy;
use Cwd qw(getcwd);

my $description = $ARGV[0];

if (not defined $description) {
    print "Please pass even a paltry introductory sentence in quotes. Thanks.\n";
    exit;
}

sub get_quicknotes {
    my $quicknote_file = "/home/lemon/Documents/Notes/quicknote.md";
    my $bak = "/home/lemon/Documents/Notes/quicknote.md-BAK";
    copy($quicknote_file, $bak) or die "Failed to make backup of file: $!";
    my @quicknotes;
    open my $fh, "<", $quicknote_file or die "Cannot open quicknote.md file";
    while (<$fh>) {
        if ($_ =~ /^- (.*)$/ || $_ =~ /(\[.*)$/) {
            push @quicknotes => "- $1\n";
        }
    }
    truncate $quicknote_file, 0;
    return \@quicknotes;
}


my $now = DateTime->now;
my $day_name = $now->day_name;
my $day = $now->day;
my $month = $now->month_name;
my $year = $now->year;

my $outfile = "/home/lemon/code/html/yulqen.org/content/techjournal/quicknote_capture_${day}_${month}_$year.md";

my $frontmatter = <<TEXT;
---
title: "Quicknote capture $day_name $day $month $year"
date: $now
draft: false
categories: ["Tech"]
tags: ['quicknotes']
---

$description

TEXT

my $qn_ref = get_quicknotes();
open my $FH, ">>", $outfile or die $!;
print $FH $frontmatter;
foreach (@{$qn_ref}) {
    print $FH $_;
}
close($FH);

chdir "/home/lemon/code/html/yulqen.org";
say getcwd();
# my @gitstatuscmd = ("git", "status");
my @gitaddcmd = ("git add -A");
my @gitcommitcmd = ("git commit -m 'update'");
my @gitpushcmd = ("git push");
my @pushcmd = ("make push");
# system(@gitaddcmd) or die "Cannot do git add $?";
# system(@gitcommitcmd) or die "Cannot do git commit: $?";
system(@pushcmd) or die "Cannot push the file to the remote: $?";
# system(@gitpushcmd) or die "Cannot do git push: $?";

say "Done!";

