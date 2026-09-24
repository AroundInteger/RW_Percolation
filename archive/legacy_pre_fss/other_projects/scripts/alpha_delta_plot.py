#!/usr/bin/env python3
"""
Alpha and Delta vs p Plot
Plot both α and δ as functions of p to show the complete phase transition
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats

def load_and_prepare_data():
    """Load the corrected analysis results and prepare for plotting"""
    
    # Load the results
    df = pd.read_csv('corrected_alpha_analysis_results.csv')
    
    # Calculate δ from α using the relationship δ = πα/2
    df['delta_radians'] = np.pi * df['alpha_opt'] / 2
    df['delta_degrees'] = df['delta_radians'] * 180 / np.pi
    
    # Sort by p for proper plotting
    df = df.sort_values('p')
    
    return df

def create_alpha_delta_plot(df):
    """Create comprehensive α and δ vs p plot"""
    
    # Set up the figure with two subplots
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10))
    
    # Color scheme for different regimes
    colors = {'liquid': 'blue', 'critical': 'orange', 'solid': 'red'}
    markers = {'liquid': 'o', 'critical': 's', 'solid': '^'}
    
    # Plot 1: α vs p
    ax1.set_title('Growth Exponent α vs Percolation Probability p', fontsize=14, fontweight='bold')
    
    for strategy in ['liquid', 'critical', 'solid']:
        mask = df['strategy'] == strategy
        if np.any(mask):
            p_vals = df.loc[mask, 'p']
            alphas = df.loc[mask, 'alpha_opt']
            ax1.plot(p_vals, alphas, marker=markers[strategy], color=colors[strategy], 
                    linestyle='-', linewidth=2, markersize=8, label=f'{strategy.title()} Regime')
    
    # Add theoretical lines
    p_c_prime = 0.6884
    ax1.axhline(y=1.0, color='blue', linestyle='--', alpha=0.7, linewidth=2, label='α = 1.0 (liquid)')
    ax1.axhline(y=0.5, color='orange', linestyle='--', alpha=0.7, linewidth=2, label='α = 0.5 (critical)')
    ax1.axhline(y=0.0, color='red', linestyle='--', alpha=0.7, linewidth=2, label='α = 0.0 (solid)')
    ax1.axvline(x=p_c_prime, color='black', linestyle=':', alpha=0.8, linewidth=3, label=f"p_c' = {p_c_prime}")
    
    # Add transition regions
    ax1.axvspan(p_c_prime - 0.05, p_c_prime + 0.05, alpha=0.2, color='orange', label='Critical Region')
    
    ax1.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax1.set_ylabel('Growth Exponent (α)', fontsize=12)
    ax1.legend(fontsize=10, loc='upper right')
    ax1.grid(True, alpha=0.3)
    ax1.set_ylim(-0.1, 1.1)
    
    # Plot 2: δ vs p
    ax2.set_title('Phase Angle δ vs Percolation Probability p', fontsize=14, fontweight='bold')
    
    for strategy in ['liquid', 'critical', 'solid']:
        mask = df['strategy'] == strategy
        if np.any(mask):
            p_vals = df.loc[mask, 'p']
            deltas = df.loc[mask, 'delta_degrees']
            ax2.plot(p_vals, deltas, marker=markers[strategy], color=colors[strategy], 
                    linestyle='-', linewidth=2, markersize=8, label=f'{strategy.title()} Regime')
    
    # Add theoretical lines for δ
    ax2.axhline(y=90.0, color='blue', linestyle='--', alpha=0.7, linewidth=2, label='δ = 90° (liquid)')
    ax2.axhline(y=45.0, color='orange', linestyle='--', alpha=0.7, linewidth=2, label='δ = 45° (critical)')
    ax2.axhline(y=0.0, color='red', linestyle='--', alpha=0.7, linewidth=2, label='δ = 0° (solid)')
    ax2.axvline(x=p_c_prime, color='black', linestyle=':', alpha=0.8, linewidth=3, label=f"p_c' = {p_c_prime}")
    
    # Add transition regions
    ax2.axvspan(p_c_prime - 0.05, p_c_prime + 0.05, alpha=0.2, color='orange', label='Critical Region')
    
    ax2.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax2.set_ylabel('Phase Angle δ (degrees)', fontsize=12)
    ax2.legend(fontsize=10, loc='upper right')
    ax2.grid(True, alpha=0.3)
    ax2.set_ylim(-5, 95)
    
    # Add regime labels
    add_regime_labels(ax1, p_c_prime)
    add_regime_labels(ax2, p_c_prime)
    
    plt.tight_layout()
    plt.savefig('alpha_delta_vs_p_comprehensive.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    return fig

def add_regime_labels(ax, p_c_prime):
    """Add regime labels to the plot"""
    
    # Liquid regime label
    ax.text(0.5 * (p_c_prime - 0.05), 0.8, 'LIQUID\nα ≈ 1.0\nδ ≈ 90°', 
            ha='center', va='center', fontsize=10, fontweight='bold',
            bbox=dict(boxstyle="round,pad=0.3", facecolor="lightblue", alpha=0.8))
    
    # Critical regime label
    ax.text(p_c_prime, 0.5, 'CRITICAL\nα ≈ 0.5\nδ ≈ 45°', 
            ha='center', va='center', fontsize=10, fontweight='bold',
            bbox=dict(boxstyle="round,pad=0.3", facecolor="lightyellow", alpha=0.8))
    
    # Solid regime label
    ax.text(0.5 * (p_c_prime + 0.05 + 0.1), 0.1, 'SOLID\nα ≈ 0.0\nδ ≈ 0°', 
            ha='center', va='center', fontsize=10, fontweight='bold',
            bbox=dict(boxstyle="round,pad=0.3", facecolor="lightcoral", alpha=0.8))

def create_combined_plot(df):
    """Create a single combined plot with both α and δ on the same axes"""
    
    fig, ax1 = plt.subplots(1, 1, figsize=(12, 8))
    
    # Create primary y-axis for α
    ax1.set_xlabel('Percolation Probability (p)', fontsize=14, fontweight='bold')
    ax1.set_ylabel('Growth Exponent (α)', fontsize=14, fontweight='bold', color='blue')
    
    # Plot α vs p
    colors = {'liquid': 'blue', 'critical': 'orange', 'solid': 'red'}
    markers = {'liquid': 'o', 'critical': 's', 'solid': '^'}
    
    for strategy in ['liquid', 'critical', 'solid']:
        mask = df['strategy'] == strategy
        if np.any(mask):
            p_vals = df.loc[mask, 'p']
            alphas = df.loc[mask, 'alpha_opt']
            ax1.plot(p_vals, alphas, marker=markers[strategy], color=colors[strategy], 
                    linestyle='-', linewidth=3, markersize=10, label=f'{strategy.title()} (α)')
    
    # Add theoretical lines for α
    p_c_prime = 0.6884
    ax1.axhline(y=1.0, color='blue', linestyle='--', alpha=0.7, linewidth=2, label='α = 1.0 (liquid)')
    ax1.axhline(y=0.5, color='orange', linestyle='--', alpha=0.7, linewidth=2, label='α = 0.5 (critical)')
    ax1.axhline(y=0.0, color='red', linestyle='--', alpha=0.7, linewidth=2, label='α = 0.0 (solid)')
    ax1.axvline(x=p_c_prime, color='black', linestyle=':', alpha=0.8, linewidth=3, label=f"p_c' = {p_c_prime}")
    
    # Add transition regions
    ax1.axvspan(p_c_prime - 0.05, p_c_prime + 0.05, alpha=0.2, color='orange', label='Critical Region')
    
    # Set primary y-axis properties
    ax1.tick_params(axis='y', labelcolor='blue')
    ax1.set_ylim(-0.1, 1.1)
    ax1.grid(True, alpha=0.3)
    
    # Create secondary y-axis for δ
    ax2 = ax1.twinx()
    ax2.set_ylabel('Phase Angle δ (degrees)', fontsize=14, fontweight='bold', color='red')
    
    # Plot δ vs p on secondary axis
    for strategy in ['liquid', 'critical', 'solid']:
        mask = df['strategy'] == strategy
        if np.any(mask):
            p_vals = df.loc[mask, 'p']
            deltas = df.loc[mask, 'delta_degrees']
            ax2.plot(p_vals, deltas, marker=markers[strategy], color=colors[strategy], 
                    linestyle='--', linewidth=2, markersize=8, alpha=0.7, label=f'{strategy.title()} (δ)')
    
    # Add theoretical lines for δ
    ax2.axhline(y=90.0, color='blue', linestyle=':', alpha=0.7, linewidth=2, label='δ = 90° (liquid)')
    ax2.axhline(y=45.0, color='orange', linestyle=':', alpha=0.7, linewidth=2, label='δ = 45° (critical)')
    ax2.axhline(y=0.0, color='red', linestyle=':', alpha=0.7, linewidth=2, label='δ = 0° (solid)')
    
    # Set secondary y-axis properties
    ax2.tick_params(axis='y', labelcolor='red')
    ax2.set_ylim(-5, 95)
    
    # Add regime labels
    add_regime_labels_combined(ax1, p_c_prime)
    
    # Combine legends
    lines1, labels1 = ax1.get_legend_handles_labels()
    lines2, labels2 = ax2.get_legend_handles_labels()
    
    # Remove duplicate labels
    unique_labels = []
    unique_lines = []
    for line, label in zip(lines1 + lines2, labels1 + labels2):
        if label not in unique_labels:
            unique_labels.append(label)
            unique_lines.append(line)
    
    ax1.legend(unique_lines, unique_labels, loc='center right', fontsize=10)
    
    plt.title('Phase Transition: α and δ vs p', fontsize=16, fontweight='bold')
    plt.tight_layout()
    plt.savefig('alpha_delta_combined.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    return fig

def add_regime_labels_combined(ax, p_c_prime):
    """Add regime labels to the combined plot"""
    
    # Liquid regime label
    ax.text(0.5 * (p_c_prime - 0.05), 0.8, 'LIQUID\nα ≈ 1.0\nδ ≈ 90°', 
            ha='center', va='center', fontsize=11, fontweight='bold',
            bbox=dict(boxstyle="round,pad=0.4", facecolor="lightblue", alpha=0.9))
    
    # Critical regime label
    ax.text(p_c_prime, 0.5, 'CRITICAL\nα ≈ 0.5\nδ ≈ 45°', 
            ha='center', va='center', fontsize=11, fontweight='bold',
            bbox=dict(boxstyle="round,pad=0.4", facecolor="lightyellow", alpha=0.9))
    
    # Solid regime label
    ax.text(0.5 * (p_c_prime + 0.05 + 0.1), 0.1, 'SOLID\nα ≈ 0.0\nδ ≈ 0°', 
            ha='center', va='center', fontsize=11, fontweight='bold',
            bbox=dict(boxstyle="round,pad=0.4", facecolor="lightcoral", alpha=0.9))

def print_summary_statistics(df):
    """Print summary statistics for α and δ"""
    
    print("=== ALPHA AND DELTA SUMMARY STATISTICS ===")
    print()
    
    # Group by strategy
    for strategy in ['liquid', 'critical', 'solid']:
        mask = df['strategy'] == strategy
        if np.any(mask):
            subset = df.loc[mask]
            
            print(f"{strategy.upper()} REGIME:")
            print(f"  Count: {len(subset)} p-values")
            print(f"  α range: {subset['alpha_opt'].min():.3f} to {subset['alpha_opt'].max():.3f}")
            print(f"  α mean: {subset['alpha_opt'].mean():.3f} ± {subset['alpha_opt'].std():.3f}")
            print(f"  δ range: {subset['delta_degrees'].min():.1f}° to {subset['delta_degrees'].max():.1f}°")
            print(f"  δ mean: {subset['delta_degrees'].mean():.1f}° ± {subset['delta_degrees'].std():.1f}°")
            print()
    
    # Overall statistics
    print("OVERALL STATISTICS:")
    print(f"  Total p-values: {len(df)}")
    print(f"  α range: {df['alpha_opt'].min():.3f} to {df['alpha_opt'].max():.3f}")
    print(f"  δ range: {df['delta_degrees'].min():.1f}° to {df['delta_degrees'].max():.1f}°")
    print(f"  Phase transition magnitude: {df['delta_degrees'].max() - df['delta_degrees'].min():.1f}°")

def main():
    """Main function to create all plots"""
    
    print("=== ALPHA AND DELTA VS P PLOTTING ===")
    print()
    
    # Load and prepare data
    df = load_and_prepare_data()
    print(f"Loaded data for {len(df)} p-values")
    print()
    
    # Create separate plots
    print("Creating separate α and δ plots...")
    fig1 = create_alpha_delta_plot(df)
    
    # Create combined plot
    print("Creating combined α and δ plot...")
    fig2 = create_combined_plot(df)
    
    # Print summary statistics
    print_summary_statistics(df)
    
    print("\nPlots saved:")
    print("- alpha_delta_vs_p_comprehensive.png (separate plots)")
    print("- alpha_delta_combined.png (combined plot)")

if __name__ == "__main__":
    main()
