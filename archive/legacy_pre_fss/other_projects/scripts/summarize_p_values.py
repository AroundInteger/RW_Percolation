#!/usr/bin/env python3
"""
Summarize P-value Distribution
Quick analysis of the p-value spacing and distribution in the MSD dataset.
"""

import pandas as pd
import numpy as np

def analyze_p_value_distribution():
    """Analyze the p-value distribution in the MSD dataset."""
    
    # Load just the header to get column names
    df_header = pd.read_csv("matlab/Clusters/p_output_C1.csv", nrows=0)
    
    # Extract p-values
    p_values = []
    for col in df_header.columns:
        if col.startswith('MSD_'):
            p_val = float(col.replace('MSD_', ''))
            p_values.append(p_val)
    
    p_values = sorted(p_values)
    
    print("=== P-VALUE DISTRIBUTION ANALYSIS ===")
    print(f"Total p-values: {len(p_values)}")
    print(f"Range: {p_values[0]} to {p_values[-1]}")
    
    print(f"\nComplete p-value list:")
    for i, p in enumerate(p_values):
        print(f"  {i+1:2d}. {p:.4f}")
    
    # Analyze spacing
    print(f"\n=== SPACING ANALYSIS ===")
    p_diffs = np.diff(p_values)
    
    print(f"Average spacing: {np.mean(p_diffs):.4f}")
    print(f"Min spacing: {np.min(p_diffs):.4f}")
    print(f"Max spacing: {np.max(p_diffs):.4f}")
    
    print(f"\nSpacing between consecutive p-values:")
    for i in range(len(p_values)-1):
        diff = p_diffs[i]
        print(f"  {p_values[i]:.4f} → {p_values[i+1]:.4f}: {diff:.4f}")
    
    # Check critical regions
    p_c = 0.3116
    p_c_prime = 0.6884
    
    print(f"\n=== CRITICAL REGION COVERAGE ===")
    print(f"p_c = {p_c}")
    print(f"p_c' = {p_c_prime}")
    
    # Find p-values within 0.01 of critical points
    near_p_c = [p for p in p_values if abs(p - p_c) < 0.01]
    near_p_c_prime = [p for p in p_values if abs(p - p_c_prime) < 0.01]
    
    print(f"\nP-values within 0.01 of p_c: {near_p_c}")
    print(f"P-values within 0.01 of p_c': {near_p_c_prime}")
    
    # Check fine resolution around critical points
    print(f"\n=== FINE RESOLUTION CHECK ===")
    
    # Around p_c
    p_c_region = [p for p in p_values if 0.3 <= p <= 0.35]
    print(f"P-values in p_c region (0.3-0.35): {p_c_region}")
    
    # Around p_c'
    p_c_prime_region = [p for p in p_values if 0.64 <= p <= 0.74]
    print(f"P-values in p_c' region (0.64-0.74): {p_c_prime_region}")
    
    print(f"\nFine resolution in p_c' region: {len(p_c_prime_region)} p-values")
    print(f"Average spacing in p_c' region: {np.mean(np.diff(p_c_prime_region)):.4f}")

if __name__ == "__main__":
    analyze_p_value_distribution()
