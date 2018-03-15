#!/usr/bin/env perl
#
# Create Unix facility timeline charts using SlickGrid
#
# Copyright 2011-2012 Diomidis Spinellis
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
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
for my $release (<data/[FB]* data/Research* data/3*>) {
	open(my $in, '<', $release) || die;
	$release =~ s|data/||;
	while (<$in>) {
		chop;
		if (m|^(\d)[^\t]*\t([^\t]+)|) {
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
	$n =~ s/Net_2/Net-2/;
	return $n;
}

# Set first release date for each command
# These is used for sorting commands by their release date
# Also create a table listing number of commands per release
open(my $tab, '>', 'mancount.txt');
for my $release (sort by_release_order keys %release_order) {
	for my $section (keys %{$release_page{$release}}) {
		my $count = 0;
		for my $name (keys %{$release_page{$release}{$section}}) {
			$count++;
			if (!defined($first_release_order{$section}{$name})) {
				$first_release_order{$section}{$name} = $release_order{$release};
				$first_release_name{$section}{$name} = beautify($release);
			}
		}
		print $tab beautify($release) . "\t$section\t$count\n";
	}
}
close($tab);


# Order release names by their chronological/version order
sub by_release_order {
	return $release_order{$a} <=> $release_order{$b};
}


# Create index file
my $sitedir = $ENV{'SITEDIR'};
mkdir($sitedir);
open(my $index_file, '>', "$sitedir/index.html") || die;
bs_head($index_file);
print $index_file '
    <title>Evolution of Unix Facilities</title>
  </head>
  <body>
    <h1>Evolution of Unix Facilities</h1>
    <ol>
';
for (my $i = 1; $i <= $#section_title; $i++) {
	print $index_file qq{      <li><a href="man$i.html">$section_title[$i]</a></li>\n};
	open($section_file, '>', "$sitedir/man$i.html") || die;
	section($i);
}
print $index_file '
    </ol>
    <p>
      The source code for creating this site is available in
      <a href="https://github.com/dspinellis/unix-history-man">https://github.com/dspinellis/unix-history-man</a>.
    </p>
  </body>
</html>
';

# Order facilities by order of their first appearance and then
# alphabetically
sub by_first_appearance {
	my ($section) = @_;
	return ($first_release_order{$section}{$a} <=> $first_release_order{$section}{$b}) || ($a cmp $b);
}

# Given the name of a parent and the current row in the array reference
# facilities, return 'new', 'noparent', or 'child' depending on whether
# the current row name should establish a new parent node, a node without
# a parent, or a child of the existing parent node.
# The variable parent contains a prefix up to an underscore
sub
node_type
{
	my ($parent, $row, $facilities) = @_;

	# Nodes with same prefix in order to establish parent
	my $SAME_PREFIX = 3;

	if (defined($parent)) {
		# Remove suffix used for display purposes
		$parent =~ s/_.*/_/;

		return 'child' if ($facilities->[$row] =~ m/^$parent/);
	}
	return 'noparent' if ($facilities->[$row] !~ m/^([^_]+_)/);

	my $candidate = $1;
	for (my $i = $row; $i < $row + $SAME_PREFIX; $i++) {
		return 'noparent' if ($facilities->[$i] !~ m/^$candidate/);
	}
	return 'new';
}

# Produce timelines for a whole man page section
sub
section
{
	my ($section) = @_;

	slick_head($section);

	# Release dates
	print $section_file q'
      var release_date = {
';
	for my $r (sort keys %release_date) {
		my $br = beautify($r);
		print $section_file qq<        "$br": "$release_date{$r}",\n>;
	}
	print $section_file "  };\n";

	# Release label time line
	print $section_file q'
      var columns = [
	{id: "Facility", name: "Facility", field: "Facility", cssClass: "slick-header-row", formatter: FacilityNameFormatter, sortable: true},
	{id: "Appearance", name: "Appearance", field: "Appearance", cssClass: "slick-header-row", sortable: true},
';
	for my $r (sort by_release_order keys %release_order) {
		my $br = beautify($r);
		print $section_file qq<        {id: "$r", name: "$br", field: "$r", formatter: ImplementedFormatter},\n>;
	}
	print $section_file "  ];\n";

	# Row titles
	print $section_file q|

    var dataView;
    var grid;
    var options = {
      enableCellNavigation: true,
      frozenColumn: 1,
      enableColumnReorder: false,
      multiColumnSort: true
    };
    var parent = null;

    data = [
|;
	my @facilities = sort { by_first_appearance $section} keys %{$first_release_order{$section}};
	my $parent_name;
	my $parent_val = 'null';
	my $indent;
	my $out_row = 0;
	my $highlights;
	for (my $in_row = 0; $in_row <= $#facilities; $in_row++) {
		my $name = $facilities[$in_row];
		my $type = node_type($parent_name, $in_row, \@facilities);
		if ($type eq 'new') {
			# Parent of many
			$parent_name = $name;
			$parent_name =~ s/^([^_]+)_.*/$1_*/;
			$parent_val = $out_row;
			$highlights = element_line($out_row, $section, $name);
			print $section_file qq(
      { // $out_row
	Facility: "$parent_name",
	Appearance: "$first_release_name{$section}{$name}",
	indent: 0,
	id: "id_$out_row",
	'parent': null,
	_collapsed: true$highlights
      },
);
			$out_row++;
			$indent = 1;
		} elsif ($type eq 'noparent') {
			# Simple node (possibly after child ones)
			$parent_name = undef;
			$parent_val = 'null';
			$indent = 0;
		}
		# Output a child or a simple node
		$highlights = element_line($out_row, $section, $name);
		print $section_file qq[
      { // $out_row
	Facility: "$name",
	Appearance: "$first_release_name{$section}{$name}",
	indent: $indent,
	id: "id_$out_row",
	'parent': $parent_val$highlights
      },
];
		$out_row++;
	}
print $section_file '
    ]; // data[] initilization end

    // initialize the model
    dataView = new Slick.Data.DataView({ inlineFilters: true });
    dataView.beginUpdate();
    dataView.setItems(data);
    dataView.setFilter(collapseFilter);
    dataView.endUpdate();

    // initialize the grid
    grid = new Slick.Grid("#myGrid", dataView, columns, options);

    grid.onCellChange.subscribe(function (e, args) {
      dataView.updateItem(args.item.id, args.item);
    });

    grid.onClick.subscribe(function (e, args) {
      if ($(e.target).hasClass("toggle")) {
	var item = dataView.getItem(args.row);
	if (item) {
	  if (!item._collapsed) {
	    item._collapsed = true;
	  } else {
	    item._collapsed = false;
	  }
	  dataView.updateItem(item.id, item);
	}
	e.stopImmediatePropagation();
      }
    });

    dataView.onRowsChanged.subscribe(function (e, args) {
      grid.invalidateRows(args.rows);
      grid.render();
    });

    grid.onSort.subscribe(function(e, args) {
      gridSorter(args.sortCols, grid, dataView);
    });

    grid.setSortColumn("Appearance", true);

';
	tail();
}

# Return a timeline for a single man page element
# appearing on the specified row
sub
element_line
{
	my ($row, $section, $name) = @_;
	my $ret = '';

	for my $r (keys %release_date) {
		next unless (defined($release_page{$r}{$section}{$name}));
		$ret .= ",\n      '$r': 1";
	}
	return $ret;
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
    <title>Evolution of Unix facilities: $section</title>
    <link rel="stylesheet" href="SlickGrid/slick.grid.css" type="text/css"/>
    <link rel="stylesheet" href="SlickGrid/css/smoothness/jquery-ui-1.8.24.custom.css" type="text/css"/>
    <link rel="stylesheet" href="SlickGrid/examples/examples.css" type="text/css"/>
  </head>
  <body>
    <h1>Evolution of Unix section $section: $section_title[$section]</h1>
    <div id="myGrid" style="width:1000px;height:500px;"></div>
    <script src="SlickGrid/lib/jquery-1.7.min.js"></script>
    <script src="SlickGrid/lib/jquery.event.drag-2.2.js"></script>

    <script src="SlickGrid/slick.core.js"></script>
    <script src="SlickGrid/slick.grid.js"></script>
    <script src="SlickGrid/slick.dataview.js"></script>

    <style>
    .cell-title {
      background: gray;
    }

    .slick-header-column.ui-state-default {
      height: 100%;
    }

    .slick-header-row {
      background: #edeef0;
    }

    .implemented {
      background: LightSkyBlue;
      width: 95%;
      display: inline-block;
      height: 6px;
      border-radius: 3px;
      -moz-border-radius: 3px;
      -webkit-border-radius: 3px;
    }

    .toggle {
      height: 9px;
      width: 9px;
      display: inline-block;
    }
    .toggle.expand {
      background: url(SlickGrid/images/expand.gif) no-repeat center center;
    }
    .toggle.collapse {
      background: url(SlickGrid/images/collapse.gif) no-repeat center center;
    }

  </style>
|;

	print $section_file q#
  <script>
    var data = [];

    function collapseFilter(item) {
      if (item.parent != null) {
	var parent = data[item.parent];
	while (parent) {
	  if (parent._collapsed) {
	    return false;
	  }
	  parent = data[parent.parent];
	}
      }
      return true;
    }

    var groupingDisabled = false;

    // Remove parent nodes (*), pointers to them, and indentation
    function disableGrouping() {
      if (groupingDisabled) {
	return;
      }
      for (var i = 0; i < data.length; i++) {
	if (data[i].Facility.slice(-1) == "*") {
	  data.splice(i, 1);
	  i--;
	  continue;
	}
	data[i].indent = 0;
	data[i].parent = null;
      }
      groupingDisabled = true;
    }

    $(function () {

      var FacilityNameFormatter = function (row, cell, value, columnDef, dataContext) {
	value = value.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");
	var spacer = "<span style='display:inline-block;height:1px;width:" + (15 * dataContext["indent"]) + "px'></span>";
	var idx = dataView.getIdxById(dataContext.id);
	if (data[idx + 1] && data[idx + 1].indent > data[idx].indent) {
	  if (dataContext._collapsed) {
	    return spacer + " <span class='toggle expand'></span>&nbsp;" + value;
	  } else {
	    return spacer + " <span class='toggle collapse'></span>&nbsp;" + value;
	  }
	} else {
	  return spacer + " <span class='toggle'></span>&nbsp;" + value;
	}
      };

      var ImplementedFormatter = function(row, cell, value, columnDef, dataContext) {
	if (value == null || value === "") {
	  return "";
	} else {
	  return "<span class='implemented'></span>";
	}
      };

      var gridSorter = function(cols, grid, gridData) {
        /*
	 * After changing the order of the rows, the parent pointers are
	 * no longer valid, so we disable grouping.
	 */
        disableGrouping();
	gridData.sort(function (dataRow1, dataRow2) {
	  for (var i = 0, l = cols.length; i < l; i++) {
	    var field = cols[i].sortCol.field;
	    var sign = cols[i].sortAsc ? 1 : -1;
	    var value1 = dataRow1[field], value2 = dataRow2[field];
	    if (field == "Appearance") {
	      value1 = release_date[value1];
	      value2 = release_date[value2];
	    }
	    var result = (value1 == value2) ?  0 :
	      ((value1 > value2 ? 1 : -1)) * sign;
	    if (result != 0) {
	      return result;
	    }
	  }
	  return 0;
	});
	grid.invalidate();
	grid.render();
      };

#;
}

sub
tail
{
	print $section_file q|
  })
    </script>
    <p>
      <a href="index.html">Back to section index</a>
    <p>
    <h2>Notes and disclaimers</h2>
    <ul>
      <li>Click on the "Facility" or "Appearance" headers
        to change the sort order.</li>
      <li>The name of a facility may have been repurposed over time.</li>
      <li>Facilities in sections 1, 6, 8 moved across sections over time.
        To allow a continuous view of their evolution, all have been
	relocated to the section of the most recent FreeBSD release,
	if they still existed at the time.
      </li>
      <li> The evolution data of collapsed tree nodes depict the evolution
        of the tree's first child node.
      </li>
    </ul>
  </body>
</html>
|;
}
