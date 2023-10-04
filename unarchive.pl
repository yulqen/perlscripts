#!/usr/bin/env -S perl

use strict;
use warnings;
use feature q(say);
use Archive::Tar;

# This is just a test script to play with the Archive::Tar package 

# Specify the archive file you want to read
my $archive_file = 'journal_archive_aug23.tgz';

# Create an Archive::Tar object for reading
my $tar = Archive::Tar->new;

# Read the archive file
$tar->read($archive_file);

# Search string
my $search_string = "Joanna";

# Iterate through the files in the archive in memory
foreach my $file ($tar->get_files) {
    # Check if the file matches your filter (e.g., .txt extension)
    if ($file->name =~ /\.md$/) {
        # Get the content of the file and process it as needed
        my $file_content = $file->get_content;
        
        # Perform your desired operations on $file_content
        # For example, you can print it or manipulate it here
		
		my @lines = split(/\n/, $file_content);	
		foreach my $line (@lines) {
			if ($line =~ /$search_string/) {
				print "File name: " . $file->name . ": " . $line . "\n";
			}
		}
    }
}
