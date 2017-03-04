#!/usr/bin/env perl
#
# Create D3 timeline charts
#

use strict;
use warnings;

# Date of each release
my %release_date;

# Defined manual pages: all with the first release date and per release
my %first_release_date;
my %release_page;

my $last_release;

# Read timeline of releases
open(my $in, '<', 'timeline') || die;
while (<$in>) {
	my ($name, $y, $m, $d) = split;
	$release_date{$name} = "$y, $m, $d";
	$last_release = $name if (!defined($last_release) || $release_date{$name} gt $release_date{$last_release});
}
close($in);

# Return the minimum date of two
sub min_date
{
	my ($a, $b) = @_;

	return $b if (!defined($a));
	return $a if (!defined($b));
	if ($a lt $b) {
		return $a;
	} else {
		return $b;
	}
}

# Read man pages in each release
for my $release (<[FRB]* 3*>) {
	open(my $in, '<', $release) || die;
	while (<$in>) {
		chop;
		if (m|man([\dx])f?/(.+)\.\d[a-z]?$|) {
			my $section = $1;
			my $name = $2;
			if (!defined($release_date{$release})) {
				print STDERR "Undefined release date for $release\n";
				exit 1;
			}
			$release_page{$release}{$section}{$name} = 1;
		} else {
			print STDERR "$release: Unable to parse $_\n";
			exit 1;
		}
	}
}

# Move man pages in sections 1 (user commands) 6 (games) and
# 8 (administrator commands and daemons) to match their location
# in the last release.
for my $last_section ((1, 6, 8)) {
	for my $name (keys %{$release_page{$last_release}{$last_section}}) {
		for my $r (keys %release_date) {
			next if ($r eq $last_release);
			for my $original_section ((1, 6, 8)) {
				next if ($original_section eq $last_section);
				if (defined($release_page{$r}{$original_section}{$name})) {
					delete $release_page{$r}{$original_section}{$name};
					$release_page{$r}{$last_section}{$name} = 1;
				}
			}
		}
	}
}

# Set first release date for each command
# These is used for sorting commands by their release date
for my $release (sort by_release_date keys %release_date) {
	for my $section (keys %{$release_page{$release}}) {
		for my $name (keys %{$release_page{$release}{$section}}) {
			if (!defined($first_release_date{$section}{$name})) {
				$first_release_date{$section}{$name} = $release_date{$release};
			}
		}
	}
}

head();

# Order release names by their date
sub by_release_date {
	return $release_date{$a} cmp $release_date{$b};
}

# Release label time line
print q'
  var columns = [
    {id: "Facility", name: "Facility", field: "Facility", cssClass: "slick-header-row",},
';
for my $r (sort by_release_date keys %release_date) {
	my $from = $release_date{$r};
	# Ensure dates are not interpreted as octal
	$from =~ s/ 0/ /g;
	my ($y, $m, $d) = split(/,/, $from);
	$y++;
	print qq<    {id: "$r", name: "$r", field: "$r"},\n>;
}
print "  ];\n";

section(6);

tail();

# Order facilities by order of their first appearance and then
# alphabetically
sub by_first_appearance {
	my ($section) = @_;
	return ($first_release_date{$section}{$a} cmp $first_release_date{$section}{$b}) || ($a cmp $b);
}


# Produce timelines for a whole man page section
sub
section
{
	my ($section) = @_;

	# Row titles
	print "  var data = [\n";
	for my $name (sort { by_first_appearance $section} keys %{$first_release_date{$section}}) {
		print qq[    {Facility : "$name"},\n];
	}
print '
  ];
    grid = new Slick.Grid("#myGrid", data, columns, options);
    grid.setCellCssStyles("implemented_facilities", {
';
	# Rows
	my $row = 0;
	for my $name (sort {by_first_appearance $section} keys %{$first_release_date{$section}}) {
		print "  $row: {\n";
		element_line($section, $name);
		print "  },\n";
		$row++;
	}
}

# Produce a timeline for a single man page element
sub
element_line
{
	my ($section, $name) = @_;
	for my $r (keys %release_date) {
		next unless (defined($release_page{$r}{$section}{$name}));
		print "      '$r': 'highlight',\n";
	}
}

sub
head
{
	print q|<!doctype html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <title>Timeline of Unix Facilities</title>
  <link rel="stylesheet" href="../slick.grid.css" type="text/css"/>
  <link rel="stylesheet" href="../css/smoothness/jquery-ui-1.8.24.custom.css" type="text/css"/>
  <link rel="stylesheet" href="../examples/examples.css" type="text/css"/>
</head>
<body>
<div id="myGrid" style="width:1000px;height:700px;"></div>
<script src="../lib/jquery-1.7.min.js"></script>
<script src="../lib/jquery.event.drag-2.2.js"></script>

<script src="../slick.core.js"></script>
<script src="../slick.grid.js"></script>

<style>
.cell-title {
	background: gray;
}

.highlight{ background: blue }

.slick-header-row {
  background: #edeef0;
}

</style>

<script>
  var grid;
  var options = {
    enableCellNavigation: true,
    frozenColumn: 0,
    enableColumnReorder: false
  };
  $(function () {
|;
}


sub
tail
{
	print q|
    })
  })
</script>
</body>
</html>
|;
}
