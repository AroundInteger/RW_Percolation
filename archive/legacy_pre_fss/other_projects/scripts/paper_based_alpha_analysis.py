#!/usr/bin/env python3
"""
Paper-Based α Analysis: Direct Implementation of Paper's Findings

Based on PAPER_VALIDATION_ANALYSIS.md, we implement the exact strategy:

For p < p_c' (LIQUID): Look in REGULAR DIFFUSION region (τ > τ_cr) for α ≈ 1.0
For p ≈ p_c' (CRITICAL): Look in ANOMALOUS DIFFUSION region (τ_ℓ < τ < τ_ξ) for α ≈ 0.5
For p > p_c' (SOLID): Look in LONG TIME plateau (τ > τ_plateau) for α ≈ 0.0

This script directly implements the paper's recommendations.
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import os
from scipy.signal import savgol_filter

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

def find_crossover_time(t, msd, p, p_c_prime=0.6884):
    """
    Find τ_cr (crossover time) based on paper's method:
    "Intersection of straight line fits to anomalous and regular diffusion regions"
    """
    alpha_local = calculate_local_alpha(t, msd)
    
    # For liquid regime, look for transition from α < 1 to α ≈ 1
    if p < p_c_prime - 0.05:
        # Find where α crosses 0.8 (approaching regular diffusion)
        crossover_mask = (alpha_local > 0.8) & np.isfinite(alpha_local)
        if np.any(crossover_mask):
            crossover_idx = np.where(crossover_mask)[0][0]
            return t[crossover_idx]
    
    # For critical regime, look for transition from α ≈ 0.5 to α > 0.7
    elif abs(p - p_c_prime) < 0.05:
        # Find where α starts increasing significantly from ~0.5
        increasing_mask = (alpha_local > 0.7) & np.isfinite(alpha_local)
        if np.any(increasing_mask):
            crossover_idx = np.where(increasing_mask)[0][0]
            return t[crossover_idx]
    
    # Default: use middle of time range
    return t[len(t) // 2]

def find_anomalous_diffusion_region(t, msd, p, p_c_prime=0.6884):
    """
    Find anomalous diffusion region (τ_ℓ < τ < τ_ξ) for critical regime
    """
    alpha_local = calculate_local_alpha(t, msd)
    
    # Look for region where α ≈ 0.5 ± 0.2 and relatively stable
    anomalous_mask = (np.abs(alpha_local - 0.5) < 0.2) & np.isfinite(alpha_local)
    
    if np.any(anomalous_mask):
        anomalous_indices = np.where(anomalous_mask)[0]
        
        # Find consecutive region
        regions = []
        start_idx = anomalous_indices[0]
        for i in range(1, len(anomalous_indices)):
            if anomalous_indices[i] - anomalous_indices[i-1] > 1:
                # Gap found, end current region
                regions.append((start_idx, anomalous_indices[i-1]))
                start_idx = anomalous_indices[i]
        
        # Add final region
        regions.append((start_idx, anomalous_indices[-1]))
        
        # Take the longest region
        if regions:
            longest_region = max(regions, key=lambda x: x[1] - x[0])
            return t[longest_region[0]], t[longest_region[1]]
    
    return None, None

def find_plateau_region(t, msd, p, p_c_prime=0.6884):
    """
    Find plateau region for solid regime where α ≈ 0
    """
    alpha_local = calculate_local_alpha(t, msd)
    
    # Look for region where α ≈ 0 ± 0.1
    plateau_mask = (np.abs(alpha_local) < 0.1) & np.isfinite(alpha_local)
    
    if np.any(plateau_mask):
        plateau_indices = np.where(plateau_mask)[0]
        
        # Find consecutive region
        regions = []
        start_idx = plateau_indices[0]
        for i in range(1, len(plateau_indices)):
            if plateau_indices[i] - plateau_indices[i-1] > 1:
                # Gap found, end current region
                regions.append((start_idx, plateau_indices[i-1]))
                start_idx = plateau_indices[i]
        
        # Add final region
        regions.append((start_idx, plateau_indices[-1]))
        
        # Take the latest region (longest plateau)
        if regions:
            latest_region = max(regions, key=lambda x: x[0])  # Latest start time
            return t[latest_region[0]], t[latest_region[1]]
    
    return None, None

def calculate_alpha_in_region(t, msd, t_start, t_end):
    """Calculate α in specified time region"""
    region_mask = (t >= t_start) & (t <= t_end)
    t_region = t[region_mask]
    msd_region = msd[region_mask]
    
    if len(t_region) < 10:
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

def analyze_paper_based_alpha(t, msd, p, p_c_prime=0.6884):
    """
    Calculate α using paper's recommended regions
    """
    print(f"\n=== PAPER-BASED α ANALYSIS ===")
    print(f"p = {p:.4f}")
    
    # Determine regime and strategy
    if p < p_c_prime - 0.05:
        regime = "LIQUID"
        target_alpha = 1.0
        print(f"Regime: {regime} (target α = {target_alpha})")
        print("Strategy: Look in REGULAR DIFFUSION region (τ > τ_cr)")
        
        # Find crossover time
        tau_cr = find_crossover_time(t, msd, p, p_c_prime)
        print(f"τ_cr = {tau_cr:.2e}")
        
        # Use region after τ_cr
        t_start = tau_cr
        t_end = t[-1]
        
        alpha_fitted, r_squared, t_region, msd_region = calculate_alpha_in_region(t, msd, t_start, t_end)
        method = "post_tau_cr"
        
    elif abs(p - p_c_prime) < 0.05:
        regime = "CRITICAL"
        target_alpha = 0.53
        print(f"Regime: {regime} (target α = {target_alpha})")
        print("Strategy: Look in ANOMALOUS DIFFUSION region (τ_ℓ < τ < τ_ξ)")
        
        # Find anomalous diffusion region
        t_start, t_end = find_anomalous_diffusion_region(t, msd, p, p_c_prime)
        
        if t_start is None:
            print("❌ Anomalous diffusion region not found, using fallback")
            # Fallback: use middle region
            mid_idx = len(t) // 2
            t_start = t[mid_idx - 100]
            t_end = t[mid_idx + 100]
            method = "fallback_middle"
        else:
            method = "anomalous_region"
        
        alpha_fitted, r_squared, t_region, msd_region = calculate_alpha_in_region(t, msd, t_start, t_end)
        
    else:
        regime = "SOLID"
        target_alpha = 0.0
        print(f"Regime: {regime} (target α = {target_alpha})")
        print("Strategy: Look in LONG TIME plateau (τ > τ_plateau)")
        
        # Find plateau region
        t_start, t_end = find_plateau_region(t, msd, p, p_c_prime)
        
        if t_start is None:
            print("❌ Plateau region not found, using fallback")
            # Fallback: use late time region
            t_start = t[int(0.8 * len(t))]
            t_end = t[-1]
            method = "fallback_late"
        else:
            method = "plateau_region"
        
        alpha_fitted, r_squared, t_region, msd_region = calculate_alpha_in_region(t, msd, t_start, t_end)
    
    if np.isnan(alpha_fitted):
        print("❌ Failed to calculate α")
        return None
    
    print(f"Time region: τ = {t_start:.2e} to {t_end:.2e}")
    print(f"Data points: {len(t_region) if t_region is not None else 0}")
    print(f"Fitted α = {alpha_fitted:.6f}")
    print(f"R² = {r_squared:.6f}")
    print(f"Method: {method}")
    
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
        'method': method,
        'time_range': (t_start, t_end),
        'data_points': len(t_region) if t_region is not None else 0,
        'alpha_error': alpha_error,
        'relative_error': relative_error,
        'agreement': agreement,
        't_region': t_region,
        'msd_region': msd_region
    }

def plot_paper_based_analysis(t, msd, result, p, seed):
    """Plot analysis with paper-based regions"""
    
    fig, axes = plt.subplots(2, 2, figsize=(15, 12))
    fig.suptitle(f'Paper-Based α Analysis: p = {p:.4f}, seed = {seed:02d}', fontsize=16)
    
    # Plot 1: MSD vs time (log-log)
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
    
    # Plot 2: Local α vs time
    ax2 = axes[0, 1]
    alpha_local = calculate_local_alpha(t, msd)
    valid_mask = np.isfinite(alpha_local)
    ax2.semilogx(t[valid_mask], alpha_local[valid_mask], 'g-', linewidth=2, label='Local α')
    
    # Add theoretical α line
    p_c_prime = 0.6884
    if p < p_c_prime - 0.05:
        ax2.axhline(y=1.0, color='blue', linestyle='--', alpha=0.7, label='α = 1.0 (Liquid)')
    elif abs(p - p_c_prime) < 0.05:
        ax2.axhline(y=0.53, color='orange', linestyle='--', alpha=0.7, label='α = 0.53 (Critical)')
    else:
        ax2.axhline(y=0.0, color='red', linestyle='--', alpha=0.7, label='α = 0.0 (Solid)')
    
    # Mark analysis region
    if result and result['time_range']:
        t_start, t_end = result['time_range']
        ax2.axvspan(t_start, t_end, alpha=0.3, color='red', label='Analysis region')
    
    ax2.set_xlabel('Time τ')
    ax2.set_ylabel('Local α')
    ax2.set_title('Local α vs Time')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: MSD vs time (linear scale)
    ax3 = axes[1, 0]
    ax3.plot(t, msd, 'b-', linewidth=2, label='MSD')
    
    # Mark analysis region
    if result and result['t_region'] is not None:
        ax3.plot(result['t_region'], result['msd_region'], 'r-', linewidth=4, 
                label=f"Analysis region")
    
    ax3.set_xlabel('Time τ')
    ax3.set_ylabel('MSD')
    ax3.set_title('MSD vs Time (Linear Scale)')
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
    plt.savefig(f"{output_dir}/paper_based_alpha_p{p:.4f}_seed{seed:02d}.png", 
                dpi=300, bbox_inches='tight')
    
    return fig

def main():
    """Main analysis function"""
    print("=== PAPER-BASED α ANALYSIS ===")
    print("Direct implementation of paper's findings")
    print("Based on PAPER_VALIDATION_ANALYSIS.md")
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
                
                # Analyze using paper's method
                result = analyze_paper_based_alpha(t, msd, p, p_c_prime)
                
                # Plot analysis
                fig = plot_paper_based_analysis(t, msd, result, p, seed)
                
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
        print("SUMMARY OF PAPER-BASED α ANALYSIS")
        print(f"{'='*80}")
        
        df = pd.DataFrame(results)
        summary_table = df[['p', 'seed', 'regime', 'target_alpha', 'alpha_fitted', 
                           'relative_error', 'agreement', 'method']].copy()
        
        print(summary_table.to_string(index=False, float_format='%.4f'))
        
        # Save results
        output_file = "../paper_figures/paper_based_alpha_results.csv"
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

if __name__ == "__main__":
    main() 