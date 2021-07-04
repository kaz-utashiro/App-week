package App::week;
our $VERSION = "0.13";

use v5.14;
use warnings;

use App::week::Util;

use utf8;
use Time::localtime;
use List::Util qw(max);
use Pod::Usage;
use Data::Dumper;

use open IO => ':utf8', ':std';

sub new {
    my $class = shift;
    my $obj = bless {}, $class;
}

my($sec, $min, $hour, $mday, $mon, $year) = CORE::localtime(time);
$mon++;
$year += 1900;

my %colormap = (
	     DAYS => "L05/335",
	     WEEK => "L05/445",
	    FRAME => "L05/445",
	    MONTH => "L05/335",
	  THISDAY => "522/113",
	 THISDAYS => "555/113",
	 THISWEEK => "L05/445",
	THISMONTH => "555/113",
	   DOW_SU => "",
	   DOW_MO => "",
	   DOW_TU => "",
	   DOW_WE => "",
	   DOW_TH => "",
	   DOW_FR => "",
	   DOW_SA => "",
    );

use Getopt::EX::Colormap;
my $colormap = Getopt::EX::Colormap
    ->new(HASH => \%colormap);

sub color {
    $colormap->color(@_);
}

my $months = 0;
my $opt_A;
my $opt_B = 1;
my $opt_C;
my $opt_column = 3;
my $opt_colordump;
my @opt_colormap;
my $opt_year;
my $opt_Y;
my $opt_usage;
my $opt_rgb24;
our %debug;

my %month = do {
    my $i;
    map { $_ => ++$i } qw(JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC)
};

my @optargs = (
    "after|A:1"     => \$opt_A,
    "before|B:1"    => \$opt_B,
    "C:4"           => sub { $opt_A = $opt_B = $_[1] },
    "year|y"        => \$opt_year,
    "Y:1"           => \$opt_Y,
    "column|c=n"    => \$opt_column,
    "colormap|cm=s" => \@opt_colormap,
    "colordump"     => \$opt_colordump,
    "rgb24!"        => \$opt_rgb24,
    "usage:s"       => \$opt_usage,
    "debug=s"       => \%debug,
    "<>" => sub {
	local $_ = $_[0];
	if (/^-+([0-9]+)$/) {
	    $months = $1;
	}
	elsif (/^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)/i) {
	    $mon = $month{uc($1)}
	}
	elsif (/^-/) {
	    die "@_: Unknown option\n";
	}
	else {
	    $mday = $1 if s/\/*(\d+)$//;
	    $mon  = $1 if s/\/*(\d+)$//;
	    $year = $1 if m/(\d+)$/;
	    if ($mday > 31) {
		$year = $mday;
		undef $mday;
		$opt_year++;
	    }
	}
    },
    );

sub usage {
    pod2usage(-verbose => 0, -exitval => "NOEXIT");
    print "Version: $VERSION\n";
    exit 2;
}

sub run {
    my $obj = shift;
    local @ARGV = @_;

    ##
    ## Getopt staff
    ##
    use Getopt::EX::Long qw(:DEFAULT Configure ExConfigure);
    ExConfigure BASECLASS => [ "App::week", "Getopt::EX", "" ];
    Configure qw(bundling no_getopt_compat no_ignore_case pass_through);
    GetOptions(@optargs) || usage({status => 1});

    $colormap->load_params(@opt_colormap);

    if (defined $opt_rgb24) {
	no warnings 'once';
	$Getopt::EX::Colormap::RGB24 = $opt_rgb24;
    }

    if ($opt_colordump) {
	print $colormap->colormap(
	    name   => '--changeme',
	    option => '--colormap');
	exit;
    }

    if ($months == 1) {
	$opt_B = $opt_A = 0;
    }
    elsif ($months > 1) {
	if (defined $opt_B) {
	    $opt_A = $months - $opt_B - 1;
	} elsif (defined $opt_A) {
	    $opt_B = $months - $opt_A - 1;
	} else {
	    use integer;
	    $opt_B = ($months - 1) / 2;
	    $opt_A = $months - $opt_B - 1;
	}
    }
    elsif ($opt_year or defined $opt_Y) {
	$months = 12 * ($opt_Y // 1);
	$opt_B = $mon - 1;
	$opt_A = $months - $mon;
    }
    else {
	$opt_B //= 1;
	$opt_A //= max(0, $opt_column - $opt_B - 1);
	$months = $opt_B + $opt_A + 1;
    }

    $opt_B //= 1;
    $opt_A //= 1;

    $year += $year < 50 ? 2000 : $year < 100 ? 1900 : 0;

    calendar(
	( map { calref($year, $mon + $_) } -$opt_B .. -1 ) ,
	(       calref($year, $mon, $mday)               ) ,
	( map { calref($year, $mon + $_) } 1 .. $opt_A   )
	);

    return 0;
}

######################################################################

sub calendar {
    my $cols = $opt_column;
    my $row = 0;
    my @refs;
    my $cal_width = 24;
    my $hr1 = " " x $cal_width;
    my $gap = "  ";
    while (@_) {
	@refs = splice @_, 0, $cols;
	do {
	    my $n = $row++ ? $cols : @refs;
	    print color(FRAME => join('', ' ', ($hr1) x $n, ' '));
	}
	and print "\n";
	for (my $i = 0; 1; $i++) {
	    my @cols;
	    for my $ref (@refs) {
		push @cols, $$ref[$i];
	    }
	    last if !grep(defined, @cols);
	    print join(color(FRAME => $gap), '', @cols, ''), "\n";
	}
    }
    do {
	print color(FRAME => join('', ' ', ($hr1) x @refs, ' '));
    }
    and print "\n";
}

use App::week::CalYear qw(@calyear);

sub calref {
    my($y, $m, $d) = @_;

    while ($m > 12) { $y += 1; $m -= 12 }
    while ($m <= 0) { $y -= 1; $m += 12 }

    my @cal = @{$calyear[$y][$m]};

    my %label = (
	month => $d ? "THISMONTH" : "MONTH",
	week  => $d ? "THISWEEK"  : "WEEK",
	days  => $d ? "THISDAYS"  : "DAYS",
	);

    $cal[0] = color($label{month}, $cal[0]);
    $cal[1] = color($label{week}, state $week = week_line($cal[1]));
    map {
	s/(?= \d\b|\d\d\b)( ?$d\b)/color("THISDAY", $1)/e if $d;
	$_ = color($label{days}, $_);
    } @cal[2..$#cal];

    return \@cal;
}

sub week_line {
    my $week = shift;
    my @week = split_week $week;
    for (0..6) {
	my $label = "DOW_" . qw(SU MO TU WE TH FR SA)[$_];
	if (my $color = $colormap{$label}) {
	    my $indx = $_ * 2 + 1;
	    $week[$indx] = color($label, $week[$indx]);
	}
    }
    join '', @week;
}

1;

__END__

=encoding utf-8

=head1 NAME

week - colorful calendar command

=head1 SYNOPSIS

B<week> [ -MI<module> ] [ option ] [ date ]

=head1 DESCRIPTION

Yet another calendar command.  Read the script's manual for detail.

=head1 AUTHOR

Kazumasa Utashiro E<lt>kaz@utashiro.comE<gt>

=head1 LICENSE

Copyright 2018- Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
