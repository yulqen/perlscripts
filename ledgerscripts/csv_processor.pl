#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use Text::CSV;
use JSON;

my $csv = Text::CSV->new({
        sep_char => ',',
        binary => 1,
        quote => "\N{FULLWIDTH QUOTATION MARK}"}
);

my %transaction;
my @jlist; # used to create the categories json fil0
my $cat_json;

my $file = $ARGV[0] or die "Need to get CSV file on the command line\n";
open(my $csvdata, '<:encoding(UTF-8)', $file) or die "Could not open '$file' $!\n";

{
    open(my $category_file, '<', "categories.json") or die "Could not open category file $!\n";
    local $/ = undef; # slurp mode!
    $cat_json = <$category_file>;
}

my $catref = decode_json $cat_json;
my $cats = $catref->{"data"};
# say qq($catref_d->[0]->{"desc"});

my @descs = map $_->{"desc"}, @{$cats};

sub get_category_from_desc {
    my $desc = shift;
    for my $hsh (@{$cats}) {
        if ($desc eq $hsh->{"desc"}) {
                return $hsh->{"category"};
            }
    }
}

while (my $line = <$csvdata>) {
    $line =~ s/^\N{BOM}//; 
    chomp $line;
    if ($csv->parse($line)) {
        my @fields = $csv->fields();
        $transaction{day} = substr $fields[0], 0, 2;
        $transaction{month} = substr $fields[0], 3, 2;
        $transaction{year} = substr $fields[0], 6, 4;
        $transaction{date} = $fields[0];
        $fields[1] =~ s/\s+/ /g;

        # used to create the categories json file - see below
        push @jlist, {"desc" => $fields[1], "category" => "NONE"};

        $transaction{desc} = $fields[1];
        $transaction{cost} = $fields[2];

        for my $d (@descs) {
            if ($transaction{desc} eq $d) {
                $transaction{exp_type} = get_category_from_desc $d;
            }
        }

        if ($fields[1] =~ /^.+(VIS|DR|DD|TFR|CR|SO|ATM|\)\)\))$/) {
            $transaction{type} = $1;
        } else 
            { die("CANNOT DETERMINE TYPE!\n")}

        if ($fields[2] =~ /^\-/) {
            $transaction{expense} = 1;
        } else 
            { $transaction{expense} = 0; }

        print join "", (
            $transaction{year},
            "/",
            $transaction{month},
            "/",
            $transaction{day},
            " ",
            "*",
            " ",
            $transaction{desc}
        ), "\n";
        if ($transaction{expense} == 1) {
            (my $cost = $transaction{cost}) =~ s/^\-//;
            print qq(\t$transaction{exp_type}\t$cost\n);
            print "\tassets:hsbc current\t$transaction{cost}\n";
            print "\n";
        } else {
            print "\tincome:baws\t-$transaction{cost}\n";
            print "\tassets:hsbc current\t$transaction{cost}\n";
            print "\n";
        }
    } else
        { warn "Line could not be parsed: $line\n";}
}



# The following code is used to output a JSON file
# to be used for categories. Uncomment for use.
# my $data = encode_json {data => \@jlist};

# open(my $fh, '>', "/tmp/categories.json") or die "Could not open file '/tmp/toss.json' $!";
# print $fh $data;
# close $fh;
# print "done\n";
