# MCAS vs Double-Collect Presentation

This folder contains a LaTeX Beamer presentation explaining the performance trade-offs between MCAS-based and double-collect atomic snapshot implementations.

## Files

- `mcas_presentation.tex`: Main LaTeX presentation source
- `compile_presentation.sh`: Script to compile the presentation to PDF
- `assets/`: Generated benchmark charts and figures
- `data/`: Raw benchmark results and metadata

## Compilation

### Prerequisites

- LaTeX distribution (TeX Live, MiKTeX, etc.)
- Beamer class
- Standard LaTeX packages (graphicx, tikz, pgfplots, etc.)

### Building the Presentation

```bash
# Option 1: Use the provided script
./compile_presentation.sh

# Option 2: Manual compilation
pdflatex mcas_presentation.tex
pdflatex mcas_presentation.tex  # Run twice for references
```

## Presentation Structure

1. **Introduction**: Research question and background
2. **Implementations**: Double-collect vs MCAS algorithms
3. **Benchmark Setup**: Experimental parameters
4. **Results**: Performance comparison across workloads
5. **Analysis**: Trade-off discussion and quantitative analysis
6. **Conclusion**: Key takeaways and implications

## Key Figures Included

- Benchmark overview (all workloads)
- Relative performance comparison
- Workload-specific analysis (100% updates, 50/50, scan-heavy)
- Quantitative performance tables

## Academic Theme

The presentation uses:
- Beamer Madrid theme (research-oriented)
- Beaver color scheme (professional)
- Academic formatting and structure
- Clear visual hierarchy for educational purposes