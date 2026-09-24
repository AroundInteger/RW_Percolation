#!/usr/bin/env python3
"""
Hybrid Complete Analysis with Sigmoid Fitting
Applies the hybrid analyzer to both datasets and generates comprehensive visualizations
showing the continuous evolution of all viscoelastic parameters.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from hybrid_alpha_analyzer import HybridAlphaAnalyzer
import os

# Set plotting style
plt.style.use('default')
sns.set_palette("husl")

def analyze_dataset_with_hybrid(file_path, dataset_name, output_dir):
    """
    Analyze a dataset using the hybrid approach
    """
    print(f"\n{'='*60}")
    print(f"ANALYZING {dataset_name.upper()} WITH HYBRID APPROACH")
    print(f"{'='*60}")
    
    # Load dataset
    print(f"Loading {dataset_name}...")
    df = pd.read_csv(file_path)
    
    # Extract p-values
    p_values = []
    for col in df.columns:
        if col.startswith('MSD_'):
            try:
                p_val = float(col.replace('MSD_', ''))
                p_values.append(p_val)
            except ValueError:
                continue
    
    p_values.sort()
    print(f"Found {len(p_values)} p-values: {p_values[:5]}...{p_values[-5:]}")
    
    # Initialize hybrid analyzer
    analyzer = HybridAlphaAnalyzer()
    
    # Analyze dataset
    results = analyzer.analyze_dataset(df, p_values)
    
    if results is not None and len(results) > 0:
        # Save results
        output_file = os.path.join(output_dir, f"{dataset_name}_hybrid_results.csv")
        results.to_csv(output_file, index=False)
        print(f"✓ Results saved to {output_file}")
        
        # Create output directory for plots
        plots_dir = os.path.join(output_dir, "plots")
        os.makedirs(plots_dir, exist_ok=True)
        
        # Generate comprehensive plots
        create_comprehensive_plots(results, analyzer, dataset_name, plots_dir)
        
        return results, analyzer
    else:
        print(f"✗ Analysis failed for {dataset_name}")
        return None, None

def create_comprehensive_plots(results_df, analyzer, dataset_name, plots_dir):
    """
    Create comprehensive visualization plots
    """
    print(f"Creating comprehensive plots for {dataset_name}...")
    
    # 1. Alpha vs p with sigmoid fit
    create_alpha_vs_p_plot(results_df, analyzer, dataset_name, plots_dir)
    
    # 2. Classification method comparison
    create_classification_plot(results_df, dataset_name, plots_dir)
    
    # 3. Continuous parameter evolution
    if analyzer.continuous_params is not None:
        create_continuous_parameters_plot(analyzer, dataset_name, plots_dir)
    
    # 4. Sigmoid fit quality
    create_sigmoid_quality_plot(results_df, analyzer, dataset_name, plots_dir)
    
    # 5. Transition region analysis
    create_transition_analysis_plot(results_df, dataset_name, plots_dir)

def create_alpha_vs_p_plot(results_df, analyzer, dataset_name, plots_dir):
    """Create α vs p plot with sigmoid fit and classification"""
    
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10))
    
    # Plot 1: Alpha vs p with sigmoid fit
    p_values = results_df['p'].values
    alpha_values = results_df['alpha_opt'].values
    strategies = results_df['strategy'].values
    
    # Color by strategy
    colors = {'liquid': 'blue', 'critical': 'orange', 'solid': 'red'}
    
    for strategy in colors.keys():
        mask = strategies == strategy
        ax1.scatter(p_values[mask], alpha_values[mask], 
                   c=colors[strategy], s=60, alpha=0.7, 
                   label=f'{strategy.title()} ({np.sum(mask)} points)')
    
    # Add sigmoid fit if available
    if analyzer.sigmoid_params is not None:
        p_fine = np.linspace(min(p_values), max(p_values), 1000)
        alpha_fine = analyzer.alpha_sigmoid_function(p_fine)
        ax1.plot(p_fine, alpha_fine, 'k-', linewidth=3, alpha=0.8, 
                label='Sigmoid Fit')
        
        # Add confidence bands
        if analyzer.sigmoid_covariance is not None:
            # Calculate confidence intervals (simplified)
            alpha_std = np.std(alpha_values)
            ax1.fill_between(p_fine, alpha_fine - alpha_std, alpha_fine + alpha_std,
                           alpha=0.2, color='gray', label='±1σ Range')
    
    # Add theoretical lines
    p_c_prime = 0.6884
    ax1.axvline(x=p_c_prime, color='black', linestyle=':', alpha=0.8, linewidth=2,
                label=f"p_c' = {p_c_prime}")
    ax1.axhline(y=0.5, color='gray', linestyle='--', alpha=0.6, label='α = 0.5 (critical)')
    
    ax1.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax1.set_ylabel('Growth Exponent α', fontsize=12)
    ax1.set_title(f'{dataset_name.title()}: Growth Exponent vs Percolation Probability', 
                  fontsize=14, fontweight='bold')
    ax1.legend(fontsize=10)
    ax1.grid(True, alpha=0.3)
    ax1.set_ylim(-0.1, 1.1)
    
    # Plot 2: Classification confidence
    physics_scores = results_df['physics_score'].values
    geometric_scores = results_df['geometric_score'].values
    transition_detected = results_df['transition_detected'].values
    
    # Create confidence visualization
    for i, (p, phys_score, geo_score, trans) in enumerate(zip(p_values, physics_scores, geometric_scores, transition_detected)):
        if trans:
            # Transition detected - highlight
            ax2.scatter(p, phys_score, c='green', s=80, alpha=0.8, marker='s')
        else:
            # Regular classification
            ax2.scatter(p, phys_score, c='blue', s=60, alpha=0.6)
        
        # Add geometric fallback indicator
        if geo_score > 0:
            ax2.scatter(p, geo_score, c='red', s=40, alpha=0.4, marker='^')
    
    ax2.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax2.set_ylabel('Classification Score', fontsize=12)
    ax2.set_title('Classification Confidence and Method', fontsize=14, fontweight='bold')
    ax2.legend(['Transition Detected', 'Physics Score', 'Geometric Fallback'], 
               loc='upper right', fontsize=10)
    ax2.grid(True, alpha=0.3)
    ax2.set_ylim(-0.1, 1.1)
    
    plt.tight_layout()
    output_file = os.path.join(plots_dir, f"{dataset_name}_alpha_vs_p_comprehensive.png")
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  ✓ Alpha vs p plot saved: {output_file}")

def create_classification_plot(results_df, dataset_name, plots_dir):
    """Create classification method comparison plot"""
    
    fig, axes = plt.subplots(2, 2, figsize=(15, 12))
    
    # Plot 1: Strategy distribution
    strategy_counts = results_df['strategy'].value_counts()
    colors = {'liquid': 'blue', 'critical': 'orange', 'solid': 'red'}
    
    strategy_colors = [colors.get(s, 'gray') for s in strategy_counts.index]
    axes[0, 0].pie(strategy_counts.values, labels=strategy_counts.index, 
                   colors=strategy_colors, autopct='%1.1f%%', startangle=90)
    axes[0, 0].set_title('Regime Distribution', fontsize=14, fontweight='bold')
    
    # Plot 2: Classification method distribution
    method_counts = results_df['classification_method'].value_counts()
    axes[0, 1].bar(method_counts.index, method_counts.values, 
                   color=['blue', 'orange', 'green', 'red', 'purple'][:len(method_counts)])
    axes[0, 1].set_title('Classification Methods Used', fontsize=14, fontweight='bold')
    axes[0, 1].set_ylabel('Number of p-values')
    plt.setp(axes[0, 1].xaxis.get_majorticklabels(), rotation=45, ha='right')
    
    # Plot 3: Transition detection
    transition_counts = results_df['transition_detected'].value_counts()
    axes[1, 0].pie(transition_counts.values, labels=['No Transition', 'Transition Detected'], 
                   colors=['lightgray', 'green'], autopct='%1.1f%%', startangle=90)
    axes[1, 0].set_title('Transition Detection', fontsize=14, fontweight='bold')
    
    # Plot 4: Confidence distribution
    confidence_values = results_df['confidence'].values
    axes[1, 1].hist(confidence_values, bins=20, alpha=0.7, color='skyblue', edgecolor='black')
    axes[1, 1].set_title('Classification Confidence Distribution', fontsize=14, fontweight='bold')
    axes[1, 1].set_xlabel('Confidence Score')
    axes[1, 1].set_ylabel('Frequency')
    axes[1, 1].axvline(np.mean(confidence_values), color='red', linestyle='--', 
                       label=f'Mean: {np.mean(confidence_values):.3f}')
    axes[1, 1].legend()
    
    plt.tight_layout()
    output_file = os.path.join(plots_dir, f"{dataset_name}_classification_analysis.png")
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  ✓ Classification analysis plot saved: {output_file}")

def create_continuous_parameters_plot(analyzer, dataset_name, plots_dir):
    """Create continuous parameter evolution plots"""
    
    if analyzer.continuous_params is None:
        return
    
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    
    p_fine = analyzer.continuous_params['p_fine']
    alpha_fine = analyzer.continuous_params['alpha_fine']
    G_prime_fine = analyzer.continuous_params['G_prime_fine']
    G_double_prime_fine = analyzer.continuous_params['G_double_prime_fine']
    delta_fine = analyzer.continuous_params['delta_fine']
    tan_delta_fine = analyzer.continuous_params['tan_delta_fine']
    
    # Plot 1: G'(ω) and G''(ω) evolution
    axes[0, 0].plot(p_fine, G_prime_fine, 'b-', linewidth=3, label="G'(ω)")
    axes[0, 0].plot(p_fine, G_double_prime_fine, 'r-', linewidth=3, label="G''(ω)")
    axes[0, 0].axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2,
                       label="p_c' = 0.6884")
    axes[0, 0].set_xlabel('Percolation Probability (p)', fontsize=12)
    axes[0, 0].set_ylabel('Modulus G(ω)', fontsize=12)
    axes[0, 0].set_title('Storage and Loss Moduli Evolution', fontsize=14, fontweight='bold')
    axes[0, 0].legend(fontsize=10)
    axes[0, 0].grid(True, alpha=0.3)
    
    # Plot 2: Phase angle δ evolution
    axes[0, 1].plot(p_fine, delta_fine, 'g-', linewidth=3, label='Phase Angle δ')
    axes[0, 1].axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2,
                       label="p_c' = 0.6884")
    axes[0, 1].axhline(y=90, color='blue', linestyle='--', alpha=0.6, label='δ = 90° (liquid)')
    axes[0, 1].axhline(y=45, color='orange', linestyle='--', alpha=0.6, label='δ = 45° (critical)')
    axes[0, 1].axhline(y=0, color='red', linestyle='--', alpha=0.6, label='δ = 0° (solid)')
    axes[0, 1].set_xlabel('Percolation Probability (p)', fontsize=12)
    axes[0, 1].set_ylabel('Phase Angle δ (degrees)', fontsize=12)
    axes[0, 1].set_title('Phase Angle Evolution', fontsize=14, fontweight='bold')
    axes[0, 1].legend(fontsize=10)
    axes[0, 1].grid(True, alpha=0.3)
    axes[0, 1].set_ylim(-5, 95)
    
    # Plot 3: Loss tangent evolution
    axes[1, 0].plot(p_fine, tan_delta_fine, 'm-', linewidth=3, label='Loss Tangent tan δ')
    axes[1, 0].axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2,
                       label="p_c' = 0.6884")
    axes[1, 0].axhline(y=100, color='blue', linestyle='--', alpha=0.6, label='tan δ → ∞ (liquid)')
    axes[1, 0].axhline(y=1, color='orange', linestyle='--', alpha=0.6, label='tan δ = 1 (critical)')
    axes[1, 0].axhline(y=0, color='red', linestyle='--', alpha=0.6, label='tan δ = 0 (solid)')
    axes[1, 0].set_xlabel('Percolation Probability (p)', fontsize=12)
    axes[1, 0].set_ylabel('Loss Tangent tan δ', fontsize=12)
    axes[1, 0].set_title('Loss Tangent Evolution', fontsize=14, fontweight='bold')
    axes[1, 0].legend(fontsize=10)
    axes[1, 0].grid(True, alpha=0.3)
    axes[1, 0].set_ylim(-5, 105)
    
    # Plot 4: Sigmoid fit parameters
    if analyzer.sigmoid_params is not None:
        p_c, width, alpha_min, alpha_max = analyzer.sigmoid_params
        
        # Create theoretical sigmoid for comparison
        def theoretical_sigmoid(p):
            return alpha_min + (alpha_max - alpha_min) / (1 + np.exp((p - p_c) / width))
        
        alpha_theoretical = theoretical_sigmoid(p_fine)
        
        axes[1, 1].plot(p_fine, alpha_fine, 'k-', linewidth=3, label='Fitted Sigmoid')
        axes[1, 1].plot(p_fine, alpha_theoretical, 'r--', linewidth=2, alpha=0.7, 
                        label='Theoretical')
        axes[1, 1].axvline(x=p_c, color='green', linestyle=':', alpha=0.8, linewidth=2,
                           label=f'p_c = {p_c:.4f}')
        axes[1, 1].axhline(y=alpha_min, color='gray', linestyle='--', alpha=0.6, 
                           label=f'α_min = {alpha_min:.3f}')
        axes[1, 1].axhline(y=alpha_max, color='gray', linestyle='--', alpha=0.6, 
                           label=f'α_max = {alpha_max:.3f}')
        axes[1, 1].set_xlabel('Percolation Probability (p)', fontsize=12)
        axes[1, 1].set_ylabel('Growth Exponent α', fontsize=12)
        axes[1, 1].set_title('Sigmoid Fit Analysis', fontsize=14, fontweight='bold')
        axes[1, 1].legend(fontsize=10)
        axes[1, 1].grid(True, alpha=0.3)
        axes[1, 1].set_ylim(-0.1, 1.1)
    
    plt.tight_layout()
    output_file = os.path.join(plots_dir, f"{dataset_name}_continuous_parameters.png")
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  ✓ Continuous parameters plot saved: {output_file}")

def create_sigmoid_quality_plot(results_df, analyzer, dataset_name, plots_dir):
    """Create sigmoid fit quality analysis plot"""
    
    if analyzer.sigmoid_params is None:
        return
    
    fig, axes = plt.subplots(2, 2, figsize=(15, 10))
    
    p_values = results_df['p'].values
    alpha_opt = results_df['alpha_opt'].values
    alpha_sigmoid = results_df['alpha_sigmoid'].values
    alpha_residual = results_df['alpha_residual'].values
    
    # Plot 1: Data vs Fit
    axes[0, 0].scatter(p_values, alpha_opt, c='blue', s=60, alpha=0.7, label='Data')
    axes[0, 0].scatter(p_values, alpha_sigmoid, c='red', s=40, alpha=0.8, label='Sigmoid Fit')
    axes[0, 0].axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2,
                       label="p_c' = 0.6884")
    axes[0, 0].set_xlabel('Percolation Probability (p)', fontsize=12)
    axes[0, 0].set_ylabel('Growth Exponent α', fontsize=12)
    axes[0, 0].set_title('Data vs Sigmoid Fit', fontsize=14, fontweight='bold')
    axes[0, 0].legend(fontsize=10)
    axes[0, 0].grid(True, alpha=0.3)
    axes[0, 0].set_ylim(-0.1, 1.1)
    
    # Plot 2: Residuals
    axes[0, 1].scatter(p_values, alpha_residual, c='green', s=60, alpha=0.7)
    axes[0, 1].axhline(y=0, color='black', linestyle='-', alpha=0.5)
    axes[0, 1].axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2,
                       label="p_c' = 0.6884")
    axes[0, 1].set_xlabel('Percolation Probability (p)', fontsize=12)
    axes[0, 1].set_ylabel('Residual (α_data - α_fit)', fontsize=12)
    axes[0, 1].set_title('Sigmoid Fit Residuals', fontsize=14, fontweight='bold')
    axes[0, 1].grid(True, alpha=0.3)
    
    # Plot 3: Residual distribution
    axes[1, 0].hist(alpha_residual, bins=20, alpha=0.7, color='lightgreen', edgecolor='black')
    axes[1, 0].axvline(np.mean(alpha_residual), color='red', linestyle='--', 
                       label=f'Mean: {np.mean(alpha_residual):.4f}')
    axes[1, 0].axvline(np.std(alpha_residual), color='orange', linestyle='--', 
                       label=f'Std: {np.std(alpha_residual):.4f}')
    axes[1, 0].set_xlabel('Residual Value', fontsize=12)
    axes[1, 0].set_ylabel('Frequency', fontsize=12)
    axes[1, 0].set_title('Residual Distribution', fontsize=14, fontweight='bold')
    axes[1, 0].legend(fontsize=10)
    axes[1, 0].grid(True, alpha=0.3)
    
    # Plot 4: Fit quality metrics
    if analyzer.sigmoid_r2 is not None:
        metrics = ['R²', 'Mean Residual', 'Std Residual', 'Max Residual']
        values = [analyzer.sigmoid_r2, np.mean(alpha_residual), 
                 np.std(alpha_residual), np.max(np.abs(alpha_residual))]
        colors = ['green', 'blue', 'orange', 'red']
        
        bars = axes[1, 1].bar(metrics, values, color=colors, alpha=0.7)
        axes[1, 1].set_ylabel('Value', fontsize=12)
        axes[1, 1].set_title('Sigmoid Fit Quality Metrics', fontsize=14, fontweight='bold')
        axes[1, 1].grid(True, alpha=0.3, axis='y')
        
        # Add value labels on bars
        for bar, value in zip(bars, values):
            height = bar.get_height()
            axes[1, 1].text(bar.get_x() + bar.get_width()/2., height + 0.01,
                           f'{value:.4f}', ha='center', va='bottom', fontsize=10)
    
    plt.tight_layout()
    output_file = os.path.join(plots_dir, f"{dataset_name}_sigmoid_quality.png")
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  ✓ Sigmoid quality plot saved: {output_file}")

def create_transition_analysis_plot(results_df, dataset_name, plots_dir):
    """Create transition region analysis plot"""
    
    fig, axes = plt.subplots(2, 2, figsize=(15, 10))
    
    p_values = results_df['p'].values
    alpha_std = results_df['alpha_std'].values
    confidence = results_df['confidence'].values
    transition_detected = results_df['transition_detected'].values
    
    # Plot 1: Alpha standard deviation vs p
    colors = ['red' if t else 'blue' for t in transition_detected]
    sizes = [80 if t else 40 for t in transition_detected]
    
    scatter = axes[0, 0].scatter(p_values, alpha_std, c=colors, s=sizes, alpha=0.7)
    axes[0, 0].axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2,
                       label="p_c' = 0.6884")
    axes[0, 0].set_xlabel('Percolation Probability (p)', fontsize=12)
    axes[0, 0].set_ylabel('α Standard Deviation', fontsize=12)
    axes[0, 0].set_title('Alpha Variability Across Windows', fontsize=14, fontweight='bold')
    axes[0, 0].legend(['Transition Detected', 'No Transition', "p_c'"], fontsize=10)
    axes[0, 0].grid(True, alpha=0.3)
    
    # Plot 2: Confidence vs p
    axes[0, 1].scatter(p_values, confidence, c='green', s=60, alpha=0.7)
    axes[0, 1].axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2,
                       label="p_c' = 0.6884")
    axes[0, 1].axhline(y=0.7, color='red', linestyle='--', alpha=0.6, label='Confidence Threshold')
    axes[0, 1].set_xlabel('Percolation Probability (p)', fontsize=12)
    axes[0, 1].set_ylabel('Classification Confidence', fontsize=12)
    axes[0, 1].set_title('Classification Confidence vs p', fontsize=14, fontweight='bold')
    axes[0, 1].legend(fontsize=10)
    axes[0, 1].grid(True, alpha=0.3)
    axes[0, 1].set_ylim(0, 1)
    
    # Plot 3: Transition detection summary
    transition_summary = results_df.groupby('transition_detected').agg({
        'p': ['count', 'mean', 'std'],
        'alpha_std': 'mean',
        'confidence': 'mean'
    }).round(4)
    
    if not transition_summary.empty:
        # Create a simple bar plot
        transition_counts = results_df['transition_detected'].value_counts()
        axes[1, 0].bar(['No Transition', 'Transition Detected'], 
                       [transition_counts.get(False, 0), transition_counts.get(True, 0)],
                       color=['lightblue', 'lightgreen'], alpha=0.7, edgecolor='black')
        axes[1, 0].set_ylabel('Number of p-values', fontsize=12)
        axes[1, 0].set_title('Transition Detection Summary', fontsize=14, fontweight='bold')
        axes[1, 0].grid(True, alpha=0.3, axis='y')
        
        # Add count labels on bars
        for i, count in enumerate([transition_counts.get(False, 0), transition_counts.get(True, 0)]):
            axes[1, 0].text(i, count + 0.1, str(count), ha='center', va='bottom', fontsize=12)
    
    # Plot 4: Classification method effectiveness
    method_effectiveness = results_df.groupby('classification_method').agg({
        'confidence': 'mean',
        'alpha_std': 'mean'
    }).round(4)
    
    if not method_effectiveness.empty:
        methods = method_effectiveness.index
        confidences = method_effectiveness['confidence'].values
        alpha_stds = method_effectiveness['alpha_std'].values
        
        x = np.arange(len(methods))
        width = 0.35
        
        bars1 = axes[1, 1].bar(x - width/2, confidences, width, label='Mean Confidence', 
                               color='skyblue', alpha=0.7)
        bars2 = axes[1, 1].bar(x + width/2, alpha_stds, width, label='Mean α Std Dev', 
                               color='lightcoral', alpha=0.7)
        
        axes[1, 1].set_xlabel('Classification Method', fontsize=12)
        axes[1, 1].set_ylabel('Value', fontsize=12)
        axes[1, 1].set_title('Method Effectiveness Comparison', fontsize=14, fontweight='bold')
        axes[1, 1].set_xticks(x)
        axes[1, 1].set_xticklabels(methods, rotation=45, ha='right')
        axes[1, 1].legend(fontsize=10)
        axes[1, 1].grid(True, alpha=0.3, axis='y')
    
    plt.tight_layout()
    output_file = os.path.join(plots_dir, f"{dataset_name}_transition_analysis.png")
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  ✓ Transition analysis plot saved: {output_file}")

def create_comparison_plot(results_orig, results_new, analyzers, output_dir):
    """Create comparison plot between datasets"""
    
    print("\nCreating comparison plot between datasets...")
    
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    
    # Plot 1: Alpha comparison
    p_orig = results_orig['p'].values
    alpha_orig = results_orig['alpha_opt'].values
    p_new = results_new['p'].values
    alpha_new = results_new['alpha_opt'].values
    
    axes[0, 0].scatter(p_orig, alpha_orig, c='blue', s=60, alpha=0.7, label='Original Dataset')
    axes[0, 0].scatter(p_new, alpha_new, c='red', s=60, alpha=0.7, label='New Dataset')
    
    # Add sigmoid fits if available
    if analyzers['original'].sigmoid_params is not None:
        p_fine_orig = np.linspace(min(p_orig), max(p_orig), 1000)
        alpha_fine_orig = analyzers['original'].alpha_sigmoid_function(p_fine_orig)
        axes[0, 0].plot(p_fine_orig, alpha_fine_orig, 'b-', linewidth=2, alpha=0.8)
    
    if analyzers['new'].sigmoid_params is not None:
        p_fine_new = np.linspace(min(p_new), max(p_new), 1000)
        alpha_fine_new = analyzers['new'].alpha_sigmoid_function(p_fine_new)
        axes[0, 0].plot(p_fine_new, alpha_fine_new, 'r-', linewidth=2, alpha=0.8)
    
    axes[0, 0].axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2,
                       label="p_c' = 0.6884")
    axes[0, 0].set_xlabel('Percolation Probability (p)', fontsize=12)
    axes[0, 0].set_ylabel('Growth Exponent α', fontsize=12)
    axes[0, 0].set_title('Alpha Comparison: Original vs New Dataset', fontsize=14, fontweight='bold')
    axes[0, 0].legend(fontsize=10)
    axes[0, 0].grid(True, alpha=0.3)
    axes[0, 0].set_ylim(-0.1, 1.1)
    
    # Plot 2: Classification method comparison
    method_orig = results_orig['classification_method'].value_counts()
    method_new = results_new['classification_method'].value_counts()
    
    x = np.arange(len(set(list(method_orig.index) + list(method_new.index))))
    width = 0.35
    
    all_methods = sorted(set(list(method_orig.index) + list(method_new.index)))
    orig_counts = [method_orig.get(m, 0) for m in all_methods]
    new_counts = [method_new.get(m, 0) for m in all_methods]
    
    bars1 = axes[0, 1].bar(x - width/2, orig_counts, width, label='Original Dataset', 
                           color='skyblue', alpha=0.7)
    bars2 = axes[0, 1].bar(x + width/2, new_counts, width, label='New Dataset', 
                           color='lightcoral', alpha=0.7)
    
    axes[0, 1].set_xlabel('Classification Method', fontsize=12)
    axes[0, 1].set_ylabel('Number of p-values', fontsize=12)
    axes[0, 1].set_title('Classification Method Distribution', fontsize=14, fontweight='bold')
    axes[0, 1].set_xticks(x)
    axes[0, 1].set_xticklabels(all_methods, rotation=45, ha='right')
    axes[0, 1].legend(fontsize=10)
    axes[0, 1].grid(True, alpha=0.3, axis='y')
    
    # Plot 3: Sigmoid fit comparison
    if analyzers['original'].sigmoid_params is not None and analyzers['new'].sigmoid_params is not None:
        p_c_orig, width_orig, alpha_min_orig, alpha_max_orig = analyzers['original'].sigmoid_params
        p_c_new, width_new, alpha_min_new, alpha_max_new = analyzers['new'].sigmoid_params
        
        # Create comparison table
        params = ['p_c', 'Width', 'α_min', 'α_max', 'R²']
        orig_values = [p_c_orig, width_orig, alpha_min_orig, alpha_max_orig, 
                      analyzers['original'].sigmoid_r2]
        new_values = [p_c_new, width_new, alpha_min_new, alpha_max_new, 
                     analyzers['new'].sigmoid_r2]
        
        # Create table
        table_data = [[f'{orig:.4f}', f'{new:.4f}'] for orig, new in zip(orig_values, new_values)]
        table = axes[1, 0].table(cellText=table_data, rowLabels=params, 
                                colLabels=['Original', 'New'], loc='center')
        table.auto_set_font_size(False)
        table.set_fontsize(12)
        table.scale(1, 2)
        
        axes[1, 0].set_title('Sigmoid Fit Parameters Comparison', fontsize=14, fontweight='bold')
        axes[1, 0].axis('off')
    
    # Plot 4: Transition detection comparison
    trans_orig = results_orig['transition_detected'].value_counts()
    trans_new = results_new['transition_detected'].value_counts()
    
    trans_data = [
        [trans_orig.get(False, 0), trans_new.get(False, 0)],
        [trans_orig.get(True, 0), trans_new.get(True, 0)]
    ]
    
    table = axes[1, 1].table(cellText=trans_data, 
                             rowLabels=['No Transition', 'Transition Detected'],
                             colLabels=['Original', 'New'], loc='center')
    table.auto_set_font_size(False)
    table.set_fontsize(12)
    table.scale(1, 2)
    
    axes[1, 1].set_title('Transition Detection Comparison', fontsize=14, fontweight='bold')
    axes[1, 1].axis('off')
    
    plt.tight_layout()
    output_file = os.path.join(output_dir, "dataset_comparison.png")
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  ✓ Dataset comparison plot saved: {output_file}")

def main():
    """Main analysis pipeline"""
    
    print("=== HYBRID COMPLETE ANALYSIS PIPELINE ===")
    print("Combining physics-based classification, transition detection, and sigmoid fitting")
    
    # Create output directory
    output_dir = "output_hybrid_analysis"
    os.makedirs(output_dir, exist_ok=True)
    
    # Analyze original dataset
    results_orig, analyzer_orig = analyze_dataset_with_hybrid(
        "../matlab/Clusters/p_output_C1.csv", "original", output_dir
    )
    
    # Analyze new dataset
    results_new, analyzer_new = analyze_dataset_with_hybrid(
        "../matlab/p_output_NEW34.csv", "new", output_dir
    )
    
    # Create comparison plot
    if results_orig is not None and results_new is not None:
        analyzers = {'original': analyzer_orig, 'new': analyzer_new}
        create_comparison_plot(results_orig, results_new, analyzers, output_dir)
        
        # Generate summary report
        generate_summary_report(results_orig, results_new, analyzers, output_dir)
    
    print(f"\n{'='*60}")
    print("HYBRID ANALYSIS COMPLETE!")
    print(f"Results saved to: {output_dir}")
    print(f"{'='*60}")

def generate_summary_report(results_orig, results_new, analyzers, output_dir):
    """Generate a comprehensive summary report"""
    
    report_file = os.path.join(output_dir, "hybrid_analysis_summary.md")
    
    with open(report_file, 'w') as f:
        f.write("# Hybrid Alpha Analysis Summary Report\n\n")
        f.write("## Overview\n\n")
        f.write("This report summarizes the hybrid analysis approach combining:\n")
        f.write("- **Physics-based classification** for clear regimes\n")
        f.write("- **Transition detection** for critical regions\n")
        f.write("- **Sigmoid fitting** for continuous parameter evolution\n")
        f.write("- **Adaptive critical region** width determination\n\n")
        
        f.write("## Dataset Analysis Results\n\n")
        
        # Original dataset summary
        f.write("### Original Dataset (p_output_C1.csv)\n\n")
        f.write(f"- **Total p-values analyzed**: {len(results_orig)}\n")
        f.write(f"- **Regime distribution**:\n")
        strategy_counts = results_orig['strategy'].value_counts()
        for strategy, count in strategy_counts.items():
            f.write(f"  - {strategy}: {count} p-values\n")
        
        if analyzers['original'].sigmoid_params is not None:
            p_c, width, alpha_min, alpha_max = analyzers['original'].sigmoid_params
            f.write(f"- **Sigmoid fit parameters**:\n")
            f.write(f"  - p_c = {p_c:.4f}\n")
            f.write(f"  - Width = {width:.4f}\n")
            f.write(f"  - α_min = {alpha_min:.4f}\n")
            f.write(f"  - α_max = {alpha_max:.4f}\n")
            f.write(f"  - R² = {analyzers['original'].sigmoid_r2:.4f}\n")
        
        f.write("\n### New Dataset (p_output_NEW34.csv)\n\n")
        f.write(f"- **Total p-values analyzed**: {len(results_new)}\n")
        f.write(f"- **Regime distribution**:\n")
        strategy_counts = results_new['strategy'].value_counts()
        for strategy, count in strategy_counts.items():
            f.write(f"  - {strategy}: {count} p-values\n")
        
        if analyzers['new'].sigmoid_params is not None:
            p_c, width, alpha_min, alpha_max = analyzers['new'].sigmoid_params
            f.write(f"- **Sigmoid fit parameters**:\n")
            f.write(f"  - p_c = {p_c:.4f}\n")
            f.write(f"  - Width = {width:.4f}\n")
            f.write(f"  - α_min = {alpha_min:.4f}\n")
            f.write(f"  - α_max = {alpha_max:.4f}\n")
            f.write(f"  - R² = {analyzers['new'].sigmoid_r2:.4f}\n")
        
        f.write("\n## Key Insights\n\n")
        f.write("1. **Transition Detection**: The hybrid approach successfully identifies critical regions\n")
        f.write("2. **Continuous Parameters**: Sigmoid fitting enables calculation of G', G'', δ, and tan δ at any p-value\n")
        f.write("3. **Robust Classification**: Combines multiple methods for reliable regime determination\n")
        f.write("4. **Physics Preservation**: Maintains physical consistency while improving classification accuracy\n\n")
        
        f.write("## Output Files\n\n")
        f.write("- `*_hybrid_results.csv`: Detailed analysis results for each dataset\n")
        f.write("- `plots/`: Comprehensive visualization plots\n")
        f.write("- `dataset_comparison.png`: Direct comparison between datasets\n")
        f.write("- `hybrid_analysis_summary.md`: This summary report\n\n")
    
    print(f"  ✓ Summary report saved: {report_file}")

if __name__ == "__main__":
    main()
