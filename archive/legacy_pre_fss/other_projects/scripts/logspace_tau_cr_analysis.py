#!/usr/bin/env python3
"""
Log-Space τ_cr Analysis - Understanding the Late Transitions

This script focuses on understanding why τ_cr appears so late in the time series:
1. Properly accounts for log-space interpretations
2. Investigates the nature of late-time transitions
3. Analyzes the log-space scaling relationships
4. Focuses on the transition region with finer resolution
5. Examines whether the late τ_cr values are real or artifacts
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

def analyze_logspace_scaling(t, msd, p_value, regime):
    """
    Analyze log-space scaling relationships in different time regions
    
    In log-space: log(MSD) = α * log(t) + b
    The exponent α represents the slope in log-log space
    """
    p_c_prime = 0.6884
    
    # Remove invalid values
    valid_mask = np.isfinite(msd) & (msd > 0)
    t_valid = t[valid_mask]
    msd_valid = msd[valid_mask]
    
    if len(t_valid) < 100:
        return None, None, None
    
    # Convert to log-space
    log_t = np.log10(t_valid)
    log_msd = np.log10(msd_valid)
    
    # Define time regions for analysis
    regions = {
        'early': (1e2, 1e4),      # Early time: finite-size effects
        'middle': (1e4, 1e5),     # Middle time: anomalous diffusion
        'late': (1e5, 1e6),       # Late time: transition to regular diffusion
        'very_late': (9e5, 1e6)   # Very late: final behavior
    }
    
    results = {}
    
    for region_name, (t_start, t_end) in regions.items():
        # Filter data for this region
        region_mask = (t_valid >= t_start) & (t_valid <= t_end)
        if np.sum(region_mask) < 10:
            continue
        
        t_region = log_t[region_mask]
        msd_region = log_msd[region_mask]
        
        # Fit linear relationship in log-space
        model = LinearRegression()
        model.fit(t_region.reshape(-1, 1), msd_region)
        alpha = model.coef_[0]
        intercept = model.intercept_
        r2 = model.score(t_region.reshape(-1, 1), msd_region)
        
        # Calculate residuals to assess fit quality
        y_pred = alpha * t_region + intercept
        residuals = msd_region - y_pred
        residual_std = np.std(residuals)
        
        results[region_name] = {
            'alpha': alpha,
            'intercept': intercept,
            'r2': r2,
            'residual_std': residual_std,
            'n_points': len(t_region),
            't_range': (t_start, t_end)
        }
    
    return results

def detect_logspace_changepoint(t, msd, p_value, regime):
    """
    Detect changepoint by analyzing log-space derivatives and curvature
    
    In log-space, we look for:
    1. Changes in the local slope (d(log MSD)/d(log t))
    2. Changes in curvature (d²(log MSD)/d(log t)²)
    3. Deviations from expected scaling behavior
    """
    p_c_prime = 0.6884
    
    # Remove invalid values
    valid_mask = np.isfinite(msd) & (msd > 0)
    t_valid = t[valid_mask]
    msd_valid = msd[valid_mask]
    
    if len(t_valid) < 200:
        return None, None
    
    # Convert to log-space
    log_t = np.log10(t_valid)
    log_msd = np.log10(msd_valid)
    
    # Calculate first and second derivatives in log-space
    try:
        # Use Savitzky-Golay filter for smooth derivatives
        window_length = min(21, len(log_msd)//10)
        if window_length % 2 == 0:
            window_length += 1
        
        if window_length < 5:
            return None, None
        
        # Smooth the log MSD data
        log_msd_smooth = savgol_filter(log_msd, window_length, 3)
        
        # Calculate derivatives
        first_deriv = np.gradient(log_msd_smooth, log_t)
        second_deriv = np.gradient(first_deriv, log_t)
        
        # Expected behavior based on regime
        if regime == "LIQUID":
            expected_alpha = 1.0
            expected_deriv = 0.0  # Constant slope
        elif regime == "CRITICAL":
            expected_alpha = 0.53
            expected_deriv = 0.0  # Constant slope
        else:  # SOLID
            expected_alpha = 0.0
            expected_deriv = 0.0  # Constant slope
        
        # Find points where behavior deviates from expected
        alpha_deviation = np.abs(first_deriv - expected_deriv)
        curvature = np.abs(second_deriv)
        
        # Thresholds for detection
        alpha_threshold = 0.1
        curvature_threshold = np.std(curvature) * 2
        
        # Find changepoints
        alpha_changes = np.where(alpha_deviation > alpha_threshold)[0]
        curvature_changes = np.where(curvature > curvature_threshold)[0]
        
        # Combine detected changes
        all_changes = list(set(alpha_changes) | set(curvature_changes))
        
        if len(all_changes) == 0:
            return None, None
        
        # Take the latest significant change (working backwards)
        latest_change_idx = max(all_changes)
        tau_cr = t_valid[latest_change_idx]
        
        return tau_cr, {
            'alpha_deviation': alpha_deviation[latest_change_idx],
            'curvature': curvature[latest_change_idx],
            'log_t_at_change': log_t[latest_change_idx],
            'log_msd_at_change': log_msd_smooth[latest_change_idx]
        }
        
    except Exception as e:
        print(f"Warning: Derivative detection failed for p={p_value}: {e}")
        return None, None

def analyze_transition_region(data, p_values, t):
    """
    Focused analysis of the transition region around p_c'
    """
    p_c_prime = 0.6884
    transition_width = 0.05
    
    # Find p-values in transition region
    transition_mask = np.abs(np.array(p_values) - p_c_prime) < transition_width
    transition_p_values = [p for i, p in enumerate(p_values) if transition_mask[i]]
    
    print(f"=== TRANSITION REGION ANALYSIS ===")
    print(f"p_c' = {p_c_prime}")
    print(f"Transition region: p ∈ [{p_c_prime - transition_width:.4f}, {p_c_prime + transition_width:.4f}]")
    print(f"Found {len(transition_p_values)} p-values in transition region")
    
    transition_results = []
    
    for p in transition_p_values:
        msd_col = f'MSD_{p}'
        if msd_col not in data.columns:
            continue
        
        msd = data[msd_col].values
        
        # Analyze log-space scaling
        scaling_results = analyze_logspace_scaling(t, msd, p, "CRITICAL")
        
        # Detect changepoint
        tau_cr, change_info = detect_logspace_changepoint(t, msd, p, "CRITICAL")
        
        result = {
            'p': p,
            'tau_cr': tau_cr,
            'scaling_results': scaling_results,
            'change_info': change_info
        }
        transition_results.append(result)
        
        print(f"\np = {p:.4f}:")
        if tau_cr is not None:
            print(f"  τ_cr = {tau_cr:.0f}")
            if change_info:
                print(f"  α deviation = {change_info['alpha_deviation']:.4f}")
                print(f"  Curvature = {change_info['curvature']:.4f}")
        else:
            print(f"  τ_cr = Not detected")
        
        if scaling_results:
            for region, info in scaling_results.items():
                print(f"  {region}: α = {info['alpha']:.4f}, R² = {info['r2']:.4f}")
    
    return transition_results

def plot_logspace_analysis(data, p_values, t, transition_results):
    """Plot comprehensive log-space analysis"""
    
    fig, axes = plt.subplots(2, 3, figsize=(18, 12))
    fig.suptitle('Log-Space τ_cr Analysis: Understanding Late Transitions', fontsize=16)
    
    # Plot 1: Example MSD in log-space
    ax1 = axes[0, 0]
    example_p = 0.6884  # Critical point
    msd_col = f'MSD_{example_p}'
    if msd_col in data.columns:
        msd = data[msd_col].values
        valid_mask = np.isfinite(msd) & (msd > 0)
        t_valid = t[valid_mask]
        msd_valid = msd[valid_mask]
        
        log_t = np.log10(t_valid)
        log_msd = np.log10(msd_valid)
        
        ax1.plot(log_t, log_msd, 'b-', linewidth=2, label='log(MSD)')
        
        # Add theoretical lines
        t_theory = np.logspace(2, 6, 100)
        log_t_theory = np.log10(t_theory)
        
        # Liquid: α = 1
        log_msd_liquid = log_t_theory + np.mean(log_msd) - np.mean(log_t_theory)
        ax1.plot(log_t_theory, log_msd_liquid, 'g--', alpha=0.7, label='α = 1 (Liquid)')
        
        # Critical: α = 0.53
        log_msd_critical = 0.53 * log_t_theory + np.mean(log_msd) - 0.53 * np.mean(log_t_theory)
        ax1.plot(log_t_theory, log_msd_critical, 'r--', alpha=0.7, label='α = 0.53 (Critical)')
        
        # Solid: α = 0
        log_msd_solid = np.full_like(log_t_theory, np.mean(log_msd))
        ax1.plot(log_t_theory, log_msd_solid, 'k--', alpha=0.7, label='α = 0 (Solid)')
        
        ax1.set_xlabel('log₁₀(t)')
        ax1.set_ylabel('log₁₀(MSD)')
        ax1.set_title(f'Log-Space MSD: p = {example_p}')
        ax1.legend()
        ax1.grid(True, alpha=0.3)
    
    # Plot 2: α vs time for different regions
    ax2 = axes[0, 1]
    if transition_results:
        p_vals = [r['p'] for r in transition_results]
        alphas_early = [r['scaling_results']['early']['alpha'] if 'early' in r['scaling_results'] else np.nan 
                       for r in transition_results]
        alphas_middle = [r['scaling_results']['middle']['alpha'] if 'middle' in r['scaling_results'] else np.nan 
                        for r in transition_results]
        alphas_late = [r['scaling_results']['late']['alpha'] if 'late' in r['scaling_results'] else np.nan 
                      for r in transition_results]
        
        ax2.plot(p_vals, alphas_early, 'o-', label='Early (10²-10⁴)', markersize=6)
        ax2.plot(p_vals, alphas_middle, 's-', label='Middle (10⁴-10⁵)', markersize=6)
        ax2.plot(p_vals, alphas_late, '^-', label='Late (10⁵-10⁶)', markersize=6)
        
        ax2.axhline(y=1.0, color='g', linestyle='--', alpha=0.7, label='Liquid α = 1')
        ax2.axhline(y=0.53, color='r', linestyle='--', alpha=0.7, label='Critical α = 0.53')
        ax2.axhline(y=0.0, color='k', linestyle='--', alpha=0.7, label='Solid α = 0')
        
        ax2.set_xlabel('p')
        ax2.set_ylabel('α (log-space exponent)')
        ax2.set_title('α vs p in Different Time Regions')
        ax2.legend()
        ax2.grid(True, alpha=0.3)
    
    # Plot 3: τ_cr vs p in transition region
    ax3 = axes[0, 2]
    if transition_results:
        p_vals = [r['p'] for r in transition_results]
        tau_cr_vals = [r['tau_cr'] for r in transition_results if r['tau_cr'] is not None]
        p_vals_valid = [r['p'] for r in transition_results if r['tau_cr'] is not None]
        
        if tau_cr_vals:
            ax3.semilogy(p_vals_valid, tau_cr_vals, 'ro-', markersize=8, linewidth=2)
            ax3.set_xlabel('p')
            ax3.set_ylabel('τ_cr')
            ax3.set_title('τ_cr vs p in Transition Region')
            ax3.grid(True, alpha=0.3)
    
    # Plot 4: Log-space derivatives
    ax4 = axes[1, 0]
    if msd_col in data.columns:
        msd = data[msd_col].values
        valid_mask = np.isfinite(msd) & (msd > 0)
        t_valid = t[valid_mask]
        msd_valid = msd[valid_mask]
        
        log_t = np.log10(t_valid)
        log_msd = np.log10(msd_valid)
        
        # Calculate derivatives
        window_length = min(21, len(log_msd)//10)
        if window_length % 2 == 0:
            window_length += 1
        
        if window_length >= 5:
            log_msd_smooth = savgol_filter(log_msd, window_length, 3)
            first_deriv = np.gradient(log_msd_smooth, log_t)
            second_deriv = np.gradient(first_deriv, log_t)
            
            ax4.plot(log_t, first_deriv, 'b-', linewidth=2, label='d(log MSD)/d(log t)')
            ax4.axhline(y=1.0, color='g', linestyle='--', alpha=0.7, label='Liquid slope')
            ax4.axhline(y=0.53, color='r', linestyle='--', alpha=0.7, label='Critical slope')
            ax4.axhline(y=0.0, color='k', linestyle='--', alpha=0.7, label='Solid slope')
            
            ax4.set_xlabel('log₁₀(t)')
            ax4.set_ylabel('d(log MSD)/d(log t)')
            ax4.set_title('Log-Space First Derivative')
            ax4.legend()
            ax4.grid(True, alpha=0.3)
    
    # Plot 5: R² vs time region
    ax5 = axes[1, 1]
    if transition_results:
        p_vals = [r['p'] for r in transition_results]
        r2_early = [r['scaling_results']['early']['r2'] if 'early' in r['scaling_results'] else np.nan 
                   for r in transition_results]
        r2_middle = [r['scaling_results']['middle']['r2'] if 'middle' in r['scaling_results'] else np.nan 
                    for r in transition_results]
        r2_late = [r['scaling_results']['late']['r2'] if 'late' in r['scaling_results'] else np.nan 
                  for r in transition_results]
        
        ax5.plot(p_vals, r2_early, 'o-', label='Early', markersize=6)
        ax5.plot(p_vals, r2_middle, 's-', label='Middle', markersize=6)
        ax5.plot(p_vals, r2_late, '^-', label='Late', markersize=6)
        
        ax5.set_xlabel('p')
        ax5.set_ylabel('R²')
        ax5.set_title('R² vs p in Different Time Regions')
        ax5.legend()
        ax5.grid(True, alpha=0.3)
    
    # Plot 6: Summary table
    ax6 = axes[1, 2]
    ax6.axis('off')
    
    if transition_results:
        # Create summary table
        summary_data = []
        for r in transition_results[:8]:  # Show first 8
            p = r['p']
            tau_cr = r['tau_cr']
            alpha_middle = r['scaling_results']['middle']['alpha'] if 'middle' in r['scaling_results'] else np.nan
            r2_middle = r['scaling_results']['middle']['r2'] if 'middle' in r['scaling_results'] else np.nan
            
            summary_data.append([
                f"{p:.4f}",
                f"{tau_cr:.0f}" if tau_cr else "N/A",
                f"{alpha_middle:.3f}" if not np.isnan(alpha_middle) else "N/A",
                f"{r2_middle:.3f}" if not np.isnan(r2_middle) else "N/A"
            ])
        
        table = ax6.table(cellText=summary_data,
                         colLabels=['p', 'τ_cr', 'α (middle)', 'R² (middle)'],
                         cellLoc='center',
                         loc='center')
        table.auto_set_font_size(False)
        table.set_fontsize(10)
        table.scale(1, 2)
        
        ax6.set_title('Transition Region Summary')
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/logspace_tau_cr_analysis.png", 
                dpi=300, bbox_inches='tight')
    
    return fig

def main():
    """Main analysis function"""
    print("=== LOG-SPACE τ_cr ANALYSIS ===")
    print("Understanding late transitions in log-space")
    print("=" * 60)
    
    try:
        # Load data
        data, p_values, t = load_p_output_data()
        print(f"Loaded data with {len(p_values)} p-values")
        
        # Focused analysis of transition region
        transition_results = analyze_transition_region(data, p_values, t)
        
        # Create comprehensive plots
        print("\nCreating log-space analysis plots...")
        fig = plot_logspace_analysis(data, p_values, t, transition_results)
        plt.close(fig)
        
        # Save results
        results_df = pd.DataFrame([
            {
                'p': r['p'],
                'tau_cr': r['tau_cr'],
                'alpha_early': r['scaling_results']['early']['alpha'] if 'early' in r['scaling_results'] else np.nan,
                'alpha_middle': r['scaling_results']['middle']['alpha'] if 'middle' in r['scaling_results'] else np.nan,
                'alpha_late': r['scaling_results']['late']['alpha'] if 'late' in r['scaling_results'] else np.nan,
                'r2_early': r['scaling_results']['early']['r2'] if 'early' in r['scaling_results'] else np.nan,
                'r2_middle': r['scaling_results']['middle']['r2'] if 'middle' in r['scaling_results'] else np.nan,
                'r2_late': r['scaling_results']['late']['r2'] if 'late' in r['scaling_results'] else np.nan
            }
            for r in transition_results
        ])
        
        output_file = "../paper_figures/logspace_tau_cr_results.csv"
        results_df.to_csv(output_file, index=False)
        print(f"\nResults saved to: {output_file}")
        
        # Summary statistics
        print(f"\n{'='*60}")
        print("SUMMARY STATISTICS")
        print(f"{'='*60}")
        
        valid_tau_cr = [r['tau_cr'] for r in transition_results if r['tau_cr'] is not None]
        if valid_tau_cr:
            print(f"\nτ_cr statistics:")
            print(f"  Mean: {np.mean(valid_tau_cr):.0f}")
            print(f"  Median: {np.median(valid_tau_cr):.0f}")
            print(f"  Std: {np.std(valid_tau_cr):.0f}")
            print(f"  Range: {min(valid_tau_cr):.0f} - {max(valid_tau_cr):.0f}")
        
        print("\nAnalysis complete!")
        print("Check ../paper_figures/ for plots and results")
        
    except Exception as e:
        print(f"Error in analysis: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main() 