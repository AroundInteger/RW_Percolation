#!/usr/bin/env python3
"""
Pragmatic τ_cr Analysis - Working Backwards with Theoretical Knowledge

This script implements a robust strategy to estimate τ_cr by:
1. Working backwards from maximum steps (1,000,000)
2. Looking for the FIRST significant deviation from expected α behavior
3. Using theoretical knowledge: α ≈ 1 for liquid, α ≈ 0.53 for critical, α ≈ 0 for solid
4. Finding where MSD steps away from the expected scaling line
5. Being pragmatic about what constitutes a "significant" change
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

def get_expected_alpha(p_value):
    """
    Get expected α based on theoretical knowledge
    """
    p_c_prime = 0.6884
    
    if p_value < p_c_prime - 0.05:
        return 1.0  # Liquid: regular diffusion
    elif abs(p_value - p_c_prime) < 0.05:
        return 0.53  # Critical: anomalous diffusion
    else:
        return 0.0  # Solid: no diffusion (plateau)

def calculate_local_alpha_backwards(t, msd, window_size=500, step_size=100, min_t=1e3):
    """
    Calculate local α working backwards from the end
    """
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
    
    # Work backwards from the end
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
    
    # Reverse arrays to maintain chronological order
    return np.array(alphas[::-1]), np.array(r2_scores[::-1]), np.array(window_centers[::-1])

def detect_pragmatic_changepoint(t, msd, p_value):
    """
    Pragmatic changepoint detection working backwards
    
    Strategy:
    1. Work backwards from the end
    2. Find the FIRST point where α deviates significantly from expected
    3. Use theoretical knowledge to guide detection
    4. Be pragmatic about thresholds
    """
    expected_alpha = get_expected_alpha(p_value)
    
    # Calculate local α working backwards
    alphas, r2_scores, centers = calculate_local_alpha_backwards(
        t, msd, window_size=500, step_size=100, min_t=1e3
    )
    
    if len(alphas) < 5:
        return None, None, None
    
    # Define pragmatic thresholds based on regime
    if expected_alpha == 1.0:  # Liquid
        alpha_threshold = 0.1  # Significant deviation from α = 1
        r2_threshold = 0.9     # Require good fit
    elif expected_alpha == 0.53:  # Critical
        alpha_threshold = 0.15  # Larger threshold for critical
        r2_threshold = 0.85    # Slightly lower R² requirement
    else:  # Solid
        alpha_threshold = 0.05  # Small threshold for solid
        r2_threshold = 0.8     # Lower R² requirement
    
    # Find the FIRST significant deviation (working backwards)
    changepoint_idx = None
    
    for i in range(len(alphas) - 1, 0, -1):  # Work backwards
        alpha_deviation = abs(alphas[i] - expected_alpha)
        r2_current = r2_scores[i]
        
        # Check if this is a significant deviation
        if alpha_deviation > alpha_threshold and r2_current > r2_threshold:
            # Additional check: is this a sustained deviation?
            # Look at the next few points to ensure it's not just noise
            if i >= 2:
                next_deviations = [abs(alphas[j] - expected_alpha) for j in range(i-2, i+1)]
                if all(dev > alpha_threshold * 0.5 for dev in next_deviations):
                    changepoint_idx = i
                    break
            else:
                changepoint_idx = i
                break
    
    if changepoint_idx is None:
        return None, None, None
    
    tau_cr = centers[changepoint_idx]
    alpha_at_changepoint = alphas[changepoint_idx]
    r2_at_changepoint = r2_scores[changepoint_idx]
    
    return tau_cr, alpha_at_changepoint, r2_at_changepoint

def analyze_regime_transitions(data, p_values, t):
    """
    Analyze transitions in each regime using pragmatic approach
    """
    p_c_prime = 0.6884
    
    # Separate p-values by regime
    liquid_p = [p for p in p_values if p < p_c_prime - 0.05]
    critical_p = [p for p in p_values if abs(p - p_c_prime) < 0.05]
    solid_p = [p for p in p_values if p > p_c_prime + 0.05]
    
    print(f"=== PRAGMATIC τ_cr ANALYSIS ===")
    print(f"p_c' = {p_c_prime}")
    print(f"LIQUID regime (p < {p_c_prime - 0.05:.4f}): {len(liquid_p)} p-values")
    print(f"CRITICAL regime (|p - {p_c_prime}| < 0.05): {len(critical_p)} p-values")
    print(f"SOLID regime (p > {p_c_prime + 0.05:.4f}): {len(solid_p)} p-values")
    
    all_results = []
    
    # Analyze each regime
    for regime_name, p_list in [("LIQUID", liquid_p), ("CRITICAL", critical_p), ("SOLID", solid_p)]:
        print(f"\n--- {regime_name} REGIME ---")
        
        for p in p_list:
            msd_col = f'MSD_{p}'
            if msd_col not in data.columns:
                continue
            
            msd = data[msd_col].values
            
            # Detect changepoint
            tau_cr, alpha_at_cp, r2_at_cp = detect_pragmatic_changepoint(t, msd, p)
            
            expected_alpha = get_expected_alpha(p)
            
            result = {
                'p': p,
                'regime': regime_name,
                'tau_cr': tau_cr,
                'alpha_at_changepoint': alpha_at_cp,
                'r2_at_changepoint': r2_at_cp,
                'expected_alpha': expected_alpha,
                'alpha_deviation': abs(alpha_at_cp - expected_alpha) if alpha_at_cp is not None else None
            }
            all_results.append(result)
            
            if tau_cr is not None:
                print(f"p = {p:.4f}: τ_cr = {tau_cr:.0f}, α = {alpha_at_cp:.4f} (expected: {expected_alpha:.2f}), R² = {r2_at_cp:.4f}")
            else:
                print(f"p = {p:.4f}: τ_cr = Not detected")
    
    return all_results

def analyze_power_law_pragmatic(results):
    """
    Analyze power-law relationship using pragmatic τ_cr values
    """
    p_c_prime = 0.6884
    
    # Extract valid results
    valid_results = [r for r in results if r['tau_cr'] is not None and r['tau_cr'] > 1e3 and r['tau_cr'] < 9e5]
    
    if len(valid_results) < 5:
        print("Insufficient valid data for power-law analysis")
        return None
    
    # Separate by regime
    liquid_data = [(r['p'], r['tau_cr']) for r in valid_results if r['regime'] == "LIQUID"]
    critical_data = [(r['p'], r['tau_cr']) for r in valid_results if r['regime'] == "CRITICAL"]
    solid_data = [(r['p'], r['tau_cr']) for r in valid_results if r['regime'] == "SOLID"]
    
    power_law_results = {}
    
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
        
        power_law_results[regime_name] = {
            'nu': slope,
            'intercept': intercept,
            'r_squared': r_squared,
            'std_err': std_err,
            'p_values': p_values[valid_mask],
            'tau_cr_values': tau_cr_values[valid_mask],
            'distance': distance[valid_mask]
        }
        
        print(f"\n{regime_name} regime power-law:")
        print(f"  ν = {slope:.4f} ± {std_err:.4f}")
        print(f"  R² = {r_squared:.4f}")
        print(f"  τ_cr ∝ |p - {p_c_prime}|^{slope:.4f}")
        print(f"  Data points: {len(p_values[valid_mask])}")
    
    return power_law_results

def plot_pragmatic_analysis(data, p_values, t, results, power_law_results):
    """Plot pragmatic τ_cr analysis"""
    
    fig, axes = plt.subplots(2, 3, figsize=(18, 12))
    fig.suptitle('Pragmatic τ_cr Analysis: Working Backwards with Theoretical Knowledge', fontsize=16)
    
    # Plot 1: Example MSD with τ_cr detection
    ax1 = axes[0, 0]
    example_p = 0.6884  # Critical point
    msd_col = f'MSD_{example_p}'
    if msd_col in data.columns:
        msd = data[msd_col].values
        valid_mask = np.isfinite(msd) & (msd > 0)
        t_valid = t[valid_mask]
        msd_valid = msd[valid_mask]
        
        ax1.loglog(t_valid, msd_valid, 'b-', linewidth=2, label='MSD')
        
        # Find τ_cr for this example
        tau_cr, alpha_at_cp, r2_at_cp = detect_pragmatic_changepoint(t, msd, example_p)
        if tau_cr is not None:
            ax1.axvline(x=tau_cr, color='r', linestyle='--', linewidth=2, 
                       label=f'τ_cr = {tau_cr:.0f}\nα = {alpha_at_cp:.3f}')
        
        ax1.set_xlabel('Time τ')
        ax1.set_ylabel('MSD')
        ax1.set_title(f'Example: p = {example_p} (Critical)')
        ax1.legend()
        ax1.grid(True, alpha=0.3)
    
    # Plot 2: τ_cr vs p by regime
    ax2 = axes[0, 1]
    valid_results = [r for r in results if r['tau_cr'] is not None]
    
    if valid_results:
        # Color by regime
        colors = {'LIQUID': 'blue', 'CRITICAL': 'red', 'SOLID': 'green'}
        for regime in set(r['regime'] for r in valid_results):
            regime_results = [r for r in valid_results if r['regime'] == regime]
            p_vals = [r['p'] for r in regime_results]
            tau_cr_vals = [r['tau_cr'] for r in regime_results]
            
            ax2.scatter(p_vals, tau_cr_vals, c=colors[regime], label=regime, s=50, alpha=0.7)
        
        ax2.set_xlabel('p (occupation probability)')
        ax2.set_ylabel('τ_cr')
        ax2.set_title('τ_cr vs p by Regime')
        ax2.set_yscale('log')
        ax2.legend()
        ax2.grid(True, alpha=0.3)
    
    # Plot 3: Power-law analysis
    ax3 = axes[0, 2]
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
    
    # Plot 4: α at changepoint vs expected α
    ax4 = axes[1, 0]
    if valid_results:
        expected_alphas = [r['expected_alpha'] for r in valid_results]
        actual_alphas = [r['alpha_at_changepoint'] for r in valid_results]
        regimes = [r['regime'] for r in valid_results]
        
        # Color by regime
        for regime in set(regimes):
            mask = [r == regime for r in regimes]
            ax4.scatter([expected_alphas[i] for i, m in enumerate(mask) if m],
                       [actual_alphas[i] for i, m in enumerate(mask) if m],
                       c=colors[regime], label=regime, s=50, alpha=0.7)
        
        # Add diagonal line
        min_alpha = min(min(expected_alphas), min(actual_alphas))
        max_alpha = max(max(expected_alphas), max(actual_alphas))
        ax4.plot([min_alpha, max_alpha], [min_alpha, max_alpha], 'k--', alpha=0.5, label='Perfect agreement')
        
        ax4.set_xlabel('Expected α')
        ax4.set_ylabel('α at changepoint')
        ax4.set_title('α Agreement')
        ax4.legend()
        ax4.grid(True, alpha=0.3)
    
    # Plot 5: R² at changepoint
    ax5 = axes[1, 1]
    if valid_results:
        p_vals = [r['p'] for r in valid_results]
        r2_vals = [r['r2_at_changepoint'] for r in valid_results]
        regimes = [r['regime'] for r in valid_results]
        
        # Color by regime
        for regime in set(regimes):
            mask = [r == regime for r in regimes]
            ax5.scatter([p_vals[i] for i, m in enumerate(mask) if m],
                       [r2_vals[i] for i, m in enumerate(mask) if m],
                       c=colors[regime], label=regime, s=50, alpha=0.7)
        
        ax5.set_xlabel('p')
        ax5.set_ylabel('R² at changepoint')
        ax5.set_title('Fit Quality at Changepoint')
        ax5.legend()
        ax5.grid(True, alpha=0.3)
    
    # Plot 6: Summary table
    ax6 = axes[1, 2]
    ax6.axis('off')
    
    if valid_results:
        # Create summary table
        summary_data = []
        for r in valid_results[:10]:  # Show first 10
            summary_data.append([
                f"{r['p']:.4f}",
                r['regime'],
                f"{r['tau_cr']:.0f}",
                f"{r['alpha_at_changepoint']:.3f}",
                f"{r['expected_alpha']:.2f}",
                f"{r['r2_at_changepoint']:.3f}"
            ])
        
        table = ax6.table(cellText=summary_data,
                         colLabels=['p', 'Regime', 'τ_cr', 'α (actual)', 'α (expected)', 'R²'],
                         cellLoc='center',
                         loc='center')
        table.auto_set_font_size(False)
        table.set_fontsize(9)
        table.scale(1, 2)
        
        ax6.set_title('Pragmatic Results Summary')
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/pragmatic_tau_cr_analysis.png", 
                dpi=300, bbox_inches='tight')
    
    return fig

def main():
    """Main analysis function"""
    print("=== PRAGMATIC τ_cr ANALYSIS ===")
    print("Working backwards with theoretical knowledge")
    print("=" * 60)
    
    try:
        # Load data
        data, p_values, t = load_p_output_data()
        print(f"Loaded data with {len(p_values)} p-values")
        
        # Analyze regime transitions
        results = analyze_regime_transitions(data, p_values, t)
        
        # Create comprehensive plots
        print("\nCreating pragmatic analysis plots...")
        power_law_results = analyze_power_law_pragmatic(results)
        fig = plot_pragmatic_analysis(data, p_values, t, results, power_law_results)
        plt.close(fig)
        
        # Save results
        results_df = pd.DataFrame(results)
        output_file = "../paper_figures/pragmatic_tau_cr_results.csv"
        results_df.to_csv(output_file, index=False)
        print(f"\nResults saved to: {output_file}")
        
        # Summary statistics
        print(f"\n{'='*60}")
        print("SUMMARY STATISTICS")
        print(f"{'='*60}")
        
        valid_results = [r for r in results if r['tau_cr'] is not None]
        if valid_results:
            print(f"\nτ_cr statistics:")
            tau_cr_vals = [r['tau_cr'] for r in valid_results]
            print(f"  Mean: {np.mean(tau_cr_vals):.0f}")
            print(f"  Median: {np.median(tau_cr_vals):.0f}")
            print(f"  Std: {np.std(tau_cr_vals):.0f}")
            print(f"  Range: {min(tau_cr_vals):.0f} - {max(tau_cr_vals):.0f}")
            
            print(f"\nα agreement statistics:")
            alpha_deviations = [r['alpha_deviation'] for r in valid_results if r['alpha_deviation'] is not None]
            if alpha_deviations:
                print(f"  Mean deviation: {np.mean(alpha_deviations):.4f}")
                print(f"  Median deviation: {np.median(alpha_deviations):.4f}")
                print(f"  Max deviation: {np.max(alpha_deviations):.4f}")
        
        if power_law_results:
            print(f"\nPower-law relationships found:")
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