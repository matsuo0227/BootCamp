### -*- tab-width: 8 -*-
###
### Makefile for LaTeX documents
###
### Yoshinari Nomura
###
### GNU make 3.81 will work for you.
###

#####################################################################
# Typeset commands and path settings
#####################################################################

TEXINPUTS := $(TEXINPUTS):sty:sty/ipsj-unix:
BSTINPUTS := :sty:$(BSTINPUTS)

PLATEX     = TEXINPUTS=$(TEXINPUTS) platex -interaction=errstopmode -synctex=1
BIBTEX     = BSTINPUTS=$(BSTINPUTS) pbibtex

DVIPDFMX   = dvipdfmx -p a4     # for A4

GS         = gs -q -dSAFER -dBATCH -dNOPAUSE -dAutoRotatePages=/None

LATEXDIFF = TEXINPUTS=$(TEXINPUTS) latexdiff -e utf8 -t CFONT --append-safecmd="diffblock" --append-textcmd="IEEEauthorblockN"
OPEN      = $(call findcmd, evince open xdg-open acroread)

#####################################################################
# Helper Macros
#####################################################################

# Extract trailed page number from FILE-NAME:
#  $(call pagenum,fig1.pdf) -> 1
#
pagenum = $(shell echo $(basename $1) | sed 's/^[^0-9]*//')

# Add PAGE-NUMBER to FILE-NAME:
#   $(call addpage,fig.pdf,1) -> fig1.pdf
# if SUFFIX is set as the third param, it replaces the original suffix:
#   $(call addpage,fig.pdf,1,xbb) -> fig1.xbb
#
addpage = $(basename $(1))$(2)$(if $(3),.$(3),$(suffix $(1)))

# Find suitable command from COMMAND-LIST:
#   $(call findcmd, open xdg-open) -> /usr/bin/open (Mac)
#   $(call findcmd, open xdg-open) -> /usr/bin/xdg-open (Linux)
#
# findcmd = $(firstword $(foreach c, $(1), $(shell which -v $(c))))
findcmd = $(firstword $(foreach c, $(1), $(shell which $(c))))

#####################################################################
# Suffix rules
#####################################################################

.SUFFIXES:
.SUFFIXES: .pdf .dvi .tex .eps .obj .png .gif .gnuplot

.dvi.pdf:
	${DVIPDFMX} $<

.pdf.xbb:
	@echo "Making $@ from $<"
	@${GS} -sDEVICE=bbox -r100 $< 2> $@

################################################################
## Include and check project.mk
#####################################################################

include project.mk

ifndef PROJECT
  $(error You must set PROJECT in project.mk)
endif

ifdef PROJECT_BIB
  ifeq (,$(wildcard ${PROJECT_BIB}))
    $(error ${PROJECT_BIB} set by PROJECT_BIB not found)
  endif
endif

ifdef FIG_MASTER_FILE
  ifdef FIG_PDF_FILES
    $(error You cannot set both FIG_MASTER_FILE and FIG_PDF_FILES)
  endif
endif

ifdef FIG_MASTER_FILE
  ifeq (,$(wildcard ${FIG_MASTER_FILE}))
    $(error ${FIG_MASTER_FILE} set by FIG_MASTER_FILE not found)
  endif
endif

#####################################################################
# Set project-specific variables derived from project.mk
#####################################################################

TEX_FILES = ${PROJECT}.tex

ifdef PROJECT_BIB
  BBL_FILES = ${PROJECT}.bbl
endif

FIG_PDF_FILES ?= $(foreach n, $(FIG_PAGES), $(call addpage,$(FIG_MASTER_FILE),$(n)))
FIG_EBB_FILES := $(FIG_PDF_FILES:.pdf=.xbb)
FIG_EPS_FILES := $(FIG_PDF_FILES:.pdf=.eps)

#####################################################################
# Common rules
#####################################################################

preview: ${PROJECT}.pdf
	${OPEN} $<

all:	${PROJECT}.pdf

ifdef FIG_MASTER_FILE
${FIG_PDF_FILES} : ${FIG_MASTER_FILE}
	@echo 'Making $@ from $< page: $(call pagenum,$*)'
	@${GS}  -sDEVICE=pdfwrite \
		-dFirstPage=$(call pagenum,$*)  \
		-dLastPage=$(call pagenum,$*)   \
		-sOutputFile=$@ ${FIG_MASTER_FILE} 2>/dev/null
endif

${FIG_EBB_FILES} : %.xbb : %.pdf
	@echo "Making $@ from $<"
	@${GS} -sDEVICE=bbox -r100 $< 2> $@

${FIG_EPS_FILES} : %.eps : %.pdf
	@echo "Making $@ from $<"
	@pdf2ps $< - | ps2eps -r 100 > $@

ifdef PROJECT_BIB
${BBL_FILES} : ${PROJECT_BIB} ${TEX_FILES}
	${PLATEX} ${PROJECT}.tex
	${BIBTEX} ${PROJECT}
endif

${PROJECT}.dvi: ${TEX_FILES} ${FIG_PDF_FILES} ${FIG_EBB_FILES} ${BBL_FILES}
	${PLATEX} ${PROJECT}.tex
	${PLATEX} ${PROJECT}.tex

${PROJECT}.pdf: ${PROJECT}.dvi

latexdiff:
	TEXINPUTS=$(TEXINPUTS) git latexdiff

distclean: clean figclean pdfclean

eps:  ${FIG_EPS_FILES}

clean:
	rm -f *.aux *.bak *.bbl *.blg *.dvi *.idx *.ilg *.ind *.lnk *.lof *.log *.lot *.synctex *.synctex.gz *.toc *~

figclean:
	rm -f ${FIG_PDF_FILES} ${FIG_EBB_FILES} ${FIG_EPS_FILES}
pdfclean:
	rm -f ${PROJECT}.pdf
diff:
	git show HEAD:./$(PROJECT).tex > $(PROJECT)-orig.tex
	${LATEXDIFF} $(PROJECT)-orig.tex $(PROJECT)-anno.tex > $(PROJECT)-diff.tex
	${PLATEX} ${PROJECT}-diff.tex
	${PLATEX} ${PROJECT}-diff.tex
	${DVIPDFMX} ${PROJECT}-diff.dvi
	${OPEN} ${PROJECT}-diff.pdf
