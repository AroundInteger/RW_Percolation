#!/usr/bin/env python3
"""
Detailed τ_cr Visualization - Critical Region Analysis

This script creates detailed visualizations showing:
1. MSD curves for p = p_c' - 0.05, p_c', p_c' + 0.05
2. τ_cr detection points
3. Linear regions where α is calculated
4. Power-law fits in the linear regions
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import os
from scipy import stats
from sklearn.linear_model import LinearRegression

def load_p_output_data():
    """Load the p_output.csv data with MSD_ prefix headers"""
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

def get_expected_alpha(p_value):
    """Get expected α based on theoretical knowledge"""
    p_c_prime = 0.6884
    
    if p_value < p_c_prime - 0.05:
        return 1.0  # Liquid: regular diffusion
    elif abs(p_value - p_c_prime) < 0.05:
        return 0.53  # Critical: anomalous diffusion
    else:
        return 0.0  # Solid: no diffusion (plateau)

def calculate_local_alpha_with_regions(t, msd, window_size=200, step_size=50, max_t=1e4):
    """
    Calculate local α and return the linear regions used for fitting
    """
    # Filter data to focus on meaningful regions
    valid_mask = (t <= max_t) & np.isfinite(msd) & (msd > 0)
    t_valid = t[valid_mask]
    msd_valid = msd[valid_mask]
    
    if len(t_valid) < window_size:
        return np.array([]), np.array([]), np.array([]), [], []
    
    log_t = np.log10(t_valid)
    log_msd = np.log10(msd_valid)
    
    alphas = []
    r2_scores = []
    window_centers = []
    linear_regions_t = []  # Store the t values for each linear region
    linear_regions_msd = []  # Store the MSD values for each linear region
    
    # Work backwards from the meaningful region boundary
    for i in range(len(t_valid) - window_size, 0, -step_size):
        # Extract window
        t_window = log_t[i:i+window_size]
        msd_window = log_msd[i:i+window_size]
        
        # Additional validation
        if len(t_window) < window_size * 0.8:
            continue
            
        # Fit linear relationship
        model = LinearRegression()
        model.fit(t_window.reshape(-1, 1), msd_window)
        alpha = model.coef_[0]
        r2 = model.score(t_window.reshape(-1, 1), msd_window)
        
        # Only keep high-quality fits
        if r2 > 0.8:
            alphas.append(alpha)
            r2_scores.append(r2)
            window_centers.append(t_valid[i + window_size//2])
            
            # Store the linear region data
            linear_regions_t.append(10**t_window)  # Convert back to linear scale
            linear_regions_msd.append(10**msd_window)  # Convert back to linear scale
    
    # Reverse arrays to maintain chronological order
    return (np.array(alphas[::-1]), np.array(r2_scores[::-1]), 
            np.array(window_centers[::-1]), linear_regions_t[::-1], linear_regions_msd[::-1])

def detect_changepoint_with_regions(t, msd, p_value):
    """
    Detect changepoint and return the linear regions used
    """
    expected_alpha = get_expected_alpha(p_value)
    
    # Calculate local α in meaningful regions
    alphas, r2_scores, centers, linear_regions_t, linear_regions_msd = calculate_local_alpha_with_regions(
        t, msd, window_size=200, step_size=50, max_t=1e4
    )
    
    if len(alphas) < 5:
        return None, None, None, None, None
    
    # Define reasonable thresholds based on regime
    if expected_alpha == 1.0:  # Liquid
        alpha_threshold = 0.2
        r2_threshold = 0.85
    elif expected_alpha == 0.53:  # Critical
        alpha_threshold = 0.25
        r2_threshold = 0.8
    else:  # Solid
        alpha_threshold = 0.1
        r2_threshold = 0.75
    
    # Find the FIRST significant deviation (working backwards)
    changepoint_idx = None
    
    for i in range(len(alphas) - 1, 0, -1):
        alpha_deviation = abs(alphas[i] - expected_alpha)
        r2_current = r2_scores[i]
        
        # Check if this is a significant deviation
        if alpha_deviation > alpha_threshold and r2_current > r2_threshold:
            # Additional check: is this a sustained deviation?
            if i >= 2:
                next_deviations = [abs(alphas[j] - expected_alpha) for j in range(i-2, i+1)]
                if all(dev > alpha_threshold * 0.5 for dev in next_deviations):
                    changepoint_idx = i
                    break
            else:
                changepoint_idx = i
                break
    
    if changepoint_idx is None:
        return None, None, None, None, None
    
    tau_cr = centers[changepoint_idx]
    alpha_at_changepoint = alphas[changepoint_idx]
    r2_at_changepoint = r2_scores[changepoint_idx]
    
    # Get the linear region at the changepoint
    changepoint_region_t = linear_regions_t[changepoint_idx] if changepoint_idx < len(linear_regions_t) else None
    changepoint_region_msd = linear_regions_msd[changepoint_idx] if changepoint_idx < len(linear_regions_msd) else None
    
    return tau_cr, alpha_at_changepoint, r2_at_changepoint, changepoint_region_t, changepoint_region_msd

def create_detailed_visualization(data, p_values, t):
    """Create detailed visualization of critical region analysis"""
    
    p_c_prime = 0.6884
    
    # Define the three key p-values
    key_p_values = [
        p_c_prime - 0.05,  # Liquid
        p_c_prime,         # Critical
        p_c_prime + 0.05   # Solid
    ]
    
    # Find closest available p-values
    available_p_values = []
    for target_p in key_p_values:
        closest_p = min(p_values, key=lambda x: abs(x - target_p))
        available_p_values.append(closest_p)
        print(f"Target: {target_p:.4f}, Available: {closest_p:.4f}")
    
    # Create figure
    fig, axes = plt.subplots(2, 3, figsize=(20, 12))
    fig.suptitle('Detailed τ_cr Analysis: Critical Region (p_c\' ± 0.05)', fontsize=16, fontweight='bold')
    
    colors = ['blue', 'red', 'green']
    regime_names = ['LIQUID', 'CRITICAL', 'SOLID']
    
    for idx, (p, color, regime) in enumerate(zip(available_p_values, colors, regime_names)):
        msd_col = f'MSD_{p}'
        if msd_col not in data.columns:
            continue
        
        msd = data[msd_col].values
        expected_alpha = get_expected_alpha(p)
        
        # Filter data for meaningful region
        valid_mask = np.isfinite(msd) & (msd > 0) & (t <= 1e4)
        t_valid = t[valid_mask]
        msd_valid = msd[valid_mask]
        
        # Plot 1: MSD curves with τ_cr detection
        ax1 = axes[0, idx]
        ax1.loglog(t_valid, msd_valid, color=color, linewidth=2, label=f'p = {p:.4f}')
        
        # Add boundary line
        ax1.axvline(x=1e4, color='k', linestyle=':', alpha=0.7, label='Boundary (t = 10⁴)')
        
        # Detect changepoint
        tau_cr, alpha_at_cp, r2_at_cp, region_t, region_msd = detect_changepoint_with_regions(t, msd, p)
        
        if tau_cr is not None:
            ax1.axvline(x=tau_cr, color='orange', linestyle='--', linewidth=3, 
                       label=f'τ_cr = {tau_cr:.0f}')
            
            # Highlight the linear region used for α calculation
            if region_t is not None and region_msd is not None:
                ax1.loglog(region_t, region_msd, 'o', color='orange', markersize=4, alpha=0.7,
                          label=f'Linear region\nα = {alpha_at_cp:.3f}')
        
        ax1.set_xlabel('Time τ')
        ax1.set_ylabel('MSD')
        ax1.set_title(f'{regime}\np = {p:.4f} (expected α = {expected_alpha:.2f})')
        ax1.legend(fontsize=9)
        ax1.grid(True, alpha=0.3)
        ax1.set_xlim(1e1, 1e4)
        
        # Plot 2: Log-log plot with power-law fits
        ax2 = axes[1, idx]
        log_t = np.log10(t_valid)
        log_msd = np.log10(msd_valid)
        
        ax2.plot(log_t, log_msd, color=color, linewidth=2, label=f'p = {p:.4f}')
        
        if tau_cr is not None and region_t is not None and region_msd is not None:
            # Plot the linear region in log-log space
            log_region_t = np.log10(region_t)
            log_region_msd = np.log10(region_msd)
            
            ax2.plot(log_region_t, log_region_msd, 'o', color='orange', markersize=6, alpha=0.8,
                    label=f'Linear region\nα = {alpha_at_cp:.3f}')
            
            # Fit line through the linear region
            if len(log_region_t) > 1:
                slope, intercept, r_value, p_value, std_err = stats.linregress(log_region_t, log_region_msd)
                x_fit = np.array([log_region_t.min(), log_region_t.max()])
                y_fit = slope * x_fit + intercept
                ax2.plot(x_fit, y_fit, '--', color='orange', linewidth=2, alpha=0.8,
                        label=f'Fit: α = {slope:.3f}')
            
            # Mark τ_cr
            ax2.axvline(x=np.log10(tau_cr), color='orange', linestyle='--', linewidth=2,
                       label=f'τ_cr = {tau_cr:.0f}')
        
        # Add expected behavior lines
        x_range = np.array([log_t.min(), log_t.max()])
        
        # Expected α line
        y_expected = expected_alpha * x_range + np.log10(msd_valid[0]) - expected_alpha * log_t[0]
        ax2.plot(x_range, y_expected, 'k--', alpha=0.5, linewidth=1, label=f'Expected α = {expected_alpha:.2f}')
        
        ax2.set_xlabel('log₁₀(τ)')
        ax2.set_ylabel('log₁₀(MSD)')
        ax2.set_title(f'{regime} - Log-Log Analysis')
        ax2.legend(fontsize=8)
        ax2.grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/detailed_tau_cr_critical_region.png", 
                dpi=300, bbox_inches='tight')
    
    return fig

def create_summary_table(data, p_values, t):
    """Create a summary table of the analysis results"""
    
    p_c_prime = 0.6884
    key_p_values = [p_c_prime - 0.05, p_c_prime, p_c_prime + 0.05]
    
    # Find closest available p-values
    available_p_values = []
    for target_p in key_p_values:
        closest_p = min(p_values, key=lambda x: abs(x - target_p))
        available_p_values.append(closest_p)
    
    # Create summary table
    summary_data = []
    for p in available_p_values:
        msd_col = f'MSD_{p}'
        if msd_col not in data.columns:
            continue
        
        msd = data[msd_col].values
        expected_alpha = get_expected_alpha(p)
        
        # Detect changepoint
        tau_cr, alpha_at_cp, r2_at_cp, region_t, region_msd = detect_changepoint_with_regions(t, msd, p)
        
        # Determine regime
        if p < p_c_prime - 0.05:
            regime = "LIQUID"
        elif abs(p - p_c_prime) < 0.05:
            regime = "CRITICAL"
        else:
            regime = "SOLID"
        
        summary_data.append({
            'p': p,
            'regime': regime,
            'expected_alpha': expected_alpha,
            'tau_cr': tau_cr if tau_cr is not None else 'Not detected',
            'alpha_at_changepoint': alpha_at_cp if alpha_at_cp is not None else 'N/A',
            'r2_at_changepoint': r2_at_cp if r2_at_cp is not None else 'N/A',
            'alpha_deviation': abs(alpha_at_cp - expected_alpha) if alpha_at_cp is not None else 'N/A'
        })
    
    # Create summary figure
    fig, ax = plt.subplots(1, 1, figsize=(12, 6))
    ax.axis('off')
    
    # Create table data
    table_data = []
    for row in summary_data:
        table_data.append([
            f"{row['p']:.4f}",
            row['regime'],
            f"{row['expected_alpha']:.2f}",
            f"{row['tau_cr']}" if isinstance(row['tau_cr'], str) else f"{row['tau_cr']:.0f}",
            f"{row['alpha_at_changepoint']}" if isinstance(row['alpha_at_changepoint'], str) else f"{row['alpha_at_changepoint']:.3f}",
            f"{row['r2_at_changepoint']}" if isinstance(row['r2_at_changepoint'], str) else f"{row['r2_at_changepoint']:.3f}",
            f"{row['alpha_deviation']}" if isinstance(row['alpha_deviation'], str) else f"{row['alpha_deviation']:.3f}"
        ])
    
    table = ax.table(cellText=table_data,
                    colLabels=['p', 'Regime', 'Expected α', 'τ_cr', 'α (actual)', 'R²', 'α Deviation'],
                    cellLoc='center',
                    loc='center')
    
    table.auto_set_font_size(False)
    table.set_fontsize(12)
    table.scale(1, 2)
    
    # Color code the table
    for i, row in enumerate(summary_data):
        if row['regime'] == 'LIQUID':
            color = 'lightblue'
        elif row['regime'] == 'CRITICAL':
            color = 'lightcoral'
        else:
            color = 'lightgreen'
        
        for j in range(7):
            table[(i+1, j)].set_facecolor(color)
    
    ax.set_title('Critical Region τ_cr Analysis Summary', fontsize=16, fontweight='bold', pad=20)
    
    plt.tight_layout()
    
    # Save table
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/critical_region_summary_table.png", 
                dpi=300, bbox_inches='tight')
    
    return fig

def main():
    """Main analysis function"""
    print("=== DETAILED τ_cr VISUALIZATION ===")
    print("Critical Region Analysis (p_c' ± 0.05)")
    print("=" * 60)
    
    try:
        # Load data
        data, p_values, t = load_p_output_data()
        print(f"Loaded data with {len(p_values)} p-values")
        
        # Create detailed visualization
        print("\nCreating detailed critical region visualization...")
        fig1 = create_detailed_visualization(data, p_values, t)
        plt.close(fig1)
        
        # Create summary table
        print("Creating summary table...")
        fig2 = create_summary_table(data, p_values, t)
        plt.close(fig2)
        
        print("\nAnalysis complete!")
        print("Check ../paper_figures/ for detailed visualizations")
        print("Files created:")
        print("  - detailed_tau_cr_critical_region.png")
        print("  - critical_region_summary_table.png")
        
    except Exception as e:
        print(f"Error in analysis: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main() 