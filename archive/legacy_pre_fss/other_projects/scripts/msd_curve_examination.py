#!/usr/bin/env python3
"""
MSD Curve Examination: Understanding the Actual Data Structure

This script examines the actual MSD curves to understand where the correct regions
for α determination should be, based on the paper's findings.
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

def examine_msd_curves():
    """Examine MSD curves to understand the data structure"""
    
    p_values = [0.0000, 0.3116, 0.6884, 0.7500]
    seeds = [1, 2]
    
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('MSD Curve Examination: Understanding Data Structure', fontsize=16)
    
    for idx, p in enumerate(p_values):
        ax = axes[idx // 2, idx % 2]
        
        # Plot both seeds
        for seed in seeds:
            try:
                t, msd = load_ensemble_data(p, seed)
                
                # Plot MSD
                ax.loglog(t, msd, '-', linewidth=2, label=f'Seed {seed:02d}')
                
                # Calculate and plot local α
                alpha_local = calculate_local_alpha(t, msd)
                valid_mask = np.isfinite(alpha_local)
                
                # Create secondary y-axis for α
                ax2 = ax.twinx()
                ax2.semilogx(t[valid_mask], alpha_local[valid_mask], '--', alpha=0.7, linewidth=1)
                
            except Exception as e:
                print(f"Error with p = {p:.4f}, seed = {seed:02d}: {e}")
                continue
        
        # Add theoretical α lines
        p_c_prime = 0.6884
        if p < p_c_prime - 0.05:
            ax2.axhline(y=1.0, color='blue', linestyle=':', alpha=0.8, label='α = 1.0 (Liquid)')
        elif abs(p - p_c_prime) < 0.05:
            ax2.axhline(y=0.53, color='orange', linestyle=':', alpha=0.8, label='α = 0.53 (Critical)')
        else:
            ax2.axhline(y=0.0, color='red', linestyle=':', alpha=0.8, label='α = 0.0 (Solid)')
        
        ax.set_xlabel('Time τ')
        ax.set_ylabel('MSD')
        ax2.set_ylabel('Local α')
        ax.set_title(f'p = {p:.4f}')
        ax.grid(True, alpha=0.3)
        
        # Combine legends
        lines1, labels1 = ax.get_legend_handles_labels()
        lines2, labels2 = ax2.get_legend_handles_labels()
        ax.legend(lines1 + lines2, labels1 + labels2, loc='upper left')
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/msd_curve_examination.png", dpi=300, bbox_inches='tight')
    
    return fig

def examine_early_time_regions():
    """Examine early time regions where α should be determined"""
    
    p_values = [0.0000, 0.3116, 0.6884, 0.7500]
    seeds = [1]
    
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('Early Time Region Examination: Where α Should Be Determined', fontsize=16)
    
    for idx, p in enumerate(p_values):
        ax = axes[idx // 2, idx % 2]
        
        for seed in seeds:
            try:
                t, msd = load_ensemble_data(p, seed)
                
                # Focus on early time region (first 1000 points)
                early_mask = t <= t[1000] if len(t) > 1000 else slice(None)
                t_early = t[early_mask]
                msd_early = msd[early_mask]
                
                # Plot MSD
                ax.loglog(t_early, msd_early, '-', linewidth=2, label=f'Seed {seed:02d}')
                
                # Calculate and plot local α
                alpha_local = calculate_local_alpha(t_early, msd_early, window_size=10)
                valid_mask = np.isfinite(alpha_local)
                
                # Create secondary y-axis for α
                ax2 = ax.twinx()
                ax2.semilogx(t_early[valid_mask], alpha_local[valid_mask], '--', alpha=0.7, linewidth=1)
                
                # Mark potential regions
                # Look for regions where α is relatively stable
                stable_mask = (np.abs(alpha_local - np.nanmean(alpha_local)) < 0.1) & valid_mask
                if np.any(stable_mask):
                    ax2.scatter(t_early[stable_mask], alpha_local[stable_mask], 
                              color='red', s=20, alpha=0.6, label='Stable α')
                
            except Exception as e:
                print(f"Error with p = {p:.4f}, seed = {seed:02d}: {e}")
                continue
        
        # Add theoretical α lines
        p_c_prime = 0.6884
        if p < p_c_prime - 0.05:
            ax2.axhline(y=1.0, color='blue', linestyle=':', alpha=0.8, label='α = 1.0 (Liquid)')
        elif abs(p - p_c_prime) < 0.05:
            ax2.axhline(y=0.53, color='orange', linestyle=':', alpha=0.8, label='α = 0.53 (Critical)')
        else:
            ax2.axhline(y=0.0, color='red', linestyle=':', alpha=0.8, label='α = 0.0 (Solid)')
        
        ax.set_xlabel('Time τ')
        ax.set_ylabel('MSD')
        ax2.set_ylabel('Local α')
        ax.set_title(f'p = {p:.4f} (Early Time)')
        ax.grid(True, alpha=0.3)
        
        # Combine legends
        lines1, labels1 = ax.get_legend_handles_labels()
        lines2, labels2 = ax2.get_legend_handles_labels()
        ax.legend(lines1 + lines2, labels1 + labels2, loc='upper left')
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/early_time_examination.png", dpi=300, bbox_inches='tight')
    
    return fig

def analyze_optimal_regions():
    """Analyze optimal regions for α determination"""
    
    p_values = [0.0000, 0.3116, 0.6884, 0.7500]
    seeds = [1]
    
    print("=== OPTIMAL REGION ANALYSIS ===")
    print("=" * 60)
    
    for p in p_values:
        print(f"\n--- p = {p:.4f} ---")
        
        for seed in seeds:
            try:
                t, msd = load_ensemble_data(p, seed)
                
                # Calculate local α
                alpha_local = calculate_local_alpha(t, msd, window_size=10)
                valid_mask = np.isfinite(alpha_local)
                
                # Find regions with stable α
                alpha_mean = np.nanmean(alpha_local[valid_mask])
                alpha_std = np.nanstd(alpha_local[valid_mask])
                
                print(f"Seed {seed:02d}:")
                print(f"  Mean α = {alpha_mean:.3f} ± {alpha_std:.3f}")
                print(f"  α range: {np.nanmin(alpha_local):.3f} to {np.nanmax(alpha_local):.3f}")
                
                # Find regions where α is close to theoretical value
                p_c_prime = 0.6884
                if p < p_c_prime - 0.05:
                    target_alpha = 1.0
                    regime = "LIQUID"
                elif abs(p - p_c_prime) < 0.05:
                    target_alpha = 0.53
                    regime = "CRITICAL"
                else:
                    target_alpha = 0.0
                    regime = "SOLID"
                
                # Find best region
                alpha_error = np.abs(alpha_local - target_alpha)
                best_idx = np.nanargmin(alpha_error)
                best_alpha = alpha_local[best_idx]
                best_time = t[best_idx]
                
                print(f"  Regime: {regime}")
                print(f"  Best α = {best_alpha:.3f} at τ = {best_time:.2e}")
                print(f"  Error = {alpha_error[best_idx]:.3f}")
                
                # Find stable region around best point
                stable_threshold = 0.1
                stable_mask = (np.abs(alpha_local - best_alpha) < stable_threshold) & valid_mask
                
                if np.any(stable_mask):
                    stable_indices = np.where(stable_mask)[0]
                    stable_start = t[stable_indices[0]]
                    stable_end = t[stable_indices[-1]]
                    stable_count = len(stable_indices)
                    
                    print(f"  Stable region: τ = {stable_start:.2e} to {stable_end:.2e} ({stable_count} points)")
                    
                    # Calculate α in stable region
                    stable_alpha = np.nanmean(alpha_local[stable_mask])
                    stable_std = np.nanstd(alpha_local[stable_mask])
                    print(f"  Stable α = {stable_alpha:.3f} ± {stable_std:.3f}")
                
            except Exception as e:
                print(f"Error with p = {p:.4f}, seed = {seed:02d}: {e}")
                continue

def main():
    """Main examination function"""
    print("=== MSD CURVE EXAMINATION ===")
    print("Understanding the actual data structure")
    print("=" * 60)
    
    # Examine full curves
    print("Examining full MSD curves...")
    fig1 = examine_msd_curves()
    plt.close(fig1)
    
    # Examine early time regions
    print("Examining early time regions...")
    fig2 = examine_early_time_regions()
    plt.close(fig2)
    
    # Analyze optimal regions
    print("Analyzing optimal regions...")
    analyze_optimal_regions()
    
    print("\nExamination complete. Check paper_figures/ for plots.")

if __name__ == "__main__":
    main() 