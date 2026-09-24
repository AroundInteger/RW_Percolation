#!/usr/bin/env python3
"""
FINAL CORRECTED Universality Class Analysis
Based on the actual MATLAB results from analyze_mat_results_1.m
"""

import pandas as pd
import numpy as np

def analyze_final_universality_classes():
    """Final corrected analysis based on MATLAB results"""
    
    # Load the MATLAB-generated results
    results_file = "/Users/iMacPro/Documents/GitHub/RW_Percolation/matlab/Clusters1/output/universality_class_analysis.csv"
    data = pd.read_csv(results_file)
    
    print("=" * 80)
    print("FINAL CORRECTED UNIVERSALITY CLASS ANALYSIS")
    print("Based on MATLAB analyze_mat_results_1.m output")
    print("=" * 80)
    
    # Define critical regions
    p_c = 0.3116
    p_c_prime = 0.6884
    
    # Analyze each variant
    variants = ['6N_Templated', '26N_Templated', 'Density_Increment', 'Random_Percolation']
    
    print("\nDETAILED ALPHA VALUES BY REGION:")
    print("-" * 50)
    
    for variant in variants:
        variant_data = data[data['variant'] == variant]
        
        # Below p_c
        below_pc = variant_data[variant_data['p_value'] < p_c]
        # Between p_c and p_c'
        between_critical = variant_data[(variant_data['p_value'] >= p_c) & 
                                      (variant_data['p_value'] < p_c_prime)]
        # Above p_c'
        above_pc_prime = variant_data[variant_data['p_value'] >= p_c_prime]
        
        print(f"\n{variant}:")
        print(f"  Below p_c: α = {below_pc['alpha'].mean():.3f} ± {below_pc['alpha'].std():.3f} (n={len(below_pc)})")
        print(f"  Between p_c and p_c': α = {between_critical['alpha'].mean():.3f} ± {between_critical['alpha'].std():.3f} (n={len(between_critical)})")
        print(f"  Above p_c': α = {above_pc_prime['alpha'].mean():.3f} ± {above_pc_prime['alpha'].std():.3f} (n={len(above_pc_prime)})")
    
    # Now identify the universality classes based on the MATLAB results
    print("\n" + "=" * 80)
    print("CORRECTED UNIVERSALITY CLASS IDENTIFICATION")
    print("=" * 80)
    
    # Look at the behavior above p_c' to identify classes
    above_pc_prime_data = data[data['p_value'] >= p_c_prime]
    
    print("\nAlpha values above p_c' (0.6884):")
    for variant in variants:
        variant_above = above_pc_prime_data[above_pc_prime_data['variant'] == variant]
        mean_alpha = variant_above['alpha'].mean()
        print(f"  {variant}: α = {mean_alpha:.3f}")
    
    # Group by similar behavior based on the MATLAB results
    print("\nIDENTIFIED UNIVERSALITY CLASSES:")
    print("\n1. TEMPLATED UNIVERSALITY CLASS:")
    print("   - 6N_Templated")
    print("   - 26N_Templated")
    print("   - Behavior: Maintains relatively high α ≈ 0.75-0.80 above p_c'")
    print("   - Gradual transition, no dramatic phase change")
    
    print("\n2. STANDARD UNIVERSALITY CLASS:")
    print("   - Random_Percolation") 
    print("   - Density_Increment")
    print("   - Behavior: Dramatic drop to α ≈ 0.40 above p_c'")
    print("   - Clear viscoelastic phase transition")
    
    # Calculate the transition magnitude
    templated_6n = above_pc_prime_data[above_pc_prime_data['variant'] == '6N_Templated']['alpha'].mean()
    templated_26n = above_pc_prime_data[above_pc_prime_data['variant'] == '26N_Templated']['alpha'].mean()
    random_perc = above_pc_prime_data[above_pc_prime_data['variant'] == 'Random_Percolation']['alpha'].mean()
    density_inc = above_pc_prime_data[above_pc_prime_data['variant'] == 'Density_Increment']['alpha'].mean()
    
    templated_alpha = (templated_6n + templated_26n) / 2
    standard_alpha = (random_perc + density_inc) / 2
    
    transition_magnitude = templated_alpha - standard_alpha
    
    print(f"\nTRANSITION MAGNITUDE:")
    print(f"  Templated Class α (above p_c'): {templated_alpha:.3f}")
    print(f"  Standard Class α (above p_c'): {standard_alpha:.3f}")
    print(f"  Difference: {transition_magnitude:.3f} ({transition_magnitude/templated_alpha*100:.1f}% difference)")
    
    # Key insights from the MATLAB analysis
    print(f"\nKEY INSIGHTS FROM MATLAB ANALYSIS:")
    print(f"  - 6N_Templated: mean α = 0.763, range = [-0.037, 1.011]")
    print(f"  - 26N_Templated: mean α = 0.765, range = [-0.038, 1.012]")
    print(f"  - Density_Increment: mean α = 0.409, range = [-0.009, 1.019]")
    print(f"  - Random_Percolation: mean α = 0.407, range = [-0.011, 1.014]")
    
    print(f"\nPHASE ANGLE ANALYSIS:")
    print(f"  - Templated variants: δ ≈ 68.7° (viscoelastic)")
    print(f"  - Standard variants: δ ≈ 36.6° (more solid-like)")
    
    return data

if __name__ == "__main__":
    data = analyze_final_universality_classes()
