package App::week::mlb;

use strict;
use warnings;
use utf8;

1;

__DATA__

define RED    400
define YELLOW 550
define BLACK  L00
define WHITE  L25

######################################################################

define DodBlue1 #435b91
define DodBlue2 #023585
define DodRed   #d05850

option --dodgers \
	--cm *MONTH=*DAYS=WHITE/DodBlue1 \
	--cm FRAME=*WEEK=WHITE/DodBlue2 \
	--cm THISDAY=WHITE/DodRed,THISMONTH=THISDAYS=DodBlue2/WHITE \
	$<ignore>

option --dodgers-rev --dodgers
