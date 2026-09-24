#!/bin/bash
# Compile colleague report LaTeX document

echo "Compiling colleague report..."

# Change to paper_drafts directory
cd /Users/iMacPro/Documents/GitHub/RW_Percolation/paper_drafts

# First pass
pdflatex colleague_report.tex

# Bibliography
bibtex colleague_report

# Second pass
pdflatex colleague_report.tex

# Third pass
pdflatex colleague_report.tex

echo "Compilation complete!"
echo "Output: colleague_report.pdf"

# Check if PDF was created
if [ -f "colleague_report.pdf" ]; then
    echo "✅ PDF created successfully!"
    echo "File size: $(ls -lh colleague_report.pdf | awk '{print $5}')"
else
    echo "❌ PDF creation failed!"
fi

