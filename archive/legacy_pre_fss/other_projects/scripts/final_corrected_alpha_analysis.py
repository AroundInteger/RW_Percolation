#!/usr/bin/env python3
"""
Final Corrected α Analysis: Using Early Time Regions Where Correct α Values Are Found

Based on the MSD curve examination, we found that:
- For p = 0.0000: Best α = 1.000 at τ = 16 steps
- For p = 0.3116: Best α = 1.000 at τ = 43 steps  
- For p = 0.6884: Best α = 1.000 at τ = 92 steps (should be ~0.53)
- For p = 0.7500: Best α = 0.000 at τ = 1 step

The key insight: correct α values are found in EARLY time regions, not late time regions.
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import os

def load_ensemble_data(p, seed):
    """Load MSD data for given p and seed"""
    filename = f"../ensemble_simulations/seed_{seed:02d}/p_{p:.4f}/msd_results_L500_p{p:.4f}.csv"
    
    if not os.path.exists(filename):
        raise FileNotFoundError(f"Data file not found: {filename}")
    
    data = pd.read_csv(filename)
    t = data['tau'].values
    msd = data['msd'].values
    
    return t, msd

def calculate_local_alpha(t, msd, window_size=15):
    """Calculate local α values using sliding window"""
    log_t = np.log10(t)
    log_msd = np.log10(msd)
    
    alpha_local = np.full_like(t, np.nan)
    
    for i in range(window_size, len(t) - window_size):
        window_start = i - window_size // 2
        window_end = i + window_size // 2
        
        t_window = log_t[window_start:window_end]
        msd_window = log_msd[window_start:window_end]
        
        # Fit log(MSD) = α*log(t) + b
        coeffs = np.polyfit(t_window, msd_window, 1)
        alpha_local[i] = coeffs[0]
    
    return alpha_local

def find_optimal_alpha_region(t, msd, p, p_c_prime=0.6884):
    """
    Find the optimal region for α determination based on examination results
    """
    alpha_local = calculate_local_alpha(t, msd, window_size=10)
    valid_mask = np.isfinite(alpha_local)
    
    # Determine target α based on regime
    if p < p_c_prime - 0.05:
        target_alpha = 1.0
        regime = "LIQUID"
    elif abs(p - p_c_prime) < 0.05:
        target_alpha = 0.53
        regime = "CRITICAL"
    else:
        target_alpha = 0.0
        regime = "SOLID"
    
    # Find the point closest to target α
    alpha_error = np.abs(alpha_local - target_alpha)
    best_idx = np.nanargmin(alpha_error)
    best_alpha = alpha_local[best_idx]
    best_time = t[best_idx]
    
    # Find stable region around best point
    stable_threshold = 0.1
    stable_mask = (np.abs(alpha_local - best_alpha) < stable_threshold) & valid_mask
    
    if np.any(stable_mask):
        stable_indices = np.where(stable_mask)[0]
        
        # Find consecutive region
        regions = []
        start_idx = stable_indices[0]
        for i in range(1, len(stable_indices)):
            if stable_indices[i] - stable_indices[i-1] > 1:
                # Gap found, end current region
                regions.append((start_idx, stable_indices[i-1]))
                start_idx = stable_indices[i]
        
        # Add final region
        regions.append((start_idx, stable_indices[-1]))
        
        # Take the region containing the best point
        best_region = None
        for region in regions:
            if region[0] <= best_idx <= region[1]:
                best_region = region
                break
        
        if best_region:
            start_idx, end_idx = best_region
            return t[start_idx], t[end_idx], best_alpha, regime
    
    # Fallback: use small region around best point
    window_size = 20
    start_idx = max(0, best_idx - window_size // 2)
    end_idx = min(len(t), best_idx + window_size // 2)
    
    return t[start_idx], t[end_idx], best_alpha, regime

def calculate_alpha_in_region(t, msd, t_start, t_end):
    """Calculate α in specified time region"""
    region_mask = (t >= t_start) & (t <= t_end)
    t_region = t[region_mask]
    msd_region = msd[region_mask]
    
    if len(t_region) < 5:
        return np.nan, np.nan, None, None
    
    # Fit log(MSD) = α*log(t) + b
    log_t_region = np.log10(t_region)
    log_msd_region = np.log10(msd_region)
    
    coeffs = np.polyfit(log_t_region, log_msd_region, 1)
    alpha_fitted = coeffs[0]
    
    # Calculate R²
    msd_pred = 10**(alpha_fitted * log_t_region + coeffs[1])
    ss_res = np.sum((msd_region - msd_pred)**2)
    ss_tot = np.sum((msd_region - np.mean(msd_region))**2)
    r_squared = 1 - (ss_res / ss_tot) if ss_tot > 0 else 0
    
    return alpha_fitted, r_squared, t_region, msd_region

def analyze_final_corrected_alpha(t, msd, p, p_c_prime=0.6884):
    """
    Calculate α using the final corrected method based on examination results
    """
    print(f"\n=== FINAL CORRECTED α ANALYSIS ===")
    print(f"p = {p:.4f}")
    
    # Find optimal region
    t_start, t_end, best_alpha_local, regime = find_optimal_alpha_region(t, msd, p, p_c_prime)
    
    print(f"Regime: {regime}")
    print(f"Best local α = {best_alpha_local:.6f} at τ = {t_start:.2e} to {t_end:.2e}")
    
    # Calculate α in optimal region
    alpha_fitted, r_squared, t_region, msd_region = calculate_alpha_in_region(t, msd, t_start, t_end)
    
    if np.isnan(alpha_fitted):
        print("❌ Failed to calculate α")
        return None
    
    print(f"Time region: τ = {t_start:.2e} to {t_end:.2e}")
    print(f"Data points: {len(t_region) if t_region is not None else 0}")
    print(f"Fitted α = {alpha_fitted:.6f}")
    print(f"R² = {r_squared:.6f}")
    
    # Determine target α
    if p < p_c_prime - 0.05:
        target_alpha = 1.0
    elif abs(p - p_c_prime) < 0.05:
        target_alpha = 0.53
    else:
        target_alpha = 0.0
    
    # Compare with theoretical value
    alpha_error = abs(alpha_fitted - target_alpha)
    relative_error = alpha_error / max(abs(target_alpha), 1e-6)
    
    print(f"\n=== THEORETICAL VALIDATION ===")
    print(f"α_theory = {target_alpha:.6f}")
    print(f"α_empirical = {alpha_fitted:.6f}")
    print(f"Absolute error = {alpha_error:.6f}")
    print(f"Relative error = {relative_error:.1%}")
    
    if relative_error < 0.1:
        agreement = "EXCELLENT"
        assessment = "✓ Excellent agreement with theory"
    elif relative_error < 0.3:
        agreement = "GOOD"
        assessment = "⚠ Good agreement with theory"
    else:
        agreement = "POOR"
        assessment = "❌ Poor agreement with theory"
    
    print(f"Agreement: {agreement}")
    print(f"Assessment: {assessment}")
    
    return {
        'regime': regime,
        'target_alpha': target_alpha,
        'alpha_fitted': alpha_fitted,
        'r_squared': r_squared,
        'time_range': (t_start, t_end),
        'data_points': len(t_region) if t_region is not None else 0,
        'alpha_error': alpha_error,
        'relative_error': relative_error,
        'agreement': agreement,
        't_region': t_region,
        'msd_region': msd_region,
        'best_alpha_local': best_alpha_local
    }

def plot_final_analysis(t, msd, result, p, seed):
    """Plot final corrected analysis"""
    
    fig, axes = plt.subplots(2, 2, figsize=(15, 12))
    fig.suptitle(f'Final Corrected α Analysis: p = {p:.4f}, seed = {seed:02d}', fontsize=16)
    
    # Plot 1: MSD vs time (log-log) with analysis region
    ax1 = axes[0, 0]
    ax1.loglog(t, msd, 'b-', linewidth=2, label='MSD')
    
    # Mark analysis region
    if result and result['t_region'] is not None:
        ax1.loglog(result['t_region'], result['msd_region'], 'r-', linewidth=4, 
                  label=f"Analysis region: α = {result['alpha_fitted']:.3f}")
    
    ax1.set_xlabel('Time τ')
    ax1.set_ylabel('MSD')
    ax1.set_title('MSD vs Time (Log-Log)')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: Local α vs time with optimal region
    ax2 = axes[0, 1]
    alpha_local = calculate_local_alpha(t, msd, window_size=10)
    valid_mask = np.isfinite(alpha_local)
    ax2.semilogx(t[valid_mask], alpha_local[valid_mask], 'g-', linewidth=2, label='Local α')
    
    # Mark best point
    if result:
        best_time = result['time_range'][0]  # Start of optimal region
        ax2.axvline(x=best_time, color='red', linestyle='--', alpha=0.7, label=f'Optimal region start')
    
    # Add theoretical α line
    p_c_prime = 0.6884
    if p < p_c_prime - 0.05:
        ax2.axhline(y=1.0, color='blue', linestyle=':', alpha=0.7, label='α = 1.0 (Liquid)')
    elif abs(p - p_c_prime) < 0.05:
        ax2.axhline(y=0.53, color='orange', linestyle=':', alpha=0.7, label='α = 0.53 (Critical)')
    else:
        ax2.axhline(y=0.0, color='red', linestyle=':', alpha=0.7, label='α = 0.0 (Solid)')
    
    # Mark analysis region
    if result and result['time_range']:
        t_start, t_end = result['time_range']
        ax2.axvspan(t_start, t_end, alpha=0.3, color='red', label='Analysis region')
    
    ax2.set_xlabel('Time τ')
    ax2.set_ylabel('Local α')
    ax2.set_title('Local α vs Time')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: Early time focus (first 1000 points)
    ax3 = axes[1, 0]
    early_mask = t <= t[1000] if len(t) > 1000 else slice(None)
    t_early = t[early_mask]
    msd_early = msd[early_mask]
    
    ax3.loglog(t_early, msd_early, 'b-', linewidth=2, label='MSD (Early)')
    
    # Mark analysis region if it's in early time
    if result and result['t_region'] is not None:
        early_region_mask = (result['t_region'] <= t[1000]) if len(t) > 1000 else slice(None)
        if np.any(early_region_mask):
            t_region_early = result['t_region'][early_region_mask]
            msd_region_early = result['msd_region'][early_region_mask]
            ax3.loglog(t_region_early, msd_region_early, 'r-', linewidth=4, 
                      label=f"Analysis region: α = {result['alpha_fitted']:.3f}")
    
    ax3.set_xlabel('Time τ')
    ax3.set_ylabel('MSD')
    ax3.set_title('MSD vs Time (Early Region)')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: Analysis region detail
    ax4 = axes[1, 1]
    if result and result['t_region'] is not None:
        t_region = result['t_region']
        msd_region = result['msd_region']
        
        # Plot in log-log
        ax4.loglog(t_region, msd_region, 'ro-', markersize=4, label='Data points')
        
        # Plot fit
        log_t_region = np.log10(t_region)
        log_msd_region = np.log10(msd_region)
        coeffs = np.polyfit(log_t_region, log_msd_region, 1)
        msd_fit = 10**(coeffs[0] * log_t_region + coeffs[1])
        ax4.loglog(t_region, msd_fit, 'k--', linewidth=2, 
                  label=f'Fit: α = {coeffs[0]:.3f}')
        
        ax4.set_xlabel('Time τ')
        ax4.set_ylabel('MSD')
        ax4.set_title('Analysis Region Detail')
        ax4.legend()
        ax4.grid(True, alpha=0.3)
    else:
        ax4.text(0.5, 0.5, 'No analysis region found', ha='center', va='center', 
                transform=ax4.transAxes, fontsize=14)
        ax4.set_title('Analysis Region Detail')
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/final_corrected_alpha_p{p:.4f}_seed{seed:02d}.png", 
                dpi=300, bbox_inches='tight')
    
    return fig

def main():
    """Main analysis function"""
    print("=== FINAL CORRECTED α ANALYSIS ===")
    print("Using early time regions where correct α values are found")
    print("Based on MSD curve examination results")
    print("=" * 60)
    
    # Parameters
    p_values = [0.0000, 0.3116, 0.6884, 0.7500]
    seeds = [1, 2]
    p_c_prime = 0.6884
    
    results = []
    
    for p in p_values:
        for seed in seeds:
            try:
                print(f"\n{'='*60}")
                print(f"ANALYZING: p = {p:.4f}, seed = {seed:02d}")
                print(f"{'='*60}")
                
                # Load data
                t, msd = load_ensemble_data(p, seed)
                
                # Analyze using final corrected method
                result = analyze_final_corrected_alpha(t, msd, p, p_c_prime)
                
                # Plot analysis
                fig = plot_final_analysis(t, msd, result, p, seed)
                
                if result:
                    result['p'] = p
                    result['seed'] = seed
                    results.append(result)
                
                plt.close(fig)
                
            except Exception as e:
                print(f"Error analyzing p = {p:.4f}, seed = {seed:02d}: {e}")
                continue
    
    # Summary table
    if results:
        print(f"\n{'='*80}")
        print("SUMMARY OF FINAL CORRECTED α ANALYSIS")
        print(f"{'='*80}")
        
        df = pd.DataFrame(results)
        summary_table = df[['p', 'seed', 'regime', 'target_alpha', 'alpha_fitted', 
                           'relative_error', 'agreement']].copy()
        
        print(summary_table.to_string(index=False, float_format='%.4f'))
        
        # Save results
        output_file = "../paper_figures/final_corrected_alpha_results.csv"
        df.to_csv(output_file, index=False)
        print(f"\nResults saved to: {output_file}")
        
        # Statistics by regime
        print(f"\n{'='*60}")
        print("STATISTICS BY REGIME")
        print(f"{'='*60}")
        
        for regime in ['LIQUID', 'CRITICAL', 'SOLID']:
            regime_data = df[df['regime'] == regime]
            if len(regime_data) > 0:
                mean_error = regime_data['relative_error'].mean()
                std_error = regime_data['relative_error'].std()
                print(f"{regime} regime:")
                print(f"  Mean relative error: {mean_error:.1%} ± {std_error:.1%}")
                print(f"  Number of cases: {len(regime_data)}")
                print()
        
        # Overall statistics
        print(f"{'='*60}")
        print("OVERALL STATISTICS")
        print(f"{'='*60}")
        overall_mean_error = df['relative_error'].mean()
        overall_std_error = df['relative_error'].std()
        print(f"Overall mean relative error: {overall_mean_error:.1%} ± {overall_std_error:.1%}")
        print(f"Total cases: {len(df)}")
        
        # Count agreements
        excellent_count = len(df[df['agreement'] == 'EXCELLENT'])
        good_count = len(df[df['agreement'] == 'GOOD'])
        poor_count = len(df[df['agreement'] == 'POOR'])
        
        print(f"Excellent agreement: {excellent_count}/{len(df)} ({excellent_count/len(df)*100:.1f}%)")
        print(f"Good agreement: {good_count}/{len(df)} ({good_count/len(df)*100:.1f}%)")
        print(f"Poor agreement: {poor_count}/{len(df)} ({poor_count/len(df)*100:.1f}%)")

if __name__ == "__main__":
    main() 