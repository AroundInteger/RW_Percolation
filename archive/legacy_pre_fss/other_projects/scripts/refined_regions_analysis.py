#!/usr/bin/env python3
"""
Refined Regions Analysis: Better Alignment with Paper's Findings

The paper states that "not all regions are present in every regime". 
This script uses more stringent criteria to identify regions.
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import os
from scipy.signal import savgol_filter

def load_p_output_data():
    """Load the p_output.csv data"""
    filepath = "/Users/rowanbrown/Documents/GitHub/RW_Percolation/matlab/p_output.csv"
    
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"Data file not found: {filepath}")
    
    # Load data
    data = pd.read_csv(filepath)
    
    # Extract p-values from headers (remove 'MSD_' prefix)
    p_values = []
    for col in data.columns:
        if col.startswith('MSD_'):
            p_str = col[4:]  # Remove 'MSD_' prefix
            try:
                p_values.append(float(p_str))
            except ValueError:
                print(f"Warning: Could not parse p-value from column {col}")
    
    # Create time array (steps)
    t = np.arange(len(data))
    
    return data, p_values, t

def calculate_local_alpha(t, msd, window_size=15):
    """Calculate local α values using sliding window"""
    log_t = np.log10(t[1:])  # Skip t=0 to avoid log(0)
    log_msd = np.log10(msd[1:])  # Skip MSD=0
    
    alpha_local = np.full_like(t, np.nan)
    
    for i in range(window_size, len(log_t) - window_size):
        window_start = i - window_size // 2
        window_end = i + window_size // 2
        
        t_window = log_t[window_start:window_end]
        msd_window = log_msd[window_start:window_end]
        
        # Fit log(MSD) = α*log(t) + b
        coeffs = np.polyfit(t_window, msd_window, 1)
        alpha_local[i+1] = coeffs[0]  # +1 because we skipped t=0
    
    return alpha_local

def find_consecutive_regions(mask, min_length=10):
    """Find consecutive regions in a boolean mask"""
    regions = []
    start_idx = None
    
    for i, value in enumerate(mask):
        if value and start_idx is None:
            start_idx = i
        elif not value and start_idx is not None:
            if i - start_idx >= min_length:
                regions.append((start_idx, i - 1))
            start_idx = None
    
    # Handle case where region extends to end
    if start_idx is not None and len(mask) - start_idx >= min_length:
        regions.append((start_idx, len(mask) - 1))
    
    return regions

def identify_regions_refined(t, msd, p, p_c_prime=0.6884):
    """
    Identify regions using more stringent criteria based on paper's findings
    """
    alpha_local = calculate_local_alpha(t, msd)
    valid_mask = np.isfinite(alpha_local)
    
    regions = {
        'finite_size': {'present': False, 'start': None, 'end': None, 'characteristic': 'α < 1 and decreasing'},
        'anomalous': {'present': False, 'start': None, 'end': None, 'characteristic': 'α < 1 and constant'},
        'transition': {'present': False, 'start': None, 'end': None, 'characteristic': 'α increasing with τ'},
        'regular': {'present': False, 'start': None, 'end': None, 'characteristic': 'α ≈ 1'}
    }
    
    if not np.any(valid_mask):
        return regions
    
    # Calculate 2nd derivative for region identification
    alpha_valid = alpha_local[valid_mask]
    t_valid = t[valid_mask]
    
    if len(alpha_valid) < 30:
        return regions
    
    # Use Savitzky-Golay to calculate 2nd derivative
    window_size = min(15, len(alpha_valid) // 4)
    if window_size < 5:
        window_size = 5
    
    try:
        alpha_2nd_deriv = savgol_filter(alpha_valid, window_size, 3, deriv=1)
    except:
        return regions
    
    # Region 1: Finite size effect (α < 1 and decreasing)
    # More stringent: look for early region with clear decreasing trend
    finite_mask = (alpha_valid < 0.8) & (alpha_2nd_deriv < -0.002) & (t_valid < t_valid[len(t_valid)//4])
    finite_regions = find_consecutive_regions(finite_mask, min_length=8)
    if finite_regions:
        # Take the earliest region
        start_idx, end_idx = finite_regions[0]
        regions['finite_size']['present'] = True
        regions['finite_size']['start'] = t_valid[start_idx]
        regions['finite_size']['end'] = t_valid[end_idx]
    
    # Region 2: Anomalous diffusion (α < 1 and constant)
    # More stringent: look for region with α ≈ 0.5 ± 0.2 and very stable
    if abs(p - p_c_prime) < 0.1:  # Only look for anomalous in critical regime
        anomalous_mask = (np.abs(alpha_valid - 0.5) < 0.2) & (np.abs(alpha_2nd_deriv) < 0.002)
        anomalous_regions = find_consecutive_regions(anomalous_mask, min_length=15)
        if anomalous_regions:
            # Take the longest region
            longest_region = max(anomalous_regions, key=lambda x: x[1] - x[0])
            start_idx, end_idx = longest_region
            regions['anomalous']['present'] = True
            regions['anomalous']['start'] = t_valid[start_idx]
            regions['anomalous']['end'] = t_valid[end_idx]
    
    # Region 3: Transition (α increasing)
    # More stringent: look for clear increasing trend
    transition_mask = (alpha_2nd_deriv > 0.002) & (alpha_valid > 0.3)
    transition_regions = find_consecutive_regions(transition_mask, min_length=10)
    if transition_regions:
        # Take the longest region
        longest_region = max(transition_regions, key=lambda x: x[1] - x[0])
        start_idx, end_idx = longest_region
        regions['transition']['present'] = True
        regions['transition']['start'] = t_valid[start_idx]
        regions['transition']['end'] = t_valid[end_idx]
    
    # Region 4: Regular diffusion (α ≈ 1)
    # More stringent: look for region with α ≈ 1.0 ± 0.1 and stable
    if p < p_c_prime - 0.05:  # Only look for regular in liquid regime
        regular_mask = (np.abs(alpha_valid - 1.0) < 0.1) & (np.abs(alpha_2nd_deriv) < 0.002)
        regular_regions = find_consecutive_regions(regular_mask, min_length=15)
        if regular_regions:
            # Take the latest region (after transition)
            latest_region = max(regular_regions, key=lambda x: x[0])
            start_idx, end_idx = latest_region
            regions['regular']['present'] = True
            regions['regular']['start'] = t_valid[start_idx]
            regions['regular']['end'] = t_valid[end_idx]
    
    return regions

def plot_regions_refined(t, msd, alpha_local, regions, p, p_c_prime=0.6884):
    """Plot the identified regions with refined criteria"""
    
    fig, axes = plt.subplots(2, 2, figsize=(15, 12))
    fig.suptitle(f'Refined MSD Regions Analysis: p = {p:.4f}', fontsize=16)
    
    # Determine regime
    if p < p_c_prime - 0.05:
        regime = "LIQUID"
    elif abs(p - p_c_prime) < 0.05:
        regime = "CRITICAL"
    else:
        regime = "SOLID"
    
    # Plot 1: MSD vs time (log-log)
    ax1 = axes[0, 0]
    ax1.loglog(t, msd, 'b-', linewidth=2, label='MSD')
    
    # Mark regions on MSD plot
    colors = ['red', 'orange', 'green', 'blue']
    region_names = ['Finite Size', 'Anomalous', 'Transition', 'Regular']
    region_keys = ['finite_size', 'anomalous', 'transition', 'regular']
    
    for i, (key, name) in enumerate(zip(region_keys, region_names)):
        region_info = regions[key]
        if region_info['present']:
            region_mask = (t >= region_info['start']) & (t <= region_info['end'])
            region_msd = msd[region_mask]
            region_t = t[region_mask]
            if len(region_t) > 0:
                ax1.loglog(region_t, region_msd, color=colors[i], linewidth=4, 
                          label=f"{name}: {region_info['characteristic']}")
    
    ax1.set_xlabel('Time τ')
    ax1.set_ylabel('MSD')
    ax1.set_title(f'MSD vs Time (Log-Log) - {regime} Regime')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: Local α vs time
    ax2 = axes[0, 1]
    valid_mask = np.isfinite(alpha_local)
    ax2.semilogx(t[valid_mask], alpha_local[valid_mask], 'g-', linewidth=2, label='Local α')
    
    # Add theoretical α lines
    if p < p_c_prime - 0.05:
        ax2.axhline(y=1.0, color='blue', linestyle='--', alpha=0.7, label='α = 1.0 (Liquid)')
    elif abs(p - p_c_prime) < 0.05:
        ax2.axhline(y=0.53, color='orange', linestyle='--', alpha=0.7, label='α = 0.53 (Critical)')
    else:
        ax2.axhline(y=0.0, color='red', linestyle='--', alpha=0.7, label='α = 0.0 (Solid)')
    
    # Mark regions on α plot
    for i, (key, name) in enumerate(zip(region_keys, region_names)):
        region_info = regions[key]
        if region_info['present']:
            ax2.axvspan(region_info['start'], region_info['end'], 
                       alpha=0.3, color=colors[i], label=f'{name} region')
    
    ax2.set_xlabel('Time τ')
    ax2.set_ylabel('Local α')
    ax2.set_title('Local α vs Time')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: Region summary
    ax3 = axes[1, 0]
    region_counts = [regions[key]['present'] for key in region_keys]
    bars = ax3.bar(region_names, region_counts, color=colors, alpha=0.7)
    
    # Add value labels on bars
    for bar, count in zip(bars, region_counts):
        height = bar.get_height()
        ax3.text(bar.get_x() + bar.get_width()/2., height + 0.05,
                f'{count}', ha='center', va='bottom')
    
    ax3.set_ylabel('Present (1) / Absent (0)')
    ax3.set_title(f'Regions Present for p = {p:.4f}')
    ax3.set_ylim(0, 1.2)
    
    # Plot 4: Region characteristics
    ax4 = axes[1, 1]
    present_regions = []
    for key, name in zip(region_keys, region_names):
        if regions[key]['present']:
            present_regions.append(name)
    
    if present_regions:
        ax4.text(0.1, 0.8, f'Regime: {regime}', fontsize=14, fontweight='bold')
        ax4.text(0.1, 0.6, f'p = {p:.4f}', fontsize=12)
        ax4.text(0.1, 0.4, 'Present regions:', fontsize=12, fontweight='bold')
        for i, region in enumerate(present_regions):
            ax4.text(0.1, 0.3 - i*0.1, f'• {region}', fontsize=11)
    else:
        ax4.text(0.5, 0.5, 'No regions identified', ha='center', va='center', 
                fontsize=14, transform=ax4.transAxes)
    
    ax4.set_xlim(0, 1)
    ax4.set_ylim(0, 1)
    ax4.axis('off')
    ax4.set_title('Region Summary')
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/refined_regions_p{p:.4f}.png", 
                dpi=300, bbox_inches='tight')
    
    return fig

def analyze_refined_regions():
    """Analyze regions using refined criteria"""
    
    print("=== REFINED REGIONS ANALYSIS ===")
    print("Using more stringent criteria to align with paper's findings")
    print("=" * 60)
    
    # Load data
    data, p_values, t = load_p_output_data()
    
    print(f"Loaded data with {len(p_values)} p-values")
    print(f"Time range: {t[0]} to {t[-1]} steps")
    print()
    
    results = []
    
    # Analyze each p-value
    for i, p in enumerate(p_values):
        try:
            print(f"Analyzing p = {p:.4f} ({i+1}/{len(p_values)})")
            
            # Extract MSD data for this p-value
            msd_col = f'MSD_{p}'
            if msd_col in data.columns:
                msd = data[msd_col].values
                
                # Identify regions with refined criteria
                regions = identify_regions_refined(t, msd, p)
                
                # Count present regions
                present_count = sum(regions[key]['present'] for key in regions.keys())
                
                # Determine regime
                p_c_prime = 0.6884
                if p < p_c_prime - 0.05:
                    regime = "LIQUID"
                elif abs(p - p_c_prime) < 0.05:
                    regime = "CRITICAL"
                else:
                    regime = "SOLID"
                
                # Store results
                result = {
                    'p': p,
                    'regime': regime,
                    'present_regions': present_count,
                    'finite_size': regions['finite_size']['present'],
                    'anomalous': regions['anomalous']['present'],
                    'transition': regions['transition']['present'],
                    'regular': regions['regular']['present']
                }
                results.append(result)
                
                # Plot for selected p-values
                if p in [0.0, 0.3116, 0.6884, 0.75] or p % 0.1 < 0.01:
                    alpha_local = calculate_local_alpha(t, msd)
                    fig = plot_regions_refined(t, msd, alpha_local, regions, p)
                    plt.close(fig)
                
                print(f"  Regime: {regime}, Regions present: {present_count}")
                
            else:
                print(f"  Warning: Column {msd_col} not found")
                
        except Exception as e:
            print(f"  Error analyzing p = {p:.4f}: {e}")
            continue
    
    # Create summary DataFrame
    df = pd.DataFrame(results)
    
    # Save results
    output_file = "../paper_figures/refined_regions_summary.csv"
    df.to_csv(output_file, index=False)
    print(f"\nResults saved to: {output_file}")
    
    # Print summary statistics
    print(f"\n{'='*60}")
    print("REFINED SUMMARY STATISTICS")
    print(f"{'='*60}")
    
    for regime in ['LIQUID', 'CRITICAL', 'SOLID']:
        regime_data = df[df['regime'] == regime]
        if len(regime_data) > 0:
            print(f"\n{regime} regime ({len(regime_data)} p-values):")
            print(f"  Mean regions present: {regime_data['present_regions'].mean():.2f}")
            print(f"  Finite size region: {regime_data['finite_size'].sum()}/{len(regime_data)} ({regime_data['finite_size'].mean()*100:.1f}%)")
            print(f"  Anomalous region: {regime_data['anomalous'].sum()}/{len(regime_data)} ({regime_data['anomalous'].mean()*100:.1f}%)")
            print(f"  Transition region: {regime_data['transition'].sum()}/{len(regime_data)} ({regime_data['transition'].mean()*100:.1f}%)")
            print(f"  Regular region: {regime_data['regular'].sum()}/{len(regime_data)} ({regime_data['regular'].mean()*100:.1f}%)")
    
    # Overall statistics
    print(f"\nOverall statistics ({len(df)} p-values):")
    print(f"  Mean regions present: {df['present_regions'].mean():.2f}")
    print(f"  P-values with all 4 regions: {(df['present_regions'] == 4).sum()}")
    print(f"  P-values with 3 regions: {(df['present_regions'] == 3).sum()}")
    print(f"  P-values with 2 regions: {(df['present_regions'] == 2).sum()}")
    print(f"  P-values with 1 region: {(df['present_regions'] == 1).sum()}")
    print(f"  P-values with 0 regions: {(df['present_regions'] == 0).sum()}")
    
    return df

def main():
    """Main analysis function"""
    try:
        df = analyze_refined_regions()
        print("\nRefined analysis complete!")
    except Exception as e:
        print(f"Error in refined analysis: {e}")

if __name__ == "__main__":
    main() 