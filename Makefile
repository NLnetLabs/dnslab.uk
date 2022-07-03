.SUFFIXES: .md .html

all: part0.html part1.html part1b.html part1c.html part1d.html part2.html part_privacy.html part_day3-1.html part_day3-2.html part_day4-1.html part_day4-2.html slides.html

clean:
	rm part0.html part1.html part1b.html part1c.html part1d.html part2.html part_privacy.html part_day3-1.html part_day3-2.html part_day4-1.html part_day4-2.html slides.html

.md.html:
	pandoc -B menu.html -s --css=github.css --to=html5 --highlight-style=haddock \
       --self-contained -o $@ $<

watch:
	while true; do \
		make $(WATCHMAKE); \
		inotifywait -qre close_write .; \
	done
