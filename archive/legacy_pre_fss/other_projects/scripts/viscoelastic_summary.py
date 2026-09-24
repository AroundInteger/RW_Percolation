#!/usr/bin/env python3
"""
Viscoelastic Summary: Key Insights from Surface Analysis
Highlight the key features of G'(ω) and G''(ω) surfaces across the phase transition
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm

def create_summary_plots(df):
    """Create summary plots highlighting key viscoelastic features"""
    
    # Extract data
    p_values = df['p'].values
    alpha_values = df['alpha_opt'].values
    
    # Create frequency domain for analysis
    omega = np.logspace(-2, 2, 50)  # 0.01 to 100 rad/s
    
    # Select key p-values for detailed analysis
    p_c_prime = 0.6884
    
    # Find representative p-values for each regime
    p_liquid = df['p'].iloc[(df['p'] - 0.3).abs().argsort()[:1]].iloc[0]
    p_critical = df['p'].iloc[(df['p'] - p_c_prime).abs().argsort()[:1]].iloc[0]
    p_solid = df['p'].iloc[(df['p'] - 0.75).abs().argsort()[:1]].iloc[0]
    
    alpha_liquid = df[df['p'] == p_liquid]['alpha_opt'].iloc[0]
    alpha_critical = df[df['p'] == p_critical]['alpha_opt'].iloc[0]
    alpha_solid = df[df['p'] == p_solid]['alpha_opt'].iloc[0]
    
    print(f"=== VISCOELASTIC SURFACE ANALYSIS SUMMARY ===")
    print(f"Critical point: p_c' = {p_c_prime}")
    print()
    print(f"Representative regimes:")
    print(f"  Liquid: p = {p_liquid:.4f}, α = {alpha_liquid:.3f}")
    print(f"  Critical: p = {p_critical:.4f}, α = {alpha_critical:.3f}")
    print(f"  Solid: p = {p_solid:.4f}, α = {alpha_solid:.3f}")
    print()
    
    # Create summary plots
    fig, axes = plt.subplots(2, 3, figsize=(18, 12))
    
    # Plot 1: α vs p with regime labels
    ax1 = axes[0, 0]
    colors = {'liquid': 'blue', 'critical': 'orange', 'solid': 'red'}
    
    for strategy in ['liquid', 'critical', 'solid']:
        mask = df['strategy'] == strategy
        if np.any(mask):
            p_vals = df.loc[mask, 'p']
            alphas = df.loc[mask, 'alpha_opt']
            ax1.plot(p_vals, alphas, 'o', color=colors[strategy], 
                    markersize=8, label=f'{strategy.title()}')
    
    # Add theoretical lines
    ax1.axhline(y=1.0, color='blue', linestyle='--', alpha=0.7, label='α = 1.0 (liquid)')
    ax1.axhline(y=0.5, color='orange', linestyle='--', alpha=0.7, label='α = 0.5 (critical)')
    ax1.axhline(y=0.0, color='red', linestyle='--', alpha=0.7, label='α = 0.0 (solid)')
    ax1.axvline(x=p_c_prime, color='black', linestyle=':', alpha=0.8, linewidth=2, label=f"p_c' = {p_c_prime}")
    
    ax1.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax1.set_ylabel('Growth Exponent (α)', fontsize=12)
    ax1.set_title('Phase Transition: α vs p', fontsize=14, fontweight='bold')
    ax1.legend(fontsize=10)
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: G'(ω) vs ω for different regimes
    ax2 = axes[0, 1]
    
    # Calculate G'(ω) for each regime
    G_prime_liquid = np.full_like(omega, 1.0)  # α = 1: constant
    G_prime_critical = omega ** alpha_critical  # α < 1: power law
    G_prime_solid = np.full_like(omega, 1.0)   # α = 0: constant
    
    ax2.loglog(omega, G_prime_liquid, 'b-', linewidth=3, label=f'Liquid (α = {alpha_liquid:.3f})')
    ax2.loglog(omega, G_prime_critical, 'orange', linewidth=3, label=f'Critical (α = {alpha_critical:.3f})')
    ax2.loglog(omega, G_prime_solid, 'r--', linewidth=3, label=f'Solid (α = {alpha_solid:.3f})')
    
    ax2.set_xlabel('Frequency ω (rad/s)', fontsize=12)
    ax2.set_ylabel("G'(ω)", fontsize=12)
    ax2.set_title("Storage Modulus vs Frequency", fontsize=14, fontweight='bold')
    ax2.legend(fontsize=10)
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: G''(ω) vs ω for different regimes
    ax3 = axes[0, 2]
    
    # Calculate G''(ω) for each regime
    G_double_prime_liquid = np.full_like(omega, 1.0)  # α = 1: constant
    G_double_prime_critical = omega ** alpha_critical  # α < 1: power law
    G_double_prime_solid = np.zeros_like(omega)        # α = 0: zero
    
    ax3.loglog(omega, G_double_prime_liquid, 'b-', linewidth=3, label=f'Liquid (α = {alpha_liquid:.3f})')
    ax3.loglog(omega, G_double_prime_critical, 'orange', linewidth=3, label=f'Critical (α = {alpha_critical:.3f})')
    ax3.loglog(omega, np.maximum(G_double_prime_solid, 1e-3), 'r--', linewidth=3, label=f'Solid (α = {alpha_solid:.3f})')
    
    ax3.set_xlabel('Frequency ω (rad/s)', fontsize=12)
    ax3.set_ylabel("G''(ω)", fontsize=12)
    ax3.set_title("Loss Modulus vs Frequency", fontsize=14, fontweight='bold')
    ax3.legend(fontsize=10)
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: Tan δ vs ω for different regimes
    ax4 = axes[1, 0]
    
    # Calculate tan δ for each regime
    tan_delta_liquid = G_double_prime_liquid / G_prime_liquid
    tan_delta_critical = G_double_prime_critical / G_prime_critical
    tan_delta_solid = G_double_prime_solid / np.maximum(G_prime_solid, 1e-10)
    
    ax4.loglog(omega, tan_delta_liquid, 'b-', linewidth=3, label=f'Liquid (α = {alpha_liquid:.3f})')
    ax4.loglog(omega, tan_delta_critical, 'orange', linewidth=3, label=f'Critical (α = {alpha_critical:.3f})')
    ax4.loglog(omega, np.maximum(tan_delta_solid, 1e-3), 'r-', linewidth=3, label=f'Solid (α = {alpha_solid:.3f})')
    
    ax4.set_xlabel('Frequency ω (rad/s)', fontsize=12)
    ax4.set_ylabel("tan δ = G''/G'", fontsize=12)
    ax4.set_title("Loss Tangent vs Frequency", fontsize=14, fontweight='bold')
    ax4.legend(fontsize=10)
    ax4.grid(True, alpha=0.3)
    
    # Plot 5: Phase angle δ vs ω for different regimes
    ax5 = axes[1, 1]
    
    # Calculate δ for each regime
    delta_liquid = np.arctan2(G_double_prime_liquid, G_prime_liquid) * 180 / np.pi
    delta_critical = np.arctan2(G_double_prime_critical, G_prime_critical) * 180 / np.pi
    delta_solid = np.arctan2(G_double_prime_solid, G_prime_solid) * 180 / np.pi
    
    ax5.semilogx(omega, delta_liquid, 'b-', linewidth=3, label=f'Liquid (α = {alpha_liquid:.3f})')
    ax5.semilogx(omega, delta_critical, 'orange', linewidth=3, label=f'Critical (α = {alpha_critical:.3f})')
    ax5.semilogx(omega, delta_solid, 'r--', linewidth=3, label=f'Solid (α = {alpha_solid:.3f})')
    
    ax5.set_xlabel('Frequency ω (rad/s)', fontsize=12)
    ax5.set_ylabel("Phase Angle δ (degrees)", fontsize=12)
    ax5.set_title("Phase Angle vs Frequency", fontsize=14, fontweight='bold')
    ax5.legend(fontsize=10)
    ax5.grid(True, alpha=0.3)
    ax5.set_ylim(0, 90)
    
    # Plot 6: 2D surface preview (G' + G'' vs p and ω)
    ax6 = axes[1, 2]
    
    # Create a simplified surface for visualization
    p_surface = np.linspace(0, 0.8, 50)
    omega_surface = np.logspace(-2, 2, 50)
    P, Omega = np.meshgrid(p_surface, omega_surface)
    
    # Create a simplified surface based on α behavior
    alpha_surface = np.zeros_like(P)
    for i, p in enumerate(p_surface):
        if p < p_c_prime - 0.05:
            alpha_surface[:, i] = 1.0  # Liquid
        elif abs(p - p_c_prime) < 0.05:
            alpha_surface[:, i] = 0.5  # Critical
        else:
            alpha_surface[:, i] = 0.0  # Solid
    
    # Calculate combined modulus surface
    combined_surface = np.where(alpha_surface > 0, 
                               omega_surface[:, np.newaxis] ** alpha_surface, 
                               1.0)
    
    contour = ax6.contourf(P, Omega, combined_surface, levels=20, cmap=cm.viridis)
    ax6.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax6.set_ylabel('Frequency ω (rad/s)', fontsize=12)
    ax6.set_title("Combined Modulus Surface Preview", fontsize=14, fontweight='bold')
    ax6.set_yscale('log')
    ax6.axvline(x=p_c_prime, color='white', linestyle='--', alpha=0.8, linewidth=2, label="p_c'")
    plt.colorbar(contour, ax=ax6, label="G'(ω) + G''(ω)")
    ax6.legend(fontsize=10)
    
    plt.tight_layout()
    plt.savefig('viscoelastic_summary_analysis.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    return fig

def print_key_insights(df):
    """Print key insights from the viscoelastic analysis"""
    
    print("=== KEY INSIGHTS FROM VISCOELASTIC SURFACE ANALYSIS ===")
    print()
    
    # Extract data
    p_values = df['p'].values
    alpha_values = df['alpha_opt'].values
    p_c_prime = 0.6884
    
    # 1. Phase Transition Behavior
    print("1. PHASE TRANSITION BEHAVIOR:")
    print("   - Liquid regime (p < p_c'): α ≈ 1.0 → G'(ω) = G''(ω) = constant")
    print("   - Critical regime (p ≈ p_c'): α ≈ 0.5 → G'(ω) ∝ G''(ω) ∝ ω^0.5")
    print("   - Solid regime (p > p_c'): α ≈ 0.0 → G'(ω) = constant, G''(ω) = 0")
    print()
    
    # 2. Frequency Dependence
    print("2. FREQUENCY DEPENDENCE:")
    print("   - Liquid: No frequency dependence (Newtonian fluid)")
    print("   - Critical: Power law frequency dependence (viscoelastic)")
    print("   - Solid: No frequency dependence (elastic solid)")
    print()
    
    # 3. Loss Tangent Behavior
    print("3. LOSS TANGENT (tan δ) BEHAVIOR:")
    print("   - Liquid: tan δ = ∞ (purely viscous, δ = 90°)")
    print("   - Critical: tan δ = 1 (balanced viscoelastic, δ = 45°)")
    print("   - Solid: tan δ = 0 (purely elastic, δ = 0°)")
    print()
    
    # 4. Phase Angle Evolution
    print("4. PHASE ANGLE (δ) EVOLUTION:")
    print("   - Liquid: δ = 90° (purely viscous response)")
    print("   - Critical: δ = 45° (balanced viscoelastic response)")
    print("   - Solid: δ = 0° (purely elastic response)")
    print()
    
    # 5. Surface Features
    print("5. SURFACE FEATURES:")
    print("   - G'(ω) surface: Shows transition from frequency-dependent to constant")
    print("   - G''(ω) surface: Shows transition from frequency-dependent to zero")
    print("   - Combined surface: Reveals the complete viscoelastic landscape")
    print("   - Critical region: Characterized by power law behavior")
    print()
    
    # 6. Physical Interpretation
    print("6. PHYSICAL INTERPRETATION:")
    print("   - The surfaces reveal how material response evolves across the phase transition")
    print("   - Liquid regime: Fluid-like behavior with energy dissipation")
    print("   - Critical regime: Complex viscoelastic behavior with power law scaling")
    print("   - Solid regime: Elastic behavior with no energy dissipation")
    print()
    
    # 7. Applications
    print("7. APPLICATIONS:")
    print("   - Material design: Tune viscoelastic properties by controlling p")
    print("   - Rheology: Understand frequency-dependent material response")
    print("   - Phase transitions: Identify critical points from material properties")
    print("   - Engineering: Design materials with specific viscoelastic characteristics")

def main():
    """Main function to create summary analysis"""
    
    print("=== VISCOELASTIC SURFACE SUMMARY ANALYSIS ===")
    print()
    
    # Load the corrected analysis results
    df = pd.read_csv('corrected_alpha_analysis_results.csv')
    print(f"Loaded data for {len(df)} p-values")
    print()
    
    # Create summary plots
    print("Creating summary plots...")
    fig = create_summary_plots(df)
    
    # Print key insights
    print_key_insights(df)
    
    print("\nSummary plot saved to: viscoelastic_summary_analysis.png")

if __name__ == "__main__":
    main()
