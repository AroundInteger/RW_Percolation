#!/usr/bin/env python3
"""
Plot MSD Patterns from p_output.csv

This script plots the MSD curves to visually identify the different regions
and patterns in the actual data.
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import os

def load_p_output_data():
    """Load the p_output.csv data"""
    filepath = "/Users/rowanbrown/Documents/GitHub/RW_Percolation/matlab/p_output.csv"
    
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"Data file not found: {filepath}")
    
    # Load data
    data = pd.read_csv(filepath)
    
    # Extract p-values from headers (remove 'MSD_' prefix)
    p_values = []
    for col in data.columns:
        if col.startswith('MSD_'):
            p_str = col[4:]  # Remove 'MSD_' prefix
            try:
                p_values.append(float(p_str))
            except ValueError:
                print(f"Warning: Could not parse p-value from column {col}")
    
    # Create time array (steps)
    t = np.arange(len(data))
    
    return data, p_values, t

def plot_msd_overview(data, p_values, t):
    """Plot overview of all MSD curves"""
    
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('MSD Curves Overview - All p-values', fontsize=16)
    
    # Determine regime for each p-value
    p_c_prime = 0.6884
    regimes = []
    for p in p_values:
        if p < p_c_prime - 0.05:
            regimes.append('LIQUID')
        elif abs(p - p_c_prime) < 0.05:
            regimes.append('CRITICAL')
        else:
            regimes.append('SOLID')
    
    # Plot 1: All MSD curves (log-log)
    ax1 = axes[0, 0]
    colors = {'LIQUID': 'blue', 'CRITICAL': 'orange', 'SOLID': 'red'}
    
    for i, p in enumerate(p_values):
        msd_col = f'MSD_{p}'
        if msd_col in data.columns:
            msd = data[msd_col].values
            regime = regimes[i]
            color = colors[regime]
            alpha = 0.7 if regime == 'CRITICAL' else 0.5
            ax1.loglog(t, msd, color=color, alpha=alpha, linewidth=1)
    
    ax1.set_xlabel('Time τ')
    ax1.set_ylabel('MSD')
    ax1.set_title('All MSD Curves (Log-Log)')
    ax1.grid(True, alpha=0.3)
    
    # Add legend
    for regime, color in colors.items():
        ax1.plot([], [], color=color, linewidth=2, label=regime)
    ax1.legend()
    
    # Plot 2: Selected p-values for detailed examination
    ax2 = axes[0, 1]
    selected_p = [0.0, 0.3116, 0.6884, 0.7484]  # Representative from each regime
    selected_colors = ['blue', 'green', 'orange', 'red']
    
    for i, p in enumerate(selected_p):
        msd_col = f'MSD_{p}'
        if msd_col in data.columns:
            msd = data[msd_col].values
            ax2.loglog(t, msd, color=selected_colors[i], linewidth=2, label=f'p = {p:.4f}')
    
    ax2.set_xlabel('Time τ')
    ax2.set_ylabel('MSD')
    ax2.set_title('Selected MSD Curves')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: MSD vs time (linear scale) for selected p-values
    ax3 = axes[1, 0]
    for i, p in enumerate(selected_p):
        msd_col = f'MSD_{p}'
        if msd_col in data.columns:
            msd = data[msd_col].values
            ax3.plot(t, msd, color=selected_colors[i], linewidth=2, label=f'p = {p:.4f}')
    
    ax3.set_xlabel('Time τ')
    ax3.set_ylabel('MSD')
    ax3.set_title('Selected MSD Curves (Linear Scale)')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: Critical region zoom
    ax4 = axes[1, 1]
    critical_p = [p for p in p_values if abs(p - p_c_prime) < 0.1]
    
    for p in critical_p:
        msd_col = f'MSD_{p}'
        if msd_col in data.columns:
            msd = data[msd_col].values
            ax4.loglog(t, msd, linewidth=1, alpha=0.7, label=f'p = {p:.4f}')
    
    ax4.set_xlabel('Time τ')
    ax4.set_ylabel('MSD')
    ax4.set_title('Critical Region (p ≈ 0.6884)')
    ax4.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/msd_patterns_overview.png", 
                dpi=300, bbox_inches='tight')
    
    return fig

def plot_individual_msd_analysis(data, p_values, t):
    """Plot detailed analysis of individual MSD curves"""
    
    # Select key p-values for detailed analysis
    key_p_values = [0.0, 0.3116, 0.6884, 0.7484]
    
    for p in key_p_values:
        msd_col = f'MSD_{p}'
        if msd_col not in data.columns:
            continue
            
        msd = data[msd_col].values
        
        # Determine regime
        p_c_prime = 0.6884
        if p < p_c_prime - 0.05:
            regime = "LIQUID"
        elif abs(p - p_c_prime) < 0.05:
            regime = "CRITICAL"
        else:
            regime = "SOLID"
        
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        fig.suptitle(f'MSD Analysis: p = {p:.4f} ({regime} Regime)', fontsize=16)
        
        # Plot 1: MSD vs time (log-log)
        ax1 = axes[0, 0]
        ax1.loglog(t, msd, 'b-', linewidth=2, label='MSD')
        ax1.set_xlabel('Time τ')
        ax1.set_ylabel('MSD')
        ax1.set_title(f'MSD vs Time (Log-Log) - {regime}')
        ax1.legend()
        ax1.grid(True, alpha=0.3)
        
        # Plot 2: MSD vs time (linear)
        ax2 = axes[0, 1]
        ax2.plot(t, msd, 'g-', linewidth=2, label='MSD')
        ax2.set_xlabel('Time τ')
        ax2.set_ylabel('MSD')
        ax2.set_title(f'MSD vs Time (Linear) - {regime}')
        ax2.legend()
        ax2.grid(True, alpha=0.3)
        
        # Plot 3: MSD vs time (semi-log)
        ax3 = axes[1, 0]
        ax3.semilogx(t, msd, 'r-', linewidth=2, label='MSD')
        ax3.set_xlabel('Time τ')
        ax3.set_ylabel('MSD')
        ax3.set_title(f'MSD vs Time (Semi-Log) - {regime}')
        ax3.legend()
        ax3.grid(True, alpha=0.3)
        
        # Plot 4: MSD vs time (log-linear)
        ax4 = axes[1, 1]
        ax4.semilogy(t, msd, 'm-', linewidth=2, label='MSD')
        ax4.set_xlabel('Time τ')
        ax4.set_ylabel('MSD')
        ax4.set_title(f'MSD vs Time (Log-Linear) - {regime}')
        ax4.legend()
        ax4.grid(True, alpha=0.3)
        
        plt.tight_layout()
        
        # Save plot
        output_dir = "../paper_figures"
        os.makedirs(output_dir, exist_ok=True)
        plt.savefig(f"{output_dir}/msd_analysis_p{p:.4f}.png", 
                    dpi=300, bbox_inches='tight')
        plt.close(fig)

def plot_msd_derivatives(data, p_values, t):
    """Plot derivatives of MSD to identify regions"""
    
    from scipy.signal import savgol_filter
    
    # Select key p-values
    key_p_values = [0.0, 0.3116, 0.6884, 0.7484]
    
    for p in key_p_values:
        msd_col = f'MSD_{p}'
        if msd_col not in data.columns:
            continue
            
        msd = data[msd_col].values
        
        # Determine regime
        p_c_prime = 0.6884
        if p < p_c_prime - 0.05:
            regime = "LIQUID"
        elif abs(p - p_c_prime) < 0.05:
            regime = "CRITICAL"
        else:
            regime = "SOLID"
        
        # Calculate derivatives
        log_t = np.log10(t[1:])  # Skip t=0
        log_msd = np.log10(msd[1:])  # Skip MSD=0
        
        # First derivative (local α)
        window_size = min(15, len(log_t) // 4)
        if window_size < 5:
            window_size = 5
        
        alpha_local = np.full_like(t, np.nan)
        for i in range(window_size, len(log_t) - window_size):
            window_start = i - window_size // 2
            window_end = i + window_size // 2
            t_window = log_t[window_start:window_end]
            msd_window = log_msd[window_start:window_end]
            coeffs = np.polyfit(t_window, msd_window, 1)
            alpha_local[i+1] = coeffs[0]
        
        # Second derivative
        valid_mask = np.isfinite(alpha_local)
        alpha_valid = alpha_local[valid_mask]
        t_valid = t[valid_mask]
        
        if len(alpha_valid) > 20:
            try:
                alpha_2nd_deriv = savgol_filter(alpha_valid, window_size, 3, deriv=1)
            except:
                alpha_2nd_deriv = np.gradient(alpha_valid)
        else:
            alpha_2nd_deriv = np.gradient(alpha_valid)
        
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        fig.suptitle(f'MSD Derivatives Analysis: p = {p:.4f} ({regime})', fontsize=16)
        
        # Plot 1: MSD vs time
        ax1 = axes[0, 0]
        ax1.loglog(t, msd, 'b-', linewidth=2, label='MSD')
        ax1.set_xlabel('Time τ')
        ax1.set_ylabel('MSD')
        ax1.set_title('MSD vs Time')
        ax1.legend()
        ax1.grid(True, alpha=0.3)
        
        # Plot 2: Local α vs time
        ax2 = axes[0, 1]
        ax2.semilogx(t_valid, alpha_valid, 'g-', linewidth=2, label='Local α')
        
        # Add theoretical α lines
        if regime == "LIQUID":
            ax2.axhline(y=1.0, color='blue', linestyle='--', alpha=0.7, label='α = 1.0')
        elif regime == "CRITICAL":
            ax2.axhline(y=0.53, color='orange', linestyle='--', alpha=0.7, label='α = 0.53')
        else:
            ax2.axhline(y=0.0, color='red', linestyle='--', alpha=0.7, label='α = 0.0')
        
        ax2.set_xlabel('Time τ')
        ax2.set_ylabel('Local α')
        ax2.set_title('Local α vs Time')
        ax2.legend()
        ax2.grid(True, alpha=0.3)
        
        # Plot 3: Second derivative
        ax3 = axes[1, 0]
        ax3.semilogx(t_valid, alpha_2nd_deriv, 'r-', linewidth=2, label='dα/d(log τ)')
        ax3.axhline(y=0, color='black', linestyle='-', alpha=0.5)
        ax3.set_xlabel('Time τ')
        ax3.set_ylabel('dα/d(log τ)')
        ax3.set_title('Second Derivative')
        ax3.legend()
        ax3.grid(True, alpha=0.3)
        
        # Plot 4: Combined view
        ax4 = axes[1, 1]
        ax4_twin = ax4.twinx()
        
        # MSD on left axis
        line1 = ax4.loglog(t, msd, 'b-', linewidth=2, label='MSD')
        ax4.set_xlabel('Time τ')
        ax4.set_ylabel('MSD', color='blue')
        ax4.tick_params(axis='y', labelcolor='blue')
        
        # α on right axis
        line2 = ax4_twin.semilogx(t_valid, alpha_valid, 'g-', linewidth=2, label='Local α')
        ax4_twin.set_ylabel('Local α', color='green')
        ax4_twin.tick_params(axis='y', labelcolor='green')
        
        ax4.set_title('MSD and α Combined')
        ax4.grid(True, alpha=0.3)
        
        plt.tight_layout()
        
        # Save plot
        output_dir = "../paper_figures"
        os.makedirs(output_dir, exist_ok=True)
        plt.savefig(f"{output_dir}/msd_derivatives_p{p:.4f}.png", 
                    dpi=300, bbox_inches='tight')
        plt.close(fig)

def main():
    """Main analysis function"""
    print("=== MSD PATTERNS ANALYSIS ===")
    print("Plotting MSD curves to identify regions and patterns")
    print("=" * 60)
    
    try:
        # Load data
        data, p_values, t = load_p_output_data()
        
        print(f"Loaded data with {len(p_values)} p-values")
        print(f"Time range: {t[0]} to {t[-1]} steps")
        print(f"P-values: {p_values[:5]}...{p_values[-5:]}")
        print()
        
        # Create plots
        print("Creating overview plot...")
        fig1 = plot_msd_overview(data, p_values, t)
        plt.close(fig1)
        
        print("Creating individual MSD analysis plots...")
        plot_individual_msd_analysis(data, p_values, t)
        
        print("Creating derivative analysis plots...")
        plot_msd_derivatives(data, p_values, t)
        
        print("\nAnalysis complete!")
        print("Check ../paper_figures/ for all plots")
        
    except Exception as e:
        print(f"Error in analysis: {e}")

if __name__ == "__main__":
    main() 