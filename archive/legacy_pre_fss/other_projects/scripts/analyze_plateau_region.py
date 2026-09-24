#!/usr/bin/env python3
"""
Analyze Plateau Region for t > 10^4

This script directly analyzes the plateau region in the last column (p=0.7484)
for t > 10^4 and calculates α from that region.
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

def analyze_plateau_region():
    """Analyze the plateau region for t > 10^4"""
    
    print("=== PLATEAU REGION ANALYSIS ===")
    print("Analyzing plateau region for t > 10^4 in last column")
    print("=" * 60)
    
    # Load data
    data, p_values, t = load_p_output_data()
    
    # Get the last column (highest p-value)
    last_p = p_values[-1]
    last_col = f'MSD_{last_p}'
    
    print(f"Last p-value: {last_p:.4f}")
    print(f"Column name: {last_col}")
    
    if last_col not in data.columns:
        print(f"Error: Column {last_col} not found!")
        return
    
    # Extract MSD data
    msd = data[last_col].values
    
    # Find plateau region (t > 10^4)
    plateau_mask = t >= 1e4
    t_plateau = t[plateau_mask]
    msd_plateau = msd[plateau_mask]
    
    print(f"Plateau region: t = {t_plateau[0]:.0f} to {t_plateau[-1]:.0f}")
    print(f"Number of points in plateau: {len(t_plateau)}")
    
    # Calculate α from plateau region
    log_t_plateau = np.log10(t_plateau)
    log_msd_plateau = np.log10(msd_plateau)
    
    # Fit log(MSD) = α*log(t) + b
    coeffs = np.polyfit(log_t_plateau, log_msd_plateau, 1)
    alpha_plateau = coeffs[0]
    intercept = coeffs[1]
    
    # Calculate R²
    y_pred = alpha_plateau * log_t_plateau + intercept
    ss_res = np.sum((log_msd_plateau - y_pred) ** 2)
    ss_tot = np.sum((log_msd_plateau - np.mean(log_msd_plateau)) ** 2)
    r_squared = 1 - (ss_res / ss_tot)
    
    # Calculate standard error
    residuals = log_msd_plateau - y_pred
    std_error = np.std(residuals)
    
    print(f"\nPlateau Analysis Results:")
    print(f"  α = {alpha_plateau:.6f}")
    print(f"  R² = {r_squared:.6f}")
    print(f"  Standard error = {std_error:.6f}")
    print(f"  Intercept = {intercept:.6f}")
    
    # Theoretical α
    alpha_theory = 0.0  # Solid regime
    error = abs(alpha_plateau - alpha_theory)
    
    print(f"\nComparison with Theory:")
    print(f"  Theoretical α = {alpha_theory}")
    print(f"  Empirical α = {alpha_plateau:.6f}")
    print(f"  Absolute error = {error:.6f}")
    print(f"  Relative error = {error/alpha_theory*100 if alpha_theory != 0 else '∞'}%")
    
    # Create comprehensive plot
    fig, axes = plt.subplots(2, 3, figsize=(18, 12))
    fig.suptitle(f'Plateau Region Analysis: p = {last_p:.4f} (SOLID Regime)', fontsize=16)
    
    # Plot 1: Full MSD curve (log-log)
    ax1 = axes[0, 0]
    ax1.loglog(t, msd, 'b-', linewidth=2, label='Full MSD')
    ax1.loglog(t_plateau, msd_plateau, 'r-', linewidth=3, label='Plateau region (t > 10⁴)')
    ax1.axvline(x=1e4, color='orange', linestyle='--', alpha=0.7, label='t = 10⁴')
    ax1.set_xlabel('Time τ')
    ax1.set_ylabel('MSD')
    ax1.set_title('Full MSD Curve (Log-Log)')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: Plateau region only (log-log)
    ax2 = axes[0, 1]
    ax2.loglog(t_plateau, msd_plateau, 'r-', linewidth=3, label='Plateau region')
    
    # Add fitted line
    t_fit = np.logspace(np.log10(t_plateau[0]), np.log10(t_plateau[-1]), 100)
    msd_fit = 10**(alpha_plateau * np.log10(t_fit) + intercept)
    ax2.loglog(t_fit, msd_fit, 'g--', linewidth=2, label=f'Fit: α = {alpha_plateau:.3f}')
    
    ax2.set_xlabel('Time τ')
    ax2.set_ylabel('MSD')
    ax2.set_title('Plateau Region (t > 10⁴)')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: Log MSD vs Log t (plateau region)
    ax3 = axes[0, 2]
    ax3.plot(log_t_plateau, log_msd_plateau, 'ro', markersize=4, label='Plateau data')
    ax3.plot(log_t_plateau, y_pred, 'g-', linewidth=2, label=f'Fit: α = {alpha_plateau:.3f}')
    ax3.set_xlabel('log₁₀(τ)')
    ax3.set_ylabel('log₁₀(MSD)')
    ax3.set_title('Log MSD vs Log t (Plateau Region)')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: MSD vs t (linear scale, plateau region)
    ax4 = axes[1, 0]
    ax4.plot(t_plateau, msd_plateau, 'r-', linewidth=2, label='Plateau region')
    ax4.set_xlabel('Time τ')
    ax4.set_ylabel('MSD')
    ax4.set_title('MSD vs Time (Plateau Region)')
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    # Plot 5: Residuals
    ax5 = axes[1, 1]
    ax5.plot(log_t_plateau, residuals, 'ko', markersize=3, label='Residuals')
    ax5.axhline(y=0, color='red', linestyle='--', alpha=0.7)
    ax5.set_xlabel('log₁₀(τ)')
    ax5.set_ylabel('Residuals')
    ax5.set_title(f'Residuals (R² = {r_squared:.3f})')
    ax5.legend()
    ax5.grid(True, alpha=0.3)
    
    # Plot 6: Summary
    ax6 = axes[1, 2]
    ax6.axis('off')
    
    summary_text = f"""
    p = {last_p:.4f}
    Regime: SOLID
    
    Plateau Region:
    t = {t_plateau[0]:.0f} to {t_plateau[-1]:.0f}
    Points: {len(t_plateau)}
    
    Fit Results:
    α = {alpha_plateau:.6f}
    R² = {r_squared:.6f}
    Std Error = {std_error:.6f}
    
    Theory Comparison:
    α_theory = {alpha_theory}
    α_empirical = {alpha_plateau:.6f}
    Error = {error:.6f}
    """
    
    ax6.text(0.1, 0.8, summary_text, fontsize=11, fontfamily='monospace',
             verticalalignment='top', transform=ax6.transAxes,
             bbox=dict(boxstyle="round,pad=0.3", facecolor="lightgray", alpha=0.8))
    
    ax6.set_title('Summary')
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/plateau_region_analysis_p{last_p:.4f}.png", 
                dpi=300, bbox_inches='tight')
    
    print(f"\nPlot saved to: {output_dir}/plateau_region_analysis_p{last_p:.4f}.png")
    
    return fig, alpha_plateau, r_squared, error

def main():
    """Main analysis function"""
    try:
        fig, alpha, r2, error = analyze_plateau_region()
        plt.close(fig)
        
        print(f"\n{'='*60}")
        print("FINAL RESULTS")
        print(f"{'='*60}")
        print(f"Plateau α = {alpha:.6f}")
        print(f"R² = {r2:.6f}")
        print(f"Error vs theory = {error:.6f}")
        
        if r2 > 0.9:
            print("✓ Excellent fit (R² > 0.9)")
        elif r2 > 0.8:
            print("✓ Good fit (R² > 0.8)")
        elif r2 > 0.7:
            print("○ Fair fit (R² > 0.7)")
        else:
            print("✗ Poor fit (R² < 0.7)")
        
        if error < 0.1:
            print("✓ Excellent agreement with theory")
        elif error < 0.2:
            print("✓ Good agreement with theory")
        elif error < 0.5:
            print("○ Fair agreement with theory")
        else:
            print("✗ Poor agreement with theory")
        
        print("\nAnalysis complete!")
        
    except Exception as e:
        print(f"Error in analysis: {e}")

if __name__ == "__main__":
    main() 