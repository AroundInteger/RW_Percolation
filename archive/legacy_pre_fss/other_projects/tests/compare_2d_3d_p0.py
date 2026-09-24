#!/usr/bin/env python3
"""
Comparison between 2D and 3D implementations for p=0
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from pathlib import Path

def run_2d_p0_test():
    """Run 2D p=0 test with proper PBC handling"""
    from matlab_compatible_rw import test_p0_every_step
    return test_p0_every_step()

def run_3d_p0_test():
    """Run 3D p=0 test with corrected PBC handling"""
    import sys
    sys.path.append('scripts')
    from analyze_free_rw_corrected import run_free_rw_corrected
    
    # Run 3D simulation with p=0
    results = run_free_rw_corrected(
        lattice_size=100,  # Use same order of magnitude as 2D
        p_value=0.0,
        num_steps=10000,
        num_walkers=100,
        random_seed=42
    )
    
    return results

def compare_2d_3d_results():
    """Compare 2D and 3D results"""
    print("=== 2D vs 3D Comparison for p=0 ===")
    print()
    
    # Run 2D test
    print("Running 2D test...")
    t_2d, msd_2d, exp_2d, r2_2d = run_2d_p0_test()
    
    print("\n" + "="*50)
    
    # Run 3D test
    print("Running 3D test...")
    results_3d = run_3d_p0_test()
    
    # Extract 3D data
    df_3d = results_3d['msd_data']
    t_3d = df_3d['step'].values
    msd_3d = df_3d['msd'].values
    
    # Analyze 3D results
    t_clean_3d = t_3d[10:]  # Remove first 10 points
    msd_clean_3d = msd_3d[10:]
    
    ln_t_3d = np.log10(t_clean_3d)
    ln_msd_3d = np.log10(msd_clean_3d)
    
    coeffs_3d = np.polyfit(ln_t_3d, ln_msd_3d, 1)
    exp_3d = coeffs_3d[0]
    
    msd_pred_3d = 10**(exp_3d * ln_t_3d + coeffs_3d[1])
    ss_res_3d = np.sum((msd_clean_3d - msd_pred_3d) ** 2)
    ss_tot_3d = np.sum((msd_clean_3d - np.mean(msd_clean_3d)) ** 2)
    r2_3d = 1 - (ss_res_3d / ss_tot_3d)
    
    print(f"\n=== Comparison Summary ===")
    print(f"2D Results:")
    print(f"  Growth exponent: α = {exp_2d:.3f}")
    print(f"  R²: {r2_2d:.6f}")
    print(f"  Expected: α = 1.0")
    print(f"  Ratio to expected: {exp_2d:.3f}")
    
    print(f"\n3D Results:")
    print(f"  Growth exponent: α = {exp_3d:.3f}")
    print(f"  R²: {r2_3d:.6f}")
    print(f"  Expected: α = 1.0")
    print(f"  Ratio to expected: {exp_3d:.3f}")
    
    print(f"\nComparison:")
    print(f"  2D/3D exponent ratio: {exp_2d/exp_3d:.3f}")
    print(f"  2D R² / 3D R²: {r2_2d/r2_3d:.3f}")
    
    # Plot comparison
    plt.figure(figsize=(15, 5))
    
    # Linear scale
    plt.subplot(1, 3, 1)
    plt.plot(t_2d, msd_2d, 'b-', linewidth=2, label='2D (L=400)')
    plt.plot(t_3d, msd_3d, 'r-', linewidth=2, label='3D (L=100)')
    
    # Theoretical lines
    theoretical_2d = t_2d / 4  # D = 1/4 for 2D
    theoretical_3d = t_3d / 6  # D = 1/6 for 3D
    plt.plot(t_2d, theoretical_2d, 'b--', linewidth=1, label='Theoretical 2D')
    plt.plot(t_3d, theoretical_3d, 'r--', linewidth=1, label='Theoretical 3D')
    
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('2D vs 3D - Linear Scale')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    # Log-log scale
    plt.subplot(1, 3, 2)
    plt.loglog(t_2d, msd_2d, 'b-', linewidth=2, label='2D (L=400)')
    plt.loglog(t_3d, msd_3d, 'r-', linewidth=2, label='3D (L=100)')
    plt.loglog(t_2d, t_2d, 'g:', linewidth=1, label='Slope = 1')
    
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('2D vs 3D - Log-Log Scale')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    # Early time comparison
    plt.subplot(1, 3, 3)
    early_range_2d = slice(100, min(1000, len(t_2d)))
    early_range_3d = slice(100, min(1000, len(t_3d)))
    
    plt.loglog(t_2d[early_range_2d], msd_2d[early_range_2d], 'b-', linewidth=2, label='2D (Early)')
    plt.loglog(t_3d[early_range_3d], msd_3d[early_range_3d], 'r-', linewidth=2, label='3D (Early)')
    plt.loglog(t_2d[early_range_2d], t_2d[early_range_2d], 'g:', linewidth=1, label='Slope = 1')
    
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('Early Time (Steps 100-1000)')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('2d_3d_comparison.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    # Save comparison data
    comparison_df = pd.DataFrame({
        'step_2d': t_2d,
        'msd_2d': msd_2d,
        'theoretical_2d': theoretical_2d,
        'step_3d': np.concatenate([t_3d, np.full(len(t_2d) - len(t_3d), np.nan)]),
        'msd_3d': np.concatenate([msd_3d, np.full(len(t_2d) - len(t_3d), np.nan)]),
        'theoretical_3d': np.concatenate([theoretical_3d, np.full(len(t_2d) - len(t_3d), np.nan)])
    })
    
    comparison_df.to_csv('2d_3d_comparison.csv', index=False)
    print(f"\nComparison saved to: 2d_3d_comparison.csv")
    print(f"Plot saved to: 2d_3d_comparison.png")

if __name__ == "__main__":
    compare_2d_3d_results() 