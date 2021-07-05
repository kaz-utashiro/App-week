package App::week;
our $VERSION = "0.13";

use v5.14;
use warnings;

use App::week::Util;

use utf8;
use Time::localtime;
use List::Util qw(max);
use List::MoreUtils qw(zip);
use Hash::Util qw(lock_keys);
use Pod::Usage;
use Data::Dumper;

use App::week::CalYear qw(@calyear);

use open IO => ':utf8', ':std';

my($sec, $min, $hour, $mday, $mon, $year) = CORE::localtime(time);
$mon++;
$year += 1900;
my $months = 0;

my @month_name = qw(JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC);
my %month = zip @month_name, @{[1..12]};
my $month_re = do { local $" = '|'; qr/(?:@month_name)/i };

use Getopt::EX::Colormap;

my %DEFAULT_COLORMAP = (
    (),      DAYS => "L05/335",
    (),      WEEK => "L05/445",
    (),     FRAME => "L05/445",
    (),     MONTH => "L05/335",
    (),   THISDAY => "522/113",
    (),  THISDAYS => "555/113",
    (),  THISWEEK => "L05/445",
    (), THISMONTH => "555/113",
    (),    DOW_SU => "",
    (),    DOW_MO => "",
    (),    DOW_TU => "",
    (),    DOW_WE => "",
    (),    DOW_TH => "",
    (),    DOW_FR => "",
    (),    DOW_SA => "",
    );

sub new {
    my $class = shift;
    my %obj;
    my $obj = bless \%obj, $class;
    %obj = (
	after       => undef,
	before      => 1,
	context     => sub {
	    $obj->{after} = $obj->{before} = $_[1];
	},
	column      => 3,
	colordump   => undef,
	colormap    => [],
	show_year   => undef,
	years       => undef,
	usage       => undef,
	rgb24       => undef,
	year_on_all => undef,
	year_on     => undef,
	"<>"        => sub {
	    local $_ = $_[0];
	    if (/^-+([0-9]+)$/) {
		$months = $1;
	    }
	    elsif (/^($month_re)/) {
		$mon = $month{uc($1)};
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
		    $obj->{show_year}++;
		}
	    }
	},
	COLORMAP => { %DEFAULT_COLORMAP },
	);

    $obj->{CM} = Getopt::EX::Colormap
	->new(HASH => $obj->{COLORMAP});
    
    lock_keys %{$obj};
    $obj;
}

sub colormap { (+shift)->{COLORMAP} }
sub colorobj { (+shift)->{CM} }
sub color    { (+shift)->colorobj->color(@_) }

my @optargs = (
    "after|A:1",
    "before|B:1",
    "context|C:4",
    "show_year|y",
    "years|Y:1",
    "column|c=n",
    "colormap|cm=s@",
    "colordump",
    "rgb24!",
    "usage:s",
    "config=s%",
    "year_on_all|S",
    "year_on|s:i",
    "<>",
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
    GetOptions($obj, @optargs) || usage({status => 1});

    $obj->initialize();

    $obj->calendar(
	( map { $obj->calref($year, $mon + $_) } -$obj->{before} .. -1 ) ,
	(       $obj->calref($year, $mon, $mday)               ) ,
	( map { $obj->calref($year, $mon + $_) } 1 .. $obj->{after}   )
	);

    return 0;
}

sub initialize {
    my $obj = shift;

    my $colormap = $obj->colorobj;
    $colormap->load_params(@{$obj->{colormap}});

    if (defined $obj->{rgb24}) {
	no warnings 'once';
	$Getopt::EX::Colormap::RGB24 = $obj->{rgb24};
    }

    if ($obj->{colordump}) {
	print $colormap->colormap(
	    name   => '--changeme',
	    option => '--colormap');
	exit;
    }

    if ($obj->{year_on_all}) {
	App::week::CalYear::Configure(show_year => [ 1..12 ]);
    }
    elsif (defined (my $m = $obj->{year_on})) {
	App::week::CalYear::Configure(
	    show_year => [ $m < 0 ? (1..12) : $m || $mon ]);
    }
	
    if ($months == 1) {
	$obj->{before} = $obj->{after} = 0;
    }
    elsif ($months > 1) {
	if (defined $obj->{before}) {
	    $obj->{after} = $months - $obj->{before} - 1;
	} elsif (defined $obj->{after}) {
	    $obj->{before} = $months - $obj->{after} - 1;
	} else {
	    use integer;
	    $obj->{before} = ($months - 1) / 2;
	    $obj->{after} = $months - $obj->{before} - 1;
	}
    }
    elsif ($obj->{show_year} or defined $obj->{years}) {
	$months = 12 * ($obj->{years} // 1);
	$obj->{before} = $mon - 1;
	$obj->{after} = $months - $mon;
    }
    else {
	$obj->{before} //= 1;
	$obj->{after} //= max(0, $obj->{column} - $obj->{before} - 1);
	$months = $obj->{before} + $obj->{after} + 1;
    }

    $obj->{before} //= 1;
    $obj->{after} //= 1;

    $year += $year < 50 ? 2000 : $year < 100 ? 1900 : 0;
}

######################################################################

sub calendar {
    my $obj = shift;
    my $cols = $obj->{column};
    my $row = 0;
    my @refs;
    my $cal_width = 24;
    my $hr1 = " " x $cal_width;
    my $gap = "  ";
    while (@_) {
	@refs = splice @_, 0, $cols;
	do {
	    my $n = $row++ ? $cols : @refs;
	    print $obj->color(FRAME => join('', ' ', ($hr1) x $n, ' '));
	}
	and print "\n";
	for (my $i = 0; 1; $i++) {
	    my @cols;
	    for my $ref (@refs) {
		push @cols, $$ref[$i];
	    }
	    last if !grep(defined, @cols);
	    print join($obj->color(FRAME => $gap), '', @cols, ''), "\n";
	}
    }
    do {
	print $obj->color(FRAME => join('', ' ', ($hr1) x @refs, ' '));
    }
    and print "\n";
}

sub calref {
    my $obj = shift;
    my($y, $m, $d) = @_;

    while ($m > 12) { $y += 1; $m -= 12 }
    while ($m <= 0) { $y -= 1; $m += 12 }

    my @cal = @{$calyear[$y][$m]};

    my %label = (
	month => $d ? "THISMONTH" : "MONTH",
	week  => $d ? "THISWEEK"  : "WEEK",
	days  => $d ? "THISDAYS"  : "DAYS",
	);

    $cal[0] = $obj->color($label{month}, $cal[0]);
    $cal[1] = $obj->color($label{week}, state $week = $obj->week_line($cal[1]));
    map {
	s/(?= \d\b|\d\d\b)( ?$d\b)/$obj->color("THISDAY", $1)/e if $d;
	$_ = $obj->color($label{days}, $_);
    } @cal[2..$#cal];

    return \@cal;
}

sub week_line {
    my $obj = shift;
    my $week = shift;
    my @week = split_week $week;
    for (0..6) {
	my $label = "DOW_" . qw(SU MO TU WE TH FR SA)[$_];
	if (my $color = $obj->colormap->{$label}) {
	    my $indx = $_ * 2 + 1;
	    $week[$indx] = $obj->color($label, $week[$indx]);
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
