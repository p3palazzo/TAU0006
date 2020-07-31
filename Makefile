VPATH = .:assets
vpath %.csl styles
vpath %.html .:_includes:_layouts:_site
vpath %.scss assets/css
vpath %.xml _site
vpath %.yaml .:spec
vpath default.% lib

ROOT      = $(filter-out README.md,$(wildcard *.md))
DOCS      = $(wildcard docs/*.md)
PAGES    := $(patsubst %.md,_site/%.html,$(ROOT))
SLIDES   := $(patsubst docs/%.md,_site/_slides/%.html,$(DOCS))
HANDOUTS := $(patsubst docs/%.md,_site/_handouts/%.html,$(DOCS))

deploy : _site/sitemap.xml _site/.pages \
	_site/_slides/.slides _site/_handouts/.handouts

tau0006-%.pdf : %.tex
	docker run -i -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		-v "`pwd`/assets/fonts:/usr/share/fonts" blang/latex:ctanfull \
		latexmk -pdflatex="xelatex" -cd -f -interaction=batchmode -pdf $<
	mv $*.pdf $@

plano.tex : pdf.yaml plano.md plano-metodo.md plano-programa.md \
	plano-apoio-avalia.md biblio-leitura.md plano-biblio.md | styles
	docker run -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		pandoc/core:2.10 -o $@ -d $^

%.tex : pdf.yaml %.md | default.latex
	docker run -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		pandoc/core:2.10 -o $@ -d $^

_site/.pages : $(PAGES)
	touch _site/.pages

_site/%.html : html.yaml %.md | styles
	docker run -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		pandoc/core:2.10 -o $@ -d $^

_site/_handouts/.handouts : $(HANDOUTS)
	touch _site/_handouts/.handouts

_site/_handouts/%.html : html.yaml docs/%.md | styles
	docker run -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		pandoc/core:2.10 -o $@ -d $^

_site/_slides/.slides : $(SLIDES)
	touch _site/_slides/.slides

_site/_slides/%.html : revealjs.yaml %.md | styles
	docker run -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		pandoc/core:2.10 -o $@ -d $^

_site/sitemap.xml : clean 
	docker run --rm -v "`pwd`:/srv/jekyll" \
		jekyll/jekyll:4.1.0 /bin/bash -c "chmod 777 /srv/jekyll && jekyll build"

serve :
	docker run --rm -p 4000:4000 -h 127.0.0.1 \
		-v "`pwd`:/srv/jekyll" -it jekyll/jekyll:4.1.0 \
		jekyll serve --skip-initial-build --no-watch

styles :
	git clone https://github.com/citation-style-language/styles.git

clean :
	rm -rf styles *.aux *.bbl *.bcf *.blg *.fdb_latexmk *.fls *.log *.run.xml
