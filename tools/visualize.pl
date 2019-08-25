#!/usr/bin/env/perl
#
# Visualize all the elements by outputting a tab-separated file
# with a 1 for each documented element of each release
#

use strict;
use warnings;

# All documented elements
my %documented_all;
# What's documented for each release
my %documented_release;
my @releases;

open(my $T, '<', '../data/timeline') || die;
while (<$T>) {
	my ($release) = split;
	push(@releases, $release);
	open(my $DOC, '<', "../data/$release") || die;
	while (<$DOC>) {
		my ($section, $name, $url) = split;
		my $ref = "$section\t$name";
		$documented_all{$ref} = 1;
		$documented_release{$release}{$ref} = 1;
	}
}

# Release header
print "Section\tName";
for my $r (@releases) {
	print "\t$r";
}
print "\n";

for my $feature (sort keys %documented_all) {
	print $feature;
	for my $release (@releases) {
		print "\t" . ($documented_release{$release}{$feature} ? 1 : 0);
	}
	print "\n";
}
