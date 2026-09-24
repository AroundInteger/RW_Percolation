#!/usr/bin/env python3
"""
Viscoelastic Surfaces: G'(ω) and G''(ω) vs p and ω
Generate 2D surface plots showing how storage and loss moduli evolve
across the percolation probability range and frequency domain
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from matplotlib import cm
import warnings
warnings.filterwarnings('ignore')

def calculate_viscoelastic_response(alpha, omega, p, p_c_prime=0.6884):
    """
    Calculate G'(ω) and G''(ω) based on α values and frequency
    
    For a power law material with MSD ∝ t^α:
    - G'(ω) ∝ ω^α (storage modulus)
    - G''(ω) ∝ ω^α (loss modulus)
    
    The exact relationship depends on the material properties
    """
    
    # Base modulus (normalized)
    G0 = 1.0
    
    # Ensure omega is an array
    omega = np.asarray(omega)
    
    # Calculate moduli based on α
    if alpha <= 0:
        # Solid regime: purely elastic
        G_prime = np.full_like(omega, G0)
        G_double_prime = np.zeros_like(omega)
    elif alpha >= 1:
        # Liquid regime: Newtonian fluid
        G_prime = np.full_like(omega, G0)
        G_double_prime = np.full_like(omega, G0)
    else:
        # Viscoelastic regime: power law behavior
        G_prime = G0 * (omega ** alpha)
        G_double_prime = G0 * (omega ** alpha)
    
    return G_prime, G_double_prime

def create_viscoelastic_surfaces(df):
    """Create 2D surface plots for G'(ω) and G''(ω)"""
    
    # Extract p-values and α values
    p_values = df['p'].values
    alpha_values = df['alpha_opt'].values
    
    # Create frequency domain (logarithmic scale)
    omega_min = 1e-2  # 0.01 rad/s
    omega_max = 1e2   # 100 rad/s
    n_omega = 100
    omega = np.logspace(np.log10(omega_min), np.log10(omega_max), n_omega)
    
    # Create meshgrid for 3D plotting
    P, Omega = np.meshgrid(p_values, omega)
    
    # Calculate G'(ω) and G''(ω) for each (p, ω) combination
    G_prime_surface = np.zeros_like(P)
    G_double_prime_surface = np.zeros_like(P)
    
    for i, omega_val in enumerate(omega):
        for j, (p_val, alpha_val) in enumerate(zip(p_values, alpha_values)):
            G_prime, G_double_prime = calculate_viscoelastic_response(alpha_val, omega_val, p_val)
            G_prime_surface[i, j] = G_prime
            G_double_prime_surface[i, j] = G_double_prime
    
    # Create the plots
    fig = plt.figure(figsize=(20, 12))
    
    # Plot 1: G'(ω) surface
    ax1 = fig.add_subplot(2, 3, 1, projection='3d')
    surf1 = ax1.plot_surface(P, Omega, G_prime_surface, cmap=cm.viridis, alpha=0.8)
    ax1.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax1.set_ylabel('Frequency ω (rad/s)', fontsize=12)
    ax1.set_zlabel("G'(ω)", fontsize=12)
    ax1.set_title("Storage Modulus G'(ω) Surface", fontsize=14, fontweight='bold')
    ax1.view_init(elev=20, azim=45)
    
    # Plot 2: G''(ω) surface
    ax2 = fig.add_subplot(2, 3, 2, projection='3d')
    surf2 = ax2.plot_surface(P, Omega, G_double_prime_surface, cmap=cm.plasma, alpha=0.8)
    ax2.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax2.set_ylabel('Frequency ω (rad/s)', fontsize=12)
    ax2.set_zlabel("G''(ω)", fontsize=12)
    ax2.set_title("Loss Modulus G''(ω) Surface", fontsize=14, fontweight='bold')
    ax2.view_init(elev=20, azim=45)
    
    # Plot 3: Combined surface (G' + G'')
    ax3 = fig.add_subplot(2, 3, 3, projection='3d')
    combined_surface = G_prime_surface + G_double_prime_surface
    surf3 = ax3.plot_surface(P, Omega, combined_surface, cmap=cm.magma, alpha=0.8)
    ax3.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax3.set_ylabel('Frequency ω (rad/s)', fontsize=12)
    ax3.set_zlabel("G'(ω) + G''(ω)", fontsize=12)
    ax3.set_title("Combined Modulus Surface", fontsize=14, fontweight='bold')
    ax3.view_init(elev=20, azim=45)
    
    # Plot 4: 2D contour plot of G'(ω)
    ax4 = fig.add_subplot(2, 3, 4)
    contour1 = ax4.contourf(P, Omega, G_prime_surface, levels=20, cmap=cm.viridis)
    ax4.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax4.set_ylabel('Frequency ω (rad/s)', fontsize=12)
    ax4.set_title("G'(ω) Contour Map", fontsize=14, fontweight='bold')
    ax4.set_yscale('log')
    plt.colorbar(contour1, ax=ax4, label="G'(ω)")
    
    # Plot 5: 2D contour plot of G''(ω)
    ax5 = fig.add_subplot(2, 3, 5)
    contour2 = ax5.contourf(P, Omega, G_double_prime_surface, levels=20, cmap=cm.plasma)
    ax5.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax5.set_ylabel('Frequency ω (rad/s)', fontsize=12)
    ax5.set_title("G''(ω) Contour Map", fontsize=14, fontweight='bold')
    ax5.set_yscale('log')
    plt.colorbar(contour2, ax=ax5, label="G''(ω)")
    
    # Plot 6: Tan δ surface (G''/G')
    ax6 = fig.add_subplot(2, 3, 6, projection='3d')
    # Avoid division by zero
    tan_delta_surface = np.where(G_prime_surface > 1e-10, 
                                G_double_prime_surface / G_prime_surface, 0)
    surf6 = ax6.plot_surface(P, Omega, tan_delta_surface, cmap=cm.coolwarm, alpha=0.8)
    ax6.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax6.set_ylabel('Frequency ω (rad/s)', fontsize=12)
    ax6.set_zlabel("tan δ = G''/G'", fontsize=12)
    ax6.set_title("Loss Tangent Surface", fontsize=14, fontweight='bold')
    ax6.view_init(elev=20, azim=45)
    
    plt.tight_layout()
    plt.savefig('viscoelastic_surfaces_3d.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    return fig

def create_2d_contour_plots(df):
    """Create 2D contour plots for easier interpretation"""
    
    # Extract p-values and α values
    p_values = df['p'].values
    alpha_values = df['alpha_opt'].values
    
    # Create frequency domain
    omega_min = 1e-2
    omega_max = 1e2
    n_omega = 100
    omega = np.logspace(np.log10(omega_min), np.log10(omega_max), n_omega)
    
    # Create meshgrid
    P, Omega = np.meshgrid(p_values, omega)
    
    # Calculate surfaces
    G_prime_surface = np.zeros_like(P)
    G_double_prime_surface = np.zeros_like(P)
    
    for i, omega_val in enumerate(omega):
        for j, (p_val, alpha_val) in enumerate(zip(p_values, alpha_values)):
            G_prime, G_double_prime = calculate_viscoelastic_response(alpha_val, omega_val, p_val)
            G_prime_surface[i, j] = G_prime
            G_double_prime_surface[i, j] = G_double_prime
    
    # Create 2D plots
    fig, axes = plt.subplots(2, 3, figsize=(18, 12))
    
    # Plot 1: G'(ω) contour
    ax1 = axes[0, 0]
    contour1 = ax1.contourf(P, Omega, G_prime_surface, levels=25, cmap=cm.viridis)
    ax1.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax1.set_ylabel('Frequency ω (rad/s)', fontsize=12)
    ax1.set_title("Storage Modulus G'(ω)", fontsize=14, fontweight='bold')
    ax1.set_yscale('log')
    plt.colorbar(contour1, ax=ax1, label="G'(ω)")
    
    # Plot 2: G''(ω) contour
    ax2 = axes[0, 1]
    contour2 = ax2.contourf(P, Omega, G_double_prime_surface, levels=25, cmap=cm.plasma)
    ax2.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax2.set_ylabel('Frequency ω (rad/s)', fontsize=12)
    ax2.set_title("Loss Modulus G''(ω)", fontsize=14, fontweight='bold')
    ax2.set_yscale('log')
    plt.colorbar(contour2, ax=ax2, label="G''(ω)")
    
    # Plot 3: Combined modulus
    ax3 = axes[0, 2]
    combined_surface = G_prime_surface + G_double_prime_surface
    contour3 = ax3.contourf(P, Omega, combined_surface, levels=25, cmap=cm.magma)
    ax3.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax3.set_ylabel('Frequency ω (rad/s)', fontsize=12)
    ax3.set_title("Combined Modulus G'(ω) + G''(ω)", fontsize=14, fontweight='bold')
    ax3.set_yscale('log')
    plt.colorbar(contour3, ax=ax3, label="G'(ω) + G''(ω)")
    
    # Plot 4: Loss tangent tan δ
    ax4 = axes[1, 0]
    tan_delta_surface = np.where(G_prime_surface > 1e-10, 
                                G_double_prime_surface / G_prime_surface, 0)
    contour4 = ax4.contourf(P, Omega, tan_delta_surface, levels=25, cmap=cm.coolwarm)
    ax4.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax4.set_ylabel('Frequency ω (rad/s)', fontsize=12)
    ax4.set_title("Loss Tangent tan δ = G''/G'", fontsize=14, fontweight='bold')
    ax4.set_yscale('log')
    plt.colorbar(contour4, ax=ax4, label="tan δ")
    
    # Plot 5: Phase angle δ
    ax5 = axes[1, 1]
    delta_surface = np.arctan2(G_double_prime_surface, G_prime_surface) * 180 / np.pi
    contour5 = ax5.contourf(P, Omega, delta_surface, levels=25, cmap=cm.twilight)
    ax5.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax5.set_ylabel('Frequency ω (rad/s)', fontsize=12)
    ax5.set_title("Phase Angle δ (degrees)", fontsize=14, fontweight='bold')
    ax5.set_yscale('log')
    plt.colorbar(contour5, ax=ax5, label="δ (degrees)")
    
    # Plot 6: α values (for reference)
    ax6 = axes[1, 2]
    alpha_surface = np.tile(alpha_values, (n_omega, 1))
    contour6 = ax6.contourf(P, Omega, alpha_surface, levels=25, cmap=cm.RdYlBu_r)
    ax6.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax6.set_ylabel('Frequency ω (rad/s)', fontsize=12)
    ax6.set_title("Growth Exponent α", fontsize=14, fontweight='bold')
    ax6.set_yscale('log')
    plt.colorbar(contour6, ax=ax6, label="α")
    
    # Add critical point lines
    p_c_prime = 0.6884
    for ax in axes.flat:
        ax.axvline(x=p_c_prime, color='black', linestyle='--', alpha=0.8, linewidth=2, label="p_c'")
        ax.legend(fontsize=10)
    
    plt.tight_layout()
    plt.savefig('viscoelastic_contours_2d.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    return fig

def create_frequency_slices(df):
    """Create frequency slices at different p-values"""
    
    # Select representative p-values for each regime
    p_c_prime = 0.6884
    
    # Liquid regime - find closest available p-value
    p_liquid_target = 0.3
    p_liquid = df['p'].iloc[(df['p'] - p_liquid_target).abs().argsort()[:1]].iloc[0]
    alpha_liquid = df[df['p'] == p_liquid]['alpha_opt'].iloc[0]
    
    # Critical regime - find closest available p-value
    p_critical = df['p'].iloc[(df['p'] - p_c_prime).abs().argsort()[:1]].iloc[0]
    alpha_critical = df[df['p'] == p_critical]['alpha_opt'].iloc[0]
    
    # Solid regime - find closest available p-value
    p_solid_target = 0.75
    p_solid = df['p'].iloc[(df['p'] - p_solid_target).abs().argsort()[:1]].iloc[0]
    alpha_solid = df[df['p'] == p_solid]['alpha_opt'].iloc[0]
    
    # Create frequency domain
    omega = np.logspace(-2, 2, 100)
    
    # Calculate moduli for each regime
    G_prime_liquid, G_double_prime_liquid = calculate_viscoelastic_response(alpha_liquid, omega, p_liquid)
    G_prime_critical, G_double_prime_critical = calculate_viscoelastic_response(alpha_critical, omega, p_critical)
    G_prime_solid, G_double_prime_solid = calculate_viscoelastic_response(alpha_solid, omega, p_solid)
    
    # Ensure arrays have correct dimensions
    G_prime_liquid = np.array(G_prime_liquid).flatten()
    G_double_prime_liquid = np.array(G_double_prime_liquid).flatten()
    G_prime_critical = np.array(G_prime_critical).flatten()
    G_double_prime_critical = np.array(G_double_prime_critical).flatten()
    G_prime_solid = np.array(G_prime_solid).flatten()
    G_double_prime_solid = np.array(G_double_prime_solid).flatten()
    
    # Create plots
    fig, axes = plt.subplots(2, 2, figsize=(15, 12))
    
    # Plot 1: G'(ω) frequency dependence
    ax1 = axes[0, 0]
    ax1.loglog(omega, G_prime_liquid, 'b-', linewidth=3, label=f'Liquid (p={p_liquid}, α={alpha_liquid:.3f})')
    ax1.loglog(omega, G_prime_critical, 'orange', linewidth=3, label=f'Critical (p={p_critical}, α={alpha_critical:.3f})')
    ax1.loglog(omega, G_prime_solid, 'r--', linewidth=3, label=f'Solid (p={p_solid}, α={alpha_solid:.3f})')
    ax1.set_xlabel('Frequency ω (rad/s)', fontsize=12)
    ax1.set_ylabel("G'(ω)", fontsize=12)
    ax1.set_title("Storage Modulus vs Frequency", fontsize=14, fontweight='bold')
    ax1.legend(fontsize=10)
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: G''(ω) frequency dependence
    ax2 = axes[0, 1]
    ax2.loglog(omega, G_double_prime_liquid, 'b-', linewidth=3, label=f'Liquid (p={p_liquid}, α={alpha_liquid:.3f})')
    ax2.loglog(omega, G_double_prime_critical, 'orange', linewidth=3, label=f'Critical (p={p_critical}, α={alpha_critical:.3f})')
    ax2.loglog(omega, G_double_prime_solid, 'r--', linewidth=3, label=f'Solid (p={p_solid}, α={alpha_solid:.3f})')
    ax2.set_xlabel('Frequency ω (rad/s)', fontsize=12)
    ax2.set_ylabel("G''(ω)", fontsize=12)
    ax2.set_title("Loss Modulus vs Frequency", fontsize=14, fontweight='bold')
    ax2.legend(fontsize=10)
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: Tan δ frequency dependence
    ax3 = axes[1, 0]
    tan_delta_liquid = G_double_prime_liquid / np.maximum(G_prime_liquid, 1e-10)
    tan_delta_critical = G_double_prime_critical / np.maximum(G_prime_critical, 1e-10)
    tan_delta_solid = G_double_prime_solid / np.maximum(G_prime_solid, 1e-10)
    
    ax3.loglog(omega, tan_delta_liquid, 'b-', linewidth=3, label=f'Liquid (p={p_liquid})')
    ax3.loglog(omega, tan_delta_critical, 'orange', linewidth=3, label=f'Critical (p={p_critical})')
    ax3.loglog(omega, tan_delta_solid, 'r-', linewidth=3, label=f'Solid (p={p_solid})')
    ax3.set_xlabel('Frequency ω (rad/s)', fontsize=12)
    ax3.set_ylabel("tan δ = G''/G'", fontsize=12)
    ax3.set_title("Loss Tangent vs Frequency", fontsize=14, fontweight='bold')
    ax3.legend(fontsize=10)
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: Phase angle δ frequency dependence
    ax4 = axes[1, 1]
    delta_liquid = np.arctan2(G_double_prime_liquid, G_prime_liquid) * 180 / np.pi
    delta_critical = np.arctan2(G_double_prime_critical, G_prime_critical) * 180 / np.pi
    delta_solid = np.arctan2(G_double_prime_solid, G_prime_solid) * 180 / np.pi
    
    ax4.semilogx(omega, delta_liquid, 'b-', linewidth=3, label=f'Liquid (p={p_liquid})')
    ax4.semilogx(omega, delta_critical, 'orange', linewidth=3, label=f'Critical (p={p_critical})')
    ax4.semilogx(omega, delta_solid, 'r--', linewidth=3, label=f'Solid (p={p_solid})')
    ax4.set_xlabel('Frequency ω (rad/s)', fontsize=12)
    ax4.set_ylabel("Phase Angle δ (degrees)", fontsize=12)
    ax4.set_title("Phase Angle vs Frequency", fontsize=14, fontweight='bold')
    ax4.legend(fontsize=10)
    ax4.grid(True, alpha=0.3)
    ax4.set_ylim(0, 90)
    
    plt.tight_layout()
    plt.savefig('viscoelastic_frequency_slices.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    return fig

def main():
    """Main function to create all viscoelastic visualizations"""
    
    print("=== VISCOELASTIC SURFACE PLOTTING ===")
    print()
    
    # Load the corrected analysis results
    df = pd.read_csv('corrected_alpha_analysis_results.csv')
    print(f"Loaded data for {len(df)} p-values")
    print()
    
    # Create 3D surface plots
    print("Creating 3D surface plots...")
    fig1 = create_viscoelastic_surfaces(df)
    
    # Create 2D contour plots
    print("Creating 2D contour plots...")
    fig2 = create_2d_contour_plots(df)
    
    # Create frequency slices
    print("Creating frequency slice plots...")
    fig3 = create_frequency_slices(df)
    
    print("\nAll viscoelastic plots created:")
    print("- viscoelastic_surfaces_3d.png (3D surfaces)")
    print("- viscoelastic_contours_2d.png (2D contours)")
    print("- viscoelastic_frequency_slices.png (frequency slices)")

if __name__ == "__main__":
    main()
