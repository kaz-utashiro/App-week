package App::week::olympic;

use strict;
use warnings;
use utf8;

1;

__DATA__

define 白 #fff
define 黒 #000

define リング青　#0081c8
define リング黄　#fcb131
define リング黒　#000000
define リング緑　#00a651
define リング赤　#ee334e

define ロゴ赤　#aa272f
define ロゴ青　#00549f
define ロゴ緑　#008542

define エンブレム青　#002063
define エンブレム赤　#ee334e

expand --tokyo2020-common \
	--cm *MONTH=*DAYS=白/エンブレム青 \
	--cm WEEK=/エンブレム青 \
	--cm DOW_SU=白/エンブレム赤 \
	--cm DOW_MO=白/リング青 \
	--cm DOW_TU=白/リング黄 \
	--cm DOW_WE=白/リング黒 \
	--cm DOW_TH=白/リング緑 \
	--cm DOW_FR=白/リング赤 \
	--cm DOW_SA=白/エンブレム赤

option --tokyo2020 \
	--tokyo2020-common \
	--cm FRAME=白/エンブレム赤 \
	--cm THISDAY=D;エンブレム赤/白,THISMONTH=THISDAYS=THISWEEK=エンブレム青/白

option --tokyo2020-rev \
	--tokyo2020-common \
	--cm FRAME=エンブレム赤/白 \
	--cm THISDAY=D;エンブレム赤/白,THISMONTH=THISDAYS=THISWEEK=白/エンブレム赤
