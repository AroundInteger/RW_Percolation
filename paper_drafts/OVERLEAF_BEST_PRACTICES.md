# Overleaf Best Practices Guide

This document outlines the best practices and requirements for creating professional academic papers in Overleaf, based on our experience with the PEF framework paper.

## 📋 Table of Contents
1. [Mathematical Notation](#mathematical-notation)
2. [Language and Style](#language-and-style)
3. [Document Structure](#document-structure)
4. [Figures and Tables](#figures-and-tables)
5. [References and Citations](#references-and-citations)
6. [File Organization](#file-organization)
7. [Compilation and Quality Control](#compilation-and-quality-control)

## 🔢 Mathematical Notation

### Greek Letters
- **Always use LaTeX formatting**: `$\kappa$`, `$\rho$`, `$\delta$`, `$\sigma$`, `$\mu$`, `$\Phi$`, `$\alpha$`, `$\eta$`
- **Never use raw Unicode**: ❌ `κ`, `ρ`, `δ`, `σ`, `μ`, `Φ`, `α`, `η`
- **Consistent notation**: Use single Greek letters for mathematical variables (e.g., `$\eta$` instead of "PEF" in equations)

### Mathematical Operators
- **Square root**: `$\sqrt{}$` instead of `√`
- **Fractions**: Use `\frac{}{}` for complex fractions
- **Superscripts/Subscripts**: `$\sigma^2_A$`, `$\mu_B$`
- **Multi-character subscripts/superscripts**: Use `{}` brackets: `$SS_{effect}$`, `$\sigma^2_{pooled}$`
- **Mathematical symbols**: `$\rightarrow$` (tending to), `$\infty$` (infinity), `$\approx$` (approximately), `$\neq$` (not equal)

### Equations
- **Display equations**: Use `\begin{equation}...\end{equation}` for numbered equations
- **Inline equations**: Use `$...$` for inline mathematical expressions
- **Equation references**: Use `\ref{eq:label}` to reference equations
- **Clean notation**: Use single Greek letters instead of acronyms in equations

### Example: Good vs. Bad
```latex
% ❌ BAD - Raw Unicode and cluttered notation
PEF = (1 + κ) / (1 + κ - 2√κ × ρ)
I(X;Y) = 1 - H(Φ(δ / (2σ_A√((1 + κ) / PEF))))

% ✅ GOOD - Proper LaTeX formatting
η = \frac{1 + \kappa}{1 + \kappa - 2\sqrt{\kappa}\rho}
I(X;Y) = 1 - H\left(\Phi\left(\frac{\delta}{2\sigma_A\sqrt{\frac{1 + \kappa}{\eta}}}\right)\right)
```

## 🌍 Language and Style

### British English
- **Spelling**: Use British English throughout (`recognised`, `behaviour`, `rigour`, `optimisation`)
- **Consistency**: Check all sections for American English spellings
- **Common conversions**:
  - `recognized` → `recognised`
  - `behavior` → `behaviour`
  - `rigor` → `rigour`
  - `optimization` → `optimisation`
  - `generalized` → `generalised`
  - `standardized` → `standardised`

### Academic Tone
- **Modest language**: Avoid sensational claims
- **Substantiated statements**: All claims must be backed by statistics or references
- **Professional terminology**: Use precise, technical language
- **Consistent terminology**: Define key terms and use consistently

### Abstract Guidelines
- **No equations**: Avoid mathematical formulas in abstracts
- **Clear structure**: Problem, approach, results, implications
- **Concise language**: Typically 150-250 words
- **Key findings**: Highlight main contributions without overselling

## 📚 Document Structure

### Section Organization
```
main.tex
├── \input{sections/introduction}
├── \input{sections/theoretical_framework}
├── \input{sections/empirical_validation}
├── \input{sections/results}
├── \input{sections/discussion}
├── \input{sections/mathematical_appendix}
└── \input{sections/conclusion}
```

### File Naming Conventions
- **Sections**: `introduction.tex`, `theoretical_framework.tex`, etc.
- **Tables**: `table_1_descriptive_name.tex`
- **Figures**: `figure_1_descriptive_name.png/eps`
- **Scripts**: `generate_figure_X_descriptive_name.m`

### LaTeX Structure
```latex
% Main document
\documentclass[11pt,a4paper]{article}
\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{amsmath,amsfonts,amssymb}
\usepackage{graphicx}
\usepackage{booktabs}
\usepackage{threeparttable}

% Document content
\begin{document}
\maketitle
\begin{abstract}
% Abstract content (no equations)
\end{abstract}

% Sections
\section{Introduction}
\input{sections/introduction}

% ... other sections

% Bibliography
\bibliographystyle{apalike}
\bibliography{references/references}
\end{document}
```

## 📊 Figures and Tables

### Figure Requirements
- **No titles**: Figures should not have titles, only captions
- **Academic legends**: Descriptive, informative captions
- **High resolution**: 300 DPI for publication
- **Multiple formats**: Generate both PNG and EPS versions
- **Consistent styling**: Use same color schemes and fonts

### Table Requirements
- **Professional formatting**: Use `booktabs` package
- **Clear headers**: Descriptive column headers
- **Consistent notation**: Use LaTeX formatting for mathematical symbols
- **Notes section**: Include methodological notes where appropriate

### Figure Generation Scripts
```matlab
% Example MATLAB script structure
function generate_figure_X_descriptive_name()
    % Set up figure
    figure('Position', [100, 100, 800, 600]);
    
    % Generate plot
    % ... plotting code ...
    
    % Formatting
    xlabel('X Label', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Y Label', 'FontSize', 12, 'FontWeight', 'bold');
    
    % Save in multiple formats
    print('../figures/figure_X_descriptive_name.png', '-dpng', '-r300');
    print('../figures/figure_X_descriptive_name.eps', '-depsc', '-r300');
end
```

## 📖 References and Citations

### Citation Style
- **Consistent format**: Use `\citep{}` for parenthetical citations
- **Author-year format**: `\citep{author2023}`
- **Multiple authors**: `\citep{author1,author2,author3}`
- **Page numbers**: `\citep[p.~123]{author2023}` for specific pages

### Bibliography Management
- **BibTeX format**: Use `.bib` files
- **Consistent entries**: Ensure all required fields are present
- **Quality sources**: Use high-impact, peer-reviewed sources
- **Recent references**: Include recent work where relevant

### Example Bibliography Entry
```bibtex
@article{author2023,
  title={Title of the Paper},
  author={Author, A. and Coauthor, B.},
  journal={Journal Name},
  volume={42},
  number={3},
  pages={123--145},
  year={2023},
  publisher={Publisher Name}
}
```

## 📁 File Organization

### Directory Structure
```
paper/
├── main.tex
├── sections/
│   ├── introduction.tex
│   ├── theoretical_framework.tex
│   ├── empirical_validation.tex
│   ├── results.tex
│   ├── discussion.tex
│   ├── mathematical_appendix.tex
│   └── conclusion.tex
├── tables/
│   ├── table_1_descriptive_name.tex
│   └── table_2_descriptive_name.tex
├── figures/
│   ├── figure_1_descriptive_name.png
│   ├── figure_1_descriptive_name.eps
│   └── ...
├── scripts/
│   ├── generate_figure_1_descriptive_name.m
│   └── generate_figure_2_descriptive_name.m
├── references/
│   └── references.bib
└── README.md
```

### File Management
- **Version control**: Use Git for version control
- **Backup**: Regular backups of important files
- **Naming**: Descriptive, consistent file names
- **Organization**: Logical grouping of related files

## 🔧 Compilation and Quality Control

### Pre-Compilation Checklist
- [ ] All Greek letters properly formatted (`$\kappa$`, `$\rho$`, etc.)
- [ ] British English spelling throughout
- [ ] No equations in abstract
- [ ] All figures and tables referenced
- [ ] All citations properly formatted
- [ ] Consistent mathematical notation

### Compilation Process
1. **Initial compilation**: `pdflatex main.tex`
2. **Bibliography**: `bibtex main`
3. **Final compilation**: `pdflatex main.tex` (twice)
4. **Check output**: Review PDF for formatting issues

### Quality Control
- **Spell check**: Use LaTeX spell checkers
- **Grammar check**: Manual review of text
- **Mathematical accuracy**: Verify all equations
- **Reference accuracy**: Check all citations
- **Figure quality**: Ensure high-resolution output

### Common Issues and Solutions
- **Missing packages**: Add required packages to preamble
- **Figure not found**: Check file paths and extensions
- **Citation errors**: Verify BibTeX entries
- **Math formatting**: Use proper LaTeX syntax
- **Page breaks**: Use `\newpage` or `\clearpage` appropriately

## 📝 Writing Guidelines

### Section Structure
- **Clear headings**: Use descriptive section titles
- **Logical flow**: Each section should build on previous ones
- **Consistent depth**: Similar level of detail across sections
- **Transitions**: Smooth transitions between sections

### Narrative Flow and Engagement
- **Minimize bullet points**: Replace bullet points with flowing narrative text
- **Linking sentences**: Add transitional sentences between sections
- **Reduce repetition**: Reference first instances instead of repeating concepts
- **Concise writing**: Avoid unnecessary words and redundancy
- **Engaging tone**: Present findings in an interesting and compelling manner
- **Modest claims**: Avoid overstating contributions; let readers decide significance

### Mathematical Writing
- **Define variables**: Always define mathematical symbols
- **Explain notation**: Provide context for complex expressions
- **Step-by-step**: Break down complex derivations
- **Examples**: Provide concrete examples where helpful

### Academic Writing
- **Objective tone**: Avoid personal opinions
- **Evidence-based**: Support claims with data
- **Precise language**: Use exact terminology
- **Concise writing**: Avoid unnecessary words
- **Reference previous work**: Use "see equation (1)" instead of repeating formulas
- **Linking phrases**: Use "Building upon...", "Following...", "Drawing together..."

## 🎯 Final Checklist

### Before Submission
- [ ] All mathematical notation properly formatted
- [ ] British English throughout
- [ ] No equations in abstract
- [ ] All figures and tables present and properly formatted
- [ ] All references properly cited
- [ ] Consistent terminology
- [ ] Professional appearance
- [ ] Error-free compilation
- [ ] High-quality figures
- [ ] Well-structured tables
- [ ] Minimal bullet points (narrative flow)
- [ ] Linking sentences between sections
- [ ] Reduced repetition (reference first instances)
- [ ] Engaging and concise writing
- [ ] Modest claims (no overstatement)

### Post-Compilation Review
- [ ] PDF renders correctly
- [ ] All figures display properly
- [ ] All tables format correctly
- [ ] All citations link properly
- [ ] Page numbers are correct
- [ ] No orphaned text
- [ ] Consistent formatting throughout

## 📚 Additional Resources

### LaTeX Resources
- [Overleaf Documentation](https://www.overleaf.com/learn)
- [LaTeX Wikibook](https://en.wikibooks.org/wiki/LaTeX)
- [MathJax Documentation](https://docs.mathjax.org/)

### Academic Writing
- [Academic Writing Guidelines](https://www.scribbr.com/academic-writing/)
- [Scientific Writing Best Practices](https://www.nature.com/scitable/topicpage/scientific-writing-974154/)

### Figure Creation
- [MATLAB Plotting Guide](https://www.mathworks.com/help/matlab/ref/plot.html)
- [Python Matplotlib Guide](https://matplotlib.org/stable/tutorials/index.html)

---

**Last Updated**: December 2024  
**Version**: 1.0  
**Maintained by**: Research Team
