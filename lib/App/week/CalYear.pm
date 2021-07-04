package App::week::CalYear;

use v5.14;
use warnings;

use Exporter 'import';
our @EXPORT = qw(@calyear);

use Encode;
use Data::Dumper;
use open IO => ':utf8';
use Text::VisualWidth::PP qw(vwidth);

tie our @calyear, __PACKAGE__;

sub TIEARRAY {
    my $pkg = shift;
    bless {}, $pkg;
}

sub FETCH {
    my($obj, $year) = @_;
    $obj->{$year} //= [ CalYear($year) ];
}

my $caller = caller;

sub CalYear {
    my $year = sprintf "%4d", shift;
    my $cal = `cal $year` =~ s/_[\b]//gr;
    state $debug = do {
	no strict 'refs';
	\%{"$caller\::debug"};
    };
    if ($debug->{crashspace}) {
	$cal =~ s/ +$//mg;
    }
    if ($debug->{netbsd}) {
	$cal =~ s/(Su|Mo|We|Fr|Sa)/' ' . substr($1,0,1)/mge;
    }
    my @cal = split /\n/, $cal, -1;
    my @month = ( [ $cal[0] ], map [], 1..12 );
    my @monthline = do {
	map  { $_ - 2 }                 # 2 lines up
	grep { $cal[$_] =~ /\s 1 \s/x } # find 1st day
	0 .. $#cal;
    };
    @monthline == 4 or die "cal(1) command format error.\n";
    state $fields = do {
	use Unicode::EastAsianWidth;
	my $dow_re = qr/\p{InFullwidth}|[ \S]\S/;
	$cal[ $monthline[0] + 1 ] =~
	    m{^   (\s*)
		  ( (?: $dow_re [ ]){6} $dow_re ) (\s+)
		  ( (?: $dow_re [ ]){6} $dow_re ) (\s+)
		  ( (?: $dow_re [ ]){6} $dow_re )
	}x or die "cal(1): unexpected day-of-week line.";
	my $w = vwidth $2;
	my @w = (length $1, $w, length $3, $w, length $5, $w);
	my $blank = ' ' x $w;
	my $fold = new Text::ANSI::Fold width => \@w, padding => 1;
	sub {
	    map $_ // $blank, ($fold->text(shift)->chops)[1, 3, 5];
	};
    };
    for my $i (0 .. $#monthline) {
	my $start = $monthline[$i];
	for my $n (0..7) {
	    my @m = $fields->($cal[$start + $n]);
	    push @{$month[$i * 3 + 1]}, $m[0];
	    push @{$month[$i * 3 + 2]}, $m[1];
	    push @{$month[$i * 3 + 3]}, $m[2];
	}
    }
    for my $month (@month[1..12]) {
	for (@{$month}) {
	    $_ = " $_ ";
	}
	for ($month->[0]) {
	    ## Fix month name:
	    ## 1) Take care of cal(1) multibyte string bug.
	    ## 2) Normalize off-to-right to off-to-left.
	    while (/^ (( +)\S+( +))$/ and length($2) >= length($3)) {
		$_ = "$1 ";
	    }
	}
    }
    $month[1][0] =~ s/(?<=^ ) {4}| {4}(?= $)/$year/g;
    @month;
}

1;
