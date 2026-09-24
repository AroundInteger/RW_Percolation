#!/usr/bin/env python3
"""
THEORETICAL α VALIDATION
Compare empirical α values against theoretical predictions
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

def get_theoretical_alpha(p: float, p_c_prime: float = 0.6884):
    """Get theoretical α values based on percolation theory"""
    
    # Critical exponents for 3D percolation
    nu = 0.88  # Correlation length exponent
    z = 2.0    # Dynamic exponent
    dw = 3.8   # Walk dimension
    
    # Theoretical α values
    if p < p_c_prime:
        # Liquid regime (p < p_c'): normal diffusion
        alpha_theory = 1.0
        regime = "LIQUID"
        explanation = "Normal diffusion: α = 1"
        
    elif abs(p - p_c_prime) < 0.01:
        # Critical regime (p ≈ p_c'): anomalous diffusion
        alpha_theory = 2.0 / dw  # ≈ 0.53
        regime = "CRITICAL"
        explanation = f"Anomalous diffusion: α = 2/dw = {alpha_theory:.3f}"
        
    else:
        # Solid regime (p > p_c'): arrested diffusion
        alpha_theory = 0.0
        regime = "SOLID"
        explanation = "Arrested diffusion: α = 0"
    
    return {
        'alpha_theory': alpha_theory,
        'regime': regime,
        'explanation': explanation,
        'p_c_prime': p_c_prime,
        'nu': nu,
        'z': z,
        'dw': dw
    }

def analyze_empirical_vs_theoretical(p: float, seed: int):
    """Compare empirical α against theoretical predictions"""
    
    print(f"=== THEORETICAL VALIDATION FOR p = {p:.4f}, seed = {seed:02d} ===")
    
    # Get theoretical predictions
    theory = get_theoretical_alpha(p)
    
    print(f"Theoretical Analysis:")
    print(f"  Regime: {theory['regime']}")
    print(f"  α_theory = {theory['alpha_theory']:.3f}")
    print(f"  Explanation: {theory['explanation']}")
    print(f"  Critical exponents: ν = {theory['nu']}, z = {theory['z']}, dw = {theory['dw']}")
    print()
    
    # Load empirical data
    t, msd = load_ensemble_data(p, seed)
    
    # Calculate empirical α using current method
    window_size = min(50, len(t) // 20)
    start_idx = max(10, window_size // 2)
    
    window_start = max(0, start_idx - window_size // 2)
    window_end = min(len(t), start_idx + window_size // 2)
    
    t_early = t[window_start:window_end]
    msd_early = msd[window_start:window_end]
    
    log_t_early = np.log10(t_early)
    log_msd_early = np.log10(msd_early)
    
    coeffs_early = np.polyfit(log_t_early, log_msd_early, 1)
    alpha_empirical = coeffs_early[0]
    
    # Calculate R² for empirical fit
    msd_pred_early = 10**(alpha_empirical * log_t_early + coeffs_early[1])
    ss_res_early = np.sum((msd_early - msd_pred_early)**2)
    ss_tot_early = np.sum((msd_early - np.mean(msd_early))**2)
    r_squared_early = 1 - (ss_res_early / ss_tot_early) if ss_tot_early > 0 else 0
    
    print(f"Empirical Analysis:")
    print(f"  Time range: {t_early[0]:.2e} to {t_early[-1]:.2e}")
    print(f"  α_empirical = {alpha_empirical:.6f}")
    print(f"  R² = {r_squared_early:.6f}")
    print()
    
    # Calculate discrepancy
    alpha_discrepancy = abs(alpha_empirical - theory['alpha_theory'])
    relative_error = alpha_discrepancy / max(abs(theory['alpha_theory']), 1e-6)
    
    print(f"Validation Results:")
    print(f"  α_theory = {theory['alpha_theory']:.6f}")
    print(f"  α_empirical = {alpha_empirical:.6f}")
    print(f"  Absolute discrepancy = {alpha_discrepancy:.6f}")
    print(f"  Relative error = {relative_error:.1%}")
    
    # Assess agreement
    if relative_error < 0.1:  # Within 10%
        agreement = "EXCELLENT"
        assessment = "✓ Empirical α agrees well with theory"
    elif relative_error < 0.3:  # Within 30%
        agreement = "GOOD"
        assessment = "⚠ Empirical α reasonably close to theory"
    else:
        agreement = "POOR"
        assessment = "❌ Large discrepancy between empirical and theoretical α"
    
    print(f"  Agreement: {agreement}")
    print(f"  Assessment: {assessment}")
    print()
    
    return {
        'theory': theory,
        'alpha_empirical': alpha_empirical,
        'r_squared_empirical': r_squared_early,
        'alpha_discrepancy': alpha_discrepancy,
        'relative_error': relative_error,
        'agreement': agreement,
        'assessment': assessment,
        't_early': t_early,
        'msd_early': msd_early,
        't': t,
        'msd': msd
    }

def plot_theoretical_validation(results, p, seed):
    """Plot empirical vs theoretical α comparison"""
    
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 10))
    
    theory = results['theory']
    alpha_empirical = results['alpha_empirical']
    alpha_theory = theory['alpha_theory']
    t = results['t']
    msd = results['msd']
    t_early = results['t_early']
    msd_early = results['msd_early']
    
    # Plot 1: MSD vs time with fits
    ax1.loglog(t, msd, 'b-', linewidth=1, label='MSD', alpha=0.7)
    ax1.loglog(t_early, msd_early, 'r-', linewidth=3, label=f'Empirical fit (α = {alpha_empirical:.3f})')
    
    # Add theoretical fit line
    if alpha_theory > 0:
        # Use the same intercept as empirical fit for comparison
        log_t_early = np.log10(t_early)
        log_msd_early = np.log10(msd_early)
        coeffs_empirical = np.polyfit(log_t_early, log_msd_early, 1)
        intercept_theory = coeffs_empirical[1]  # Same intercept
        
        msd_theory = 10**(alpha_theory * log_t_early + intercept_theory)
        ax1.loglog(t_early, msd_theory, 'g--', linewidth=2, label=f'Theoretical fit (α = {alpha_theory:.3f})')
    
    ax1.set_xlabel('Time (τ)')
    ax1.set_ylabel('MSD')
    ax1.set_title(f'MSD vs Time (p = {p:.4f}, seed = {seed:02d})')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: α comparison
    methods = ['Theoretical', 'Empirical']
    alpha_values = [alpha_theory, alpha_empirical]
    colors = ['green', 'red']
    
    bars = ax2.bar(methods, alpha_values, color=colors, alpha=0.7)
    ax2.set_ylabel('α Value')
    ax2.set_title('α Comparison')
    ax2.grid(True, alpha=0.3)
    
    # Add value labels on bars
    for bar, value in zip(bars, alpha_values):
        height = bar.get_height()
        ax2.text(bar.get_x() + bar.get_width()/2., height + 0.01,
                f'{value:.3f}', ha='center', va='bottom')
    
    # Plot 3: Discrepancy analysis
    discrepancy = results['alpha_discrepancy']
    relative_error = results['relative_error']
    
    ax3.bar(['Absolute\nDiscrepancy', 'Relative\nError (%)'], 
            [discrepancy, relative_error * 100], 
            color=['orange', 'purple'], alpha=0.7)
    ax3.set_ylabel('Error')
    ax3.set_title('Discrepancy Analysis')
    ax3.grid(True, alpha=0.3)
    
    # Add value labels
    ax3.text(0, discrepancy + 0.01, f'{discrepancy:.3f}', ha='center', va='bottom')
    ax3.text(1, relative_error * 100 + 0.5, f'{relative_error:.1%}', ha='center', va='bottom')
    
    # Plot 4: Regime information
    regime = theory['regime']
    explanation = theory['explanation']
    agreement = results['agreement']
    assessment = results['assessment']
    
    ax4.text(0.1, 0.8, f'Regime: {regime}', fontsize=12, fontweight='bold')
    ax4.text(0.1, 0.7, f'Theory: {explanation}', fontsize=10)
    ax4.text(0.1, 0.6, f'α_theory = {alpha_theory:.3f}', fontsize=10)
    ax4.text(0.1, 0.5, f'α_empirical = {alpha_empirical:.3f}', fontsize=10)
    ax4.text(0.1, 0.4, f'Agreement: {agreement}', fontsize=10, 
             color='green' if agreement == 'EXCELLENT' else 'orange' if agreement == 'GOOD' else 'red')
    ax4.text(0.1, 0.3, f'Assessment: {assessment}', fontsize=9, wrap=True)
    ax4.text(0.1, 0.2, f'Critical exponents:', fontsize=9)
    ax4.text(0.1, 0.15, f'ν = {theory["nu"]}, z = {theory["z"]}, dw = {theory["dw"]}', fontsize=9)
    
    ax4.set_xlim(0, 1)
    ax4.set_ylim(0, 1)
    ax4.axis('off')
    ax4.set_title('Analysis Summary')
    
    plt.tight_layout()
    plt.savefig(f'theoretical_validation_p{p:.4f}_seed{seed:02d}.png', dpi=300, bbox_inches='tight')
    plt.show()

def comprehensive_validation():
    """Run comprehensive validation across all available data"""
    
    test_cases = [
        (0.0000, 1, "LIQUID"),
        (0.0000, 2, "LIQUID"),
        (0.3116, 1, "LIQUID"),
        (0.3116, 2, "LIQUID"),
        (0.6884, 1, "CRITICAL"),
        (0.6884, 2, "CRITICAL"),
        (0.7500, 1, "SOLID"),
        (0.7500, 2, "SOLID"),
    ]
    
    print("=== COMPREHENSIVE THEORETICAL VALIDATION ===")
    print("Comparing empirical α values against theoretical predictions")
    print("=" * 70)
    
    all_results = []
    
    for p, seed, regime in test_cases:
        print(f"\n{'='*70}")
        print(f"VALIDATING: p = {p:.4f}, seed = {seed:02d}, regime = {regime}")
        print(f"{'='*70}")
        
        try:
            results = analyze_empirical_vs_theoretical(p, seed)
            results['p'] = p
            results['seed'] = seed
            results['regime'] = regime
            
            all_results.append(results)
            
            # Plot validation
            plot_theoretical_validation(results, p, seed)
            
        except Exception as e:
            print(f"Error validating p = {p:.4f}, seed = {seed:02d}: {e}")
        
        print(f"\n{'-'*70}")
    
    # Summary
    print(f"\n{'='*70}")
    print("COMPREHENSIVE VALIDATION SUMMARY")
    print(f"{'='*70}")
    
    summary_data = []
    for result in all_results:
        p = result['p']
        seed = result['seed']
        regime = result['regime']
        alpha_theory = result['theory']['alpha_theory']
        alpha_empirical = result['alpha_empirical']
        relative_error = result['relative_error']
        agreement = result['agreement']
        
        summary_data.append({
            'p': p,
            'seed': seed,
            'regime': regime,
            'alpha_theory': alpha_theory,
            'alpha_empirical': alpha_empirical,
            'relative_error': relative_error,
            'agreement': agreement
        })
        
        print(f"p = {p:.4f}, seed = {seed:02d}, {regime}:")
        print(f"  α_theory = {alpha_theory:.3f}, α_empirical = {alpha_empirical:.3f}")
        print(f"  Relative error = {relative_error:.1%}, Agreement = {agreement}")
        print()
    
    # Create summary table
    df_summary = pd.DataFrame(summary_data)
    print("SUMMARY TABLE:")
    print(df_summary.to_string(index=False))
    
    # Overall assessment
    excellent_count = sum(1 for r in all_results if r['agreement'] == 'EXCELLENT')
    good_count = sum(1 for r in all_results if r['agreement'] == 'GOOD')
    poor_count = sum(1 for r in all_results if r['agreement'] == 'POOR')
    
    print(f"\nOVERALL ASSESSMENT:")
    print(f"  Excellent agreement: {excellent_count}/{len(all_results)} ({100*excellent_count/len(all_results):.1f}%)")
    print(f"  Good agreement: {good_count}/{len(all_results)} ({100*good_count/len(all_results):.1f}%)")
    print(f"  Poor agreement: {poor_count}/{len(all_results)} ({100*poor_count/len(all_results):.1f}%)")
    
    return all_results

def main():
    """Main function"""
    comprehensive_validation()

if __name__ == "__main__":
    main() 