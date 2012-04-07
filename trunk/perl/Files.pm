#uncomment this line to use this as a package
package Files;

use lib '/var/www/tesserae/perl';	# PERL_PATH
use TessSystemVars;

#uncomment these lines to run this as a stand-alone perl program.
#  #!/usr/bin/perl
# use strict;

=head2 function: C<cache_filename>

Returns the filename of the stem cache.


=head2 function: C<determine_input_filenames>

To keep the management of the various preprocessed files as simple as possible, the tesserae system makes use of a configuration file that specifies which comparisons exists, and which files they reside in. The configuration file is a simple text file with for each line five strings: 

=over 2

=item 1 the source  label. An internal label to refer to the source text.

=item 2 the target  label. 

=item 3 the .tess file for the source text. The name and location of the file with the source text.

=item 4 the .tess file for the target text

=item 5 the file that contains the preprocessed comparisons between the two.

=back

Example: 
C<
lucan_bk1 vergil lucan.pharsalia.book1.tess vergil.aeneid.tess lucan.pharsalia.book1.vs.vergil.aeneid.preprocessed
>

The function C<determine_input_filenames> is called with two strings as argument; the two strings are matched against a source and a target file label.

Returns a hash structure that has each of the five elements above: C<source_label>, C<source_file>, C<preprocessed_file>. If either the source or the target label is not found, the function returns null. 

Any pair will match, regardless of the order of source vs. target in the config-file; so determine_input_filenames('a','b') will match either a line starting with 'a b' or a line beginning with 'b a'. 

=cut

my $config_file = "$fs_data/v2/tesserae.datafiles.config";

sub config_file {
	return $config_file;
}
sub cache_filename {
	return "$fs_data/v2/stem.cache";
}

sub source_label_in_line($) {
	my $line = shift;
	$line =~ /(.+)\s(.+)\s(.+)\s(.+)\s(.+)/;
	return $1;
}

sub target_label_in_line($) {
	my $line = shift;
	$line =~ /(.+)\s(.+)\s(.+)\s(.+)\s(.+)/;
	return $2;
}

sub source_file_in_line($) {
	my $line = shift;
	$line =~ /(.+)\s(.+)\s(.+)\s(.+)\s(.+)/;
	return $3;
}

sub target_file_in_line($) {
	my $line = shift;
	$line =~ /(.+)\s(.+)\s(.+)\s(.+)\s(.+)/;
	return $4;
}

sub preprocessed_file_in_line($) {
	my $line = shift;
	$line =~ /(.+)\s(.+)\s(.+)\s(.+)\s(.+)/;
	return $5;
}


sub line_with_label_pair ($ $) {
	my $lookfor_source_label = shift;
	my $lookfor_target_label = shift;
	open(HANDLE, $config_file) or die "cannot open file $config_file";
	my @lines = <HANDLE>;
	foreach my $line (@lines) {
		my $source_label = source_label_in_line($line);
		my $target_label = target_label_in_line($line);
		if ($source_label eq $lookfor_source_label && $target_label eq $lookfor_target_label) {return $line;}
		if ($target_label eq $lookfor_source_label && $source_label eq $lookfor_target_label) {return $line;}
	}
	close(HANDLE);
	return ''; 
}

sub source_file_for_label_pair($ $) {
	open(HANDLE, $config_file) or die "cannot open file $config_file";
	my @lines = <HANDLE>;
	foreach my $line (@lines) {
		print $line;
		my $label_source = source_label_in_line($line);
		my $label_target = target_label_in_line($line);
	}
	close(HANDLE);
}

sub target_file_for_label_pair($ $) {
	
}

sub preprocessed_file_for_label_pair($ $) {
	
}

sub handle_error_source_target_label_pair_nonexistent {
	print "handle_error_source_target_label_pair_nonexistent called\n";
}

sub determine_input_filenames ($ $) {
	my $source_label = shift;
	my $target_label = shift;
	my %return_hash = ();
	my $debug = 0;
	if ($debug == 1) {print "determine_input_filenames\n";}
	if ($debug == 1) {print "determine_input_filenames: source label: $source_label, target label: $target_label\n";}
	my $line = line_with_label_pair($source_label, $target_label);
	if ($debug == 1) {print "determine_input_filenames: found line: $line\n";}
	
	if ($line ne '') {
		$return_hash{'source_label'} = $source_label;
		$return_hash{'target_label'} = $target_label;
		
		$return_hash{'source_file'} = source_file_in_line($line);
		$return_hash{'target_file'} = target_file_in_line($line);
		$return_hash{'preprocessed_file'} = preprocessed_file_in_line($line);
	} else {
		handle_error_source_target_label_pair_nonexistent();
		return 0;
	}
#	print"in sub target_label: ".$return_hash{'target_label'}."\n\n";
	
	return \%return_hash;
	
}

sub source_text_file {
	my $source_label = shift;
	my $target_label = shift;
	my $filenames_ref = determine_input_filenames ($source_label, $target_label);
	return $filenames_ref->{'source_file'};
}

sub target_text_file {
	my $source_label = shift;
	my $target_label = shift;
	my $filenames_ref = determine_input_filenames ($source_label, $target_label);
	return $filenames_ref->{'target_file'};
}

sub source_parsed_file {
	my $source_label = shift;
	my $target_label = shift;
	my $filenames_ref = determine_input_filenames ($source_label, $target_label);
	my $parsed_file = $filenames_ref->{'source_file'};
	$parsed_file =~ s/\.tess$/\.parsed/;
	return $parsed_file;
}

sub target_parsed_file {
	my $source_label = shift;
	my $target_label = shift;
	my $filenames_ref = determine_input_filenames ($source_label, $target_label);
	my $parsed_file = $filenames_ref->{'target_file'};
	$parsed_file =~ s/\.tess$/\.parsed/;
	return $parsed_file;
}

sub preprocessed_file {
	my $source_label = shift;
	my $target_label = shift;
	my $filenames_ref = determine_input_filenames ($source_label, $target_label);
	return $filenames_ref->{'preprocessed_file'};
}


sub test {
	# a call with a non-existent pair (as in 'vergil' - 'lucn') should result in returning 0.
	my $filenames_ref = determine_input_filenames("vergil", "lucn");
	if ($filenames_ref == 0) {
		print "test 1: determine_input_filenames returned NULL, as expected. ok. \n";
	} else {
		print "test 1: determine_input_filenames didn't return NULL, as expected. fail. \n";
		# print"target_label: ".$filenames_ref->{'target_label'}."\n\n";
	}
	
	$filenames_ref = determine_input_filenames("vergil", "lucan");
	if ($filenames_ref->{'target_label'} eq 'lucan') {
		print "test 2: determine_input_filenames was called with existing labels, returned correct label. ok.\n";
	} else {
		print "test 2: determine_input_filenames was called with existing labels, didn't return correct label. fail.\n";
		print "test 2: returned label: $filenames_ref->{'target_label'}, expected label 'vergil'";
	}
}

#uncomment this line to run this as a stand-alone perl program. 
# test();

1; # all perl packages must return true;
