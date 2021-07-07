package App::week;
our $VERSION = "0.13";

use v5.14;
use warnings;

use App::week::Util;

use utf8;
use Encode;
use Time::localtime;
use List::Util qw(min max);
use List::MoreUtils qw(zip);
use Hash::Util qw(lock_keys);
use Pod::Usage;
use Data::Dumper;
use open IO => ':utf8', ':std';
use Getopt::EX::Colormap;

use App::week::CalYear qw(@calyear);

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

    my($sec, $min, $hour, $mday, $mon, $year) = CORE::localtime(time);
    $mon++;
    $year += 1900;

    my @month_name = qw(JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC);
    my %month = zip @month_name, @{[1..12]};
    my $month_re = do { local $" = '|'; qr/(?:@month_name)/i };
    my %colormap = %DEFAULT_COLORMAP;

    my %obj;
    my $obj = bless \%obj, $class;
    %obj = (
	months      => 0,
	year        => $year,
	mday        => $mday,
	mon         => $mon,
	cell_width  => 24,
	h_gap       => '  ',

	help        => undef,
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
	config      => {},
	"<>"        => sub {
	    local $_ = $_[0];
	    if (/^-+([0-9]+)$/) {
		$obj->{months} = $1;
	    }
	    elsif (/^($month_re)/) {
		$obj->{mon} = $month{uc($1)};
	    }
	    elsif (/^-/) {
		die "@_: Option error\n";
	    }
	    else {
		@{$obj}{qw(year mon mday show_year)} =
		    guess_date($_,
			       @{$obj}{qw(year mon mday show_year)});
	    }
	},
	COLORMAP => \%colormap,
	CM => Getopt::EX::Colormap->new(HASH => \%colormap),
	);

    lock_keys %{$obj};
    $obj;
}

sub colormap { (+shift)->{COLORMAP} }
sub colorobj { (+shift)->{CM} }
sub color    { (+shift)->colorobj->color(@_) }

my @optargs = (
    "help|h",
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
    "year_on_all|P",
    "year_on|p=i",
    "<>",
    );

sub usage {
    pod2usage(-verbose => 0, -exitval => "NOEXIT");
    print "Version: $VERSION\n";
    exit 2;
}

sub run {
    my $app = shift;
    local @ARGV
	= map { utf8::is_utf8($_) ? $_ : decode('utf8', $_) } @_;

    ##
    ## Getopt staff
    ##
    use Getopt::EX::Long qw(:DEFAULT Configure ExConfigure);
    ExConfigure BASECLASS => [ "App::week", "Getopt::EX", "" ];
    Configure qw(bundling no_getopt_compat no_ignore_case pass_through);
    GetOptions($app, @optargs) || usage;
    $app->{help} and usage;

    $app->initialize();

    my($year, $mon, $mday, $before, $after)
	= @{$app}{qw(year mon mday before after)};
    $app->display(
	( map { $app->cell($year, $mon + $_) } -$before .. -1 ) ,
	(       $app->cell($year, $mon, $mday)                ) ,
	( map { $app->cell($year, $mon + $_) } 1 .. $after    )
	);

    return 0;
}

sub initialize {
    my $app = shift;

    # load --colormap option
    $app->colorobj->load_params(@{$app->{colormap}});

    # --rgb24
    if (defined $app->{rgb24}) {
	no warnings 'once';
	$Getopt::EX::Colormap::RGB24 = $app->{rgb24};
    }

    # --colordump
    if ($app->{colordump}) {
	print $app->colorobj->colormap(
	    name   => '--changeme',
	    option => '--colormap');
	exit;
    }

    #
    # show year on which month
    #
    $app->{year_on} //= $app->{mon} if $app->{mday};
    if ($app->{year_on_all}) {
	App::week::CalYear::Configure show_year => [ 1..12 ];
    }
    elsif (defined(my $m = $app->{year_on})) {
	if ($m < 0 or 12 < $m) {
	    die "$m: Month must be within 0 to 12\n";
	}
	App::week::CalYear::Configure
	    show_year => { $app->{year} => [ $m ], '*' => [ 1 ] };
    } else {
	App::week::CalYear::Configure show_year => [ 1 ];
    }
	
    # --config
    if (%{$app->{config}}) {
	App::week::CalYear::Configure %{$app->{config}};
    }

    # -y, -Y
    $app->{years} //= 1 if $app->{show_year};

    #
    # calculate output form
    #
    my @param = qw(years months before after year mon column);
    @{$app}{@param} = setup(@{$app}{@param});

    $app->{year} += $app->{year} < 50 ? 2000 : $app->{year} < 100 ? 1900 : 0;
}

sub setup {
    use integer;
    my($years, $months, $before, $after, $year, $mon, $column) = @_;

    if ($months == 1) {
	$before = $after = 0;
    }
    elsif ($months > 1) {
	if (defined $before) {
	    $after = $months - $before - 1;
	} elsif (defined $after) {
	    $before = $months - $after - 1;
	} else {
	    $before = ($months - 1) / 2;
	    $after = $months - $before - 1;
	}
    }
    elsif ($years) {
	$months = 12 * ($years // 1);
	$before = $mon - 1;
	$after = $months - $mon;
    }
    else {
	$before //= 1;
	$after  //= max(0, $column - $before - 1);
	$months = $before + $after + 1;
    }

    $before //= 1;
    $after  //= 1;

    ($years, $months, $before, $after, $year, $mon, $column);
}

######################################################################

sub display {
    my $obj = shift;
    @_ or return;
    print $obj->h_rule(min($obj->{column}, int @_)), "\n";
    while (@_) {
	my @cells = splice @_, 0, $obj->{column};
	for my $row (transpose @cells) {
	    print $obj->h_line(@{$row}), "\n";
	}
	print $obj->h_rule(int @cells), "\n";
    }
}

sub h_rule {
    my $obj = shift;
    my $column = shift;
    state $hr1 = " " x $obj->{cell_width};
    $obj->color(FRAME => join('', ' ', ($hr1) x $column, ' '));
}

sub h_line {
    my $obj = shift;
    state $gap = $obj->color(FRAME => $obj->{h_gap});
    join $gap, '', @_, '';
}

sub cell {
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
