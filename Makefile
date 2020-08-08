# {{{1 Configurações gerais
#      ====================

VPATH = .:assets
vpath %.csl _csl
vpath %.html .:_includes:_layouts:_site
vpath %.scss assets/css
vpath %.xml _site
vpath %.yaml .:_spec
vpath default.% _lib

ROOT    = $(filter-out README.md,$(wildcard *.md))
DOCS    = $(wildcard _docs/*.md)
PAGES  := $(patsubst %.md,_site/%.html,$(ROOT))
SLIDES := $(patsubst _docs/%.md,_site/slides/%.html,$(DOCS))
NOTAS  := $(patsubst _docs/%.md,_site/docs/%.html,$(DOCS))

deploy : _site/sitemap.xml _site/.pages \
	_site/slides/.slides _site/docs/.docs

# {{{1 Produtos PDF
#      ============

%.pdf : %.tex
	docker run -i -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		-v "`pwd`/assets/fonts:/usr/share/fonts" blang/latex:ctanfull \
		latexmk -pdflatex="xelatex" -cd -f -interaction=batchmode -pdf $<

tau0006-plano.tex : pdf.yaml plano.md plano-metodo.md plano-programa.md \
	plano-apoio-avalia.md biblio-leitura.md plano-biblio.md | _csl
	docker run -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		pandoc/crossref:2.10 -o $@ -d $^

%.tex : pdf.yaml %.md | default.latex
	docker run -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		pandoc/crossref:2.10 -o $@ -d $^

# {{{1 Slides, _docs de aula e outros HTML
#      ===================================

_site/.pages : $(PAGES)
	touch _site/.pages

_site/%.html : html.yaml %.md | _csl
	docker run -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		pandoc/crossref:2.10 -o $@ -d $^

_site/docs/.docs : $(NOTAS)
	touch _site/docs/.docs

_site/docs/%.html : html.yaml _docs/%.md | _csl _site/docs
	docker run -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		pandoc/crossref:2.10 -o $@ -d $^

_site/slides/.slides : $(SLIDES)
	touch _site/slides/.slides

_site/slides/%.html : revealjs.yaml _docs/%.md | _csl _site/slides
	docker run -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		pandoc/crossref:2.10 -o $@ -d $^

_site/sitemap.xml :
	docker run -v "`pwd`:/srv/jekyll" jekyll/jekyll:4.1.0 \
		/bin/bash -c "chmod 777 /srv/jekyll && jekyll build --future"

# {{{1 PHONY
#      =====

serve :
	docker run -p 4000:4000 -h 127.0.0.1 \
		-v "`pwd`:/srv/jekyll" -it jekyll/jekyll:4.1.0 \
		jekyll serve

_site/slides :
	mkdir -p _site/slides

_site/docs :
	mkdir -p _site/docs

_csl :
	git clone https://github.com/citation-style-language/styles.git _csl

clean :
	rm -rf *.aux *.bbl *.bcf *.blg *.fdb_latexmk *.fls *.log *.run.xml

# vim: set foldmethod=marker shiftwidth=2 tabstop=2 :