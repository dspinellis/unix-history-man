#!/usr/bin/env perl
#
# Create Unix facility timeline charts using SlickGrid
#

use strict;
use warnings;

# Date of each release
my %release_date;
# Order of each release
my %release_order;

# Defined manual pages: all with the first release date, name, and per release
my %first_release_order;
my %first_release_name;
my %release_page;

my $last_release;

my $section_file;

my @section_title = (
	'man0',
	'User commands',
	'System calls',
	'C library functions',
	'Devices and special files',
	'File formats and conventions',
	'Games et. al.',
	'Miscellanea',
	'System maintenance procedures and commands',
	'System kernel interfaces',
);


# Read timeline of releases
open(my $in, '<', 'timeline') || die;
while (<$in>) {
	my ($name, $y, $m, $d) = split;
	$release_date{$name} = "$y-$m-$d";
	$last_release = $name if (!defined($last_release) || $release_date{$name} gt $release_date{$last_release});
}
close($in);

sub
by_version
{
	if ($a =~ m/FreeBSD-(\d+)\.(\d+)\.(\d+)/) {
		my ($a1, $a2, $a3) = ($1, $2, $3);
		if ($b =~ m/FreeBSD-(\d+)\.(\d+)\.(\d+)/) {
			my ($b1, $b2, $b3) = ($1, $2, $3);

			return ($a1 <=> $b1) || ($a2 <=> $b2) || ($a3 <=> $b3);
		}
	}
	return $release_date{$a} cmp $release_date{$b};
}

# Set release order based on release date
my $order = 0;
for my $release (sort by_version keys %release_date) {
	$release_order{$release} = $order++;
}

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

# Beautify the name of a release for screen display
sub
beautify
{
	my ($n) = @_;

	$n =~ s/-/ /;
	$n =~ s/_/./;
	$n =~ s/_/\//;
	return $n;
}

# Set first release date for each command
# These is used for sorting commands by their release date
for my $release (sort by_release_order keys %release_order) {
	for my $section (keys %{$release_page{$release}}) {
		for my $name (keys %{$release_page{$release}{$section}}) {
			if (!defined($first_release_order{$section}{$name})) {
				$first_release_order{$section}{$name} = $release_order{$release};
				$first_release_name{$section}{$name} = beautify($release);
			}
		}
	}
}


# Order release names by their chronological/version order
sub by_release_order {
	return $release_order{$a} <=> $release_order{$b};
}


mkdir('html');
open(my $index_file, '>', 'html/index.html') || die;
bs_head($index_file);
print $index_file '
<title>Timeline of Unix Facilities</title>
</head>
<body>
<h1>Timeline of Unix Facilities</h1>
<ol>
';
for (my $i = 1; $i < 10; $i++) {
	print $index_file qq{<li><a href="man$i.html">$section_title[$i]</a></li>\n};
	open($section_file, '>', "html/man$i.html") || die;
	section($i);
}
print $index_file '
</ol>
</body>
</html>
';

# Order facilities by order of their first appearance and then
# alphabetically
sub by_first_appearance {
	my ($section) = @_;
	return ($first_release_order{$section}{$a} <=> $first_release_order{$section}{$b}) || ($a cmp $b);
}


# Produce timelines for a whole man page section
sub
section
{
	my ($section) = @_;

	slick_head($section);

	# Release label time line
	print $section_file q'
	  var columns = [
	    {id: "Facility", name: "Facility", field: "Facility", cssClass: "slick-header-row",},
	    {id: "Appearance", name: "Appearance", field: "Appearance", cssClass: "slick-header-row",},
	';
	for my $r (sort by_release_order keys %release_order) {
		my $br = beautify($r);
		print $section_file qq<    {id: "$r", name: "$br", field: "$r"},\n>;
	}
	print $section_file "  ];\n";

	# Row titles
	print $section_file "  var data = [\n";
	for my $name (sort { by_first_appearance $section} keys %{$first_release_order{$section}}) {
		print $section_file qq[    {Facility : "$name",\n];
		print $section_file qq[     Appearance : "$first_release_name{$section}{$name}"},\n];
	}
print $section_file '
  ];
    grid = new Slick.Grid("#myGrid", data, columns, options);
    grid.setCellCssStyles("implemented_facilities", {
';
	# Rows
	my $row = 0;
	for my $name (sort {by_first_appearance $section} keys %{$first_release_order{$section}}) {
		print $section_file "  $row: {\n";
		element_line($section, $name);
		print $section_file "  },\n";
		$row++;
	}

	tail();
}

# Produce a timeline for a single man page element
sub
element_line
{
	my ($section, $name) = @_;
	for my $r (keys %release_date) {
		next unless (defined($release_page{$r}{$section}{$name}));
		print $section_file "      '$r': 'highlight',\n";
	}
}

# Header for Bootstrap HTML
sub
bs_head
{
	my ($f) = @_;

	print $f qq|<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->

    <!-- Bootstrap -->
    <!-- Latest compiled and minified CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">

    <!-- Optional theme -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css" integrity="sha384-rHyoN1iRsVXV4nD0JutlnGaslCJuC7uwjduW9SVrLvRYooPp2bWYgmgJQIXwl/Sp" crossorigin="anonymous">

    <!-- Latest compiled and minified JavaScript -->
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa" crossorigin="anonymous"></script>
    <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/html5shiv/3.7.3/html5shiv.min.js"></script>
      <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
    <![endif]-->
|;
}

# Header for SlickGrid code
sub
slick_head
{
	my ($section) = @_;

	bs_head($section_file);
	print $section_file qq|
  <title>Timeline of Unix Manual Section $section Facilities</title>
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

.highlight{ background: green }

.slick-header-row {
  background: #edeef0;
}

</style>

<script>
  var grid;
  var options = {
    enableCellNavigation: true,
    frozenColumn: 1,
    enableColumnReorder: false
  };
  \$(function () {
|;
}

sub
tail
{
	print $section_file q|
    })
  })
</script>
</body>
</html>
|;
}
