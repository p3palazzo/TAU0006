# {{{1 Configurações gerais
#      ====================

VPATH = .:assets
vpath %.csl _csl
vpath %.html .:_includes:_layouts:_site
vpath %.scss assets/css
vpath %.xml _site
vpath %.yaml .:_spec
vpath default.% _lib

PANDOC/CROSSREF := docker run -v "`pwd`:/data" --user "`id -u`:`id -g`" pandoc/crossref:2.10

ROOT    = $(filter-out README.md,$(wildcard *.md))
PAGES  := $(patsubst %.md,_site/%.html,$(ROOT))
DOCS    = $(wildcard _docs/*.md)
SLIDES := $(patsubst _docs/%.md,_site/slides/%.html,$(DOCS))
NOTAS  := $(patsubst _docs/%.md,_site/docs/%.html,$(DOCS))

deploy : _site/index.html $(PAGES) $(SLIDES) $(NOTAS)

# {{{1 Produtos PDF
#      ============

%.pdf : %.tex
	docker run -i -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		-v "`pwd`/assets/fonts:/usr/share/fonts" blang/latex:ctanfull \
		latexmk -pdflatex="xelatex" -cd -f -interaction=batchmode -pdf $<

tau0006-plano.tex : pdf.yaml plano.md plano-metodo.md plano-programa.md \
	plano-apoio-avalia.md biblio-leitura.md plano-biblio.md | _csl
	$(PANDOC/CROSSREF) -o $@ -d $^

tau0006-cronograma.tex : pdf.yaml cronograma.md cronograma-pdf.md
	$(PANDOC/CROSSREF) -o $@ -d $^

%.tex : pdf.yaml %.md | default.latex
	$(PANDOC/CROSSREF) -o $@ -d $^

# {{{1 Slides, notas de aula e outros HTML
#      ===================================

.pages : $(PAGES)
	touch .pages

.notas : $(NOTAS)
	touch .notas

.slides : $(SLIDES)
	touch .slides

_site/%.html : html.yaml %.md | _csl _site
	$(PANDOC/CROSSREF) -o $@ -d $^

_site/docs/%.html : html.yaml _docs/%.md | _csl _site/docs
	$(PANDOC/CROSSREF) -o $@ -d $^

_site/slides/%.html : revealjs.yaml _docs/%.md | _csl _site/slides
	$(PANDOC/CROSSREF) -o $@ -d $^

_site/index.html : README.md _config.yaml _sass assets reveal.js
	docker run -v "`pwd`:/srv/jekyll" jekyll/jekyll:4.1.0 \
		/bin/bash -c "chmod 777 /srv/jekyll && jekyll build --future"

# {{{1 PHONY
#      =====

serve :
	docker run -p 4000:4000 -h 127.0.0.1 \
		-v "`pwd`:/srv/jekyll" -it jekyll/jekyll:4.1.0 \
		jekyll serve

_site :
	mkdir -p _site

_site/slides :
	mkdir -p _site/slides

_site/docs :
	mkdir -p _site/docs

_csl :
	git clone https://github.com/citation-style-language/styles.git _csl

clean :
	rm -rf _csl *.aux *.bbl *.bcf *.blg *.fdb_latexmk *.fls *.log *.run.xml

# vim: set foldmethod=marker shiftwidth=2 tabstop=2 :
