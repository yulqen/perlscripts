#!/usr/bin/perl

use warnings;
use strict;
use feature qw(say);
use JSON;
use DateTime;
use DateTime::Format::ISO8601;
use Net::OpenSSH;

my $rfile;

unless ($ARGV[0] =~ /^-h/ || $ARGV[0] =~ /^-w/) {
    say q(You must indicate either -h for home.rem or -w for work.rem.); exit;
    }

unless ($ARGV[1] =~ /^REM/) {
    say q(Your message must start with REM. Format is REM DATE AT TIME MSG Message - any traditional remind format.); exit;
}

if ($ARGV[0] eq "-h") {
    $rfile = "~/.reminders/home.rem";
    say "Using home.rem."
} elsif ($ARGV[0] eq "-w") {
    $rfile = "~/.reminders/home.rem";
    say "Using work.rem."
}

sub check_env {
    # Log into remote server
    my $host = $ENV{"TW_HOOK_REMIND_REMOTE_HOST"}
      or die "Cannot get TW_HOOK_REMIND_REMOTE_HOST environment variable";
    my $user = $ENV{"TW_HOOK_REMIND_REMOTE_USER"}
      or die "Cannot get TW_HOOK_REMIND_REMOTE_USER environment variable";
    return ($host, $user);
}

sub get_connection {
    my $host = shift;
    my $port = shift;
    my $user = shift;
    # use correct port
    if ( $host =~ m/.*\.xyz$/ ) { $port = 2222 }

    say "Trying to establish connection at $host:$port ...";
    my $ssh = Net::OpenSSH->new( $host, user => $user, port => $port );
    $ssh->error and die "Couldn't establish SSH connection: " . $ssh->error;
    return $ssh;
}

sub check_remind_file_exists {
    my $ssh     = shift;
    my $host    = shift;
    my $remfile = shift;
    #
    # Check for presence or remind file
    if ( $ssh->test("ls $remfile") != 1 ) {
        die "Cannot find $remfile on $host.";
    }

    # If it is there, back it up
    $ssh->system("cp $remfile $remfile.bak")
      or die "Cannot create a back-up of remind file.";
}

sub append_to_remfile {
    my $ssh     = shift;
    my $host    = shift;
    my $remfile = shift;
    my $remline = shift;

    if ($remline =~ /\sAT\s/) {
        chomp $remline;
        $remline = $remline . " %3\n";
    } else
    {
        chomp $remline;
        $remline = $remline . " %b\n";
    }
    
     
    # Append the Remind formatted line to the original remind file
    $ssh->system( { stdin_data => $remline }, "cat >> $remfile" )
      or die "Cannot append text: " . $ssh->error;
    # $ssh->system("echo >> $remline $remfile")
    #   or die "Cannot append text: " . $ssh->error;

    # Get content of remind file
    my @out_file = $ssh->capture("cat $remfile");

    print qq/
Contents of $remfile on $host is now:\n/, @out_file;
}

my ($host, $user) = check_env();
my $ssh = get_connection($host, 2222, $user);
check_remind_file_exists($ssh, $host, $rfile);
append_to_remfile($ssh, $host, $rfile, "$ARGV[1]\n");
exit;
