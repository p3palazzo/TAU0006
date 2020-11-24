# {{{1 Configurações gerais
#      ====================

VPATH = .:assets
vpath %.csl _csl
vpath %.html .:_includes:_layouts:_site
vpath %.scss assets/css
vpath %.xml _site
vpath %.yaml .:_spec
vpath default.% _lib

PANDOC/CROSSREF := docker run -v "`pwd`:/data" \
	--user "`id -u`:`id -g`" pandoc/crossref:2.11.2
PANDOC/LATEX    := docker run -v "`pwd`:/data" \
	-v "`pwd`/assets/fonts:/usr/share/fonts" \
	--user "`id -u`:`id -g`" pandoc/latex:2.11.2

ROOT    = $(filter-out README.md,$(wildcard *.md))
PAGES  := $(patsubst %.md,_site/%.html,$(ROOT))
DOCS    = $(wildcard _aula/*.md)
SLIDES := $(patsubst _aula/%.md,_site/aula/%/index.html,$(DOCS))
NOTAS  := $(patsubst _aula/%.md,_site/aula/%/notas.html,$(DOCS))

deploy : _site $(PAGES) $(SLIDES) $(NOTAS) _site/package-lock.json

# {{{1 Produtos PDF
#      ============

tau0006-cronograma.pdf : pdf.yaml cronograma.md
	$(PANDOC/LATEX) -o $@ -d $^

%.pdf : %.tex
	docker run -i -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		-v "`pwd`/assets/fonts:/usr/share/fonts" blang/latex:ctanfull \
		latexmk -pdflatex="xelatex" -cd -f -interaction=batchmode -pdf $<

tau0006-plano.tex : pdf.yaml plano.md plano-metodo.md plano-programa.md \
	plano-apoio-avalia.md biblio-leitura.md plano-biblio.md
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

_site/%.html : html.yaml %.md | _csl
	@mkdir -p _site
	$(PANDOC/CROSSREF) -o $@ -d $^

_site/aula/%/index.html : revealjs.yaml _aula/%.md | _csl
	@mkdir -p _site/aula/$*
	$(PANDOC/CROSSREF) -o $@ -d $^

# Para ativar o Multiplex, incluir as linhas abaixo no comando acima:
#-V multiplexSecret=$(multiplexSecret) \
#-V multiplexSocketId=$(multiplexSocketId) \
#-V multiplexUrl=$(multiplexUrl) \

_site/aula/%/notas.html : html.yaml _aula/%.md | _csl
	@mkdir -p _site/aula/$*
	$(PANDOC/CROSSREF) -o $@ -d $^ --css ../../assets/main.css

_site/package-lock.json : package.json | _site
	cp package.json _site/
	cd _site && npm install

_site : README.md _config.yaml _sass assets reveal.js
	docker run -v "`pwd`:/srv/jekyll" jekyll/jekyll:4.1.0 \
		/bin/bash -c "chmod 777 /srv/jekyll && jekyll build --future"

# {{{1 PHONY
#      =====

_csl :
	git clone https://github.com/citation-style-language/styles.git _csl

serve : | _site
	docker run -v "`pwd`:/srv/jekyll" -p 4000:4000 -h 127.0.0.1 \
		jekyll/jekyll:4.1.0 jekyll serve --skip-initial-build

clean :
	rm -rf *.aux *.bbl *.bcf *.blg *.fdb_latexmk *.fls *.log *.run.xml \
		_csl _site tau0006-*.tex

# vim: set foldmethod=marker shiftwidth=2 tabstop=2 :
