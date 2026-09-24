#!/usr/bin/env python3
"""
Compare and analyze both MSD datasets:
1. matlab/Clusters/p_output_C1.csv (original)
2. matlab/p_output_NEW34.csv (new)
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os
from pathlib import Path

def examine_dataset(file_path, dataset_name):
    """Examine a single dataset and return key information"""
    print(f"\n=== EXAMINING {dataset_name} ===")
    print(f"File: {file_path}")
    
    # Check file size
    file_size = os.path.getsize(file_path) / (1024 * 1024)  # MB
    print(f"File size: {file_size:.1f} MB")
    
    # Read header to get column information
    try:
        df_header = pd.read_csv(file_path, nrows=0)
        print(f"Columns: {len(df_header.columns)}")
        
        # Extract p-values from column names
        p_values = []
        for col in df_header.columns:
            if col.startswith('MSD_'):
                try:
                    p_val = float(col.replace('MSD_', ''))
                    p_values.append(p_val)
                except ValueError:
                    print(f"Warning: Could not parse p-value from column {col}")
        
        p_values.sort()
        print(f"P-values found: {len(p_values)}")
        print(f"P-value range: {min(p_values):.4f} to {max(p_values):.4f}")
        
        # Check for critical regions
        p_c_prime = 0.6884
        critical_p_values = [p for p in p_values if abs(p - p_c_prime) < 0.05]
        print(f"Critical region p-values (|p - {p_c_prime}| < 0.05): {len(critical_p_values)}")
        if critical_p_values:
            print(f"  Critical p-values: {[f'{p:.4f}' for p in critical_p_values]}")
        
        # Sample a few rows to check data quality
        df_sample = pd.read_csv(file_path, nrows=1000)
        print(f"Sample rows: {len(df_sample)}")
        
        # Check for missing/infinite values
        missing_count = df_sample.isnull().sum().sum()
        inf_count = np.isinf(df_sample.select_dtypes(include=[np.number])).sum().sum()
        print(f"Missing values in sample: {missing_count}")
        print(f"Infinite values in sample: {inf_count}")
        
        return {
            'file_path': file_path,
            'dataset_name': dataset_name,
            'file_size_mb': file_size,
            'num_columns': len(df_header.columns),
            'p_values': p_values,
            'critical_count': len(critical_p_values)
        }
        
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return None

def compare_datasets():
    """Compare both datasets"""
    print("=== COMPARING MSD DATASETS ===")
    
    # Define dataset paths
    dataset1 = "matlab/Clusters/p_output_C1.csv"
    dataset2 = "matlab/p_output_NEW34.csv"
    
    # Check if both files exist
    if not os.path.exists(dataset1):
        print(f"Error: {dataset1} not found")
        return
    if not os.path.exists(dataset2):
        print(f"Error: {dataset2} not found")
        return
    
    # Examine both datasets
    info1 = examine_dataset(dataset1, "ORIGINAL (p_output_C1)")
    info2 = examine_dataset(dataset2, "NEW (p_output_NEW34)")
    
    if info1 and info2:
        print("\n=== COMPARISON SUMMARY ===")
        print(f"{'Metric':<20} {'Original':<15} {'New':<15} {'Difference':<15}")
        print("-" * 65)
        print(f"{'File size (MB)':<20} {info1['file_size_mb']:<15.1f} {info2['file_size_mb']:<15.1f} {info2['file_size_mb'] - info1['file_size_mb']:<15.1f}")
        print(f"{'Columns':<20} {info1['num_columns']:<15} {info2['num_columns']:<15} {info2['num_columns'] - info1['num_columns']:<15}")
        print(f"{'P-values':<20} {len(info1['p_values']):<15} {len(info2['p_values']):<15} {len(info2['p_values']) - len(info1['p_values']):<15}")
        print(f"{'Critical region':<20} {info1['critical_count']:<15} {info2['critical_count']:<15} {info2['critical_count'] - info1['critical_count']:<15}")
        
        # Compare p-value ranges
        p1_min, p1_max = min(info1['p_values']), max(info1['p_values'])
        p2_min, p2_max = min(info2['p_values']), max(info2['p_values'])
        print(f"{'P-value range':<20} {p1_min:.4f}-{p1_max:.4f} {p2_min:.4f}-{p2_max:.4f} {'N/A':<15}")
        
        # Check for overlapping p-values
        p1_set = set(info1['p_values'])
        p2_set = set(info2['p_values'])
        overlap = len(p1_set.intersection(p2_set))
        unique_to_1 = len(p1_set - p2_set)
        unique_to_2 = len(p2_set - p1_set)
        
        print(f"{'Overlapping p-values':<20} {overlap:<15} {overlap:<15} {'N/A':<15}")
        print(f"{'Unique to Original':<20} {unique_to_1:<15} {'N/A':<15} {'N/A':<15}")
        print(f"{'Unique to New':<20} {'N/A':<15} {unique_to_2:<15} {'N/A':<15}")

def create_output_folders():
    """Create separate output folders for each dataset"""
    print("\n=== CREATING OUTPUT FOLDERS ===")
    
    folders = [
        "output_original_dataset",
        "output_new_dataset", 
        "output_comparison"
    ]
    
    for folder in folders:
        if not os.path.exists(folder):
            os.makedirs(folder)
            print(f"Created: {folder}/")
        else:
            print(f"Exists: {folder}/")

def main():
    """Main function"""
    print("=== MSD DATASET COMPARISON AND ORGANIZATION ===")
    
    # Compare datasets
    compare_datasets()
    
    # Create output folders
    create_output_folders()
    
    print("\n=== NEXT STEPS ===")
    print("1. Run analysis on original dataset → output_original_dataset/")
    print("2. Run analysis on new dataset → output_new_dataset/")
    print("3. Create comparison plots → output_comparison/")

if __name__ == "__main__":
    main()
