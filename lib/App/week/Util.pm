package App::week;
use v5.14;
use warnings;

use Text::ANSI::Fold;

sub split_week {
    state $fold = new Text::ANSI::Fold width => [ (1, 2) x 7, 1 ];
    $fold->text(+shift)->chops;
}

1;
