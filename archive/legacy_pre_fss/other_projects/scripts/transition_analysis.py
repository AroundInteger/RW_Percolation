#!/usr/bin/env python3
"""
Transition Analysis: Focus on α behavior around p_c'
Examine the transition from liquid (α ≈ 1) to solid (α ≈ 0) regimes
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats

def analyze_transition():
    """Analyze the transition behavior around p_c'"""
    
    # Load the corrected results
    df = pd.read_csv('corrected_alpha_analysis_results.csv')
    
    print("=== TRANSITION ANALYSIS AROUND p_c' ===")
    print(f"Critical point: p_c' = 0.6884")
    print()
    
    # Extract key data
    p_values = df['p'].values
    alpha_values = df['alpha_opt'].values
    strategies = df['strategy'].values
    r_squared = df['r_squared'].values
    
    # Find transition region
    p_c_prime = 0.6884
    transition_mask = (p_values >= 0.60) & (p_values <= 0.75)
    
    transition_data = df[transition_mask].copy()
    transition_data = transition_data.sort_values('p')
    
    print("TRANSITION REGION ANALYSIS (0.60 ≤ p ≤ 0.75):")
    print("-" * 60)
    
    for _, row in transition_data.iterrows():
        p = row['p']
        alpha = row['alpha_opt']
        strategy = row['strategy']
        r2 = row['r_squared']
        expected = row['expected_alpha']
        
        # Determine expected behavior
        if p < p_c_prime - 0.05:
            expected_behavior = "LIQUID (α ≈ 1.0)"
        elif abs(p - p_c_prime) < 0.05:
            expected_behavior = "CRITICAL (α ≈ 0.5)"
        else:
            expected_behavior = "SOLID (α ≈ 0.0)"
        
        print(f"p = {p:.4f}: α = {alpha:.3f} (expected: {expected:.1f}) | {strategy.upper()} | {expected_behavior}")
    
    print()
    
    # Analyze transition behavior
    print("TRANSITION BEHAVIOR ANALYSIS:")
    print("-" * 40)
    
    # Liquid regime (p < p_c' - 0.05)
    liquid_mask = p_values < p_c_prime - 0.05
    liquid_alphas = alpha_values[liquid_mask]
    liquid_ps = p_values[liquid_mask]
    
    print(f"LIQUID REGIME (p < {p_c_prime - 0.05:.3f}):")
    print(f"  Count: {len(liquid_alphas)} p-values")
    print(f"  α range: {liquid_alphas.min():.3f} to {liquid_alphas.max():.3f}")
    print(f"  α mean: {liquid_alphas.mean():.3f} ± {liquid_alphas.std():.3f}")
    print(f"  Expected: α ≈ 1.0")
    print(f"  Agreement: {'✓ EXCELLENT' if abs(liquid_alphas.mean() - 1.0) < 0.05 else '⚠ GOOD' if abs(liquid_alphas.mean() - 1.0) < 0.1 else '❌ POOR'}")
    
    # Critical regime (|p - p_c'| < 0.05)
    critical_mask = np.abs(p_values - p_c_prime) < 0.05
    critical_alphas = alpha_values[critical_mask]
    critical_ps = p_values[critical_mask]
    
    print(f"\nCRITICAL REGIME (|p - {p_c_prime:.3f}| < 0.05):")
    print(f"  Count: {len(critical_alphas)} p-values")
    if len(critical_alphas) > 0:
        print(f"  α range: {critical_alphas.min():.3f} to {critical_alphas.max():.3f}")
        print(f"  α mean: {critical_alphas.mean():.3f} ± {critical_alphas.std():.3f}")
        print(f"  Expected: α ≈ 0.5")
        print(f"  Agreement: {'✓ EXCELLENT' if abs(critical_alphas.mean() - 0.5) < 0.1 else '⚠ GOOD' if abs(critical_alphas.mean() - 0.5) < 0.2 else '❌ POOR'}")
    else:
        print("  No p-values in critical regime")
    
    # Solid regime (p > p_c' + 0.05)
    solid_mask = p_values > p_c_prime + 0.05
    solid_alphas = alpha_values[solid_mask]
    solid_ps = p_values[solid_mask]
    
    print(f"\nSOLID REGIME (p > {p_c_prime + 0.05:.3f}):")
    print(f"  Count: {len(solid_alphas)} p-values")
    if len(solid_alphas) > 0:
        print(f"  α range: {solid_alphas.min():.3f} to {solid_alphas.max():.3f}")
        print(f"  α mean: {solid_alphas.mean():.3f} ± {solid_alphas.std():.3f}")
        print(f"  Expected: α ≈ 0.0")
        print(f"  Agreement: {'✓ EXCELLENT' if abs(solid_alphas.mean()) < 0.05 else '⚠ GOOD' if abs(solid_alphas.mean()) < 0.1 else '❌ POOR'}")
    else:
        print("  No p-values in solid regime")
    
    # Create transition plot
    create_transition_plot(df, p_c_prime)
    
    # Analyze α vs p relationship
    analyze_alpha_vs_p_relationship(df, p_c_prime)

def create_transition_plot(df, p_c_prime):
    """Create detailed transition plot"""
    
    plt.figure(figsize=(15, 10))
    
    # Main α vs p plot
    plt.subplot(2, 2, 1)
    
    colors = {'liquid': 'blue', 'critical': 'orange', 'solid': 'red'}
    markers = {'liquid': 'o', 'critical': 's', 'solid': '^'}
    
    for strategy in ['liquid', 'critical', 'solid']:
        mask = df['strategy'] == strategy
        if np.any(mask):
            p_vals = df.loc[mask, 'p']
            alphas = df.loc[mask, 'alpha_opt']
            plt.plot(p_vals, alphas, marker=markers[strategy], color=colors[strategy], 
                    linestyle='-', linewidth=2, markersize=6, label=f'{strategy.title()}')
    
    # Add theoretical lines
    plt.axhline(y=1.0, color='blue', linestyle='--', alpha=0.7, linewidth=2, label='α = 1.0 (liquid)')
    plt.axhline(y=0.5, color='orange', linestyle='--', alpha=0.7, linewidth=2, label='α = 0.5 (critical)')
    plt.axhline(y=0.0, color='red', linestyle='--', alpha=0.7, linewidth=2, label='α = 0.0 (solid)')
    plt.axvline(x=p_c_prime, color='black', linestyle=':', alpha=0.8, linewidth=3, label=f"p_c' = {p_c_prime}")
    
    # Add transition regions
    plt.axvspan(p_c_prime - 0.05, p_c_prime + 0.05, alpha=0.2, color='orange', label='Critical Region')
    
    plt.xlabel('Percolation Probability (p)', fontsize=12)
    plt.ylabel('Growth Exponent (α)', fontsize=12)
    plt.title('Phase Transition: α vs p around p_c\'', fontsize=14, fontweight='bold')
    plt.legend(fontsize=10)
    plt.grid(True, alpha=0.3)
    plt.xlim(0.6, 0.75)
    plt.ylim(-0.1, 1.1)
    
    # R² vs p plot
    plt.subplot(2, 2, 2)
    for strategy in ['liquid', 'critical', 'solid']:
        mask = df['strategy'] == strategy
        if np.any(mask):
            p_vals = df.loc[mask, 'p']
            r_squared = df.loc[mask, 'r_squared']
            plt.plot(p_vals, r_squared, marker=markers[strategy], color=colors[strategy], 
                    linestyle='-', linewidth=2, markersize=6, label=strategy.title())
    
    plt.xlabel('Percolation Probability (p)', fontsize=12)
    plt.ylabel('R² (Fit Quality)', fontsize=12)
    plt.title('Fit Quality vs p', fontsize=14, fontweight='bold')
    plt.legend(fontsize=10)
    plt.grid(True, alpha=0.3)
    plt.xlim(0.6, 0.75)
    
    # Error vs p plot
    plt.subplot(2, 2, 3)
    for strategy in ['liquid', 'critical', 'solid']:
        mask = df['strategy'] == strategy
        if np.any(mask):
            p_vals = df.loc[mask, 'p']
            errors = df.loc[mask, 'alpha_error']
            plt.plot(p_vals, errors, marker=markers[strategy], color=colors[strategy], 
                    linestyle='-', linewidth=2, markersize=6, label=strategy.title())
    
    plt.xlabel('Percolation Probability (p)', fontsize=12)
    plt.ylabel('|α - α_expected|', fontsize=12)
    plt.title('Deviation from Expected α', fontsize=14, fontweight='bold')
    plt.legend(fontsize=10)
    plt.grid(True, alpha=0.3)
    plt.xlim(0.6, 0.75)
    
    # Strategy distribution
    plt.subplot(2, 2, 4)
    strategy_counts = df['strategy'].value_counts()
    colors_pie = [colors[s] for s in strategy_counts.index]
    plt.pie(strategy_counts.values, labels=strategy_counts.index, autopct='%1.1f%%', 
            colors=colors_pie, startangle=90)
    plt.title('Analysis Strategy Distribution', fontsize=14, fontweight='bold')
    
    plt.tight_layout()
    plt.savefig('transition_analysis_detailed.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"\nDetailed transition plot saved to: transition_analysis_detailed.png")

def analyze_alpha_vs_p_relationship(df, p_c_prime):
    """Analyze the α vs p relationship for theoretical validation"""
    
    print("\n=== THEORETICAL VALIDATION ===")
    print("-" * 40)
    
    # Extract data
    p_values = df['p'].values
    alpha_values = df['alpha_opt'].values
    
    # Test theoretical predictions
    
    # 1. Liquid regime: α should be ≈ 1.0
    liquid_mask = p_values < p_c_prime - 0.05
    if np.any(liquid_mask):
        liquid_alphas = alpha_values[liquid_mask]
        liquid_mean = liquid_alphas.mean()
        liquid_std = liquid_alphas.std()
        
        print(f"1. LIQUID REGIME (p < {p_c_prime - 0.05:.3f}):")
        print(f"   Expected: α = 1.0")
        print(f"   Observed: α = {liquid_mean:.3f} ± {liquid_std:.3f}")
        print(f"   Deviation: {abs(liquid_mean - 1.0):.3f}")
        print(f"   Assessment: {'✓ EXCELLENT' if abs(liquid_mean - 1.0) < 0.05 else '⚠ GOOD' if abs(liquid_mean - 1.0) < 0.1 else '❌ POOR'}")
    
    # 2. Critical regime: α should be ≈ 0.5
    critical_mask = np.abs(p_values - p_c_prime) < 0.05
    if np.any(critical_mask):
        critical_alphas = alpha_values[critical_mask]
        critical_mean = critical_alphas.mean()
        critical_std = critical_alphas.std()
        
        print(f"\n2. CRITICAL REGIME (|p - {p_c_prime:.3f}| < 0.05):")
        print(f"   Expected: α = 0.5")
        print(f"   Observed: α = {critical_mean:.3f} ± {critical_std:.3f}")
        print(f"   Deviation: {abs(critical_mean - 0.5):.3f}")
        print(f"   Assessment: {'✓ EXCELLENT' if abs(critical_mean - 0.5) < 0.1 else '⚠ GOOD' if abs(critical_mean - 0.5) < 0.2 else '❌ POOR'}")
    
    # 3. Solid regime: α should be ≈ 0.0
    solid_mask = p_values > p_c_prime + 0.05
    if np.any(solid_mask):
        solid_alphas = alpha_values[solid_mask]
        solid_mean = solid_alphas.mean()
        solid_std = solid_alphas.std()
        
        print(f"\n3. SOLID REGIME (p > {p_c_prime + 0.05:.3f}):")
        print(f"   Expected: α = 0.0")
        print(f"   Observed: α = {solid_mean:.3f} ± {solid_std:.3f}")
        print(f"   Deviation: {abs(solid_mean):.3f}")
        print(f"   Assessment: {'✓ EXCELLENT' if abs(solid_mean) < 0.05 else '⚠ GOOD' if abs(solid_mean) < 0.1 else '❌ POOR'}")
    
    # 4. Transition behavior
    print(f"\n4. TRANSITION BEHAVIOR:")
    print(f"   Critical point: p_c' = {p_c_prime}")
    print(f"   Transition width: ±0.05 (|p - p_c'| < 0.05)")
    print(f"   Expected: Sharp transition from α ≈ 1.0 to α ≈ 0.0")
    
    # Check if we have data on both sides of transition
    if np.any(liquid_mask) and np.any(solid_mask):
        liquid_alpha = alpha_values[liquid_mask].mean()
        solid_alpha = alpha_values[solid_mask].mean()
        transition_magnitude = abs(liquid_alpha - solid_alpha)
        
        print(f"   Observed transition magnitude: {transition_magnitude:.3f}")
        print(f"   Assessment: {'✓ EXCELLENT' if transition_magnitude > 0.8 else '⚠ GOOD' if transition_magnitude > 0.5 else '❌ POOR'}")
    else:
        print(f"   Assessment: ⚠ INCOMPLETE (missing data on one or both sides)")

def main():
    """Main analysis function"""
    analyze_transition()

if __name__ == "__main__":
    main()
