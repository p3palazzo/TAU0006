# {{{1 Configurações gerais
#      ====================

VPATH = .:assets
vpath %.csl _csl
vpath %.html .:_includes:_layouts:_site
vpath %.scss assets/css
vpath %.xml _site
vpath default.% _lib
vpath %.yaml _spec:.

PANDOC_VERSION := 2.12
JEKYLL_VERSION := 4.2.0
PANDOC/CROSSREF := docker run --rm -v "`pwd`:/data" \
	-u "`id -u`:`id -g`" pandoc/crossref:$(PANDOC_VERSION)
PANDOC/LATEX    := docker run --rm -v "`pwd`:/data" \
	-v "`pwd`/assets/fonts:/usr/share/fonts" \
	-u "`id -u`:`id -g`" pandoc/latex:$(PANDOC_VERSION)
JEKYLL := docker run --rm -v "`pwd`:/srv/jekyll" \
	-h "0.0.0.0:127.0.0.1" -p "4000:4000" \
	palazzo/jekyll-tufte:$(JEKYLL_VERSION)-$(PANDOC_VERSION)

ASSETS  = $(wildcard assets/*)
CSS     = $(wildcard assets/css/*) $(wildcard assets/css-slides/*)
ROOT    = $(wildcard *.md)
AULA    = $(wildcard _aula/*.md)
SLIDES := $(patsubst _aula/%.md,_site/slides/%.html,$(AULA))

deploy : $(SLIDES) \
	| _csl/chicago-fullnote-bibliography-with-ibid.csl
	$(JEKYLL) /bin/bash -c "chmod 777 /srv/jekyll && jekyll build"

# {{{1 Produtos PDF
#      ============
.PHONY : _site
_site : .slides \
	| _csl/chicago-fullnote-bibliography-with-ibid.csl
	@$(JEKYLL) /bin/bash -c \
		"chmod 777 /srv/jekyll && jekyll build"

tau0006.pdf : plano.pdf cronograma.pdf
	gs -dNOPAUSE -dBATCH -sDevice=pdfwrite \
		-sOutputFile=$@ $^

%.pdf : %.tex biblio.bib
	docker run -i -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		-v "`pwd`/assets/fonts/unb:/usr/share/fonts" blang/latex:ctanfull \
		latexmk -pdflatex="xelatex" -cd -f -interaction=batchmode -pdf $<

%.tex : %.md latex.yaml default.latex
	$(PANDOC/LATEX) -o $@ -d _spec/latex.yaml $<

_csl/%.csl : | _csl
	@cd _csl && git checkout master -- $(@F)
	@echo "Checked out $(@F)."

# {{{1 Slides, notas de aula e outros HTML
#      ===================================
.slides : $(SLIDES)

_site/slides/%.html : _aula/%.md biblio.bib revealjs.yaml \
	| _csl/chicago-author-date.csl _site/slides
	$(PANDOC/CROSSREF) -o $@ -d _spec/revealjs.yaml $<

# Para ativar o Multiplex, incluir as linhas abaixo no comando acima:
#-VmultiplexSecret=$(multiplexSecret) \
#-VmultiplexSocketId=$(multiplexSocketId) \
#-VmultiplexUrl=$(multiplexUrl) \

_site/slides :
	@test -e _site/slides || mkdir -p _site/slides

# {{{1 PHONY
#      =====
.PHONY : _csl
_csl :
	@echo "Fetching CSL styles..."
	@test -e $@ || \
		git clone --depth=1 --filter=blob:none --no-checkout \
		https://github.com/citation-style-language/styles.git \
		$@

.PHONY : serve
serve : $(SLIDES) \
	| _csl/chicago-fullnote-bibliography-with-ibid.csl
	@$(JEKYLL) jekyll serve

.PHONY : clean
clean :
	-@rm -rf *.aux *.bbl *.bcf *.blg *.fdb_latexmk *.fls *.log *.run.xml \
		tau0006-*.tex _csl

# vim: set foldmethod=marker shiftwidth=2 tabstop=2 :
