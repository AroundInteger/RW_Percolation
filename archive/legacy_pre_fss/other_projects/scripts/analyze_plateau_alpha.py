#!/usr/bin/env python3
"""
ANALYZE PLATEAU ALPHA
Examine whether α should be estimated on the plateau for p > p_c' (solid regime)
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path
import sys

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))

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

def analyze_msd_plateau(t, msd, p, seed):
    """Analyze MSD curve to identify plateau regions"""
    
    print(f"=== MSD PLATEAU ANALYSIS ===")
    print(f"p = {p:.4f}, seed = {seed:02d}")
    print(f"Data points: {len(t)}")
    print(f"Time range: {t[0]:.2e} to {t[-1]:.2e}")
    print(f"MSD range: {msd[0]:.2e} to {msd[-1]:.2e}")
    print()
    
    # Calculate local slopes (α values) using finite differences
    log_t = np.log10(t)
    log_msd = np.log10(msd)
    
    # Use central differences for local α
    alpha_local = np.zeros_like(t)
    alpha_local[0] = (log_msd[1] - log_msd[0]) / (log_t[1] - log_t[0])
    alpha_local[-1] = (log_msd[-1] - log_msd[-2]) / (log_t[-1] - log_t[-2])
    
    for i in range(1, len(t)-1):
        alpha_local[i] = (log_msd[i+1] - log_msd[i-1]) / (log_t[i+1] - log_t[i-1])
    
    # Find plateau regions (where α is close to 0)
    plateau_threshold = 0.1  # α < 0.1 indicates plateau
    plateau_mask = np.abs(alpha_local) < plateau_threshold
    
    # Find consecutive plateau regions
    plateau_regions = []
    start_idx = None
    
    for i in range(len(plateau_mask)):
        if plateau_mask[i] and start_idx is None:
            start_idx = i
        elif not plateau_mask[i] and start_idx is not None:
            plateau_regions.append((start_idx, i-1))
            start_idx = None
    
    # Handle case where plateau extends to end
    if start_idx is not None:
        plateau_regions.append((start_idx, len(plateau_mask)-1))
    
    print(f"=== PLATEAU DETECTION ===")
    print(f"Plateau threshold: α < {plateau_threshold}")
    print(f"Total plateau points: {np.sum(plateau_mask)} ({100*np.sum(plateau_mask)/len(plateau_mask):.1f}%)")
    print(f"Number of plateau regions: {len(plateau_regions)}")
    print()
    
    # Analyze each plateau region
    for i, (start, end) in enumerate(plateau_regions):
        region_length = end - start + 1
        time_range = (t[start], t[end])
        msd_range = (msd[start], msd[end])
        alpha_mean = np.mean(alpha_local[start:end+1])
        alpha_std = np.std(alpha_local[start:end+1])
        
        print(f"Plateau Region {i+1}:")
        print(f"  Indices: {start} to {end} (length: {region_length})")
        print(f"  Time range: {time_range[0]:.2e} to {time_range[1]:.2e}")
        print(f"  MSD range: {msd_range[0]:.2e} to {msd_range[1]:.2e}")
        print(f"  α mean: {alpha_mean:.6f} ± {alpha_std:.6f}")
        print()
    
    # Find the longest plateau region
    if plateau_regions:
        longest_plateau = max(plateau_regions, key=lambda x: x[1] - x[0])
        start_long, end_long = longest_plateau
        
        print(f"=== LONGEST PLATEAU REGION ===")
        print(f"Indices: {start_long} to {end_long}")
        print(f"Length: {end_long - start_long + 1} points")
        print(f"Time range: {t[start_long]:.2e} to {t[end_long]:.2e}")
        print(f"MSD range: {msd[start_long]:.2e} to {msd[end_long]:.2e}")
        print(f"α mean: {np.mean(alpha_local[start_long:end_long+1]):.6f}")
        print()
        
        # Fit α on the plateau region
        t_plateau = t[start_long:end_long+1]
        msd_plateau = msd[start_long:end_long+1]
        
        if len(t_plateau) >= 10:  # Need enough points for fitting
            log_t_plateau = np.log10(t_plateau)
            log_msd_plateau = np.log10(msd_plateau)
            
            # Linear fit on plateau
            coeffs = np.polyfit(log_t_plateau, log_msd_plateau, 1)
            alpha_plateau = coeffs[0]
            intercept_plateau = coeffs[1]
            
            # Calculate R²
            msd_pred = 10**(alpha_plateau * log_t_plateau + intercept_plateau)
            ss_res = np.sum((msd_plateau - msd_pred)**2)
            ss_tot = np.sum((msd_plateau - np.mean(msd_plateau))**2)
            r_squared_plateau = 1 - (ss_res / ss_tot) if ss_tot > 0 else 0
            
            print(f"=== PLATEAU α FIT ===")
            print(f"α_plateau = {alpha_plateau:.6f}")
            print(f"R² = {r_squared_plateau:.6f}")
            print(f"Equation: MSD ∝ t^{alpha_plateau:.3f}")
            print()
        else:
            print("Insufficient points for plateau fitting")
            alpha_plateau = np.nan
            r_squared_plateau = np.nan
    else:
        print("No plateau regions detected")
        alpha_plateau = np.nan
        r_squared_plateau = np.nan
        longest_plateau = None
    
    return {
        'alpha_local': alpha_local,
        'plateau_mask': plateau_mask,
        'plateau_regions': plateau_regions,
        'longest_plateau': longest_plateau,
        'alpha_plateau': alpha_plateau,
        'r_squared_plateau': r_squared_plateau
    }

def plot_msd_plateau_analysis(t, msd, results, p, seed):
    """Plot MSD curve with plateau analysis"""
    
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 10))
    
    alpha_local = results['alpha_local']
    plateau_mask = results['plateau_mask']
    plateau_regions = results['plateau_regions']
    longest_plateau = results['longest_plateau']
    
    # Plot 1: MSD vs time
    ax1.loglog(t, msd, 'b-', linewidth=1, label='MSD')
    
    # Highlight plateau regions
    for start, end in plateau_regions:
        ax1.loglog(t[start:end+1], msd[start:end+1], 'r-', linewidth=3, alpha=0.7)
    
    # Highlight longest plateau
    if longest_plateau:
        start_long, end_long = longest_plateau
        ax1.loglog(t[start_long:end_long+1], msd[start_long:end_long+1], 'g-', linewidth=4, alpha=0.8, label='Longest Plateau')
    
    ax1.set_xlabel('Time (τ)')
    ax1.set_ylabel('MSD')
    ax1.set_title(f'MSD vs Time (p = {p:.4f}, seed = {seed:02d})')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: Local α vs time
    ax2.semilogx(t, alpha_local, 'b-', linewidth=1, label='Local α')
    ax2.axhline(0, color='black', linestyle='-', alpha=0.5)
    ax2.axhline(0.1, color='orange', linestyle='--', label='Plateau threshold')
    ax2.axhline(-0.1, color='orange', linestyle='--')
    
    # Highlight plateau regions
    for start, end in plateau_regions:
        ax2.semilogx(t[start:end+1], alpha_local[start:end+1], 'r-', linewidth=3, alpha=0.7)
    
    ax2.set_xlabel('Time (τ)')
    ax2.set_ylabel('Local α')
    ax2.set_title('Local α vs Time')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: MSD plateau zoom
    if longest_plateau:
        start_long, end_long = longest_plateau
        t_plateau = t[start_long:end_long+1]
        msd_plateau = msd[start_long:end_long+1]
        
        ax3.loglog(t_plateau, msd_plateau, 'g-', linewidth=2, label='Plateau MSD')
        
        # Add fit line if available
        if not np.isnan(results['alpha_plateau']):
            alpha_plateau = results['alpha_plateau']
            intercept_plateau = np.polyfit(np.log10(t_plateau), np.log10(msd_plateau), 1)[1]
            msd_fit = 10**(alpha_plateau * np.log10(t_plateau) + intercept_plateau)
            ax3.loglog(t_plateau, msd_fit, 'r--', linewidth=2, label=f'Fit: α = {alpha_plateau:.3f}')
        
        ax3.set_xlabel('Time (τ)')
        ax3.set_ylabel('MSD')
        ax3.set_title('Longest Plateau Region')
        ax3.legend()
        ax3.grid(True, alpha=0.3)
    else:
        ax3.text(0.5, 0.5, 'No plateau detected', ha='center', va='center', transform=ax3.transAxes)
        ax3.set_title('Longest Plateau Region')
    
    # Plot 4: α distribution
    ax4.hist(alpha_local, bins=50, alpha=0.7, color='blue', edgecolor='black')
    ax4.axvline(0, color='red', linestyle='--', label='α = 0')
    ax4.axvline(0.1, color='orange', linestyle='--', label='Plateau threshold')
    ax4.axvline(-0.1, color='orange', linestyle='--')
    ax4.set_xlabel('Local α')
    ax4.set_ylabel('Frequency')
    ax4.set_title('Local α Distribution')
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(f'msd_plateau_analysis_p{p:.4f}_seed{seed:02d}.png', dpi=300, bbox_inches='tight')
    plt.show()

def compare_methods(t, msd, p, seed):
    """Compare early α vs plateau α methods"""
    
    print(f"=== METHOD COMPARISON ===")
    print(f"p = {p:.4f}, seed = {seed:02d}")
    print()
    
    # Method 1: Early α (our current method)
    window_size = min(50, len(t) // 20)
    start_idx = max(10, window_size // 2)
    
    # Use first window for early α
    window_start = max(0, start_idx - window_size // 2)
    window_end = min(len(t), start_idx + window_size // 2)
    
    t_early = t[window_start:window_end]
    msd_early = msd[window_start:window_end]
    
    log_t_early = np.log10(t_early)
    log_msd_early = np.log10(msd_early)
    
    coeffs_early = np.polyfit(log_t_early, log_msd_early, 1)
    alpha_early = coeffs_early[0]
    
    # Calculate R² for early fit
    msd_pred_early = 10**(alpha_early * log_t_early + coeffs_early[1])
    ss_res_early = np.sum((msd_early - msd_pred_early)**2)
    ss_tot_early = np.sum((msd_early - np.mean(msd_early))**2)
    r_squared_early = 1 - (ss_res_early / ss_tot_early) if ss_tot_early > 0 else 0
    
    print(f"Method 1: Early α (current method)")
    print(f"  Time range: {t_early[0]:.2e} to {t_early[-1]:.2e}")
    print(f"  α_early = {alpha_early:.6f}")
    print(f"  R² = {r_squared_early:.6f}")
    print()
    
    # Method 2: Plateau α
    results = analyze_msd_plateau(t, msd, p, seed)
    alpha_plateau = results['alpha_plateau']
    r_squared_plateau = results['r_squared_plateau']
    
    print(f"Method 2: Plateau α")
    if not np.isnan(alpha_plateau):
        print(f"  α_plateau = {alpha_plateau:.6f}")
        print(f"  R² = {r_squared_plateau:.6f}")
        
        # Determine which method is better for p > p_c'
        if p > 0.6884:  # p > p_c'
            print(f"  Recommendation: Use plateau α for p > p_c'")
            if abs(alpha_plateau) < abs(alpha_early):
                print(f"  ✓ Plateau α is closer to 0 (expected for solid)")
            else:
                print(f"  ⚠ Early α is closer to 0")
        else:
            print(f"  Recommendation: Use early α for p ≤ p_c'")
    else:
        print(f"  No plateau detected")
        print(f"  Recommendation: Use early α")
    
    print()
    
    return {
        'alpha_early': alpha_early,
        'r_squared_early': r_squared_early,
        'alpha_plateau': alpha_plateau,
        'r_squared_plateau': r_squared_plateau,
        'results': results
    }

def main():
    """Main analysis function"""
    
    # Test cases: focus on p > p_c' (solid regime)
    test_cases = [
        (0.7500, 1, "SOLID"),
        (0.7500, 2, "SOLID"),
        (0.8000, 1, "SOLID"),  # If available
        (0.8500, 1, "SOLID"),  # If available
    ]
    
    print("=== PLATEAU α ANALYSIS ===")
    print("Examining whether α should be estimated on the plateau for p > p_c'")
    print("=" * 60)
    
    for p, seed, regime in test_cases:
        print(f"\n{'='*60}")
        print(f"ANALYZING: p = {p:.4f}, seed = {seed:02d}, regime = {regime}")
        print(f"{'='*60}")
        
        try:
            # Load data
            t, msd = load_ensemble_data(p, seed)
            
            # Compare methods
            comparison = compare_methods(t, msd, p, seed)
            
            # Plot analysis
            plot_msd_plateau_analysis(t, msd, comparison['results'], p, seed)
            
        except Exception as e:
            print(f"Error analyzing p = {p:.4f}, seed = {seed:02d}: {e}")
        
        print(f"\n{'-'*60}")

if __name__ == "__main__":
    main() 