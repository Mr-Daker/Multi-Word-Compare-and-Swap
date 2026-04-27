#!/bin/bash

# Compile LaTeX presentation
# Requires: pdflatex, beamer class

echo "Compiling LaTeX presentation..."

# Change to presentation directory
cd "$(dirname "$0")"

# Compile with pdflatex (run twice for references)
pdflatex mcas_presentation.tex
pdflatex mcas_presentation.tex

echo "Presentation compiled successfully!"
echo "Output: mcas_presentation.pdf"