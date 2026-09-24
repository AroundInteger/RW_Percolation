#!/usr/bin/env python3
"""
Comprehensive Analysis of Random Walk Percolation Results
Analyzes the extensive dataset from Clusters1 with 99 p-values and 4 variants
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats
from scipy.optimize import curve_fit
import os

def load_data():
    """Load the comprehensive dataset"""
    print("Loading comprehensive dataset...")
    
    # Load MSD data
    msd_file = "/Users/iMacPro/Documents/GitHub/RW_Percolation/matlab/Clusters1/random_walk_analysis_L500_LW1000000_NW3000.csv"
    msd_data = pd.read_csv(msd_file)
    
    # Load viscoelastic analysis data
    visco_file = "/Users/iMacPro/Documents/GitHub/RW_Percolation/matlab/Clusters1/viscoelastic_analysis_L500_p0.00_to_p0.99.csv"
    visco_data = pd.read_csv(visco_file)
    
    print(f"MSD data shape: {msd_data.shape}")
    print(f"Viscoelastic data shape: {visco_data.shape}")
    
    return msd_data, visco_data

def get_variant_names():
    """Map variant numbers to names"""
    variant_map = {
        1: "Random_Percolation",
        2: "6N_Templated", 
        3: "26N_Templated",
        4: "Density_Increment"
    }
    return variant_map

def calculate_alpha_exponents(msd_data):
    """Calculate alpha exponents from MSD slopes"""
    print("Calculating alpha exponents...")
    
    variant_map = get_variant_names()
    results = []
    
    # Get unique p_values and variants
    p_values = sorted(msd_data['p_value'].unique())
    variants = sorted(msd_data['variant'].unique())
    
    for p_val in p_values:
        for variant in variants:
            # Filter data for this p_value and variant
            subset = msd_data[(msd_data['p_value'] == p_val) & 
                            (msd_data['variant'] == variant)].copy()
            
            if len(subset) < 10:  # Need sufficient data points
                continue
                
            # Sort by time_step
            subset = subset.sort_values('time_step')
            
            # Remove zero MSD values for log fitting
            subset = subset[subset['msd'] > 0]
            
            if len(subset) < 5:
                continue
            
            # Calculate alpha from log-log fit
            log_time = np.log(subset['time_step'].values)
            log_msd = np.log(subset['msd'].values)
            
            try:
                # Robust linear fit
                slope, intercept, r_value, p_value, std_err = stats.linregress(log_time, log_msd)
                
                results.append({
                    'p_value': p_val,
                    'variant': variant,
                    'variant_name': variant_map[variant],
                    'alpha': slope,
                    'r_squared': r_value**2,
                    'std_error': std_err,
                    'num_points': len(subset),
                    'time_range': (subset['time_step'].min(), subset['time_step'].max())
                })
            except:
                continue
    
    return pd.DataFrame(results)

def analyze_critical_regions(alpha_results):
    """Analyze behavior in critical regions"""
    print("Analyzing critical regions...")
    
    # Define critical regions
    p_c = 0.3116
    p_c_prime = 0.6884
    
    critical_analysis = {}
    
    for variant_name in alpha_results['variant_name'].unique():
        variant_data = alpha_results[alpha_results['variant_name'] == variant_name]
        
        # Below p_c
        below_pc = variant_data[variant_data['p_value'] < p_c]
        # Between p_c and p_c'
        between_critical = variant_data[(variant_data['p_value'] >= p_c) & 
                                      (variant_data['p_value'] < p_c_prime)]
        # Above p_c'
        above_pc_prime = variant_data[variant_data['p_value'] >= p_c_prime]
        
        critical_analysis[variant_name] = {
            'below_pc': {
                'mean_alpha': below_pc['alpha'].mean() if len(below_pc) > 0 else np.nan,
                'std_alpha': below_pc['alpha'].std() if len(below_pc) > 0 else np.nan,
                'count': len(below_pc)
            },
            'between_critical': {
                'mean_alpha': between_critical['alpha'].mean() if len(between_critical) > 0 else np.nan,
                'std_alpha': between_critical['alpha'].std() if len(between_critical) > 0 else np.nan,
                'count': len(between_critical)
            },
            'above_pc_prime': {
                'mean_alpha': above_pc_prime['alpha'].mean() if len(above_pc_prime) > 0 else np.nan,
                'std_alpha': above_pc_prime['alpha'].std() if len(above_pc_prime) > 0 else np.nan,
                'count': len(above_pc_prime)
            }
        }
    
    return critical_analysis

def create_comprehensive_plots(alpha_results, visco_data):
    """Create comprehensive analysis plots"""
    print("Creating comprehensive plots...")
    
    # Set up the plotting style
    plt.style.use('default')
    sns.set_palette("husl")
    
    # Create figure with subplots
    fig, axes = plt.subplots(2, 2, figsize=(15, 12))
    fig.suptitle('Comprehensive Random Walk Percolation Analysis\nL=500, LW=1M, NW=3000', fontsize=16)
    
    # Plot 1: Alpha vs p_value for all variants
    ax1 = axes[0, 0]
    for variant_name in alpha_results['variant_name'].unique():
        variant_data = alpha_results[alpha_results['variant_name'] == variant_name]
        ax1.plot(variant_data['p_value'], variant_data['alpha'], 'o-', 
                label=variant_name, markersize=4, linewidth=2)
    
    ax1.axvline(x=0.3116, color='red', linestyle='--', alpha=0.7, label='p_c = 0.3116')
    ax1.axvline(x=0.6884, color='orange', linestyle='--', alpha=0.7, label="p_c' = 0.6884")
    ax1.axhline(y=1.0, color='black', linestyle=':', alpha=0.5, label='Normal diffusion')
    ax1.set_xlabel('Percolation Probability (p)')
    ax1.set_ylabel('MSD Exponent (α)')
    ax1.set_title('MSD Growth Exponent vs Percolation Probability')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: R-squared quality vs p_value
    ax2 = axes[0, 1]
    for variant_name in alpha_results['variant_name'].unique():
        variant_data = alpha_results[alpha_results['variant_name'] == variant_name]
        ax2.plot(variant_data['p_value'], variant_data['r_squared'], 'o-', 
                label=variant_name, markersize=4, linewidth=2)
    
    ax2.axvline(x=0.3116, color='red', linestyle='--', alpha=0.7)
    ax2.axvline(x=0.6884, color='orange', linestyle='--', alpha=0.7)
    ax2.axhline(y=0.95, color='green', linestyle=':', alpha=0.5, label='High quality threshold')
    ax2.set_xlabel('Percolation Probability (p)')
    ax2.set_ylabel('R² (Fit Quality)')
    ax2.set_title('MSD Fit Quality vs Percolation Probability')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: Phase transition visualization
    ax3 = axes[1, 0]
    p_values = sorted(alpha_results['p_value'].unique())
    
    for variant_name in alpha_results['variant_name'].unique():
        variant_data = alpha_results[alpha_results['variant_name'] == variant_name]
        # Calculate phase angle delta = π*α/2
        delta = np.pi * variant_data['alpha'] / 2
        ax3.plot(variant_data['p_value'], delta, 'o-', 
                label=variant_name, markersize=4, linewidth=2)
    
    ax3.axvline(x=0.3116, color='red', linestyle='--', alpha=0.7)
    ax3.axvline(x=0.6884, color='orange', linestyle='--', alpha=0.7)
    ax3.axhline(y=np.pi/2, color='black', linestyle=':', alpha=0.5, label='Elastic limit')
    ax3.set_xlabel('Percolation Probability (p)')
    ax3.set_ylabel('Phase Angle δ (radians)')
    ax3.set_title('Viscoelastic Phase Angle vs Percolation Probability')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: Universality class comparison
    ax4 = axes[1, 1]
    
    # Compare Random vs Templated variants
    random_data = alpha_results[alpha_results['variant_name'] == 'Random_Percolation']
    templated_6n = alpha_results[alpha_results['variant_name'] == '6N_Templated']
    templated_26n = alpha_results[alpha_results['variant_name'] == '26N_Templated']
    
    if len(random_data) > 0:
        ax4.plot(random_data['p_value'], random_data['alpha'], 'o-', 
                label='Random Percolation', markersize=4, linewidth=2, color='blue')
    
    if len(templated_6n) > 0:
        ax4.plot(templated_6n['p_value'], templated_6n['alpha'], 's-', 
                label='6N Templated', markersize=4, linewidth=2, color='red')
    
    if len(templated_26n) > 0:
        ax4.plot(templated_26n['p_value'], templated_26n['alpha'], '^-', 
                label='26N Templated', markersize=4, linewidth=2, color='green')
    
    ax4.axvline(x=0.3116, color='red', linestyle='--', alpha=0.7)
    ax4.axvline(x=0.6884, color='orange', linestyle='--', alpha=0.7)
    ax4.axhline(y=1.0, color='black', linestyle=':', alpha=0.5)
    ax4.set_xlabel('Percolation Probability (p)')
    ax4.set_ylabel('MSD Exponent (α)')
    ax4.set_title('Universality Class Comparison')
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    # Save the plot
    output_file = "/Users/iMacPro/Documents/GitHub/RW_Percolation/comprehensive_analysis_results.png"
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"Comprehensive analysis plot saved to: {output_file}")
    
    return fig

def generate_summary_report(alpha_results, critical_analysis, visco_data):
    """Generate a comprehensive summary report"""
    print("Generating summary report...")
    
    report = []
    report.append("=" * 80)
    report.append("COMPREHENSIVE RANDOM WALK PERCOLATION ANALYSIS REPORT")
    report.append("=" * 80)
    report.append(f"Dataset: L=500, LW=1M, NW=3000")
    report.append(f"P-values: {len(alpha_results['p_value'].unique())} values from 0.00 to 0.99")
    report.append(f"Variants: {len(alpha_results['variant_name'].unique())} lattice types")
    report.append(f"Total analyses: {len(alpha_results)}")
    report.append("")
    
    # Critical region analysis
    report.append("CRITICAL REGION ANALYSIS")
    report.append("-" * 40)
    report.append(f"p_c (percolation threshold) = 0.3116")
    report.append(f"p_c' (apparent gel point) = 0.6884")
    report.append("")
    
    for variant_name, analysis in critical_analysis.items():
        report.append(f"{variant_name}:")
        report.append(f"  Below p_c: α = {analysis['below_pc']['mean_alpha']:.3f} ± {analysis['below_pc']['std_alpha']:.3f} (n={analysis['below_pc']['count']})")
        report.append(f"  Between p_c and p_c': α = {analysis['between_critical']['mean_alpha']:.3f} ± {analysis['between_critical']['std_alpha']:.3f} (n={analysis['between_critical']['count']})")
        report.append(f"  Above p_c': α = {analysis['above_pc_prime']['mean_alpha']:.3f} ± {analysis['above_pc_prime']['std_alpha']:.3f} (n={analysis['above_pc_prime']['count']})")
        report.append("")
    
    # Quality assessment
    report.append("FIT QUALITY ASSESSMENT")
    report.append("-" * 40)
    high_quality = alpha_results[alpha_results['r_squared'] > 0.95]
    medium_quality = alpha_results[(alpha_results['r_squared'] > 0.90) & (alpha_results['r_squared'] <= 0.95)]
    low_quality = alpha_results[alpha_results['r_squared'] <= 0.90]
    
    report.append(f"High quality fits (R² > 0.95): {len(high_quality)} ({len(high_quality)/len(alpha_results)*100:.1f}%)")
    report.append(f"Medium quality fits (0.90 < R² ≤ 0.95): {len(medium_quality)} ({len(medium_quality)/len(alpha_results)*100:.1f}%)")
    report.append(f"Low quality fits (R² ≤ 0.90): {len(low_quality)} ({len(low_quality)/len(alpha_results)*100:.1f}%)")
    report.append("")
    
    # Universality class findings
    report.append("UNIVERSALITY CLASS FINDINGS")
    report.append("-" * 40)
    
    # Compare Random vs Templated at key points
    key_p_values = [0.1, 0.3116, 0.6884, 0.8]
    
    for p_val in key_p_values:
        report.append(f"At p = {p_val}:")
        p_data = alpha_results[alpha_results['p_value'] == p_val]
        
        for variant_name in p_data['variant_name'].unique():
            variant_p_data = p_data[p_data['variant_name'] == variant_name]
            if len(variant_p_data) > 0:
                alpha_val = variant_p_data['alpha'].iloc[0]
                r2_val = variant_p_data['r_squared'].iloc[0]
                report.append(f"  {variant_name}: α = {alpha_val:.3f} (R² = {r2_val:.3f})")
        report.append("")
    
    # Key insights
    report.append("KEY INSIGHTS")
    report.append("-" * 40)
    
    # Find maximum alpha differences
    random_data = alpha_results[alpha_results['variant_name'] == 'Random_Percolation']
    templated_6n = alpha_results[alpha_results['variant_name'] == '6N_Templated']
    templated_26n = alpha_results[alpha_results['variant_name'] == '26N_Templated']
    
    if len(random_data) > 0 and len(templated_6n) > 0:
        # Find common p_values
        common_p = set(random_data['p_value']) & set(templated_6n['p_value'])
        if common_p:
            max_diff_6n = 0
            max_diff_p_6n = 0
            for p in common_p:
                alpha_random = random_data[random_data['p_value'] == p]['alpha'].iloc[0]
                alpha_6n = templated_6n[templated_6n['p_value'] == p]['alpha'].iloc[0]
                diff = abs(alpha_6n - alpha_random)
                if diff > max_diff_6n:
                    max_diff_6n = diff
                    max_diff_p_6n = p
            
            report.append(f"Maximum α difference (Random vs 6N Templated): {max_diff_6n:.3f} at p = {max_diff_p_6n}")
    
    if len(random_data) > 0 and len(templated_26n) > 0:
        common_p = set(random_data['p_value']) & set(templated_26n['p_value'])
        if common_p:
            max_diff_26n = 0
            max_diff_p_26n = 0
            for p in common_p:
                alpha_random = random_data[random_data['p_value'] == p]['alpha'].iloc[0]
                alpha_26n = templated_26n[templated_26n['p_value'] == p]['alpha'].iloc[0]
                diff = abs(alpha_26n - alpha_random)
                if diff > max_diff_26n:
                    max_diff_26n = diff
                    max_diff_p_26n = p
            
            report.append(f"Maximum α difference (Random vs 26N Templated): {max_diff_26n:.3f} at p = {max_diff_p_26n}")
    
    report.append("")
    report.append("=" * 80)
    
    return "\n".join(report)

def main():
    """Main analysis function"""
    print("Starting comprehensive analysis of Random Walk Percolation results...")
    
    # Load data
    msd_data, visco_data = load_data()
    
    # Calculate alpha exponents
    alpha_results = calculate_alpha_exponents(msd_data)
    
    # Analyze critical regions
    critical_analysis = analyze_critical_regions(alpha_results)
    
    # Create plots
    fig = create_comprehensive_plots(alpha_results, visco_data)
    
    # Generate summary report
    report = generate_summary_report(alpha_results, critical_analysis, visco_data)
    
    # Save results
    output_dir = "/Users/iMacPro/Documents/GitHub/RW_Percolation"
    
    # Save alpha results
    alpha_file = os.path.join(output_dir, "comprehensive_alpha_results.csv")
    alpha_results.to_csv(alpha_file, index=False)
    print(f"Alpha results saved to: {alpha_file}")
    
    # Save summary report
    report_file = os.path.join(output_dir, "comprehensive_analysis_report.txt")
    with open(report_file, 'w') as f:
        f.write(report)
    print(f"Summary report saved to: {report_file}")
    
    # Print summary to console
    print("\n" + report)
    
    print("\nAnalysis complete!")
    return alpha_results, critical_analysis, report

if __name__ == "__main__":
    alpha_results, critical_analysis, report = main()
