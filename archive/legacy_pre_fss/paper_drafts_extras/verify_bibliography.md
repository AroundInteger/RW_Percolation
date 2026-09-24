# Bibliography Verification Guide

## 🎯 **Problem**
The references in the introduction aren't showing because LaTeX needs to be compiled to process the bibliography.

## ✅ **Solution**

### **Step 1: Install LaTeX**
- **Mac**: Download and install MacTeX from https://www.tug.org/mactex/
- **Windows**: Download and install MiKTeX from https://miktex.org/
- **Linux**: Install texlive-full: `sudo apt-get install texlive-full`

### **Step 2: Compile the Document**
Run these commands in the `paper_drafts` directory:

```bash
# First pass - processes the document and creates .aux file
pdflatex main.tex

# Process bibliography - creates .bbl file
bibtex main

# Second pass - incorporates bibliography
pdflatex main.tex

# Third pass - resolves cross-references
pdflatex main.tex
```

### **Step 3: Check Output**
After compilation, you should see:
- `main.pdf` with properly formatted references
- References numbered in the text (e.g., [1,2,3])
- Bibliography section at the end with full citations

### **Step 4: Verify References**
The introduction should now show:
- `\cite{Stauffer1992,Ben-Avraham2000}` → [1,2]
- `\cite{Chambon1987,Muthukumar1989}` → [3,4]
- `\cite{Mason1995,Mason2000}` → [5,6]
- `\cite{Saxton1994,deBruyn2013}` → [7,8]

## 🔍 **Troubleshooting**

### **If References Still Don't Show:**
1. Check that `references_enhanced.bib` exists in the same directory
2. Verify the file has proper BibTeX format
3. Check for any error messages during compilation
4. Ensure all citation keys exist in the bibliography file

### **If Compilation Fails:**
1. Check for missing packages
2. Verify LaTeX installation is complete
3. Check for syntax errors in the .tex files
4. Look for missing files or incorrect paths

## 📝 **Expected Output**

After successful compilation, the introduction should look like:

> "Percolation theory describes the emergence of long-range connectivity in random systems as a function of occupation probability p [1,2]. In the context of viscoelastic materials, this translates to the formation of a spanning cluster that imparts solid-like properties to the system. The critical percolation threshold pc ≈ 0.3116 for 3D site percolation represents the point where a spanning cluster first appears, while the apparent gel-point pc' ≈ 0.6884 represents the point where the system exhibits significant viscoelastic response [3,4]."

## 🎉 **Success Indicators**

- References appear as numbered citations in the text
- Bibliography section shows full citations at the end
- No "undefined citation" warnings
- PDF compiles without errors

---

*Once LaTeX is installed and the document is compiled, the references will appear correctly!*
