# Makefile for LaTeX using Latexmk
# Use the following to include dependencies in your .tex files:
# \newcommand\inputfile[1]{%
#     \InputIfFileExists{#1}{}{\typeout{No file #1.}}%
# }

MAIN = main.tex # MAIN LaTeX FILE HERE
TARGET_FT = pdf # TARGET FILE TYPE HERE (pdf, dvi, etc.)
BUILD_ARGS = -pdflua -verbose -file-line-error -Werror -interaction=nonstopmode -halt-on-error -synctex=1 -use-make --shell-escape -pretex="\pdfvariable suppressoptionalinfo 512\relax" -usepretex

TARGET = $(foreach v,$(MAIN),$(patsubst %.tex,%.$(TARGET_FT),$(v)))
.PHONY: all clean clean_ints

all: clean $(TARGET) clean_ints

# Custom build rules
%.tex: %.raw
	./raw2tex $< > $@

%.tex: %.dat
	./dat2tex $< > $@


clean:
	latexmk -C

clean_ints:
	latexmk -c

$(TARGET): %.$(TARGET_FT): %.tex
	latexmk $(BUILD_ARGS) $<
