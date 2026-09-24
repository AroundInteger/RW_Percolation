#!/usr/bin/env python3
"""
Analyze whether p=0.0000 data represents a proper free random walk on a lattice
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path
import sys

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))

def analyze_free_random_walk(filepath='enhanced_output_fine/msd_results_L100_p0.0000.csv'):
    """
    Analyze the p=0.0000 data to check if it represents a proper free random walk
    """
    
    print("=== Free Random Walk Analysis (p = 0.0000) ===")
    print()
    
    # Load data
    df = pd.read_csv(filepath)
    steps = df['step'].values
    msd_values = df['msd'].values
    
    print(f"Data loaded: {len(df)} data points")
    print(f"Time range: {steps[0]} to {steps[-1]} steps")
    print(f"MSD range: {msd_values[0]:.1f} to {msd_values[-1]:.1f}")
    print()
    
    # Theoretical expectations for free random walk on a 3D lattice
    print("=== Theoretical Expectations ===")
    print("For a free random walk on a 3D lattice:")
    print("- MSD should grow linearly with time: MSD = D × t")
    print("- Growth exponent should be α = 1.0")
    print("- Diffusion coefficient D depends on lattice structure")
    print("- For a simple cubic lattice: D = 1/6 (in lattice units)")
    print()
    
    # Calculate growth exponent
    log_steps = np.log10(steps)
    log_msd = np.log10(msd_values)
    
    # Overall fit
    coeffs = np.polyfit(log_steps, log_msd, 1)
    overall_exponent = coeffs[0]
    intercept = coeffs[1]
    
    print(f"=== Measured Results ===")
    print(f"Overall growth exponent: α = {overall_exponent:.3f}")
    print(f"Intercept: {intercept:.3f}")
    print()
    
    # Calculate effective diffusion coefficient
    # MSD = 6D × t (for 3D)
    # D = MSD / (6 × t)
    effective_D = msd_values[-1] / (6 * steps[-1])
    print(f"Effective diffusion coefficient: D = {effective_D:.6f}")
    print(f"Theoretical D for simple cubic lattice: D = 0.166667")
    print(f"Ratio (measured/theoretical): {effective_D/0.166667:.3f}")
    print()
    
    # Early time analysis (first 1000 steps)
    early_mask = steps <= 1000
    if np.sum(early_mask) >= 5:
        early_steps = steps[early_mask]
        early_msd = msd_values[early_mask]
        
        log_early_steps = np.log10(early_steps)
        log_early_msd = np.log10(early_msd)
        
        early_coeffs = np.polyfit(log_early_steps, log_early_msd, 1)
        early_exponent = early_coeffs[0]
        
        print(f"=== Early Time Analysis (steps 100-1000) ===")
        print(f"Early growth exponent: α = {early_exponent:.3f}")
        print(f"First MSD: {early_msd[0]:.1f} at step {early_steps[0]}")
        print(f"Last MSD: {early_msd[-1]:.1f} at step {early_steps[-1]}")
        print()
    
    # Late time analysis (last 1000 steps)
    late_mask = steps >= 90000
    if np.sum(late_mask) >= 5:
        late_steps = steps[late_mask]
        late_msd = msd_values[late_mask]
        
        log_late_steps = np.log10(late_steps)
        log_late_msd = np.log10(late_msd)
        
        late_coeffs = np.polyfit(log_late_steps, log_late_msd, 1)
        late_exponent = late_coeffs[0]
        
        print(f"=== Late Time Analysis (steps 90k-100k) ===")
        print(f"Late growth exponent: α = {late_exponent:.3f}")
        print(f"First MSD: {late_msd[0]:.1f} at step {late_steps[0]}")
        print(f"Last MSD: {late_msd[-1]:.1f} at step {late_steps[-1]}")
        print()
    
    # Check for linearity
    print("=== Linearity Check ===")
    # Fit linear model: MSD = a × t + b
    linear_coeffs = np.polyfit(steps, msd_values, 1)
    linear_slope = linear_coeffs[0]
    linear_intercept = linear_coeffs[1]
    
    # Calculate R² for linear fit
    msd_predicted = linear_slope * steps + linear_intercept
    ss_res = np.sum((msd_values - msd_predicted) ** 2)
    ss_tot = np.sum((msd_values - np.mean(msd_values)) ** 2)
    r_squared_linear = 1 - (ss_res / ss_tot)
    
    print(f"Linear fit: MSD = {linear_slope:.6f} × t + {linear_intercept:.2f}")
    print(f"R² for linear fit: {r_squared_linear:.6f}")
    print()
    
    # Compare with power law fit
    ss_res_power = np.sum((log_msd - (overall_exponent * log_steps + intercept)) ** 2)
    ss_tot_power = np.sum((log_msd - np.mean(log_msd)) ** 2)
    r_squared_power = 1 - (ss_res_power / ss_tot_power)
    
    print(f"Power law fit: MSD = {10**intercept:.2f} × t^{overall_exponent:.3f}")
    print(f"R² for power law fit: {r_squared_power:.6f}")
    print()
    
    # Assessment
    print("=== Assessment ===")
    issues = []
    
    if abs(overall_exponent - 1.0) > 0.1:
        issues.append(f"Growth exponent ({overall_exponent:.3f}) deviates from expected 1.0")
    
    if r_squared_linear < 0.99:
        issues.append(f"Linear fit R² ({r_squared_linear:.3f}) suggests non-linear behavior")
    
    if abs(effective_D - 0.166667) / 0.166667 > 0.2:
        issues.append(f"Diffusion coefficient ({effective_D:.6f}) deviates from theoretical")
    
    if len(issues) == 0:
        print("✅ Data appears to represent a proper free random walk!")
        print("   - Growth exponent close to 1.0")
        print("   - High linearity (R² > 0.99)")
        print("   - Diffusion coefficient close to theoretical")
    else:
        print("⚠️  Potential issues detected:")
        for issue in issues:
            print(f"   - {issue}")
    
    return df, overall_exponent, effective_D, r_squared_linear

def plot_free_rw_analysis(df, save_plot=True):
    """
    Create detailed plots for free random walk analysis
    """
    
    steps = df['step'].values
    msd_values = df['msd'].values
    
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 12))
    
    # Plot 1: MSD vs time (linear scale)
    ax1.plot(steps, msd_values, 'b-', linewidth=2, label='Simulation Data')
    
    # Add theoretical line
    theoretical_msd = steps / 6  # D = 1/6 for simple cubic lattice
    ax1.plot(steps, theoretical_msd, 'r--', linewidth=2, label='Theoretical (D=1/6)')
    
    ax1.set_xlabel('Time Step (t)', fontsize=12)
    ax1.set_ylabel('Mean Squared Displacement (MSD)', fontsize=12)
    ax1.set_title('MSD vs Time - Linear Scale', fontsize=14, fontweight='bold')
    ax1.legend(fontsize=10)
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: MSD vs time (log-log scale)
    ax2.loglog(steps, msd_values, 'b-', linewidth=2, label='Simulation Data')
    ax2.loglog(steps, theoretical_msd, 'r--', linewidth=2, label='Theoretical (D=1/6)')
    
    # Add slope = 1 reference line
    ref_steps = np.array([steps[0], steps[-1]])
    ref_msd = ref_steps
    ax2.loglog(ref_steps, ref_msd, 'g:', linewidth=1, label='Slope = 1 (α = 1.0)')
    
    ax2.set_xlabel('Time Step (t)', fontsize=12)
    ax2.set_ylabel('Mean Squared Displacement (MSD)', fontsize=12)
    ax2.set_title('MSD vs Time - Log-Log Scale', fontsize=14, fontweight='bold')
    ax2.legend(fontsize=10)
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: Residuals from linear fit
    linear_coeffs = np.polyfit(steps, msd_values, 1)
    msd_predicted = linear_coeffs[0] * steps + linear_coeffs[1]
    residuals = msd_values - msd_predicted
    
    ax3.plot(steps, residuals, 'b-', linewidth=1)
    ax3.axhline(y=0, color='r', linestyle='--', alpha=0.7)
    ax3.set_xlabel('Time Step (t)', fontsize=12)
    ax3.set_ylabel('Residuals (MSD - Linear Fit)', fontsize=12)
    ax3.set_title('Residuals from Linear Fit', fontsize=14, fontweight='bold')
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: Local growth exponent
    # Calculate local exponent using sliding window
    window_size = min(50, len(steps) // 10)
    local_exponents = []
    local_steps = []
    
    for i in range(window_size, len(steps) - window_size):
        window_steps = steps[i-window_size:i+window_size]
        window_msd = msd_values[i-window_size:i+window_size]
        
        log_window_steps = np.log10(window_steps)
        log_window_msd = np.log10(window_msd)
        
        coeffs = np.polyfit(log_window_steps, log_window_msd, 1)
        local_exponents.append(coeffs[0])
        local_steps.append(steps[i])
    
    ax4.plot(local_steps, local_exponents, 'b-', linewidth=2)
    ax4.axhline(y=1.0, color='r', linestyle='--', alpha=0.7, label='Expected α = 1.0')
    ax4.set_xlabel('Time Step (t)', fontsize=12)
    ax4.set_ylabel('Local Growth Exponent (α)', fontsize=12)
    ax4.set_title('Local Growth Exponent vs Time', fontsize=14, fontweight='bold')
    ax4.legend(fontsize=10)
    ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    if save_plot:
        plot_file = Path('enhanced_output_fine') / "free_rw_analysis.png"
        plt.savefig(plot_file, dpi=300, bbox_inches='tight')
        print(f"Free RW analysis plot saved: {plot_file}")
    
    plt.show()
    
    return fig

if __name__ == "__main__":
    # Analyze the free random walk data
    df, exponent, D, r_squared = analyze_free_random_walk()
    
    # Create detailed plots
    plot_free_rw_analysis(df) 