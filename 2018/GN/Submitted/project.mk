#####################################################################
# Files in the project
#####################################################################

# If the main TeX file is ``myproject.tex'', set:
#   PROJECT = myproject
#
PROJECT = myproject

# If you have your own bib file ``mybibfile.bib'', set:
#   PROJECT_BIB = mybibfile.bib
# otherwise, leave it blank.
#
PROJECT_BIB = mybibdata.bib

# Set all pdf figure files in the project like:
#
#  FIG_PDF_FILES = figs/fig1.pdf figs/fig2.pdf figs/fig3.pdf \
#      figs/fig4.pdf figs/fig5.pdf
#
# Instead, if you want to create all pdf figure files automatically
# from a single master pdf, leave it commented out and set
# FIG_MASTER_FILE and FIG_PAGES (see below)
#
%FIG_PDF_FILES =

# If you want to create all pdf figure files from a single master pdf
# file by splitting it into individual pdf files, set FIG_MASTER_FILE
# and FIG_PAGES.  FIG_PAGES indicates which pages are extracted from
# FIG_MASTER_FILE.
#
# For example:
#
#   FIG_MASTER_FILE = figs/fig.pdf
#   FIG_PAGES       = 1 2 3 4 5
#
# is equivalent to:
#
#    FIG_PDF_FILES = figs/fig1.pdf figs/fig2.pdf figs/fig3.pdf \
#       figs/fig4.pdf figs/fig5.pdf
#
FIG_MASTER_FILE = figs/fig.pdf
FIG_PAGES       = 1 2
