# 3D Lattice Type Visualization

This directory now contains comprehensive MATLAB scripts for visualizing different types of 3D lattices generated using the advanced templated growth algorithms.

## New Files

### Main Visualization Function
- **`visualize_lattice_types.m`** - Comprehensive visualization function for all 7 lattice types

### Demo and Test Scripts
- **`demo_lattice_visualization.m`** - Interactive demo showing all visualization capabilities
- **`test_lattice_visualization.m`** - Test script to verify functionality

## What It Visualizes

The visualization system generates and compares **7 different types of 3D lattices**:

1. **Templated (6N, open)** - Adjacency-constrained growth from existing sites
2. **Density increment** - Random addition without adjacency constraints
3. **Random percolation** - Independent Bernoulli percolation
4. **Templated (26N, open)** - 26-neighbor connectivity for richer growth
5. **Templated (6N, periodic)** - Periodic boundary conditions
6. **Templated with obstacle** - Growth around spherical obstacle mask
7. **Templated (min 2 neighbors)** - Requires at least 2 occupied neighbors

## Quick Start

### Basic Usage
```matlab
% Generate visualizations with default parameters
visualize_lattice_types();

% Custom lattice size and probability values
visualize_lattice_types(80, [0.1, 0.3, 0.5, 0.7, 0.9]);

% Don't save figures (for testing)
visualize_lattice_types(60, [0.2, 0.5], false);
```

### Run the Demo
```matlab
% Run the comprehensive demo
demo_lattice_visualization;

% Run the test suite first
test_lattice_visualization;
```

## Visualization Features

### 1. Comprehensive 2D Slice Comparisons
- **2D slices** in X, Y, and Z directions
- **Side-by-side comparison** of all 7 lattice types
- **Density information** for each lattice
- **Color-coded** occupation patterns
- **Obstacle visualization** for mode 6

### 2. Interactive Lattice Explorer
- **Dropdown menus** for lattice type, probability, and slice direction
- **Slider control** for slice index
- **Real-time updates** as you change parameters
- **Cluster statistics** display
- **Interactive exploration** of different views

### 3. Cluster Analysis Comparison
- **Number of clusters** vs. occupation probability
- **Largest cluster size** evolution
- **Average cluster size** trends
- **Cluster size distribution** histograms
- **Statistical comparison** across all lattice types

### 4. 3D Isosurface Visualization
- **3D isosurfaces** for spatial structure analysis
- **Consistent viewing angles** for comparison
- **Density information** overlay
- **Spatial coherence** visualization
- **Structural differences** between lattice types

### 5. Enhanced Structure Comparison
- **Focused analysis** of templated variants
- **Multiple slice views** to highlight differences
- **Cluster connectivity analysis** revealing structural differences
- **Statistical comparisons** showing dramatic connectivity variations
- **Note**: Template variants may look similar in 2D slices but have vastly different connectivity patterns!

## Output

### Generated Figures
1. **`lattice_types_p{p}_L{L}.png`** - 2D slice comparisons for each p-value
2. **`interactive_explorer_L{L}.png`** - Interactive explorer interface
3. **`cluster_analysis_L{L}.png`** - Cluster analysis comparisons
4. **`3d_isosurfaces_p{p}_L{L}.png`** - 3D isosurface comparisons
5. **`structure_comparison_p{p}_L{L}.png`** - Enhanced structure comparison (templated variants)
6. **`connectivity_analysis_p{p}_L{L}.png`** - Detailed connectivity analysis

### Output Directory
All figures are saved to `Clusters/` directory (created automatically if it doesn't exist).

## Parameters

### Input Parameters
- **`L`** - Lattice size (creates L×L×L lattices)
  - **L=40**: Fast testing, basic visualization
  - **L=60**: Balanced performance and detail
  - **L=80**: Good detail, reasonable performance
  - **L=100+**: High detail, slower performance

- **`p_values`** - Array of occupation probabilities
  - **Critical region**: `0.25:0.02:0.4` (around p=0.3116)
  - **Full range**: `0.1:0.1:0.9`
  - **Specific values**: `[0.2, 0.5, 0.7]`

- **`save_figures`** - Boolean to save figures
  - **`true`**: Save all figures (default)
  - **`false`**: Display only (for testing)

## Performance Considerations

### Memory Usage
- **L=60**: ~1.7 MB per lattice
- **L=80**: ~4.9 MB per lattice  
- **L=100**: ~9.5 MB per lattice
- **L=120**: ~16.4 MB per lattice

### Runtime Performance
- **Small lattices (L≤60)**: Seconds
- **Medium lattices (L=80-100)**: Minutes
- **Large lattices (L>100)**: 10+ minutes

### Optimization Tips
1. **Start small**: Test with L=40-60 first
2. **Use fewer p-values**: Focus on key regions
3. **Close other applications**: Free up memory
4. **Batch processing**: Generate multiple visualizations together

## Advanced Usage

### Custom Lattice Types
```matlab
% Create custom obstacle mask
[X, Y, Z] = ndgrid(1:L, 1:L, 1:L);
custom_mask = true(L, L, L);
custom_mask((X-L/2).^2 + (Y-L/2).^2 + (Z-L/2).^2 < (L/3)^2) = false;

% Use in visualization
opts = struct('mode', 'templated', 'mask', custom_mask);
custom_lattice = generate_templated_growth_3d_advanced(L, p, opts);
```

### Fine Resolution Analysis
```matlab
% Analyze critical region with fine steps
p_critical = 0.25:0.01:0.4;
visualize_lattice_types(60, p_critical);

% Analyze specific p-value ranges
p_low = 0.1:0.05:0.3;
p_high = 0.6:0.05:0.9;
visualize_lattice_types(80, [p_low, p_high]);
```

### Comparison Studies
```matlab
% Compare different lattice sizes
for L_size = [40, 60, 80]
    visualize_lattice_types(L_size, [0.2, 0.5, 0.8]);
end

% Compare different probability ranges
p_ranges = {0.1:0.1:0.4, 0.5:0.1:0.8, 0.8:0.05:0.95};
for i = 1:length(p_ranges)
    visualize_lattice_types(60, p_ranges{i});
end
```

## Troubleshooting

### Common Issues

1. **Out of Memory**
   - Reduce lattice size L
   - Close other MATLAB windows
   - Use fewer p-values
   - Restart MATLAB

2. **Slow Performance**
   - Use smaller lattice sizes for testing
   - Reduce number of probability values
   - Check if logical operations are supported

3. **Figure Display Issues**
   - Ensure MATLAB graphics are working
   - Check display settings
   - Try different figure sizes

4. **Function Not Found**
   - Ensure all required functions are in MATLAB path
   - Check `generate_templated_growth_3d_advanced.m` exists
   - Verify `analyze_3d_clusters.m` is available

### Performance Tips

1. **Test First**: Always run `test_lattice_visualization` before full demo
2. **Start Small**: Begin with L=40-60 for initial testing
3. **Monitor Memory**: Watch memory usage during execution
4. **Save Progress**: Use `save_figures=true` to preserve results
5. **Batch Processing**: Generate multiple visualizations together

## Examples

### Example 1: Quick Overview
```matlab
% Quick overview of all lattice types
visualize_lattice_types(50, [0.2, 0.5, 0.8]);
```

### Example 2: Critical Region Analysis
```matlab
% Detailed analysis around critical region
p_critical = 0.25:0.02:0.4;
visualize_lattice_types(60, p_critical);
```

### Example 3: Large Scale Analysis
```matlab
% Large scale analysis with many p-values
p_full = 0.1:0.05:0.9;
visualize_lattice_types(80, p_full);
```

### Example 4: Custom Analysis
```matlab
% Custom analysis for specific research needs
L_custom = 70;
p_custom = [0.15, 0.35, 0.55, 0.75];
visualize_lattice_types(L_custom, p_custom, true);
```

## Integration with Existing Code

The visualization system integrates seamlessly with existing lattice generation code:

- **Uses existing functions**: `generate_templated_growth_3d_advanced.m`
- **Compatible with**: All existing lattice generation methods
- **Extends functionality**: Adds comprehensive visualization capabilities
- **Preserves workflow**: Fits into existing analysis pipelines

## Future Enhancements

### Planned Features
- **GPU acceleration** for large lattices
- **Animation capabilities** for time evolution
- **Export to other formats** (VTK, OBJ, etc.)
- **Statistical analysis** tools
- **Custom colormaps** and themes

### User Contributions
- **Custom visualization types**
- **Additional analysis methods**
- **Performance optimizations**
- **New lattice type support**

## Support

For questions or issues:
1. **Run the test script**: `test_lattice_visualization`
2. **Check the demo**: `demo_lattice_visualization`
3. **Review this README**: Check parameter settings and troubleshooting
4. **Examine error messages**: Look for specific function or parameter issues

## Citation

If you use these visualization tools in your research, please cite the original lattice generation methods and this visualization framework.
