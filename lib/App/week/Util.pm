package App::week;
use v5.14;
use warnings;
use utf8;

use Data::Dumper;
use Text::ANSI::Fold;
use Date::Japanese::Era;
use List::Util qw(pairmap);

my %abbr = do {
    pairmap {
	( $a => $b, substr($b, 0, 1) => $b )
    }
    map { split /:/ }
    qw( M:明治 T:大正 S:昭和 H:平成 R:令和 );
};

sub guess_date {
    my $date_str = local $_ = shift;
    my($year, $mon, $mday, $show_year) = @_;

    if (m{
	^
	  (?<Y> (?: [A-Z] | \p{Han}+ ) \d++ ) [-./年]?
	  (?: (?<M> \d++ ) [-./月]?
	      (?: (?<D> \d++ ) [日]? )?
	  )?
	$
	}ix)
    {
	my %m = %+;
	(my $era_str = $m{Y}) =~ s{^([A-Z\p{Han}])(?=\d)}{
	    $abbr{uc $1} // $1
	}ie;
	my $era = eval { Date::Japanese::Era->new($era_str) } or do {
	    my $warn = $@ =~ s/ at .*//sr;
	    die "$_: format error ($warn)\n";
	};
	$year = $era->gregorian_year;
	if ($m{D}) {
	    ($mon, $mday) = ($m{M}, $m{D});
	} else {
	    $show_year++;
	    undef $mday;
	}
    }
    else {
	$mday = $1 if s{[-./]*(\d+)日?$}{};
	$mon  = $1 if s{[-./]*(\d+)月?$}{};
	$year = $1 if s{(?:西暦)?(\d+)年?$}{};
	if (defined $mday and $mday > 31) {
	    $year = $mday;
	    undef $mday;
	    $show_year++;
	}
	die "$date_str: format error" if length;
    }

    ($year, $mon, $mday, $show_year);
}

sub split_week {
    state $fold = new Text::ANSI::Fold width => [ (1, 2) x 7, 1 ];
    $fold->text(+shift)->chops;
}

sub transpose {
    my @x;
    my @orig = map { [ @$_ ] } @_;
    while (my @l = grep { @$_ > 0 } @orig) {
	push @x, [ map { shift @$_ } @l ];
    }
    @x;
}

1;
