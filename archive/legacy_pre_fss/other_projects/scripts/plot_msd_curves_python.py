#!/usr/bin/env python3
"""
Plot MSD curves for all p values with annotations
Shows changepoints, α determination regions, and power-law evidence
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os
from pathlib import Path

def plot_msd_curves_with_annotations():
    """Plot MSD curves for all p values with comprehensive annotations"""
    
    print("=== Plotting MSD Curves with Annotations (Python) ===")
    
    # Parameters
    p_c_prime = 0.6884
    p_values = [0.0000, 0.3116, 0.6884, 0.7500]
    seeds = [1, 2]
    
    # Changepoint data from our analysis
    tau_cr_data = {
        'p_0.0000': [2.80e+03, 1.99e+04],  # seed_01, seed_02
        'p_0.3116': [6.96e+05, 5.79e+05],  # seed_01, seed_02
        'p_0.6884': [3.80e+03, 6.56e+04],  # seed_01, seed_02
        'p_0.7500': [1.94e+04, 5.50e+03],  # seed_01, seed_02
    }
    
    # Optimal α values from our analysis
    alpha_data = {
        'p_0.0000': [1.000, 1.000],  # seed_01, seed_02
        'p_0.3116': [1.000, 1.000],  # seed_01, seed_02
        'p_0.6884': [0.500, 0.500],  # seed_01, seed_02
        'p_0.7500': [0.001, 0.001],  # seed_01, seed_02
    }
    
    # Color scheme
    colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728']  # Blue, Orange, Green, Red
    regime_names = ['LIQUID', 'LIQUID', 'CRITICAL', 'SOLID']
    
    # Create figure
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    axes = axes.flatten()
    
    # Plot each p value
    for p_idx, p in enumerate(p_values):
        ax = axes[p_idx]
        p_key = f'p_{p:.4f}'
        
        # Plot both seeds
        for seed_idx, seed in enumerate(seeds):
            # Load data
            data_path = f"../ensemble_simulations/seed_{seed:02d}/{p_key}/msd_results_L500_p{p:.4f}.csv"
            
            if os.path.exists(data_path):
                print(f"Loading data: p = {p:.4f}, seed = {seed:02d}")
                data = pd.read_csv(data_path)
                t = data['tau'].values
                msd = data['msd'].values
                
                # Subsample for plotting (every 100th point for efficiency)
                if len(t) > 10000:
                    indices = np.arange(0, len(t), 100)
                    t_plot = t[indices]
                    msd_plot = msd[indices]
                else:
                    t_plot = t
                    msd_plot = msd
                
                # Plot MSD curve
                ax.loglog(t_plot, msd_plot, color=colors[p_idx], linewidth=1.5, 
                         label=f'Seed {seed:02d}')
                
                # Get changepoint data
                tau_cr = tau_cr_data[p_key][seed_idx]
                alpha_opt = alpha_data[p_key][seed_idx]
                
                # Mark changepoint
                if tau_cr > 0:
                    # Find MSD value at changepoint
                    idx = np.argmin(np.abs(t_plot - tau_cr))
                    msd_cr = msd_plot[idx]
                    
                    # Plot changepoint
                    ax.loglog(tau_cr, msd_cr, 'ko', markersize=8, markerfacecolor='k',
                             label=f'τ_cr = {tau_cr:.2e}')
                    
                    # Add text annotation
                    ax.annotate(f'τ_cr = {tau_cr:.2e}\nα = {alpha_opt:.3f}', 
                               xy=(tau_cr, msd_cr), xytext=(tau_cr*1.5, msd_cr*0.7),
                               fontsize=8, fontweight='bold',
                               bbox=dict(boxstyle="round,pad=0.3", facecolor="white", alpha=0.8),
                               arrowprops=dict(arrowstyle="->", connectionstyle="arc3"))
                
                # Add theoretical α line for comparison
                if p < p_c_prime - 0.05:
                    expected_alpha = 1.0
                elif abs(p - p_c_prime) < 0.05:
                    expected_alpha = 0.5
                else:
                    expected_alpha = 0.0
                
                # Plot theoretical line
                t_theory = np.logspace(np.log10(t_plot.min()), np.log10(t_plot.max()), 100)
                msd_theory = t_theory**expected_alpha
                ax.loglog(t_theory, msd_theory, '--', color=colors[p_idx], linewidth=1,
                         label=f'α = {expected_alpha:.1f} (theory)')
                
            else:
                print(f"No data found: p = {p:.4f}, seed = {seed:02d}")
        
        # Add regime information
        if p < p_c_prime - 0.05:
            regime = 'LIQUID'
            expected_alpha = 1.0
        elif abs(p - p_c_prime) < 0.05:
            regime = 'CRITICAL'
            expected_alpha = 0.5
        else:
            regime = 'SOLID'
            expected_alpha = 0.0
        
        # Add text box with regime info
        ax.text(0.02, 0.98, f'Regime: {regime}\nExpected α: {expected_alpha:.1f}\nDistance from p_c\': {abs(p - p_c_prime):.3f}',
                transform=ax.transAxes, verticalalignment='top',
                fontsize=10, fontweight='bold',
                bbox=dict(boxstyle="round,pad=0.5", facecolor="white", edgecolor="black"))
        
        # Labels and title
        ax.set_xlabel('Time τ')
        ax.set_ylabel('MSD')
        ax.set_title(f'p = {p:.4f} ({regime_names[p_idx]})')
        ax.grid(True, alpha=0.3)
        ax.legend(loc='best', fontsize=8)
    
    # Add overall title
    fig.suptitle('MSD Curves with Changepoint Annotations', fontsize=16, fontweight='bold')
    plt.tight_layout()
    
    # Save plot
    plt.savefig('msd_curves_with_annotations_python.png', dpi=300, bbox_inches='tight')
    plt.savefig('msd_curves_with_annotations_python.pdf', bbox_inches='tight')
    print("MSD curves plot saved")
    
    # Create power-law relationship plot
    fig2, axes2 = plt.subplots(2, 2, figsize=(12, 8))
    
    # Prepare data for power-law analysis
    p_analysis = []
    tau_analysis = []
    dist_analysis = []
    alpha_analysis = []
    
    for p_idx, p in enumerate(p_values):
        p_key = f'p_{p:.4f}'
        dist = abs(p - p_c_prime)
        
        # Skip critical point for scaling analysis
        if dist == 0:
            continue
        
        # Get τ_cr values for this p
        if p_idx == 0:  # p = 0.0000
            tau_values = tau_cr_data['p_0.0000']
            alpha_values = alpha_data['p_0.0000']
        elif p_idx == 1:  # p = 0.3116
            tau_values = tau_cr_data['p_0.3116']
            alpha_values = alpha_data['p_0.3116']
        elif p_idx == 3:  # p = 0.7500
            tau_values = tau_cr_data['p_0.7500']
            alpha_values = alpha_data['p_0.7500']
        
        # Add to analysis arrays
        for j in range(len(tau_values)):
            p_analysis.append(p)
            tau_analysis.append(tau_values[j])
            dist_analysis.append(dist)
            alpha_analysis.append(alpha_values[j])
    
    # Convert to numpy arrays
    p_analysis = np.array(p_analysis)
    tau_analysis = np.array(tau_analysis)
    dist_analysis = np.array(dist_analysis)
    alpha_analysis = np.array(alpha_analysis)
    
    # Power-law analysis
    ax1 = axes2[0, 0]
    ax1.loglog(dist_analysis, tau_analysis, 'bo', markersize=10, label='Data')
    
    # Fit power law
    log_dist = np.log10(dist_analysis)
    log_tau = np.log10(tau_analysis)
    coeffs = np.polyfit(log_dist, log_tau, 1)
    exponent = coeffs[0]
    intercept = coeffs[1]
    
    # Plot fit
    dist_range = np.logspace(np.log10(dist_analysis.min()), np.log10(dist_analysis.max()), 100)
    tau_fit = 10**(exponent * np.log10(dist_range) + intercept)
    ax1.loglog(dist_range, tau_fit, 'r-', linewidth=2, label=f'Fit: ν = {exponent:.3f}')
    
    # Add critical point
    critical_tau = tau_cr_data['p_0.6884']
    critical_dist = 0.001  # Small value for visualization
    ax1.loglog(critical_dist, np.mean(critical_tau), 'ro', markersize=12, markerfacecolor='r',
               label='Critical Point')
    
    ax1.set_xlabel('|p - p_c\'|')
    ax1.set_ylabel('τ_cr')
    ax1.set_title('Power-Law Relationship: τ_cr vs |p - p_c\'|')
    ax1.legend(loc='best')
    ax1.grid(True, alpha=0.3)
    
    # α values vs p
    ax2 = axes2[0, 1]
    ax2.plot(p_analysis, alpha_analysis, 'bo', markersize=10, label='Optimal α')
    
    # Add critical point
    ax2.plot(p_c_prime, 0.5, 'ro', markersize=12, markerfacecolor='r', label='Critical Point')
    
    # Add theoretical lines
    p_theory = [0, 0.3116, 0.6884, 0.75]
    alpha_theory = [1.0, 1.0, 0.5, 0.0]
    ax2.plot(p_theory, alpha_theory, 'k--', linewidth=2, label='Theoretical')
    
    ax2.set_xlabel('p')
    ax2.set_ylabel('α')
    ax2.set_title('α Values vs p')
    ax2.legend(loc='best')
    ax2.grid(True, alpha=0.3)
    ax2.set_ylim(-0.1, 1.1)
    
    # τ_cr vs p with regime coloring
    ax3 = axes2[1, 0]
    
    # Color by regime
    liquid_mask = p_analysis < p_c_prime - 0.05
    solid_mask = p_analysis > p_c_prime + 0.05
    
    if np.any(liquid_mask):
        ax3.semilogy(p_analysis[liquid_mask], tau_analysis[liquid_mask], 'bo', markersize=10, label='Liquid')
    ax3.semilogy(p_c_prime, np.mean(critical_tau), 'ro', markersize=12, markerfacecolor='r', label='Critical')
    if np.any(solid_mask):
        ax3.semilogy(p_analysis[solid_mask], tau_analysis[solid_mask], 'go', markersize=10, label='Solid')
    
    ax3.axvline(p_c_prime, color='k', linestyle='--', linewidth=2, label='p_c\'')
    ax3.set_xlabel('p')
    ax3.set_ylabel('τ_cr')
    ax3.set_title('τ_cr vs p (Regime Coloring)')
    ax3.legend(loc='best')
    ax3.grid(True, alpha=0.3)
    
    # Residuals
    ax4 = axes2[1, 1]
    tau_pred = exponent * log_dist + intercept
    residuals = log_tau - tau_pred
    
    ax4.plot(log_dist, residuals, 'bo', markersize=10)
    ax4.axhline(0, color='r', linestyle='--', linewidth=1)
    ax4.set_xlabel('log(|p - p_c\'|)')
    ax4.set_ylabel('Residuals')
    ax4.set_title('Fit Residuals')
    ax4.grid(True, alpha=0.3)
    
    fig2.suptitle('Power-Law Analysis Summary', fontsize=16, fontweight='bold')
    plt.tight_layout()
    
    # Save power-law plot
    plt.savefig('power_law_analysis_summary_python.png', dpi=300, bbox_inches='tight')
    plt.savefig('power_law_analysis_summary_python.pdf', bbox_inches='tight')
    print("Power-law analysis plot saved")
    
    # Print summary
    print(f"\n=== Summary ===")
    print(f"Power-law exponent: ν = {exponent:.3f}")
    print(f"Equation: τ_cr ∝ |p - p_c'|^{exponent:.3f}")
    
    # Calculate R²
    ss_res = np.sum(residuals**2)
    ss_tot = np.sum((log_tau - np.mean(log_tau))**2)
    r_squared = 1 - ss_res/ss_tot
    print(f"R² = {r_squared:.3f}")
    
    print(f"\n=== Analysis Complete ===")
    
    # Show plots
    plt.show()

if __name__ == "__main__":
    plot_msd_curves_with_annotations() 