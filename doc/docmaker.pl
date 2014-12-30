#!/usr/bin/perl
use strict; use warnings;


use Pod::2::html;


my $pod_file = shift or die "Specify POD file as argumentn";


# Create pod2html object


my $pod = Pod::2::html->new($pod_file);


# The path to the HTML template


$pod->template("pod2html.tmpl");


# The formatted HTML will go to STDOUT


$pod->readpod();