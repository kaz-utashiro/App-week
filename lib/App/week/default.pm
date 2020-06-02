package App::week::default;
use utf8;
1;
__DATA__

autoload -Mcolors --mono --green --lavender --pastel

autoload -Mteams \
	--team \
	--giants --giants-rev \
	--tigers --tigers-rev \
	--lions --lions-rev --lions2 --lions2-rev --lions3 --lions3-rev

autoload -Molympic \
	--tokyo2020 --tokyo2020-rev

option --themecolor::bg -Mtermcolor::bg(light=--$<shift>,dark=--$<shift>-rev)
option --theme --themecolor::bg $<copy(0,1)>
