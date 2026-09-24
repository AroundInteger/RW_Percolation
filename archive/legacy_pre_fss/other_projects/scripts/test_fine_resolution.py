#!/usr/bin/env python3
"""
Test version of fine resolution MSD generation with smaller parameters
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import os
from pathlib import Path
import time
from datetime import datetime

# Import functions from the main script
from generate_fine_resolution_msd import (
    rw3d_p_sp_matlab_style,
    generate_3d_lattice,
    run_single_simulation,
    simple_local_alpha_analysis,
    find_changepoint,
    analyze_fine_resolution_results,
    plot_fine_resolution_results
)

def test_fine_resolution_msd(p_c_prime=0.6884, transition_width=0.05, resolution=0.02):
    """
    Test version with smaller parameters
    """
    print("=== Test Fine Resolution MSD Generation ===")
    print(f"Critical point: p_c' = {p_c_prime}")
    print(f"Transition width: ±{transition_width}")
    print(f"Resolution: {resolution}")
    print()
    
    # Smaller parameters for testing
    L = 50  # Smaller lattice
    LW = 10000  # Fewer steps
    NW = 5  # Fewer walkers
    
    # Define p values with fine resolution in transition region
    p_min = max(0, p_c_prime - transition_width)
    p_max = min(1, p_c_prime + transition_width)
    
    # Create test p values
    p_values = []
    
    # Coarse resolution outside transition region
    p_values.extend([0.0, 0.1, 0.2, 0.3])
    p_values.append(p_min)
    
    # Fine resolution in transition region
    p_values.extend(np.arange(p_min + resolution, p_max, resolution))
    p_values.append(p_max)
    
    # Coarse resolution beyond transition region
    p_values.extend([0.8, 0.9])
    
    p_values = np.array(p_values)
    p_values = p_values[p_values <= 0.95]  # Avoid p = 1.0
    
    print(f"Total p values: {len(p_values)}")
    print(f"p range: [{p_values.min():.4f}, {p_values.max():.4f}]")
    print(f"p values: {p_values}")
    print()
    
    # Results storage
    results = {
        'p_values': [],
        'tau_cr': [],
        'alpha_opt': [],
        'alpha_error': [],
        'regime': [],
        'distance_from_critical': []
    }
    
    # Run simulations
    start_time = time.time()
    
    for i, p in enumerate(p_values):
        print(f"Progress: {i+1}/{len(p_values)} ({(i+1)/len(p_values)*100:.1f}%)")
        
        # Run simulation
        t, msd, bw = run_single_simulation(L, LW, NW, p, seed=42+i, save_data=True, output_dir="test_fine_resolution_data")
        
        if t is None:
            print(f"  Skipping p = {p:.4f} (insufficient free space)")
            continue
        
        # Analyze α and find changepoint
        tau_alpha, alpha_values, alpha_errors = simple_local_alpha_analysis(t, msd)
        tau_cr, alpha_opt, alpha_error = find_changepoint(tau_alpha, alpha_values, alpha_errors)
        
        # Determine regime
        if p < p_c_prime - 0.05:
            regime = 'LIQUID'
        elif abs(p - p_c_prime) < 0.05:
            regime = 'CRITICAL'
        else:
            regime = 'SOLID'
        
        # Store results
        results['p_values'].append(p)
        results['tau_cr'].append(tau_cr if tau_cr is not None else np.nan)
        results['alpha_opt'].append(alpha_opt if alpha_opt is not None else np.nan)
        results['alpha_error'].append(alpha_error if alpha_error is not None else np.nan)
        results['regime'].append(regime)
        results['distance_from_critical'].append(abs(p - p_c_prime))
        
        # Print summary
        if tau_cr is not None:
            print(f"  p = {p:.4f} ({regime}): τ_cr = {tau_cr:.2e}, α = {alpha_opt:.3f}, error = {alpha_error:.3f}")
        else:
            print(f"  p = {p:.4f} ({regime}): No changepoint found")
    
    elapsed_time = time.time() - start_time
    print(f"\nTotal time: {elapsed_time/60:.2f} minutes")
    
    # Convert to DataFrame
    results_df = pd.DataFrame(results)
    
    # Save results
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    results_filename = f"test_fine_resolution_results_{timestamp}.csv"
    results_df.to_csv(results_filename, index=False)
    print(f"Results saved to: {results_filename}")
    
    return results_df, p_values

def main():
    """
    Main function for test fine resolution MSD generation
    """
    print("=== Test Fine Resolution MSD Generation ===")
    print("This is a test version with smaller parameters")
    print("This should take a few minutes to complete")
    print()
    
    # Parameters
    p_c_prime = 0.6884  # Critical point
    transition_width = 0.05  # Smaller transition width
    resolution = 0.02  # Coarser resolution for testing
    
    # Generate test fine resolution MSD curves
    results_df, p_values = test_fine_resolution_msd(
        p_c_prime=p_c_prime,
        transition_width=transition_width,
        resolution=resolution
    )
    
    # Analyze results
    exponent, r_squared = analyze_fine_resolution_results(results_df, p_c_prime)
    
    # Plot results
    plot_fine_resolution_results(results_df, p_c_prime)
    
    print("\n=== Test Analysis Complete ===")
    if exponent is not None:
        print(f"Power-law exponent: ν = {exponent:.3f}")
        print(f"R² = {r_squared:.3f}")
        print(f"Equation: τ_cr ∝ |p - p_c'|^{exponent:.3f}")
    else:
        print("Could not determine power-law exponent (insufficient data)")
    
    return results_df, exponent, r_squared

if __name__ == "__main__":
    main() 