#!/bin/bash

echo "Testing LaTeX compilation with bibliography..."

# First pass - pdflatex
echo "Running pdflatex (first pass)..."
pdflatex -interaction=nonstopmode test_bib.tex

# Run bibtex
echo "Running bibtex..."
bibtex test_bib

# Second pass - pdflatex
echo "Running pdflatex (second pass)..."
pdflatex -interaction=nonstopmode test_bib.tex

# Third pass - pdflatex (for cross-references)
echo "Running pdflatex (third pass)..."
pdflatex -interaction=nonstopmode test_bib.tex

echo "Compilation complete. Check test_bib.pdf for results."
