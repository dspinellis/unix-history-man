#!/usr/bin/env perl
#
# Create D3 timeline charts
#

use strict;
use warnings;

# Date of each release
my %release_date;

# Defined manual pages: all and per release
my %man_page;
my %release_page;

# Read timeline of releases
open(my $in, '<', 'timeline') || die;
while (<$in>) {
	my ($name, $y, $m, $d) = split;
	$release_date{$name} = "$y, $m, $d";
}
close($in);

# Read man pages in each release
for my $release (<[A-Z]* 3*>) {
	open(my $in, '<', $release) || die;
	while (<$in>) {
		chop;
		if (m|man([\dx])f?/(.+)\.\d[a-z]?$|) {
			my $section = $1;
			my $name = $2;
			$man_page{$section}{$name} = 1;
			$release_page{$release}{$section}{$name} = 1;
		} else {
			print STDERR "$release: Unable to parse $_\n";
			exit 1;
		}
	}
}

head();

sub bydate {
	return $release_date{$a} cmp $release_date{$b};
}

# Release label time line
print q'
  var columns = [
    {id: "Facility", name: "Facility", field: "Facility", cssClass: "cell-title",},
';
for my $r (sort bydate keys %release_date) {
	my $from = $release_date{$r};
	# Ensure dates are not interpreted as octal
	$from =~ s/ 0/ /g;
	my ($y, $m, $d) = split(/,/, $from);
	$y++;
	print qq<    {id: "$r", name: "$r", field: "$r"},\n>;
}
print "  ];\n";

section(2);

tail();

# Produce timelines for a whole man page section
sub
section
{
	my ($section) = @_;

	# Row titles
	print "  var data = [\n";
	for my $name (sort keys %{$man_page{$section}}) {
		print qq[    {Facility : "$name"},\n];
	}
print '
  ];
    grid = new Slick.Grid("#myGrid", data, columns, options);
    grid.setCellCssStyles("implemented_facilities", {
';
	# Rows
	my $row = 0;
	for my $name (sort keys %{$man_page{$section}}) {
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
  <link rel="stylesheet" href="../css/smoothness/jquery-ui-1.8.16.custom.css" type="text/css"/>
  <link rel="stylesheet" href="examples.css" type="text/css"/>
</head>
<body>
<div id="myGrid" style="width:600px;height:500px;"></div>
<script src="../lib/jquery-1.7.min.js"></script>
<script src="../lib/jquery.event.drag-2.2.js"></script>

<script src="../slick.core.js"></script>
<script src="../slick.grid.js"></script>

<style>
.cell-title {
	font-weight: bold;
}

.highlight{ background: blue }

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
