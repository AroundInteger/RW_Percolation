#!/usr/bin/env python3
"""
Improved τ_cr Analysis - Refined Strategy

This script implements an improved strategy to estimate τ_cr:
1. Uses larger, more appropriate window sizes for 1M-step data
2. Focuses on later time regions (t > 10³) to avoid early noise
3. Implements better noise filtering and validation
4. Uses regime-specific detection criteria
5. Investigates the power-law relationship τ_cr ∝ |p - p_c'|^ν
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import os
from scipy import stats
from scipy.signal import savgol_filter
from sklearn.linear_model import LinearRegression
from sklearn.metrics import r2_score

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

def calculate_local_alpha_improved(t, msd, window_size=1000, step_size=200, min_t=1e3):
    """Calculate local α using improved sliding window approach"""
    # Filter data to avoid early noise
    valid_mask = (t >= min_t) & np.isfinite(msd) & (msd > 0)
    t_valid = t[valid_mask]
    msd_valid = msd[valid_mask]
    
    if len(t_valid) < window_size:
        return np.array([]), np.array([]), np.array([])
    
    log_t = np.log10(t_valid)
    log_msd = np.log10(msd_valid)
    
    alphas = []
    r2_scores = []
    window_centers = []
    
    for i in range(0, len(t_valid) - window_size, step_size):
        # Extract window
        t_window = log_t[i:i+window_size]
        msd_window = log_msd[i:i+window_size]
        
        # Additional validation
        if len(t_window) < window_size * 0.8:  # Need at least 80% of window
            continue
            
        # Fit linear relationship
        model = LinearRegression()
        model.fit(t_window.reshape(-1, 1), msd_window)
        alpha = model.coef_[0]
        r2 = model.score(t_window.reshape(-1, 1), msd_window)
        
        # Only keep high-quality fits
        if r2 > 0.8:  # Require good fit
            alphas.append(alpha)
            r2_scores.append(r2)
            window_centers.append(t_valid[i + window_size//2])
    
    return np.array(alphas), np.array(r2_scores), np.array(window_centers)

def detect_changepoint_improved(t, msd, p_value, regime):
    """
    Improved changepoint detection with regime-specific criteria
    """
    p_c_prime = 0.6884
    
    # Regime-specific parameters
    if regime == "LIQUID":
        # For liquid: look for transition from anomalous to regular diffusion
        window_size = 2000
        min_t = 1e4
        expected_alpha_before = 1.0
        expected_alpha_after = 1.0
        threshold = 0.05  # Smaller threshold for liquid
    elif regime == "CRITICAL":
        # For critical: look for transition from critical to regular diffusion
        window_size = 1500
        min_t = 1e3
        expected_alpha_before = 0.53
        expected_alpha_after = 1.0
        threshold = 0.1  # Larger threshold for critical
    else:  # SOLID
        # For solid: look for transition from finite-size to plateau
        window_size = 1000
        min_t = 1e3
        expected_alpha_before = 0.0
        expected_alpha_after = 0.0
        threshold = 0.05  # Smaller threshold for solid
    
    # Calculate local α
    alphas, r2_scores, centers = calculate_local_alpha_improved(
        t, msd, window_size=window_size, step_size=window_size//4, min_t=min_t
    )
    
    if len(alphas) < 5:
        return None, None
    
    # Method 1: α derivative-based detection
    alpha_derivative = np.gradient(alphas)
    change_indices = np.where(np.abs(alpha_derivative) > threshold)[0]
    
    # Method 2: R² drop detection
    r2_threshold = np.mean(r2_scores) - 0.1 * np.std(r2_scores)
    r2_drop_indices = np.where(r2_scores < r2_threshold)[0]
    
    # Method 3: α value change detection
    alpha_change_indices = []
    for i in range(1, len(alphas)):
        alpha_change = abs(alphas[i] - alphas[i-1])
        if alpha_change > threshold:
            alpha_change_indices.append(i)
    
    # Combine all detected changes
    all_changes = list(set(change_indices) | set(r2_drop_indices) | set(alpha_change_indices))
    
    if len(all_changes) == 0:
        return None, None
    
    # Take the latest significant change (working backwards)
    latest_change_idx = max(all_changes)
    tau_cr = centers[latest_change_idx]
    
    # Validation: ensure τ_cr is reasonable
    if tau_cr < min_t or tau_cr > 1e6:
        return None, None
    
    return tau_cr, centers

def adaptive_tau_cr_detection_improved(t, msd, p_value):
    """
    Improved adaptive τ_cr detection based on percolation regime
    """
    p_c_prime = 0.6884
    
    # Determine regime
    if p_value < p_c_prime - 0.05:
        regime = "LIQUID"
    elif abs(p_value - p_c_prime) < 0.05:
        regime = "CRITICAL"
    else:
        regime = "SOLID"
    
    # Detect τ_cr using improved method
    tau_cr, centers = detect_changepoint_improved(t, msd, p_value, regime)
    
    return tau_cr, regime

def analyze_power_law_scaling_improved(tau_cr_results):
    """Analyze the power-law relationship τ_cr ∝ |p - p_c'|^ν with improved filtering"""
    p_c_prime = 0.6884
    
    # Extract valid results
    valid_results = []
    for p, tau_cr, regime in tau_cr_results:
        if tau_cr is not None and tau_cr > 1e3 and tau_cr < 1e6:  # Reasonable range
            valid_results.append((p, tau_cr, regime))
    
    if len(valid_results) < 5:
        print("Insufficient valid data for power-law analysis")
        return None
    
    # Separate by regime for analysis
    liquid_data = [(p, tau_cr) for p, tau_cr, regime in valid_results if regime == "LIQUID"]
    critical_data = [(p, tau_cr) for p, tau_cr, regime in valid_results if regime == "CRITICAL"]
    solid_data = [(p, tau_cr) for p, tau_cr, regime in valid_results if regime == "SOLID"]
    
    results = {}
    
    # Analyze each regime
    for regime_name, data in [("LIQUID", liquid_data), ("CRITICAL", critical_data), ("SOLID", solid_data)]:
        if len(data) < 3:
            continue
        
        p_values = np.array([p for p, tau_cr in data])
        tau_cr_values = np.array([tau_cr for p, tau_cr in data])
        
        # Calculate distance from critical point
        distance = np.abs(p_values - p_c_prime)
        
        # Fit power law: log(τ_cr) = ν * log(|p - p_c'|) + b
        valid_mask = (distance > 0) & (tau_cr_values > 0)
        if np.sum(valid_mask) < 3:
            continue
        
        log_distance = np.log10(distance[valid_mask])
        log_tau_cr = np.log10(tau_cr_values[valid_mask])
        
        # Linear fit
        slope, intercept, r_value, p_value, std_err = stats.linregress(log_distance, log_tau_cr)
        r_squared = r_value**2
        
        results[regime_name] = {
            'nu': slope,
            'intercept': intercept,
            'r_squared': r_squared,
            'std_err': std_err,
            'p_values': p_values[valid_mask],
            'tau_cr_values': tau_cr_values[valid_mask],
            'distance': distance[valid_mask]
        }
        
        print(f"{regime_name} regime:")
        print(f"  ν = {slope:.4f} ± {std_err:.4f}")
        print(f"  R² = {r_squared:.4f}")
        print(f"  τ_cr ∝ |p - {p_c_prime}|^{slope:.4f}")
        print(f"  Data points: {len(p_values[valid_mask])}")
    
    return results

def plot_improved_analysis(data, p_values, t, tau_cr_results):
    """Plot improved τ_cr analysis"""
    
    # Create figure with multiple subplots
    fig, axes = plt.subplots(2, 3, figsize=(18, 12))
    fig.suptitle('Improved τ_cr Analysis: Regime-Specific Detection', fontsize=16)
    
    # Plot 1: Example MSD curve with τ_cr detection
    ax1 = axes[0, 0]
    example_p = 0.6884  # Critical point
    msd_col = f'MSD_{example_p}'
    if msd_col in data.columns:
        msd = data[msd_col].values
        ax1.loglog(t, msd, 'b-', linewidth=2, label='MSD')
        
        # Find τ_cr for this example
        tau_cr, regime = adaptive_tau_cr_detection_improved(t, msd, example_p)
        if tau_cr is not None:
            ax1.axvline(x=tau_cr, color='r', linestyle='--', linewidth=2, label=f'τ_cr = {tau_cr:.0f}')
        
        ax1.set_xlabel('Time τ')
        ax1.set_ylabel('MSD')
        ax1.set_title(f'Example: p = {example_p} ({regime})')
        ax1.legend()
        ax1.grid(True, alpha=0.3)
    
    # Plot 2: τ_cr vs p
    ax2 = axes[0, 1]
    valid_results = [(p, tau_cr, regime) for p, tau_cr, regime in tau_cr_results if tau_cr is not None]
    
    if valid_results:
        p_vals = [p for p, tau_cr, regime in valid_results]
        tau_cr_vals = [tau_cr for p, tau_cr, regime in valid_results]
        regimes = [regime for p, tau_cr, regime in valid_results]
        
        # Color by regime
        colors = {'LIQUID': 'blue', 'CRITICAL': 'red', 'SOLID': 'green'}
        for regime in set(regimes):
            mask = [r == regime for r in regimes]
            ax2.scatter([p_vals[i] for i, m in enumerate(mask) if m],
                       [tau_cr_vals[i] for i, m in enumerate(mask) if m],
                       c=colors[regime], label=regime, s=50, alpha=0.7)
        
        ax2.set_xlabel('p (occupation probability)')
        ax2.set_ylabel('τ_cr')
        ax2.set_title('τ_cr vs p')
        ax2.set_yscale('log')
        ax2.legend()
        ax2.grid(True, alpha=0.3)
    
    # Plot 3: Power-law analysis
    ax3 = axes[0, 2]
    power_law_results = analyze_power_law_scaling_improved(tau_cr_results)
    
    if power_law_results:
        p_c_prime = 0.6884
        colors = {'LIQUID': 'blue', 'CRITICAL': 'red', 'SOLID': 'green'}
        
        for regime, result in power_law_results.items():
            distance = result['distance']
            tau_cr_values = result['tau_cr_values']
            nu = result['nu']
            r_squared = result['r_squared']
            
            ax3.loglog(distance, tau_cr_values, 'o', c=colors[regime], 
                      label=f'{regime}: ν={nu:.3f}, R²={r_squared:.3f}')
            
            # Plot fitted line
            x_fit = np.logspace(np.log10(distance.min()), np.log10(distance.max()), 100)
            y_fit = 10**(result['intercept']) * x_fit**nu
            ax3.loglog(x_fit, y_fit, '--', c=colors[regime], alpha=0.7)
        
        ax3.set_xlabel('|p - p_c\'|')
        ax3.set_ylabel('τ_cr')
        ax3.set_title('Power-Law Scaling: τ_cr ∝ |p - p_c\'|^ν')
        ax3.legend()
        ax3.grid(True, alpha=0.3)
    
    # Plot 4: Local α analysis for example
    ax4 = axes[1, 0]
    if msd_col in data.columns:
        msd = data[msd_col].values
        alphas, r2_scores, centers = calculate_local_alpha_improved(
            t, msd, window_size=1500, step_size=300, min_t=1e3
        )
        
        if len(alphas) > 0:
            ax4.plot(centers, alphas, 'b-', linewidth=2, label='Local α')
            ax4.axhline(y=0.53, color='r', linestyle='--', alpha=0.7, label='Theoretical α')
            ax4.axhline(y=1.0, color='g', linestyle='--', alpha=0.7, label='Regular diffusion')
            
            ax4.set_xlabel('Time τ')
            ax4.set_ylabel('Local α')
            ax4.set_title('Local α Analysis (Improved)')
            ax4.set_xscale('log')
            ax4.legend()
            ax4.grid(True, alpha=0.3)
    
    # Plot 5: R² analysis
    ax5 = axes[1, 1]
    if msd_col in data.columns and len(r2_scores) > 0:
        ax5.plot(centers, r2_scores, 'g-', linewidth=2, label='R²')
        ax5.axhline(y=0.8, color='r', linestyle='--', alpha=0.7, label='R² threshold')
        ax5.set_xlabel('Time τ')
        ax5.set_ylabel('R²')
        ax5.set_title('R² Analysis (Improved)')
        ax5.set_xscale('log')
        ax5.legend()
        ax5.grid(True, alpha=0.3)
    
    # Plot 6: Summary table
    ax6 = axes[1, 2]
    ax6.axis('off')
    
    if valid_results:
        # Create summary table
        summary_data = []
        for p, tau_cr, regime in valid_results[:10]:  # Show first 10
            summary_data.append([
                f"{p:.4f}",
                regime,
                f"{tau_cr:.0f}"
            ])
        
        table = ax6.table(cellText=summary_data,
                         colLabels=['p', 'Regime', 'τ_cr'],
                         cellLoc='center',
                         loc='center')
        table.auto_set_font_size(False)
        table.set_fontsize(10)
        table.scale(1, 2)
        
        ax6.set_title('τ_cr Results Summary (Improved)')
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/improved_tau_cr_analysis.png", 
                dpi=300, bbox_inches='tight')
    
    return fig

def main():
    """Main analysis function"""
    print("=== IMPROVED τ_cr ANALYSIS ===")
    print("Refined strategy with regime-specific detection")
    print("=" * 60)
    
    try:
        # Load data
        data, p_values, t = load_p_output_data()
        print(f"Loaded data with {len(p_values)} p-values")
        
        # Analyze τ_cr for all p-values
        tau_cr_results = []
        
        for p in p_values:
            msd_col = f'MSD_{p}'
            if msd_col not in data.columns:
                continue
            
            msd = data[msd_col].values
            
            # Detect τ_cr using improved method
            tau_cr, regime = adaptive_tau_cr_detection_improved(t, msd, p)
            
            tau_cr_results.append((p, tau_cr, regime))
            
            if tau_cr is not None:
                print(f"p = {p:.4f} ({regime}): τ_cr = {tau_cr:.0f}")
            else:
                print(f"p = {p:.4f} ({regime}): τ_cr = Not detected")
        
        # Create comprehensive plots
        print("\nCreating improved analysis plots...")
        fig = plot_improved_analysis(data, p_values, t, tau_cr_results)
        plt.close(fig)
        
        # Save results
        results_df = pd.DataFrame(tau_cr_results, columns=['p', 'tau_cr', 'regime'])
        output_file = "../paper_figures/improved_tau_cr_results.csv"
        results_df.to_csv(output_file, index=False)
        print(f"\nResults saved to: {output_file}")
        
        # Power-law analysis
        print("\n=== IMPROVED POWER-LAW ANALYSIS ===")
        power_law_results = analyze_power_law_scaling_improved(tau_cr_results)
        
        if power_law_results:
            print("\nPower-law relationships found:")
            for regime, result in power_law_results.items():
                nu = result['nu']
                r_squared = result['r_squared']
                std_err = result['std_err']
                print(f"  {regime}: τ_cr ∝ |p - p_c'|^{nu:.4f} ± {std_err:.4f} (R² = {r_squared:.4f})")
        
        print("\nAnalysis complete!")
        print("Check ../paper_figures/ for plots and results")
        
    except Exception as e:
        print(f"Error in analysis: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main() 