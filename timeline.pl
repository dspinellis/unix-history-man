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

# Release label time line
start_line('Release');
for my $r (keys %release_date) {
	my$from = $release_date{$r};
	# Ensure dates are not interpreted as octal
	$from =~ s/ 0/ /g;
	my ($y, $m, $d) = split(/,/, $from);
	$y++;
	print qq<
			{
				label: '$r',
				type: TimelineChart.TYPE.INTERVAL,
				from: new Date([$from]),
				to: new Date([$y, $m, $d]),
			},
>;
}
end_line();

section(2);

tail();

# Produce timelines for a whole man page section
sub
section
{
	my ($section) = @_;

	for my $name (sort keys %{$man_page{$section}}) {
		element_line($section, $name);
	}
}

# Produce a timeline for a single man page element
sub
element_line
{
	my ($section, $name) = @_;
	start_line("$name($section)");
	for my $r (keys %release_date) {
		next unless (defined($release_page{$r}{$section}{$name}));
		my$d = $release_date{$r};
		# ensure dates are not interpreted as octal
		$d =~ s/ 0/ /g;
		print qq<
			{
				type: TimelineChart.TYPE.POINT,
				at: new Date([$d]),
			},
>;
	}
	end_line();
}

# start a time line with the specified name
sub
start_line
{
	my ($name) = @_;
	print qq(
	{
		label: '$name',
		data: [
);
}
#
# end a time line
sub
end_line
{
	print "\t\t]\n\t},\n";
}


sub
head
{
	print q{<!doctype html>
<html>

<head>
    <meta charset="utf-8" />
    <title>unix feature timeline char</title>

    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/meyer-reset/2.0/reset.min.css" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/0.0.1/prism.min.css" />
    <link rel="stylesheet" href="https://rawgithub.com/caged/d3-tip/master/examples/example-styles.css" />
    <link rel="stylesheet" href="../dist/timeline-chart.css" />
    <link rel="stylesheet" href="style.css" />
</head>

<body>
    <section flex flex-full-center>
        <div id="chart"></div>
    </section>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/0.0.1/prism.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/d3/3.5.16/d3.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/d3-tip/0.6.7/d3-tip.min.js"></script>
    <script src="../dist/timeline-chart.js"></script>

    <script id="code">

        'use strict';

        const element = document.getElementById('chart');
        const data = [
};
}


sub
tail
{
	print "\t];\n";
	print q[
        const timeline = new TimelineChart(element, data, {
            enableLiveTimer: true,
            tip: function(d) {
                return d.at || `${d.from}<br>${d.to}`;
            }
        }).onVizChange(e => console.log(e));

    </script>
</body>

</html>
];
}
