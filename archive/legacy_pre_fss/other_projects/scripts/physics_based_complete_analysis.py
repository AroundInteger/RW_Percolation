#!/usr/bin/env python3
"""
Complete Physics-Based Analysis for Both Datasets
Apply the physics-based analyzer to both datasets and compare with geometric classification
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os
from pathlib import Path
from physics_based_alpha_analyzer import PhysicsBasedAlphaAnalyzer

def analyze_dataset_physics_based(dataset_name, dataset_path, output_dir):
    """
    Analyze a dataset using physics-based classification
    
    Parameters:
    - dataset_name: Name for identification (e.g., "Original", "New")
    - dataset_path: Path to the CSV file
    - output_dir: Directory to save outputs
    """
    
    print(f"\n=== ANALYZING {dataset_name.upper()} DATASET (PHYSICS-BASED) ===")
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    # Load dataset
    print(f"Loading dataset from {dataset_path}...")
    df = pd.read_csv(dataset_path)
    print(f"Loaded {len(df)} rows and {len(df.columns)} columns")
    
    # Extract p-values
    p_values = []
    for col in df.columns:
        if col.startswith('MSD_'):
            try:
                p_val = float(col.replace('MSD_', ''))
                p_values.append(p_val)
            except ValueError:
                print(f"Warning: Could not parse p-value from column {col}")
    
    p_values.sort()
    print(f"Found {len(p_values)} p-values: {[f'{p:.4f}' for p in p_values[:5]]}...{[f'{p:.4f}' for p in p_values[-5:]]}")
    
    # Initialize physics-based analyzer
    analyzer = PhysicsBasedAlphaAnalyzer()
    
    # Analyze all p-values
    results = []
    print(f"\nAnalyzing {len(p_values)} p-values...")
    
    for i, p in enumerate(p_values):
        print(f"  Progress: {i+1}/{len(p_values)} - p = {p:.4f}")
        
        result = analyzer.analyze_single_p_value(df, p, plot=False)
        if result:
            results.append({
                'p': p,
                'strategy': result['strategy'],
                'alpha_opt': result['alpha_opt'],
                'alpha_std': result['alpha_std'],
                'r_squared': result['r_squared'],
                'confidence': result['confidence'],
                'tau_cr': result['tau_cr'],
                'classification_method': result['classification_method'],
                'physics_score': result['physics_score'],
                'geometric_score': result['geometric_score'],
                'description': result['description']
            })
        else:
            print(f"    Warning: Analysis failed for p = {p:.4f}")
    
    # Create results DataFrame
    results_df = pd.DataFrame(results)
    
    # Save results
    results_file = os.path.join(output_dir, 'physics_based_analysis_results.csv')
    results_df.to_csv(results_file, index=False)
    print(f"\nSaved physics-based analysis results to: {results_file}")
    
    # Print summary statistics
    print_analysis_summary(results_df, dataset_name)
    
    # Create plots
    create_physics_based_plots(results_df, dataset_name, output_dir)
    
    return results_df

def print_analysis_summary(df, dataset_name):
    """Print summary statistics for the analysis"""
    
    print(f"\n=== {dataset_name.upper()} DATASET SUMMARY ===")
    
    # Classification method breakdown
    method_counts = df['classification_method'].value_counts()
    print(f"Classification Methods:")
    for method, count in method_counts.items():
        print(f"  {method}: {count} p-values ({count/len(df)*100:.1f}%)")
    
    # Strategy breakdown
    strategy_counts = df['strategy'].value_counts()
    print(f"\nRegime Classification:")
    for strategy, count in strategy_counts.items():
        print(f"  {strategy}: {count} p-values ({count/len(df)*100:.1f}%)")
    
    # Physics-based vs geometric
    physics_based = df[df['classification_method'] == 'physics_based']
    geometric_fallback = df[df['classification_method'] == 'geometric_fallback']
    
    print(f"\nPhysics-Based Classifications: {len(physics_based)}")
    if len(physics_based) > 0:
        print(f"  Mean α: {physics_based['alpha_opt'].mean():.4f}")
        print(f"  Mean R²: {physics_based['r_squared'].mean():.4f}")
        print(f"  Mean confidence: {physics_based['confidence'].mean():.4f}")
    
    print(f"\nGeometric Fallback Classifications: {len(geometric_fallback)}")
    if len(geometric_fallback) > 0:
        print(f"  Mean α: {geometric_fallback['alpha_opt'].mean():.4f}")
        print(f"  Mean R²: {geometric_fallback['r_squared'].mean():.4f}")
        print(f"  Mean confidence: {geometric_fallback['confidence'].mean():.4f}")
    
    # Quality metrics
    print(f"\nOverall Quality Metrics:")
    print(f"  Mean α: {df['alpha_opt'].mean():.4f} ± {df['alpha_opt'].std():.4f}")
    print(f"  Mean R²: {df['r_squared'].mean():.4f} ± {df['r_squared'].std():.4f}")
    print(f"  Mean confidence: {df['confidence'].mean():.4f} ± {df['confidence'].std():.4f}")

def create_physics_based_plots(df, dataset_name, output_dir):
    """Create comprehensive plots for physics-based analysis"""
    
    print(f"\nCreating plots for {dataset_name} dataset...")
    
    # Create comprehensive plot
    fig, axes = plt.subplots(2, 3, figsize=(20, 12))
    
    p_values = df['p'].values
    alpha_values = df['alpha_opt'].values
    
    # Plot 1: α vs p with classification method colors
    ax1 = axes[0, 0]
    physics_mask = df['classification_method'] == 'physics_based'
    geometric_mask = df['classification_method'] == 'geometric_fallback'
    
    if physics_mask.any():
        ax1.scatter(df[physics_mask]['p'], df[physics_mask]['alpha_opt'], 
                   s=100, alpha=0.8, color='green', label='Physics-based', marker='o')
    if geometric_mask.any():
        ax1.scatter(df[geometric_mask]['p'], df[geometric_mask]['alpha_opt'], 
                   s=100, alpha=0.8, color='red', label='Geometric fallback', marker='s')
    
    ax1.axhline(y=1.0, color='blue', linestyle='--', alpha=0.7, label='α = 1.0 (liquid)')
    ax1.axhline(y=0.5, color='orange', linestyle='--', alpha=0.7, label='α = 0.5 (critical)')
    ax1.axhline(y=0.0, color='red', linestyle='--', alpha=0.7, label='α = 0.0 (solid)')
    ax1.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2, label="p_c' = 0.6884")
    ax1.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax1.set_ylabel('Growth Exponent (α)', fontsize=12)
    ax1.set_title(f'{dataset_name} Dataset - Physics-Based α vs p', fontsize=14, fontweight='bold')
    ax1.legend(fontsize=10)
    ax1.grid(True, alpha=0.3)
    ax1.set_ylim(-0.1, 1.1)
    
    # Plot 2: Confidence scores
    ax2 = axes[0, 1]
    confidence_values = df['confidence'].values
    colors = ['green' if method == 'physics_based' else 'red' for method in df['classification_method']]
    ax2.scatter(p_values, confidence_values, s=100, alpha=0.7, c=colors)
    ax2.axhline(y=0.7, color='black', linestyle='--', alpha=0.7, label='Confidence threshold')
    ax2.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2, label="p_c' = 0.6884")
    ax2.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax2.set_ylabel('Confidence Score', fontsize=12)
    ax2.set_title('Classification Confidence', fontsize=14, fontweight='bold')
    ax2.legend(fontsize=10)
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: R² quality
    ax3 = axes[0, 2]
    r_squared_values = df['r_squared'].values
    ax3.scatter(p_values, r_squared_values, s=100, alpha=0.7, c=colors)
    ax3.axhline(y=0.8, color='black', linestyle='--', alpha=0.7, label='R² threshold')
    ax3.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2, label="p_c' = 0.6884")
    ax3.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax3.set_ylabel('R² (Fit Quality)', fontsize=12)
    ax3.set_title('Fit Quality vs p', fontsize=14, fontweight='bold')
    ax3.legend(fontsize=10)
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: Strategy breakdown
    ax4 = axes[1, 0]
    for strategy in ['liquid', 'critical', 'solid']:
        mask = df['strategy'] == strategy
        if mask.any():
            physics_in_strategy = df[mask & physics_mask]
            geometric_in_strategy = df[mask & geometric_mask]
            
            if len(physics_in_strategy) > 0:
                ax4.scatter(physics_in_strategy['p'], physics_in_strategy['alpha_opt'], 
                           s=100, alpha=0.8, color='green', marker='o')
            if len(geometric_in_strategy) > 0:
                ax4.scatter(geometric_in_strategy['p'], geometric_in_strategy['alpha_opt'], 
                           s=100, alpha=0.8, color='red', marker='s')
    
    ax4.axhline(y=1.0, color='blue', linestyle='--', alpha=0.7)
    ax4.axhline(y=0.5, color='orange', linestyle='--', alpha=0.7)
    ax4.axhline(y=0.0, color='red', linestyle='--', alpha=0.7)
    ax4.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2)
    ax4.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax4.set_ylabel('Growth Exponent (α)', fontsize=12)
    ax4.set_title('Regime Classification', fontsize=14, fontweight='bold')
    ax4.grid(True, alpha=0.3)
    ax4.set_ylim(-0.1, 1.1)
    
    # Plot 5: α standard deviation (consistency)
    ax5 = axes[1, 1]
    alpha_std_values = df['alpha_std'].values
    ax5.scatter(p_values, alpha_std_values, s=100, alpha=0.7, c=colors)
    ax5.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2, label="p_c' = 0.6884")
    ax5.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax5.set_ylabel('α Standard Deviation', fontsize=12)
    ax5.set_title('α Consistency Across Windows', fontsize=14, fontweight='bold')
    ax5.legend(fontsize=10)
    ax5.grid(True, alpha=0.3)
    
    # Plot 6: Method distribution pie chart
    ax6 = axes[1, 2]
    method_counts = df['classification_method'].value_counts()
    colors_pie = ['green' if 'physics' in method else 'red' for method in method_counts.index]
    ax6.pie(method_counts.values, labels=method_counts.index, autopct='%1.1f%%', 
            colors=colors_pie, startangle=90)
    ax6.set_title('Classification Method Distribution', fontsize=14, fontweight='bold')
    
    plt.tight_layout()
    plot_file = os.path.join(output_dir, f'{dataset_name.lower()}_physics_based_analysis.png')
    plt.savefig(plot_file, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"Saved comprehensive plot to: {plot_file}")

def compare_geometric_vs_physics(original_results, new_results, output_dir):
    """Compare geometric vs physics-based classifications"""
    
    print("\n=== COMPARING GEOMETRIC VS PHYSICS-BASED CLASSIFICATIONS ===")
    
    # Load previous geometric results
    geometric_orig = pd.read_csv("output_original_dataset/corrected_alpha_analysis_results.csv")
    geometric_new = pd.read_csv("output_new_dataset/corrected_alpha_analysis_results.csv")
    
    # Create comparison plots
    fig, axes = plt.subplots(2, 2, figsize=(20, 12))
    
    # Plot 1: Original dataset comparison
    ax1 = axes[0, 0]
    ax1.scatter(geometric_orig['p'], geometric_orig['alpha_opt'], 
               s=100, alpha=0.7, color='blue', label='Geometric', marker='s')
    ax1.scatter(original_results['p'], original_results['alpha_opt'], 
               s=100, alpha=0.7, color='red', label='Physics-based', marker='o')
    ax1.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2, label="p_c' = 0.6884")
    ax1.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax1.set_ylabel('Growth Exponent (α)', fontsize=12)
    ax1.set_title('Original Dataset: Geometric vs Physics-Based', fontsize=14, fontweight='bold')
    ax1.legend(fontsize=10)
    ax1.grid(True, alpha=0.3)
    ax1.set_ylim(-0.1, 1.1)
    
    # Plot 2: New dataset comparison
    ax2 = axes[0, 1]
    ax2.scatter(geometric_new['p'], geometric_new['alpha_opt'], 
               s=100, alpha=0.7, color='blue', label='Geometric', marker='s')
    ax2.scatter(new_results['p'], new_results['alpha_opt'], 
               s=100, alpha=0.7, color='red', label='Physics-based', marker='o')
    ax2.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2, label="p_c' = 0.6884")
    ax2.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax2.set_ylabel('Growth Exponent (α)', fontsize=12)
    ax2.set_title('New Dataset: Geometric vs Physics-Based', fontsize=14, fontweight='bold')
    ax2.legend(fontsize=10)
    ax2.grid(True, alpha=0.3)
    ax2.set_ylim(-0.1, 1.1)
    
    # Plot 3: Classification changes (original)
    ax3 = axes[1, 0]
    # Find p-values that changed classification
    merged_orig = pd.merge(geometric_orig[['p', 'strategy']], 
                          original_results[['p', 'strategy']], 
                          on='p', suffixes=('_geo', '_phys'))
    changed_orig = merged_orig[merged_orig['strategy_geo'] != merged_orig['strategy_phys']]
    
    if len(changed_orig) > 0:
        ax3.scatter(changed_orig['p'], [1]*len(changed_orig), 
                   s=150, alpha=0.8, color='orange', marker='*', label='Changed classifications')
    ax3.scatter(geometric_orig['p'], [0]*len(geometric_orig), 
               s=50, alpha=0.5, color='blue', label='Geometric')
    ax3.scatter(original_results['p'], [2]*len(original_results), 
               s=50, alpha=0.5, color='red', label='Physics-based')
    ax3.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2, label="p_c' = 0.6884")
    ax3.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax3.set_ylabel('Method', fontsize=12)
    ax3.set_title(f'Original: {len(changed_orig)} Classifications Changed', fontsize=14, fontweight='bold')
    ax3.set_yticks([0, 1, 2])
    ax3.set_yticklabels(['Geometric', 'Changed', 'Physics'])
    ax3.legend(fontsize=10)
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: Classification changes (new)
    ax4 = axes[1, 1]
    merged_new = pd.merge(geometric_new[['p', 'strategy']], 
                         new_results[['p', 'strategy']], 
                         on='p', suffixes=('_geo', '_phys'))
    changed_new = merged_new[merged_new['strategy_geo'] != merged_new['strategy_phys']]
    
    if len(changed_new) > 0:
        ax4.scatter(changed_new['p'], [1]*len(changed_new), 
                   s=150, alpha=0.8, color='orange', marker='*', label='Changed classifications')
    ax4.scatter(geometric_new['p'], [0]*len(geometric_new), 
               s=50, alpha=0.5, color='blue', label='Geometric')
    ax4.scatter(new_results['p'], [2]*len(new_results), 
               s=50, alpha=0.5, color='red', label='Physics-based')
    ax4.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2, label="p_c' = 0.6884")
    ax4.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax4.set_ylabel('Method', fontsize=12)
    ax4.set_title(f'New: {len(changed_new)} Classifications Changed', fontsize=14, fontweight='bold')
    ax4.set_yticks([0, 1, 2])
    ax4.set_yticklabels(['Geometric', 'Changed', 'Physics'])
    ax4.legend(fontsize=10)
    ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    comparison_file = os.path.join(output_dir, 'geometric_vs_physics_comparison.png')
    plt.savefig(comparison_file, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"Saved comparison plot to: {comparison_file}")
    
    # Print detailed comparison results
    print(f"\nORIGINAL DATASET CHANGES:")
    if len(changed_orig) > 0:
        for _, row in changed_orig.iterrows():
            print(f"  p = {row['p']:.4f}: {row['strategy_geo']} → {row['strategy_phys']}")
    else:
        print("  No classification changes")
    
    print(f"\nNEW DATASET CHANGES:")
    if len(changed_new) > 0:
        for _, row in changed_new.iterrows():
            print(f"  p = {row['p']:.4f}: {row['strategy_geo']} → {row['strategy_phys']}")
    else:
        print("  No classification changes")

def main():
    """Main function to run complete physics-based analysis"""
    
    print("🚀 COMPLETE PHYSICS-BASED ANALYSIS PIPELINE")
    print("=" * 60)
    
    # Create main output directory
    output_base = "output_physics_based"
    os.makedirs(output_base, exist_ok=True)
    
    # Analyze both datasets
    print("Analyzing both datasets with physics-based classification...")
    
    # Original dataset
    original_results = analyze_dataset_physics_based(
        "Original", 
        "matlab/Clusters/p_output_C1.csv", 
        os.path.join(output_base, "original")
    )
    
    # New dataset
    new_results = analyze_dataset_physics_based(
        "New", 
        "matlab/p_output_NEW34.csv", 
        os.path.join(output_base, "new")
    )
    
    # Compare with geometric classification
    compare_geometric_vs_physics(original_results, new_results, output_base)
    
    print(f"\n🎉 PHYSICS-BASED ANALYSIS COMPLETE!")
    print(f"📁 All outputs saved to: {output_base}/")
    print(f"📊 Key improvements:")
    print(f"   • Physics-based classification prioritizes α behavior")
    print(f"   • Multi-window analysis for robust α determination") 
    print(f"   • Confidence scoring for classification reliability")
    print(f"   • Automatic correction of boundary misclassifications")

if __name__ == "__main__":
    main()
