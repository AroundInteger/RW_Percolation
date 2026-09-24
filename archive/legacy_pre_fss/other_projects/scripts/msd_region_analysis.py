#!/usr/bin/env python3
"""
MSD Region Analysis: Identify Four Distinct Regions Using Smoothed 2nd Derivatives

Based on PAPER_VALIDATION_ANALYSIS.md, we need to identify:
1. Region 1: Finite Size Effects (α < 1 and decreasing with τ)
2. Region 2: Anomalous Diffusion (constant α < 1)
3. Region 3: Transition Region (α increasing with τ)
4. Region 4: Regular Diffusion (α ≈ 1)

This script uses smoothed 2nd derivatives to identify these regions.
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import os
from scipy.signal import savgol_filter
from scipy.interpolate import interp1d

def load_ensemble_data(p, seed):
    """Load MSD data for given p and seed"""
    filename = f"../ensemble_simulations/seed_{seed:02d}/p_{p:.4f}/msd_results_L500_p{p:.4f}.csv"
    
    if not os.path.exists(filename):
        raise FileNotFoundError(f"Data file not found: {filename}")
    
    data = pd.read_csv(filename)
    t = data['tau'].values
    msd = data['msd'].values
    
    return t, msd

def calculate_smoothed_derivatives(t, msd, window_size=15, polyorder=3):
    """
    Calculate smoothed 1st and 2nd derivatives of log(MSD) vs log(t)
    
    Parameters:
    - t: time array
    - msd: MSD array
    - window_size: Savitzky-Golay filter window size
    - polyorder: Savitzky-Golay filter polynomial order
    
    Returns:
    - log_t: log10(t)
    - log_msd: log10(MSD)
    - alpha_local: local α values (1st derivative)
    - alpha_2nd_deriv: 2nd derivative of α
    """
    # Convert to log space
    log_t = np.log10(t)
    log_msd = np.log10(msd)
    
    # Remove any infinite or NaN values
    valid_mask = np.isfinite(log_t) & np.isfinite(log_msd)
    log_t_clean = log_t[valid_mask]
    log_msd_clean = log_msd[valid_mask]
    
    if len(log_t_clean) < window_size:
        print(f"Warning: Not enough data points for smoothing (need {window_size}, have {len(log_t_clean)})")
        return log_t, log_msd, np.full_like(log_t, np.nan), np.full_like(log_t, np.nan)
    
    # Calculate local α (1st derivative) using Savitzky-Golay
    alpha_local = savgol_filter(log_msd_clean, window_size, polyorder, deriv=1)
    
    # Calculate 2nd derivative of α
    alpha_2nd_deriv = savgol_filter(alpha_local, window_size, polyorder, deriv=1)
    
    # Map back to original arrays
    alpha_full = np.full_like(log_t, np.nan)
    alpha_2nd_full = np.full_like(log_t, np.nan)
    
    alpha_full[valid_mask] = alpha_local
    alpha_2nd_full[valid_mask] = alpha_2nd_deriv
    
    return log_t, log_msd, alpha_full, alpha_2nd_full

def identify_msd_regions(t, msd, alpha_local, alpha_2nd_deriv, p, p_c_prime=0.6884):
    """
    Identify the four MSD regions based on paper validation analysis
    
    Returns:
    - regions: dictionary with region boundaries and characteristics
    """
    log_t = np.log10(t)
    
    # Initialize regions
    regions = {
        'region1_finite_size': {'start': None, 'end': None, 'characteristic': 'α < 1 and decreasing'},
        'region2_anomalous': {'start': None, 'end': None, 'characteristic': 'constant α < 1'},
        'region3_transition': {'start': None, 'end': None, 'characteristic': 'α increasing with τ'},
        'region4_regular': {'start': None, 'end': None, 'characteristic': 'α ≈ 1'}
    }
    
    # Find valid data points
    valid_mask = np.isfinite(alpha_local) & np.isfinite(alpha_2nd_deriv)
    valid_indices = np.where(valid_mask)[0]
    
    if len(valid_indices) < 20:
        print(f"Warning: Insufficient valid data points for region identification")
        return regions
    
    # Region 1: Finite Size Effects (α < 1 and decreasing with τ)
    # Look for early region where α < 1 and dα/dτ < 0 (2nd derivative < 0)
    finite_size_mask = (alpha_local < 1.0) & (alpha_2nd_deriv < 0) & valid_mask
    if np.any(finite_size_mask):
        finite_size_indices = np.where(finite_size_mask)[0]
        # Take the earliest consecutive region
        regions['region1_finite_size']['start'] = t[finite_size_indices[0]]
        regions['region1_finite_size']['end'] = t[finite_size_indices[-1]]
    
    # Region 2: Anomalous Diffusion (constant α < 1)
    # Look for region where α is relatively constant and < 1
    # This is most important for p ≈ p_c_prime
    if abs(p - p_c_prime) < 0.05:  # Critical regime
        # Look for region with α ≈ 0.5 and small 2nd derivative
        anomalous_mask = (np.abs(alpha_local - 0.5) < 0.2) & (np.abs(alpha_2nd_deriv) < 0.01) & valid_mask
        if np.any(anomalous_mask):
            anomalous_indices = np.where(anomalous_mask)[0]
            regions['region2_anomalous']['start'] = t[anomalous_indices[0]]
            regions['region2_anomalous']['end'] = t[anomalous_indices[-1]]
    
    # Region 3: Transition Region (α increasing with τ)
    # Look for region where 2nd derivative > 0 (α increasing)
    transition_mask = (alpha_2nd_deriv > 0.01) & valid_mask
    if np.any(transition_mask):
        transition_indices = np.where(transition_mask)[0]
        regions['region3_transition']['start'] = t[transition_indices[0]]
        regions['region3_transition']['end'] = t[transition_indices[-1]]
    
    # Region 4: Regular Diffusion (α ≈ 1)
    # Look for region where α ≈ 1.0 and stable
    # This is most important for p < p_c_prime
    if p < p_c_prime - 0.05:  # Liquid regime
        regular_mask = (np.abs(alpha_local - 1.0) < 0.1) & (np.abs(alpha_2nd_deriv) < 0.01) & valid_mask
        if np.any(regular_mask):
            regular_indices = np.where(regular_mask)[0]
            regions['region4_regular']['start'] = t[regular_indices[0]]
            regions['region4_regular']['end'] = t[regular_indices[-1]]
    
    return regions

def plot_msd_region_analysis(t, msd, alpha_local, alpha_2nd_deriv, regions, p, seed):
    """Plot MSD analysis with identified regions"""
    
    fig, axes = plt.subplots(2, 2, figsize=(15, 12))
    fig.suptitle(f'MSD Region Analysis: p = {p:.4f}, seed = {seed:02d}', fontsize=16)
    
    # Plot 1: MSD vs time (log-log)
    ax1 = axes[0, 0]
    ax1.loglog(t, msd, 'b-', linewidth=2, label='MSD')
    
    # Mark regions on MSD plot
    colors = ['red', 'orange', 'green', 'blue']
    region_names = ['Finite Size', 'Anomalous', 'Transition', 'Regular']
    
    for i, (region_key, region_info) in enumerate(regions.items()):
        if region_info['start'] is not None and region_info['end'] is not None:
            region_msd = msd[(t >= region_info['start']) & (t <= region_info['end'])]
            region_t = t[(t >= region_info['start']) & (t <= region_info['end'])]
            if len(region_t) > 0:
                ax1.loglog(region_t, region_msd, color=colors[i], linewidth=4, 
                          label=f"{region_names[i]}: {region_info['characteristic']}")
    
    ax1.set_xlabel('Time τ')
    ax1.set_ylabel('MSD')
    ax1.set_title('MSD vs Time (Log-Log)')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: Local α vs time
    ax2 = axes[0, 1]
    valid_mask = np.isfinite(alpha_local)
    ax2.semilogx(t[valid_mask], alpha_local[valid_mask], 'g-', linewidth=2, label='Local α')
    
    # Add theoretical α lines
    p_c_prime = 0.6884
    if p < p_c_prime - 0.05:
        ax2.axhline(y=1.0, color='blue', linestyle='--', alpha=0.7, label='α = 1.0 (Liquid)')
    elif abs(p - p_c_prime) < 0.05:
        ax2.axhline(y=0.53, color='orange', linestyle='--', alpha=0.7, label='α = 0.53 (Critical)')
    else:
        ax2.axhline(y=0.0, color='red', linestyle='--', alpha=0.7, label='α = 0.0 (Solid)')
    
    ax2.set_xlabel('Time τ')
    ax2.set_ylabel('Local α')
    ax2.set_title('Local α vs Time')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: 2nd derivative of α vs time
    ax3 = axes[1, 0]
    valid_mask_2nd = np.isfinite(alpha_2nd_deriv)
    ax3.semilogx(t[valid_mask_2nd], alpha_2nd_deriv[valid_mask_2nd], 'r-', linewidth=2, label='d²α/dτ²')
    ax3.axhline(y=0, color='black', linestyle='-', alpha=0.5)
    ax3.set_xlabel('Time τ')
    ax3.set_ylabel('d²α/dτ²')
    ax3.set_title('2nd Derivative of α vs Time')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: MSD vs time (linear scale for plateau detection)
    ax4 = axes[1, 1]
    ax4.plot(t, msd, 'b-', linewidth=2, label='MSD')
    
    # Mark regions on linear plot
    for i, (region_key, region_info) in enumerate(regions.items()):
        if region_info['start'] is not None and region_info['end'] is not None:
            region_msd = msd[(t >= region_info['start']) & (t <= region_info['end'])]
            region_t = t[(t >= region_info['start']) & (t <= region_info['end'])]
            if len(region_t) > 0:
                ax4.plot(region_t, region_msd, color=colors[i], linewidth=4, 
                        label=f"{region_names[i]}")
    
    ax4.set_xlabel('Time τ')
    ax4.set_ylabel('MSD')
    ax4.set_title('MSD vs Time (Linear Scale)')
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/msd_region_analysis_p{p:.4f}_seed{seed:02d}.png", 
                dpi=300, bbox_inches='tight')
    
    return fig

def analyze_regime_specific_alpha(t, msd, alpha_local, regions, p, p_c_prime=0.6884):
    """
    Calculate α using regime-specific regions based on paper validation
    """
    print(f"\n=== REGIME-SPECIFIC α ANALYSIS ===")
    print(f"p = {p:.4f}")
    
    # Determine regime
    if p < p_c_prime - 0.05:
        regime = "LIQUID"
        target_alpha = 1.0
        target_region = "region4_regular"
        print(f"Regime: {regime} (target α = {target_alpha})")
    elif abs(p - p_c_prime) < 0.05:
        regime = "CRITICAL"
        target_alpha = 0.53
        target_region = "region2_anomalous"
        print(f"Regime: {regime} (target α = {target_alpha})")
    else:
        regime = "SOLID"
        target_alpha = 0.0
        target_region = "region4_regular"  # Plateau region
        print(f"Regime: {regime} (target α = {target_alpha})")
    
    # Check if target region is identified
    region_info = regions[target_region]
    if region_info['start'] is None or region_info['end'] is None:
        print(f"❌ Target region '{target_region}' not identified!")
        print("Available regions:")
        for key, info in regions.items():
            if info['start'] is not None:
                print(f"  {key}: τ = {info['start']:.2e} to {info['end']:.2e}")
        return None
    
    # Calculate α in target region
    region_mask = (t >= region_info['start']) & (t <= region_info['end'])
    t_region = t[region_mask]
    msd_region = msd[region_mask]
    
    if len(t_region) < 10:
        print(f"❌ Insufficient data points in target region ({len(t_region)} < 10)")
        return None
    
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
    
    print(f"Target region: {target_region}")
    print(f"Time range: τ = {region_info['start']:.2e} to {region_info['end']:.2e}")
    print(f"Data points: {len(t_region)}")
    print(f"Fitted α = {alpha_fitted:.6f}")
    print(f"R² = {r_squared:.6f}")
    
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
        'region_used': target_region,
        'time_range': (region_info['start'], region_info['end']),
        'data_points': len(t_region),
        'alpha_error': alpha_error,
        'relative_error': relative_error,
        'agreement': agreement
    }

def main():
    """Main analysis function"""
    print("=== MSD REGION ANALYSIS ===")
    print("Identifying four distinct regions using smoothed 2nd derivatives")
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
                
                # Calculate smoothed derivatives
                log_t, log_msd, alpha_local, alpha_2nd_deriv = calculate_smoothed_derivatives(t, msd)
                
                # Identify regions
                regions = identify_msd_regions(t, msd, alpha_local, alpha_2nd_deriv, p, p_c_prime)
                
                # Plot analysis
                fig = plot_msd_region_analysis(t, msd, alpha_local, alpha_2nd_deriv, regions, p, seed)
                
                # Analyze regime-specific α
                result = analyze_regime_specific_alpha(t, msd, alpha_local, regions, p, p_c_prime)
                
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
        print("SUMMARY OF REGIME-SPECIFIC α ANALYSIS")
        print(f"{'='*80}")
        
        df = pd.DataFrame(results)
        summary_table = df[['p', 'seed', 'regime', 'target_alpha', 'alpha_fitted', 
                           'relative_error', 'agreement', 'region_used']].copy()
        
        print(summary_table.to_string(index=False, float_format='%.4f'))
        
        # Save results
        output_file = "../paper_figures/msd_region_analysis_results.csv"
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