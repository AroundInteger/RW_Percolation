#!/usr/bin/env python3
"""
Investigate the specific case of p = 0.6384 to understand the classification
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats

def investigate_p6384():
    """Investigate p = 0.6384 classification"""
    
    print("=== INVESTIGATING p = 0.6384 CLASSIFICATION ===")
    
    # Load the new dataset
    print("Loading new dataset...")
    df = pd.read_csv("matlab/p_output_NEW34.csv")
    
    # Extract MSD data for p = 0.6384
    p_value = 0.6384
    col_name = f"MSD_{p_value}"
    
    if col_name not in df.columns:
        print(f"Error: Column {col_name} not found")
        return
    
    msd_data = df[col_name].values
    time_steps = np.arange(1, len(msd_data) + 1)
    
    print(f"MSD data shape: {msd_data.shape}")
    print(f"Time steps: {time_steps[0]} to {time_steps[-1]}")
    
    # Check for invalid data
    valid_mask = np.isfinite(msd_data) & (msd_data > 0)
    print(f"Valid data points: {np.sum(valid_mask)}/{len(msd_data)}")
    
    if not np.any(valid_mask):
        print("Error: No valid data found")
        return
    
    msd_valid = msd_data[valid_mask]
    time_valid = time_steps[valid_mask]
    
    print(f"Valid MSD range: {msd_valid.min():.2e} to {msd_valid.max():.2e}")
    
    # Analyze different time windows
    print("\n=== TIME WINDOW ANALYSIS ===")
    
    windows = [
        ("Early (10%-50%)", 0.1, 0.5),
        ("Middle (25%-75%)", 0.25, 0.75),
        ("Late (50%-100%)", 0.5, 1.0),
        ("Very Late (75%-100%)", 0.75, 1.0)
    ]
    
    results = []
    
    for name, start_frac, end_frac in windows:
        start_idx = int(len(msd_valid) * start_frac)
        end_idx = int(len(msd_valid) * end_frac)
        
        if end_idx - start_idx < 50:  # Minimum window size
            continue
            
        msd_window = msd_valid[start_idx:end_idx]
        time_window = time_valid[start_idx:end_idx]
        
        # Fit power law
        log_msd = np.log10(msd_window)
        log_time = np.log10(time_window)
        
        slope, intercept, r_value, p_value_fit, std_err = stats.linregress(log_time, log_msd)
        alpha = slope
        r_squared = r_value ** 2
        
        results.append({
            'window': name,
            'start_idx': start_idx,
            'end_idx': end_idx,
            'window_size': end_idx - start_idx,
            'alpha': alpha,
            'r_squared': r_squared,
            'msd_start': msd_window[0],
            'msd_end': msd_window[-1],
            'msd_ratio': msd_window[-1] / msd_window[0]
        })
        
        print(f"{name}:")
        print(f"  Window: {start_idx} to {end_idx} (size: {end_idx - start_idx})")
        print(f"  α = {alpha:.4f}, R² = {r_squared:.4f}")
        print(f"  MSD range: {msd_window[0]:.2e} to {msd_window[-1]:.2e}")
        print(f"  MSD ratio: {msd_window[-1] / msd_window[0]:.2f}")
        print()
    
    # Create detailed plot
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    
    # Plot 1: Full MSD curve
    ax1 = axes[0, 0]
    ax1.loglog(time_valid, msd_valid, 'b-', linewidth=2, label=f'p = {p_value}')
    ax1.set_xlabel('Time Step')
    ax1.set_ylabel('MSD')
    ax1.set_title(f'Full MSD Curve for p = {p_value}')
    ax1.grid(True, alpha=0.3)
    ax1.legend()
    
    # Plot 2: Different time windows
    ax2 = axes[0, 1]
    colors = ['red', 'orange', 'green', 'blue']
    for i, (name, start_frac, end_frac) in enumerate(windows):
        start_idx = int(len(msd_valid) * start_frac)
        end_idx = int(len(msd_valid) * end_frac)
        if end_idx - start_idx >= 50:
            msd_window = msd_valid[start_idx:end_idx]
            time_window = time_valid[start_idx:end_idx]
            ax2.loglog(time_window, msd_window, 'o-', color=colors[i], 
                      label=f'{name} (α = {results[i]["alpha"]:.3f})')
    
    ax2.set_xlabel('Time Step')
    ax2.set_ylabel('MSD')
    ax2.set_title('MSD in Different Time Windows')
    ax2.grid(True, alpha=0.3)
    ax2.legend()
    
    # Plot 3: Alpha vs window position
    ax3 = axes[1, 0]
    window_names = [r['window'] for r in results]
    alphas = [r['alpha'] for r in results]
    r_squared_values = [r['r_squared'] for r in results]
    
    bars = ax3.bar(range(len(results)), alphas, color='skyblue', alpha=0.7)
    ax3.set_xlabel('Time Window')
    ax3.set_ylabel('Growth Exponent (α)')
    ax3.set_title('α Values for Different Time Windows')
    ax3.set_xticks(range(len(results)))
    ax3.set_xticklabels(window_names, rotation=45)
    ax3.axhline(y=0.5, color='orange', linestyle='--', alpha=0.7, label='α = 0.5 (critical)')
    ax3.axhline(y=0.0, color='red', linestyle='--', alpha=0.7, label='α = 0.0 (solid)')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: R² vs window position
    ax4 = axes[1, 1]
    bars = ax4.bar(range(len(results)), r_squared_values, color='lightgreen', alpha=0.7)
    ax4.set_xlabel('Time Window')
    ax4.set_ylabel('R² (Fit Quality)')
    ax4.set_title('Fit Quality for Different Time Windows')
    ax4.set_xticks(range(len(results)))
    ax4.set_xticklabels(window_names, rotation=45)
    ax4.axhline(y=0.8, color='green', linestyle='--', alpha=0.7, label='R² = 0.8 (good)')
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(f'investigation_p{p_value}.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    # Summary and recommendation
    print("=== CLASSIFICATION ANALYSIS ===")
    print(f"p = {p_value} is {abs(p_value - 0.6884):.4f} away from p_c' = 0.6884")
    print(f"Current classification threshold: |p - p_c'| < 0.05")
    print(f"Classification: {'critical' if abs(p_value - 0.6884) < 0.05 else 'liquid' if p_value < 0.6884 - 0.05 else 'solid'}")
    
    print("\n=== RECOMMENDATIONS ===")
    
    # Check if any window shows liquid-like behavior
    liquid_windows = [r for r in results if r['alpha'] > 0.7 and r['r_squared'] > 0.8]
    critical_windows = [r for r in results if 0.3 < r['alpha'] < 0.7 and r['r_squared'] > 0.8]
    solid_windows = [r for r in results if r['alpha'] < 0.2 and r['r_squared'] > 0.8]
    
    if liquid_windows:
        print("✅ Found liquid-like behavior in some time windows")
        window_names = [w['window'] for w in liquid_windows]
        alpha_vals = [w['alpha'] for w in liquid_windows]
        print(f"   Windows: {window_names}")
        print(f"   α values: {alpha_vals}")
    
    if critical_windows:
        print("✅ Found critical-like behavior in some time windows")
        window_names = [w['window'] for w in critical_windows]
        alpha_vals = [w['alpha'] for w in critical_windows]
        print(f"   Windows: {window_names}")
        print(f"   α values: {alpha_vals}")
    
    if solid_windows:
        print("✅ Found solid-like behavior in some time windows")
        window_names = [w['window'] for w in solid_windows]
        alpha_vals = [w['alpha'] for w in solid_windows]
        print(f"   Windows: {window_names}")
        print(f"   α values: {alpha_vals}")
    
    print(f"\nOverall assessment: This p-value shows {len(critical_windows)} critical, {len(liquid_windows)} liquid, and {len(solid_windows)} solid time windows")
    
    if len(critical_windows) > len(liquid_windows) and len(critical_windows) > len(solid_windows):
        print("Recommendation: Consider reclassifying as 'critical' based on dominant behavior")
    elif len(liquid_windows) > len(critical_windows) and len(liquid_windows) > len(solid_windows):
        print("Recommendation: Consider reclassifying as 'liquid' based on dominant behavior")
    else:
        print("Recommendation: Current 'solid' classification may be appropriate")

if __name__ == "__main__":
    investigate_p6384()
