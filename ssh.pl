use strict;
use warnings;
use Net::OpenSSH;
use JSON;

my $host = "192.168.122.184";
my $user = "lemon";

my $ssh = Net::OpenSSH->new($host, user => $user);
$ssh->error and die "Couldn't establish SSH connection: " . $ssh->error;

# $ssh->system("ls -al ~") or die "remote command failed: " . $ssh->error;

my $remote_host = $ssh->capture("hostname");

print "Working on $remote_host.\n";

# my @required_file = $ssh->capture("cat ~/.bashrc") or die "Cannot get requested file";
# for (@required_file) {
#     # print $_ if $_ =~ /^if*/;
#     # print $_;
#     # print $_ if !($_ =~ /^#/); # strips the comments
#     print $_ if ($_ =~ /^#/); # just the comments
# }
# print("\n");

# append to bollocks
# my $append_text = "Tits\n";
# $ssh->system({stdin_data => $append_text}, "cat >> bollocks.txt") or die "Cannot append text: " . $ssh->error;
my %test_hash = ('first_name' => 'Matthew', 'surname' => 'Lemon');
my $json_text = encode_json \%test_hash;
print "$json_text\n";

