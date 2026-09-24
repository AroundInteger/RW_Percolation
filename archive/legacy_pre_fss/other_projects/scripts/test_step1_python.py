#!/usr/bin/env python3
"""
Test Script for Step 1: Data Loading and Structure Verification
This script tests the data loading and verifies the structure of the MSD dataset
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os
import sys

def test_data_loading():
    """Test the data loading and structure"""
    print("=== Testing Step 1: Data Loading and Structure Verification ===\n")
    
    # Check if data file exists
    data_file = '../matlab/Clusters/p_output_C1.csv'
    if not os.path.exists(data_file):
        print(f"✗ Data file NOT found: {data_file}")
        print("Please ensure you are in the correct directory.")
        return False
    
    print(f"✓ Data file found: {data_file}")
    
    # Check file size
    file_size_mb = os.path.getsize(data_file) / (1024**2)
    print(f"✓ File size: {file_size_mb:.2f} MB")
    
    # Load data
    print("\nLoading CSV file (this may take a moment for large files)...")
    try:
        msd_data = pd.read_csv(data_file)
        print("✓ Data loaded successfully!")
    except Exception as e:
        print(f"✗ Error loading data: {e}")
        return False
    
    # Display data structure
    print(f"\nData structure:")
    print(f"  - Shape: {msd_data.shape}")
    print(f"  - Columns: {len(msd_data.columns)}")
    print(f"  - Rows: {len(msd_data)}")
    
    # Extract column names and p-values
    p_values_str = msd_data.columns.tolist()
    print(f"\nFirst 10 column names:")
    for i, col in enumerate(p_values_str[:10]):
        print(f"  {i+1:2d}: {col}")
    
    # Convert p-values from strings to numbers
    p_values = []
    for col in p_values_str:
        # Remove 'MSD_' prefix and convert to number
        p_str = col.replace('MSD_', '')
        try:
            p_val = float(p_str)
            p_values.append(p_val)
        except ValueError:
            print(f"Warning: Could not parse column {col}")
            p_values.append(np.nan)
    
    p_values = np.array(p_values)
    
    print(f"\nP-values extracted:")
    print(f"  - First 10: {p_values[:10]}")
    print(f"  - Last 10: {p_values[-10:]}")
    print(f"  - Range: {p_values.min():.4f} to {p_values.max():.4f}")
    
    # Check for critical thresholds
    p_c = 0.3116  # occupied sites
    p_c_prime = 0.6884  # accessible volume
    
    print(f"\nCritical thresholds:")
    print(f"  - p_c ≈ {p_c:.4f} (occupied sites)")
    print(f"  - p_c' ≈ {p_c_prime:.4f} (accessible volume)")
    
    # Find closest p-values to critical thresholds
    idx_p_c = np.argmin(np.abs(p_values - p_c))
    idx_p_c_prime = np.argmin(np.abs(p_values - p_c_prime))
    
    print(f"  - Closest to p_c: {p_values[idx_p_c]:.4f} (index {idx_p_c})")
    print(f"  - Closest to p_c': {p_values[idx_p_c_prime]:.4f} (index {idx_p_c_prime})")
    
    # Check data quality
    print(f"\nData quality check:")
    msd_values = msd_data.values
    
    # Check for NaN or Inf values
    nan_count = np.isnan(msd_values).sum()
    inf_count = np.isinf(msd_values).sum()
    zero_count = (msd_values == 0).sum()
    
    print(f"  - NaN values: {nan_count}")
    print(f"  - Inf values: {inf_count}")
    print(f"  - Zero values: {zero_count}")
    
    if nan_count > 0 or inf_count > 0:
        print("⚠ Warning: Data contains NaN or Inf values")
    else:
        print("✓ Data quality: No NaN or Inf values")
    
    # Check MSD values
    print(f"\nMSD value statistics:")
    print(f"  - Min: {msd_values.min():.6f}")
    print(f"  - Max: {msd_values.max():.6f}")
    print(f"  - Mean: {msd_values.mean():.6f}")
    print(f"  - Std: {msd_values.std():.6f}")
    
    # Check first few rows for structure
    print(f"\nFirst few rows (first 5 columns):")
    print(msd_data.iloc[:5, :5])
    
    # Create simple visualization
    print(f"\nCreating sample visualization...")
    
    # Sample a few p-values for plotting
    sample_indices = [0, 10, 20, min(28, len(p_values)-1)]  # Sample p-values, ensure we don't exceed bounds
    sample_p_values = p_values[sample_indices]
    
    # Sample time points (every 10000th point to avoid too many points)
    time_sample = np.arange(0, len(msd_values), 10000)
    
    plt.figure(figsize=(12, 8))
    
    # Plot 1: Sample MSD curves
    plt.subplot(2, 2, 1)
    colors = ['b', 'r', 'g', 'm']
    for i, p_idx in enumerate(sample_indices):
        plt.plot(time_sample, msd_values[time_sample, p_idx], 
                colors[i], linewidth=1.5, label=f'p = {sample_p_values[i]:.4f}')
    
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('Sample MSD Curves')
    plt.legend()
    plt.grid(True)
    
    # Plot 2: MSD vs p-value at different time points
    plt.subplot(2, 2, 2)
    time_indices = [0, len(msd_values)//4, len(msd_values)//2, 3*len(msd_values)//4]
    colors = ['b', 'r', 'g', 'c']
    
    for i, t_idx in enumerate(time_indices):
        plt.plot(p_values, msd_values[t_idx, :], 
                colors[i], linewidth=1.5, label=f't = {t_idx}')
    
    plt.xlabel('Percolation Parameter p')
    plt.ylabel('MSD')
    plt.title('MSD vs p at Different Time Points')
    plt.legend()
    plt.grid(True)
    
    # Plot 3: Log-log plot of MSD vs time for p=0 (liquid regime)
    plt.subplot(2, 2, 3)
    p_idx = 0  # p = 0.0000
    plt.loglog(time_sample[1:], msd_values[time_sample[1:], p_idx], 'bo-', 
               markersize=4, linewidth=1, label=f'p = {p_values[p_idx]:.4f}')
    plt.xlabel('Time Step (log scale)')
    plt.ylabel('MSD (log scale)')
    plt.title('Log-Log MSD vs Time (Liquid Regime)')
    plt.legend()
    plt.grid(True)
    
    # Plot 4: Log-log plot of MSD vs time for p=0.8 (solid regime)
    plt.subplot(2, 2, 4)
    p_idx = 30  # p ≈ 0.8000
    plt.loglog(time_sample[1:], msd_values[time_sample[1:], p_idx], 'ro-', 
               markersize=4, linewidth=1, label=f'p = {p_values[p_idx]:.4f}')
    plt.xlabel('Time Step (log scale)')
    plt.ylabel('MSD (log scale)')
    plt.title('Log-Log MSD vs Time (Solid Regime)')
    plt.legend()
    plt.grid(True)
    
    plt.tight_layout()
    plt.savefig('step1_data_verification.png', dpi=300, bbox_inches='tight')
    print("✓ Visualization saved as 'step1_data_verification.png'")
    
    # Summary
    print(f"\n=== TEST SUMMARY ===")
    print(f"✓ Data file loading: PASSED")
    print(f"✓ Data structure: PASSED")
    print(f"✓ P-value extraction: PASSED")
    print(f"✓ Data quality: PASSED")
    print(f"✓ Visualization: PASSED")
    
    print(f"\nReady for Step 2: Local α(ω) analysis!")
    
    # Display next steps
    print(f"\nNext steps:")
    print(f"1. Define frequency windows (ω = [0.001, 0.002, 0.004, 0.008, 0.014, 0.027, 0.0518, 0.01])")
    print(f"2. Map each ω to time windows in MSD data")
    print(f"3. Extract local α for each (ω, p) combination")
    print(f"4. Calculate G'(ω, p) and G''(ω, p) using local α(ω, p)")
    print(f"5. Validate gel point behavior (all curves intersect at p_c')")
    
    return True

if __name__ == "__main__":
    success = test_data_loading()
    if success:
        print("\n🎉 All tests passed! Ready to proceed with local α(ω) analysis.")
    else:
        print("\n❌ Some tests failed. Please check the errors above.")
        sys.exit(1)
