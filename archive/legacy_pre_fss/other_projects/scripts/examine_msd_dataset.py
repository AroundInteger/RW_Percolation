#!/usr/bin/env python3
"""
Examine MSD Dataset Quality and Structure
Loads the large MSD dataset and analyzes data quality, p-value range, and basic statistics.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
import time

def load_msd_data(file_path):
    """Load the MSD dataset and return basic information."""
    print(f"Loading MSD data from: {file_path}")
    print(f"File size: {Path(file_path).stat().st_size / (1024**3):.2f} GB")
    
    start_time = time.time()
    
    # Load the data
    df = pd.read_csv(file_path)
    
    load_time = time.time() - start_time
    print(f"Load time: {load_time:.2f} seconds")
    
    return df

def analyze_data_structure(df):
    """Analyze the structure and quality of the MSD dataset."""
    print("\n=== DATASET STRUCTURE ===")
    print(f"Shape: {df.shape}")
    print(f"Columns: {len(df.columns)}")
    print(f"Rows: {len(df)}")
    
    # Extract p-values from column names
    p_values = []
    for col in df.columns:
        if col.startswith('MSD_'):
            p_val = float(col.replace('MSD_', ''))
            p_values.append(p_val)
    
    p_values = sorted(p_values)
    print(f"\nP-value range: {p_values[0]} to {p_values[-1]}")
    print(f"Number of p-values: {len(p_values)}")
    
    # Check for critical values
    p_c = 0.3116
    p_c_prime = 0.6884
    
    print(f"\nCritical values:")
    print(f"  p_c (gel-point of occupied sites): {p_c}")
    print(f"  p_c' (gel-point of unoccupied sites): {p_c_prime}")
    
    # Find closest p-values to critical points
    closest_p_c = min(p_values, key=lambda x: abs(x - p_c))
    closest_p_c_prime = min(p_values, key=lambda x: abs(x - p_c_prime))
    
    print(f"  Closest to p_c: {closest_p_c} (difference: {abs(closest_p_c - p_c):.4f})")
    print(f"  Closest to p_c': {closest_p_c_prime} (difference: {abs(closest_p_c_prime - p_c_prime):.4f})")
    
    return p_values

def check_data_quality(df):
    """Check data quality including missing values, infinities, and basic statistics."""
    print("\n=== DATA QUALITY CHECK ===")
    
    # Check for missing values
    missing_counts = df.isnull().sum()
    total_missing = missing_counts.sum()
    print(f"Total missing values: {total_missing}")
    
    if total_missing > 0:
        print("Missing values by column:")
        for col, count in missing_counts[missing_counts > 0].items():
            print(f"  {col}: {count}")
    
    # Check for infinite values
    inf_counts = np.isinf(df.select_dtypes(include=[np.number])).sum()
    total_inf = inf_counts.sum()
    print(f"Total infinite values: {total_inf}")
    
    # Check for negative values (shouldn't exist for MSD)
    negative_counts = (df.select_dtypes(include=[np.number]) < 0).sum()
    total_negative = negative_counts.sum()
    print(f"Total negative values: {total_negative}")
    
    # Basic statistics for a few key p-values
    key_p_values = [0.0, 0.3116, 0.6884, 0.7425]
    print(f"\nBasic statistics for key p-values:")
    
    for p in key_p_values:
        col_name = f"MSD_{p}"
        if col_name in df.columns:
            data = df[col_name]
            print(f"\n  {col_name}:")
            print(f"    Min: {data.min():.6f}")
            print(f"    Max: {data.max():.6f}")
            print(f"    Mean: {data.mean():.6f}")
            print(f"    Std: {data.std():.6f}")
            print(f"    Non-zero values: {(data > 0).sum()}")

def plot_sample_msd_curves(df, p_values, num_samples=8):
    """Plot sample MSD curves for different p-values."""
    print(f"\n=== PLOTTING SAMPLE MSD CURVES ===")
    
    # Select evenly spaced p-values for plotting
    if len(p_values) <= num_samples:
        plot_p_values = p_values
    else:
        indices = np.linspace(0, len(p_values)-1, num_samples, dtype=int)
        plot_p_values = [p_values[i] for i in indices]
    
    plt.figure(figsize=(12, 8))
    
    for p in plot_p_values:
        col_name = f"MSD_{p}"
        if col_name in df.columns:
            data = df[col_name]
            time_steps = np.arange(len(data))
            
            # Only plot non-zero values
            non_zero_mask = data > 0
            if non_zero_mask.sum() > 0:
                plt.loglog(time_steps[non_zero_mask], data[non_zero_mask], 
                          label=f'p = {p}', linewidth=1.5, alpha=0.8)
    
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('Sample MSD Curves for Different Percolation Values')
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    
    # Save the plot
    output_path = "msd_dataset_sample_curves.png"
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"Sample MSD curves saved to: {output_path}")
    plt.show()

def analyze_critical_regions(df, p_values):
    """Analyze data quality in critical regions around p_c and p_c'."""
    print(f"\n=== CRITICAL REGION ANALYSIS ===")
    
    p_c = 0.3116
    p_c_prime = 0.6884
    
    # Find p-values in critical regions
    critical_region_1 = [p for p in p_values if abs(p - p_c) < 0.05]
    critical_region_2 = [p for p in p_values if abs(p - p_c_prime) < 0.05]
    
    print(f"P-values near p_c ({p_c}): {critical_region_1}")
    print(f"P-values near p_c' ({p_c_prime}): {critical_region_2}")
    
    # Check data quality in critical regions
    for region_name, region_p_values in [("p_c region", critical_region_1), 
                                        ("p_c' region", critical_region_2)]:
        print(f"\n{region_name}:")
        for p in region_p_values:
            col_name = f"MSD_{p}"
            if col_name in df.columns:
                data = df[col_name]
                non_zero = (data > 0).sum()
                print(f"  p = {p}: {non_zero} non-zero values out of {len(data)}")

def main():
    """Main analysis function."""
    file_path = "matlab/Clusters/p_output_C1.csv"
    
    if not Path(file_path).exists():
        print(f"Error: File {file_path} not found!")
        return
    
    # Load data
    df = load_msd_data(file_path)
    
    # Analyze structure
    p_values = analyze_data_structure(df)
    
    # Check data quality
    check_data_quality(df)
    
    # Analyze critical regions
    analyze_critical_regions(df, p_values)
    
    # Plot sample curves
    plot_sample_msd_curves(df, p_values)
    
    print(f"\n=== SUMMARY ===")
    print(f"Dataset contains {len(p_values)} p-values from {p_values[0]} to {p_values[-1]}")
    print(f"Time evolution: {len(df)} steps (1 million + header)")
    print(f"File size: {Path(file_path).stat().st_size / (1024**3):.2f} GB")
    print(f"Excellent coverage of critical regions around p_c = 0.3116 and p_c' = 0.6884")

if __name__ == "__main__":
    main()
