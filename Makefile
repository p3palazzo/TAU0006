VPATH = .:assets
vpath %.html .:_includes:_layouts:_site
vpath %.scss assets/css
vpath %.xml _site
vpath %.yaml spec

ANYTHING  = $(filter-out _site,$(wildcard *))
PANDOC    = $(filter-out README.md,$(wildcard *.md))
REVEALJS  = $(wildcard _slides/*.md)
SLIDES   := $(patsubst _slides/%.md,_site/_slides/%.html,$(REVEALJS))
PAGES    := $(filter-out $(REVEALJS),$(ANYTHING))

deploy : jekyll slides

%.pdf : pdf.yaml %.md
	docker run --rm -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		-v "`pwd`/assets/fonts:/usr/share/fonts" \
		pandoc/latex:2.9.2.1 -o $@ -d $^

slides : $(SLIDES)

jekyll : $(PAGES)
	docker run --rm -v "`pwd`:/srv/jekyll" \
		jekyll/jekyll:4.1.0 /bin/bash -c "chmod 777 /srv/jekyll && jekyll build"

_site/%.html : %.md revealjs.yaml
	docker run --rm -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		pandoc/core:2.9.2.1 -o $@ -d spec/revealjs.yaml $<

serve :
	docker run --rm -p 4000:4000 -h 127.0.0.1 \
		-v "`pwd`:/srv/jekyll" -it jekyll/jekyll:4.1.0 \
		jekyll serve --skip-initial-build --no-watch
