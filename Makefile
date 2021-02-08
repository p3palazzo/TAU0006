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
	--user "`id -u`:`id -g`" pandoc/crossref:2.11.4
PANDOC/LATEX    := docker run -v "`pwd`:/data" \
	-v "`pwd`/assets/fonts:/usr/share/fonts" \
	--user "`id -u`:`id -g`" pandoc/latex:2.11.4

ASSETS  = $(wildcard assets/*)
CSS     = $(wildcard assets/css/*)
FONTS   = $(wildcard assets/fonts/*)
ROOT    = $(wildcard *.md)
AULA    = $(wildcard _aula/*.md)
SLIDES := $(patsubst _aula/%.md,_site/slides/%.html,$(AULA))

deploy : _site $(SLIDES) $(AULA) $(ASSETS) $(CSS) $(ROOT)
	@bundle install \
		&& bundle exec jekyll build --future

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

.slides : $(SLIDES) | _site

_site/slides/%.html : _aula/%.md biblio.bib revealjs.yaml | _csl _site/slides
	$(PANDOC/CROSSREF) -o $@ -d _spec/revealjs.yaml $<

# Para ativar o Multiplex, incluir as linhas abaixo no comando acima:
#-V multiplexSecret=$(multiplexSecret) \
#-V multiplexSocketId=$(multiplexSocketId) \
#-V multiplexUrl=$(multiplexUrl) \

#_site : README.md _config.yaml _sass reveal.js $(ASSETS) $(CSS) $(FONTS) | _csl clean
	#docker run -v "`pwd`:/srv/jekyll" palazzo/jekyll-pandoc:4.2.0-2.11.3.2 \
		#/bin/bash -c "chmod 777 /srv/jekyll && jekyll build --future"

# {{{1 PHONY
#      =====

_site :
	@gh repo clone tau0006 _site -- -b gh-pages --depth=1 \
		|| cd _site && git pull

_csl :
	git clone https://github.com/citation-style-language/styles.git _csl

_site/slides : _site
	-mkdir -p _site/slides

serve :
	@bundle install \
		&& bundle exec jekyll serve

clean :
	-@rm -rf *.aux *.bbl *.bcf *.blg *.fdb_latexmk *.fls *.log *.run.xml \
		tau0006-*.tex _csl

# vim: set foldmethod=marker shiftwidth=2 tabstop=2 :
