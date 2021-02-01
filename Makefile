# {{{1 Configurações gerais
#      ====================

VPATH = .:assets
vpath %.csl _csl
vpath %.html .:_includes:_layouts:_site
vpath %.scss assets/css
vpath %.xml _site
vpath default.% _lib
vpath %.yaml _spec:.

PANDOC/CROSSREF := docker run -v "`pwd`:/data" \
	--user "`id -u`:`id -g`" pandoc/crossref:2.11.3.2
PANDOC/LATEX    := docker run -v "`pwd`:/data" \
	-v "`pwd`/assets/fonts:/usr/share/fonts" \
	--user "`id -u`:`id -g`" pandoc/latex:2.11.3.2

ASSETS  = $(wildcard assets/*)
CSS     = $(wildcard assets/css/*)
FONTS   = $(wildcard assets/fonts/*)
ROOT    = $(filter-out README.md,$(wildcard *.md))
PAGES  := $(patsubst %.md,_site/%.html,$(ROOT))
DOCS    = $(wildcard _aula/*.md)
SLIDES := $(patsubst _aula/%.md,slides/%.html,$(DOCS))

deploy : _site $(SLIDES)

manual : _site | _csl
	@cd _site \
		&& bundle install \
		&& bundle exec jekyll build

# {{{1 Produtos PDF
#      ============

tau0006.pdf : plano.pdf cronograma.pdf
	gs -dNOPAUSE -dBATCH -sDevice=pdfwrite \
		-sOutputFile=$@ $^

%.pdf : %.tex biblio.bib
	docker run -i -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		-v "`pwd`/assets/fonts/unb:/usr/share/fonts" blang/latex:ctanfull \
		latexmk -pdflatex="xelatex" -cd -f -interaction=batchmode -pdf $<

%.tex : %.md latex.yaml default.latex
	$(PANDOC/LATEX) -o $@ -d _spec/latex.yaml $<

# {{{1 Slides, notas de aula e outros HTML
#      ===================================

.slides : $(SLIDES)

_site/slides/%.html : _aula/%.md biblio.bib revealjs.yaml | _csl slides
	$(PANDOC/CROSSREF) -o $@ -d _spec/revealjs.yaml $<

# Para ativar o Multiplex, incluir as linhas abaixo no comando acima:
#-V multiplexSecret=$(multiplexSecret) \
#-V multiplexSocketId=$(multiplexSocketId) \
#-V multiplexUrl=$(multiplexUrl) \

#_site : README.md _config.yaml _sass reveal.js $(ASSETS) $(CSS) $(FONTS) | _csl clean
	#docker run -v "`pwd`:/srv/jekyll" palazzo/jekyll-pandoc:4.2.0-2.11.3.2 \
		#/bin/bash -c "chmod 777 /srv/jekyll && jekyll build --future"

_site :
	@gh repo clone tau0006 _site -- -b gh-pages --depth=1

# {{{1 PHONY
#      =====

_csl :
	git clone https://github.com/citation-style-language/styles.git _csl

_site/slides :
	-mkdir -p _site/slides

serve : manual
	docker run -v "`pwd`:/srv/jekyll" -p 4000:4000 -h 127.0.0.1 \
		palazzo/jekyll-pandoc:4.2.0-2.11.3.2 jekyll serve --skip-initial-build

clean :
	-@rm -rf *.aux *.bbl *.bcf *.blg *.fdb_latexmk *.fls *.log *.run.xml \
		tau0006-*.tex _site

# vim: set foldmethod=marker shiftwidth=2 tabstop=2 :
