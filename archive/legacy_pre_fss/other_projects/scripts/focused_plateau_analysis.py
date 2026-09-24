#!/usr/bin/env python3
"""
FOCUSED PLATEAU ANALYSIS
Examine plateau behavior for p > p_c' and compare with early α method
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

def analyze_plateau_behavior(t, msd, p, seed):
    """Analyze plateau behavior in MSD curves"""
    
    print(f"=== PLATEAU ANALYSIS FOR p = {p:.4f}, seed = {seed:02d} ===")
    
    # Calculate local α using finite differences
    log_t = np.log10(t)
    log_msd = np.log10(msd)
    
    # Use central differences for local α
    alpha_local = np.zeros_like(t)
    alpha_local[0] = (log_msd[1] - log_msd[0]) / (log_t[1] - log_t[0])
    alpha_local[-1] = (log_msd[-1] - log_msd[-2]) / (log_t[-1] - log_t[-2])
    
    for i in range(1, len(t)-1):
        alpha_local[i] = (log_msd[i+1] - log_msd[i-1]) / (log_t[i+1] - log_t[i-1])
    
    # Find regions where α is close to 0 (plateau regions)
    plateau_threshold = 0.1
    plateau_mask = np.abs(alpha_local) < plateau_threshold
    
    # Find consecutive plateau regions
    plateau_regions = []
    start_idx = None
    
    for i in range(len(plateau_mask)):
        if plateau_mask[i] and start_idx is None:
            start_idx = i
        elif not plateau_mask[i] and start_idx is not None:
            if i - start_idx >= 5:  # Minimum 5 consecutive points
                plateau_regions.append((start_idx, i-1))
            start_idx = None
    
    # Handle case where plateau extends to end
    if start_idx is not None and len(plateau_mask) - start_idx >= 5:
        plateau_regions.append((start_idx, len(plateau_mask)-1))
    
    print(f"Plateau threshold: |α| < {plateau_threshold}")
    print(f"Total plateau points: {np.sum(plateau_mask)} ({100*np.sum(plateau_mask)/len(plateau_mask):.1f}%)")
    print(f"Number of plateau regions (≥5 points): {len(plateau_regions)}")
    
    # Analyze plateau regions
    plateau_analysis = []
    for i, (start, end) in enumerate(plateau_regions):
        region_length = end - start + 1
        time_range = (t[start], t[end])
        msd_range = (msd[start], msd[end])
        alpha_mean = np.mean(alpha_local[start:end+1])
        alpha_std = np.std(alpha_local[start:end+1])
        
        print(f"\nPlateau Region {i+1}:")
        print(f"  Length: {region_length} points")
        print(f"  Time: {time_range[0]:.2e} to {time_range[1]:.2e}")
        print(f"  MSD: {msd_range[0]:.2e} to {msd_range[1]:.2e}")
        print(f"  α: {alpha_mean:.6f} ± {alpha_std:.6f}")
        
        plateau_analysis.append({
            'region': i+1,
            'start_idx': start,
            'end_idx': end,
            'length': region_length,
            'time_start': time_range[0],
            'time_end': time_range[1],
            'msd_start': msd_range[0],
            'msd_end': msd_range[1],
            'alpha_mean': alpha_mean,
            'alpha_std': alpha_std
        })
    
    return alpha_local, plateau_regions, plateau_analysis

def compare_early_vs_plateau_alpha(t, msd, p, seed):
    """Compare early α vs plateau α methods"""
    
    print(f"\n=== METHOD COMPARISON ===")
    
    # Method 1: Early α (our current method)
    window_size = min(50, len(t) // 20)
    start_idx = max(10, window_size // 2)
    
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
    
    print(f"Method 1: Early α (current)")
    print(f"  Time range: {t_early[0]:.2e} to {t_early[-1]:.2e}")
    print(f"  α_early = {alpha_early:.6f}")
    print(f"  R² = {r_squared_early:.6f}")
    
    # Method 2: Plateau α
    alpha_local, plateau_regions, plateau_analysis = analyze_plateau_behavior(t, msd, p, seed)
    
    if plateau_analysis:
        # Use the longest plateau region
        longest_plateau = max(plateau_analysis, key=lambda x: x['length'])
        
        start_long = longest_plateau['start_idx']
        end_long = longest_plateau['end_idx']
        
        t_plateau = t[start_long:end_long+1]
        msd_plateau = msd[start_long:end_long+1]
        
        log_t_plateau = np.log10(t_plateau)
        log_msd_plateau = np.log10(msd_plateau)
        
        coeffs_plateau = np.polyfit(log_t_plateau, log_msd_plateau, 1)
        alpha_plateau = coeffs_plateau[0]
        
        # Calculate R² for plateau fit
        msd_pred_plateau = 10**(alpha_plateau * log_t_plateau + coeffs_plateau[1])
        ss_res_plateau = np.sum((msd_plateau - msd_pred_plateau)**2)
        ss_tot_plateau = np.sum((msd_plateau - np.mean(msd_plateau))**2)
        r_squared_plateau = 1 - (ss_res_plateau / ss_tot_plateau) if ss_tot_plateau > 0 else 0
        
        print(f"\nMethod 2: Plateau α")
        print(f"  Time range: {t_plateau[0]:.2e} to {t_plateau[-1]:.2e}")
        print(f"  α_plateau = {alpha_plateau:.6f}")
        print(f"  R² = {r_squared_plateau:.6f}")
        print(f"  Plateau length: {longest_plateau['length']} points")
        
        # Compare methods
        print(f"\n=== COMPARISON ===")
        print(f"Early α: {alpha_early:.6f} (R² = {r_squared_early:.6f})")
        print(f"Plateau α: {alpha_plateau:.6f} (R² = {r_squared_plateau:.6f})")
        
        if p > 0.6884:  # p > p_c'
            print(f"\nFor p > p_c' (solid regime):")
            if abs(alpha_plateau) < abs(alpha_early):
                print(f"✓ Plateau α ({alpha_plateau:.3f}) is closer to 0 than early α ({alpha_early:.3f})")
                print(f"  Recommendation: Use plateau α for p > p_c'")
            else:
                print(f"⚠ Early α ({alpha_early:.3f}) is closer to 0 than plateau α ({alpha_plateau:.3f})")
                print(f"  Recommendation: Use early α for p > p_c'")
        
        return {
            'alpha_early': alpha_early,
            'r_squared_early': r_squared_early,
            'alpha_plateau': alpha_plateau,
            'r_squared_plateau': r_squared_plateau,
            'plateau_analysis': plateau_analysis,
            'alpha_local': alpha_local,
            'plateau_regions': plateau_regions
        }
    else:
        print(f"\nMethod 2: Plateau α")
        print(f"  No significant plateau regions found")
        print(f"  Recommendation: Use early α")
        
        return {
            'alpha_early': alpha_early,
            'r_squared_early': r_squared_early,
            'alpha_plateau': np.nan,
            'r_squared_plateau': np.nan,
            'plateau_analysis': [],
            'alpha_local': alpha_local,
            'plateau_regions': []
        }

def plot_comparison(t, msd, results, p, seed):
    """Plot comparison of early vs plateau α methods"""
    
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 10))
    
    alpha_local = results['alpha_local']
    plateau_regions = results['plateau_regions']
    alpha_early = results['alpha_early']
    alpha_plateau = results['alpha_plateau']
    
    # Plot 1: MSD vs time
    ax1.loglog(t, msd, 'b-', linewidth=1, label='MSD', alpha=0.7)
    
    # Highlight early region
    window_size = min(50, len(t) // 20)
    start_idx = max(10, window_size // 2)
    window_start = max(0, start_idx - window_size // 2)
    window_end = min(len(t), start_idx + window_size // 2)
    ax1.loglog(t[window_start:window_end], msd[window_start:window_end], 'r-', linewidth=3, label=f'Early region (α = {alpha_early:.3f})')
    
    # Highlight plateau regions
    for start, end in plateau_regions:
        ax1.loglog(t[start:end+1], msd[start:end+1], 'g-', linewidth=2, alpha=0.8)
    
    # Highlight longest plateau if available
    if results['plateau_analysis']:
        longest_plateau = max(results['plateau_analysis'], key=lambda x: x['length'])
        start_long = longest_plateau['start_idx']
        end_long = longest_plateau['end_idx']
        ax1.loglog(t[start_long:end_long+1], msd[start_long:end_long+1], 'orange', linewidth=4, label=f'Longest plateau (α = {alpha_plateau:.3f})')
    
    ax1.set_xlabel('Time (τ)')
    ax1.set_ylabel('MSD')
    ax1.set_title(f'MSD vs Time (p = {p:.4f}, seed = {seed:02d})')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: Local α vs time
    ax2.semilogx(t, alpha_local, 'b-', linewidth=1, label='Local α', alpha=0.7)
    ax2.axhline(0, color='black', linestyle='-', alpha=0.5)
    ax2.axhline(0.1, color='orange', linestyle='--', label='Plateau threshold')
    ax2.axhline(-0.1, color='orange', linestyle='--')
    
    # Highlight early region
    ax2.semilogx(t[window_start:window_end], alpha_local[window_start:window_end], 'r-', linewidth=3, label=f'Early region (α = {alpha_early:.3f})')
    
    # Highlight plateau regions
    for start, end in plateau_regions:
        ax2.semilogx(t[start:end+1], alpha_local[start:end+1], 'g-', linewidth=2, alpha=0.8)
    
    ax2.set_xlabel('Time (τ)')
    ax2.set_ylabel('Local α')
    ax2.set_title('Local α vs Time')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: Early region zoom
    ax3.loglog(t_early, msd_early, 'r-', linewidth=2, label='Early MSD')
    
    # Add early fit line
    msd_fit_early = 10**(alpha_early * log_t_early + coeffs_early[1])
    ax3.loglog(t_early, msd_fit_early, 'r--', linewidth=2, label=f'Early fit: α = {alpha_early:.3f}')
    
    ax3.set_xlabel('Time (τ)')
    ax3.set_ylabel('MSD')
    ax3.set_title('Early Region Analysis')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: Plateau region zoom (if available)
    if results['plateau_analysis']:
        longest_plateau = max(results['plateau_analysis'], key=lambda x: x['length'])
        start_long = longest_plateau['start_idx']
        end_long = longest_plateau['end_idx']
        
        t_plateau = t[start_long:end_long+1]
        msd_plateau = msd[start_long:end_long+1]
        
        ax4.loglog(t_plateau, msd_plateau, 'orange', linewidth=2, label='Plateau MSD')
        
        # Add plateau fit line
        log_t_plateau = np.log10(t_plateau)
        log_msd_plateau = np.log10(msd_plateau)
        coeffs_plateau = np.polyfit(log_t_plateau, log_msd_plateau, 1)
        msd_fit_plateau = 10**(alpha_plateau * log_t_plateau + coeffs_plateau[1])
        ax4.loglog(t_plateau, msd_fit_plateau, 'orange', linestyle='--', linewidth=2, label=f'Plateau fit: α = {alpha_plateau:.3f}')
        
        ax4.set_xlabel('Time (τ)')
        ax4.set_ylabel('MSD')
        ax4.set_title('Longest Plateau Region')
        ax4.legend()
        ax4.grid(True, alpha=0.3)
    else:
        ax4.text(0.5, 0.5, 'No significant plateau regions', ha='center', va='center', transform=ax4.transAxes)
        ax4.set_title('Plateau Region')
    
    plt.tight_layout()
    plt.savefig(f'plateau_comparison_p{p:.4f}_seed{seed:02d}.png', dpi=300, bbox_inches='tight')
    plt.show()

def main():
    """Main analysis function"""
    
    # Test cases: focus on p > p_c' (solid regime)
    test_cases = [
        (0.7500, 1, "SOLID"),
        (0.7500, 2, "SOLID"),
    ]
    
    print("=== FOCUSED PLATEAU ANALYSIS ===")
    print("Examining whether α should be estimated on the plateau for p > p_c'")
    print("=" * 60)
    
    all_results = []
    
    for p, seed, regime in test_cases:
        print(f"\n{'='*60}")
        print(f"ANALYZING: p = {p:.4f}, seed = {seed:02d}, regime = {regime}")
        print(f"{'='*60}")
        
        try:
            # Load data
            t, msd = load_ensemble_data(p, seed)
            
            # Compare methods
            results = compare_early_vs_plateau_alpha(t, msd, p, seed)
            results['p'] = p
            results['seed'] = seed
            results['regime'] = regime
            
            all_results.append(results)
            
            # Plot analysis
            plot_comparison(t, msd, results, p, seed)
            
        except Exception as e:
            print(f"Error analyzing p = {p:.4f}, seed = {seed:02d}: {e}")
        
        print(f"\n{'-'*60}")
    
    # Summary
    print(f"\n{'='*60}")
    print("SUMMARY")
    print(f"{'='*60}")
    
    for result in all_results:
        p = result['p']
        seed = result['seed']
        alpha_early = result['alpha_early']
        alpha_plateau = result['alpha_plateau']
        
        print(f"p = {p:.4f}, seed = {seed:02d}:")
        print(f"  Early α: {alpha_early:.6f}")
        if not np.isnan(alpha_plateau):
            print(f"  Plateau α: {alpha_plateau:.6f}")
            if p > 0.6884:  # p > p_c'
                if abs(alpha_plateau) < abs(alpha_early):
                    print(f"  ✓ Plateau α is better for p > p_c'")
                else:
                    print(f"  ⚠ Early α is better for p > p_c'")
        else:
            print(f"  No plateau detected")
        print()

if __name__ == "__main__":
    main() 