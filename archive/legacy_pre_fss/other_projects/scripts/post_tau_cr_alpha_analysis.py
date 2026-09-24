#!/usr/bin/env python3
"""
POST τ_cr α ANALYSIS
Analyze whether α should be calculated after τ_cr for liquid regime (p > 0 & p < p_c')
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path
import sys

def load_ensemble_data(p: float, seed: int):
    """Load ensemble simulation data"""
    data_path = Path(f"../ensemble_simulations/seed_{seed:02d}/p_{p:.4f}/msd_results_L500_p{p:.4f}.csv")
    data = pd.read_csv(data_path)
    
    if 'tau' in data.columns:
        t = data['tau'].values
    else:
        t = data.iloc[:, 0].values
    
    if 'msd' in data.columns:
        msd = data['msd'].values
    else:
        msd = data.iloc[:, 1].values
    
    t = np.maximum(t, 1e-3)
    msd = np.maximum(msd, 1e-6)
    
    return t, msd

def find_tau_cr(t, msd, p, seed):
    """Find τ_cr using our current method"""
    
    # Current method: sliding window analysis
    window_size = min(50, len(t) // 20)
    start_idx = max(10, window_size // 2)
    end_idx = len(t) - window_size // 2
    
    alpha_values = []
    tau_values = []
    alpha_errors = []
    
    for i in range(start_idx, end_idx):
        window_start = max(0, i - window_size // 2)
        window_end = min(len(t), i + window_size // 2)
        
        t_window = t[window_start:window_end]
        msd_window = msd[window_start:window_end]
        
        log_t_window = np.log10(t_window)
        log_msd_window = np.log10(msd_window)
        
        coeffs = np.polyfit(log_t_window, log_msd_window, 1)
        alpha = coeffs[0]
        
        # Calculate R²
        msd_pred = 10**(alpha * log_t_window + coeffs[1])
        ss_res = np.sum((msd_window - msd_pred)**2)
        ss_tot = np.sum((msd_window - np.mean(msd_window))**2)
        r_squared = 1 - (ss_res / ss_tot) if ss_tot > 0 else 0
        
        alpha_values.append(alpha)
        tau_values.append(t[i])
        alpha_errors.append(1 - r_squared)
    
    # Find first good quality point (error < 0.1)
    good_quality = np.array(alpha_errors) < 0.1
    if not np.any(good_quality):
        best_idx = np.argmin(alpha_errors)
        tau_cr = tau_values[best_idx]
        alpha_cr = alpha_values[best_idx]
    else:
        first_good_idx = np.where(good_quality)[0][0]
        tau_cr = tau_values[first_good_idx]
        alpha_cr = alpha_values[first_good_idx]
    
    return tau_cr, alpha_cr, tau_values, alpha_values, alpha_errors

def analyze_pre_vs_post_tau_cr(t, msd, p, seed):
    """Compare α calculation before vs after τ_cr"""
    
    print(f"=== PRE vs POST τ_cr ANALYSIS FOR p = {p:.4f}, seed = {seed:02d} ===")
    
    # Find τ_cr
    tau_cr, alpha_cr, tau_values, alpha_values, alpha_errors = find_tau_cr(t, msd, p, seed)
    
    print(f"τ_cr = {tau_cr:.2e}")
    print(f"α at τ_cr = {alpha_cr:.6f}")
    print()
    
    # Method 1: Current method (before τ_cr)
    window_size = min(50, len(t) // 20)
    start_idx = max(10, window_size // 2)
    
    window_start = max(0, start_idx - window_size // 2)
    window_end = min(len(t), start_idx + window_size // 2)
    
    t_pre = t[window_start:window_end]
    msd_pre = msd[window_start:window_end]
    
    log_t_pre = np.log10(t_pre)
    log_msd_pre = np.log10(msd_pre)
    
    coeffs_pre = np.polyfit(log_t_pre, log_msd_pre, 1)
    alpha_pre = coeffs_pre[0]
    
    # Calculate R² for pre-τ_cr fit
    msd_pred_pre = 10**(alpha_pre * log_t_pre + coeffs_pre[1])
    ss_res_pre = np.sum((msd_pre - msd_pred_pre)**2)
    ss_tot_pre = np.sum((msd_pre - np.mean(msd_pre))**2)
    r_squared_pre = 1 - (ss_res_pre / ss_tot_pre) if ss_tot_pre > 0 else 0
    
    print(f"Method 1: Pre-τ_cr α (current method)")
    print(f"  Time range: {t_pre[0]:.2e} to {t_pre[-1]:.2e}")
    print(f"  α_pre = {alpha_pre:.6f}")
    print(f"  R² = {r_squared_pre:.6f}")
    print()
    
    # Method 2: Post-τ_cr α
    # Find index of τ_cr
    tau_cr_idx = np.argmin(np.abs(t - tau_cr))
    
    # Use window after τ_cr
    post_start = tau_cr_idx + window_size // 2
    post_end = min(len(t), post_start + window_size)
    
    if post_end - post_start >= 20:  # Need enough points
        t_post = t[post_start:post_end]
        msd_post = msd[post_start:post_end]
        
        log_t_post = np.log10(t_post)
        log_msd_post = np.log10(msd_post)
        
        coeffs_post = np.polyfit(log_t_post, log_msd_post, 1)
        alpha_post = coeffs_post[0]
        
        # Calculate R² for post-τ_cr fit
        msd_pred_post = 10**(alpha_post * log_t_post + coeffs_post[1])
        ss_res_post = np.sum((msd_post - msd_pred_post)**2)
        ss_tot_post = np.sum((msd_post - np.mean(msd_post))**2)
        r_squared_post = 1 - (ss_res_post / ss_tot_post) if ss_tot_post > 0 else 0
        
        print(f"Method 2: Post-τ_cr α")
        print(f"  Time range: {t_post[0]:.2e} to {t_post[-1]:.2e}")
        print(f"  α_post = {alpha_post:.6f}")
        print(f"  R² = {r_squared_post:.6f}")
        print()
        
        # Compare methods
        print(f"=== COMPARISON ===")
        print(f"Pre-τ_cr α: {alpha_pre:.6f} (R² = {r_squared_pre:.6f})")
        print(f"Post-τ_cr α: {alpha_post:.6f} (R² = {r_squared_post:.6f})")
        
        # Theoretical expectation for liquid regime
        if p > 0 and p < 0.6884:  # Liquid regime
            alpha_theory = 1.0
            print(f"Theoretical α (liquid): {alpha_theory:.3f}")
            
            pre_error = abs(alpha_pre - alpha_theory)
            post_error = abs(alpha_post - alpha_theory)
            
            print(f"Pre-τ_cr error: {pre_error:.6f}")
            print(f"Post-τ_cr error: {post_error:.6f}")
            
            if post_error < pre_error:
                print(f"✓ Post-τ_cr α is closer to theoretical value")
                recommendation = "Use post-τ_cr α for liquid regime"
            else:
                print(f"⚠ Pre-τ_cr α is closer to theoretical value")
                recommendation = "Use pre-τ_cr α for liquid regime"
        else:
            recommendation = "Not applicable (not liquid regime)"
        
        print(f"Recommendation: {recommendation}")
        
        return {
            'tau_cr': tau_cr,
            'alpha_cr': alpha_cr,
            'alpha_pre': alpha_pre,
            'r_squared_pre': r_squared_pre,
            'alpha_post': alpha_post,
            'r_squared_post': r_squared_post,
            't_pre': t_pre,
            'msd_pre': msd_pre,
            't_post': t_post,
            'msd_post': msd_post,
            'recommendation': recommendation
        }
    else:
        print(f"Method 2: Post-τ_cr α")
        print(f"  Insufficient points after τ_cr for analysis")
        print(f"  Recommendation: Use pre-τ_cr α")
        
        return {
            'tau_cr': tau_cr,
            'alpha_cr': alpha_cr,
            'alpha_pre': alpha_pre,
            'r_squared_pre': r_squared_pre,
            'alpha_post': np.nan,
            'r_squared_post': np.nan,
            't_pre': t_pre,
            'msd_pre': msd_pre,
            't_post': None,
            'msd_post': None,
            'recommendation': "Use pre-τ_cr α (insufficient post-τ_cr data)"
        }

def plot_pre_vs_post_analysis(t, msd, results, p, seed):
    """Plot pre vs post τ_cr analysis"""
    
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 10))
    
    tau_cr = results['tau_cr']
    alpha_pre = results['alpha_pre']
    alpha_post = results['alpha_post']
    t_pre = results['t_pre']
    msd_pre = results['msd_pre']
    t_post = results['t_post']
    msd_post = results['msd_post']
    
    # Plot 1: Full MSD curve with τ_cr marked
    ax1.loglog(t, msd, 'b-', linewidth=1, label='MSD', alpha=0.7)
    ax1.axvline(tau_cr, color='red', linestyle='--', linewidth=2, label=f'τ_cr = {tau_cr:.2e}')
    
    # Highlight pre-τ_cr region
    ax1.loglog(t_pre, msd_pre, 'orange', linewidth=3, label=f'Pre-τ_cr (α = {alpha_pre:.3f})')
    
    # Highlight post-τ_cr region if available
    if t_post is not None:
        ax1.loglog(t_post, msd_post, 'green', linewidth=3, label=f'Post-τ_cr (α = {alpha_post:.3f})')
    
    ax1.set_xlabel('Time (τ)')
    ax1.set_ylabel('MSD')
    ax1.set_title(f'MSD vs Time (p = {p:.4f}, seed = {seed:02d})')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: Pre-τ_cr analysis
    log_t_pre = np.log10(t_pre)
    log_msd_pre = np.log10(msd_pre)
    
    ax2.loglog(t_pre, msd_pre, 'orange', linewidth=2, label='Pre-τ_cr MSD')
    
    # Add pre-τ_cr fit
    coeffs_pre = np.polyfit(log_t_pre, log_msd_pre, 1)
    msd_fit_pre = 10**(alpha_pre * log_t_pre + coeffs_pre[1])
    ax2.loglog(t_pre, msd_fit_pre, 'orange', linestyle='--', linewidth=2, label=f'Pre-τ_cr fit: α = {alpha_pre:.3f}')
    
    ax2.set_xlabel('Time (τ)')
    ax2.set_ylabel('MSD')
    ax2.set_title('Pre-τ_cr Analysis')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: Post-τ_cr analysis (if available)
    if t_post is not None:
        log_t_post = np.log10(t_post)
        log_msd_post = np.log10(msd_post)
        
        ax3.loglog(t_post, msd_post, 'green', linewidth=2, label='Post-τ_cr MSD')
        
        # Add post-τ_cr fit
        coeffs_post = np.polyfit(log_t_post, log_msd_post, 1)
        msd_fit_post = 10**(alpha_post * log_t_post + coeffs_post[1])
        ax3.loglog(t_post, msd_fit_post, 'green', linestyle='--', linewidth=2, label=f'Post-τ_cr fit: α = {alpha_post:.3f}')
        
        ax3.set_xlabel('Time (τ)')
        ax3.set_ylabel('MSD')
        ax3.set_title('Post-τ_cr Analysis')
        ax3.legend()
        ax3.grid(True, alpha=0.3)
    else:
        ax3.text(0.5, 0.5, 'Insufficient post-τ_cr data', ha='center', va='center', transform=ax3.transAxes)
        ax3.set_title('Post-τ_cr Analysis')
    
    # Plot 4: α comparison
    methods = ['Pre-τ_cr', 'Post-τ_cr']
    alpha_values = [alpha_pre, alpha_post if not np.isnan(alpha_post) else 0]
    colors = ['orange', 'green']
    
    bars = ax4.bar(methods, alpha_values, color=colors, alpha=0.7)
    ax4.set_ylabel('α Value')
    ax4.set_title('α Comparison')
    ax4.grid(True, alpha=0.3)
    
    # Add theoretical line for liquid regime
    if p > 0 and p < 0.6884:
        ax4.axhline(1.0, color='red', linestyle='--', label='Theoretical α = 1.0')
        ax4.legend()
    
    # Add value labels on bars
    for bar, value in zip(bars, alpha_values):
        height = bar.get_height()
        ax4.text(bar.get_x() + bar.get_width()/2., height + 0.01,
                f'{value:.3f}', ha='center', va='bottom')
    
    plt.tight_layout()
    plt.savefig(f'pre_vs_post_tau_cr_p{p:.4f}_seed{seed:02d}.png', dpi=300, bbox_inches='tight')
    plt.show()

def main():
    """Main analysis function"""
    
    # Test cases: focus on liquid regime (p > 0 & p < p_c')
    test_cases = [
        (0.0000, 1, "LIQUID"),
        (0.0000, 2, "LIQUID"),
        (0.3116, 1, "LIQUID"),
        (0.3116, 2, "LIQUID"),
    ]
    
    print("=== PRE vs POST τ_cr α ANALYSIS ===")
    print("Analyzing whether α should be calculated after τ_cr for liquid regime")
    print("=" * 70)
    
    all_results = []
    
    for p, seed, regime in test_cases:
        print(f"\n{'='*70}")
        print(f"ANALYZING: p = {p:.4f}, seed = {seed:02d}, regime = {regime}")
        print(f"{'='*70}")
        
        try:
            # Load data
            t, msd = load_ensemble_data(p, seed)
            
            # Analyze pre vs post τ_cr
            results = analyze_pre_vs_post_tau_cr(t, msd, p, seed)
            results['p'] = p
            results['seed'] = seed
            results['regime'] = regime
            
            all_results.append(results)
            
            # Plot analysis
            plot_pre_vs_post_analysis(t, msd, results, p, seed)
            
        except Exception as e:
            print(f"Error analyzing p = {p:.4f}, seed = {seed:02d}: {e}")
        
        print(f"\n{'-'*70}")
    
    # Summary
    print(f"\n{'='*70}")
    print("SUMMARY")
    print(f"{'='*70}")
    
    for result in all_results:
        p = result['p']
        seed = result['seed']
        alpha_pre = result['alpha_pre']
        alpha_post = result['alpha_post']
        recommendation = result['recommendation']
        
        print(f"p = {p:.4f}, seed = {seed:02d}:")
        print(f"  Pre-τ_cr α: {alpha_pre:.6f}")
        if not np.isnan(alpha_post):
            print(f"  Post-τ_cr α: {alpha_post:.6f}")
        else:
            print(f"  Post-τ_cr α: N/A")
        print(f"  Recommendation: {recommendation}")
        print()

if __name__ == "__main__":
    main() 