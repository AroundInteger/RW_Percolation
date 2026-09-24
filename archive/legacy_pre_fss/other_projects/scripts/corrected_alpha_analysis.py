#!/usr/bin/env python3
"""
Corrected Alpha Analysis with Adaptive Time Window Selection
Implements the theoretical framework from the documentation:
- p < p_c': α ≈ 1.0 (normal diffusion)
- p ≈ p_c': α ≈ 0.5 (anomalous diffusion)  
- p > p_c': α ≈ 0.0 (plateau region)
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats
import warnings
warnings.filterwarnings('ignore')

class CorrectedAlphaAnalyzer:
    """Corrected alpha analysis with adaptive time window selection"""
    
    def __init__(self, p_c_prime=0.6884):
        self.p_c_prime = p_c_prime
        print(f"=== CORRECTED ALPHA ANALYSIS ===")
        print(f"Critical point: p_c' = {self.p_c_prime}")
        print()
        
    def load_data(self, file_path):
        """Load the MSD dataset"""
        print(f"Loading data from: {file_path}")
        df = pd.read_csv(file_path)
        
        # Extract p-values from column names
        p_values = []
        for col in df.columns:
            if col.startswith('MSD_'):
                p_str = col.replace('MSD_', '')
                if p_str == '0':
                    p_val = 0.0
                else:
                    p_val = float(p_str)
                p_values.append(p_val)
        
        p_values = sorted(p_values)
        print(f"Found {len(p_values)} p-values: {p_values[0]} to {p_values[-1]}")
        return df, p_values
    
    def determine_analysis_strategy(self, p_value):
        """Determine analysis strategy based on p-value"""
        if p_value < self.p_c_prime - 0.05:
            # Liquid regime: use REGULAR DIFFUSION region
            strategy = "liquid"
            expected_alpha = 1.0
            description = "Normal diffusion region (after cross-over point)"
        elif abs(p_value - self.p_c_prime) < 0.05:
            # Critical regime: use ANOMALOUS DIFFUSION region
            strategy = "critical"
            expected_alpha = 0.5
            description = "Anomalous diffusion region"
        else:
            # Solid regime: use LONG TIME plateau
            strategy = "solid"
            expected_alpha = 0.0
            description = "Plateau region (arrested diffusion)"
        
        return strategy, expected_alpha, description
    
    def analyze_single_p_value(self, df, p_value, plot=False):
        """Analyze a single p-value with adaptive strategy"""
        
        # Get column name
        if p_value == 0.0:
            col_name = "MSD_0"
        else:
            col_name = f"MSD_{p_value}"
        
        if col_name not in df.columns:
            print(f"Warning: Column {col_name} not found")
            return None
        
        # Get strategy
        strategy, expected_alpha, description = self.determine_analysis_strategy(p_value)
        
        # Extract MSD data
        msd_data = df[col_name].values
        time_steps = np.arange(1, len(msd_data) + 1)
        
        # Remove any invalid data
        valid_mask = np.isfinite(msd_data) & (msd_data > 0)
        if not np.any(valid_mask):
            print(f"Warning: No valid data for p = {p_value}")
            return None
        
        msd_valid = msd_data[valid_mask]
        time_valid = time_steps[valid_mask]
        
        # Apply adaptive time window selection
        if strategy == "liquid":
            # Use later time region for normal diffusion
            start_idx = len(msd_valid) // 4  # Start at 25% of data
            end_idx = len(msd_valid)
        elif strategy == "critical":
            # Use middle region for anomalous diffusion
            start_idx = len(msd_valid) // 10  # Start at 10% of data
            end_idx = len(msd_valid) // 2     # End at 50% of data
        else:  # solid
            # Use plateau region (very late times)
            start_idx = len(msd_valid) // 2   # Start at 50% of data
            end_idx = len(msd_valid)
        
        # Ensure minimum window size
        min_window = 50
        if end_idx - start_idx < min_window:
            start_idx = max(0, end_idx - min_window)
        
        # Extract analysis window
        msd_window = msd_valid[start_idx:end_idx]
        time_window = time_valid[start_idx:end_idx]
        
        # For solid regime (plateau), fit constant instead of power law
        if strategy == "solid":
            # Fit constant: MSD = constant
            constant = np.mean(msd_window)
            alpha = 0.0  # By definition for plateau
            r_squared = 1.0 - np.var(msd_window - constant) / np.var(msd_window)
            tau_cr = time_window[len(time_window)//2]  # Midpoint
        else:
            # Fit power law: log(MSD) = α * log(time) + intercept
            log_msd = np.log10(msd_window)
            log_time = np.log10(time_window)
            
            slope, intercept, r_value, p_value_fit, std_err = stats.linregress(log_time, log_msd)
            alpha = slope
            r_squared = r_value ** 2
            tau_cr = time_window[len(time_window)//2]  # Midpoint
        
        # Calculate error (deviation from expected)
        alpha_error = abs(alpha - expected_alpha)
        
        result = {
            'p': p_value,
            'strategy': strategy,
            'expected_alpha': expected_alpha,
            'alpha_opt': alpha,
            'alpha_error': alpha_error,
            'r_squared': r_squared,
            'tau_cr': tau_cr,
            'window_start': time_window[0],
            'window_end': time_window[-1],
            'window_size': len(time_window),
            'description': description
        }
        
        if plot:
            self.plot_analysis(msd_valid, time_valid, msd_window, time_window, 
                             alpha, r_squared, p_value, strategy)
        
        return result
    
    def plot_analysis(self, msd_full, time_full, msd_window, time_window, 
                     alpha, r_squared, p_value, strategy):
        """Plot the analysis results"""
        plt.figure(figsize=(12, 8))
        
        # Full MSD curve
        plt.subplot(2, 2, 1)
        plt.loglog(time_full, msd_full, 'b-', alpha=0.7, label='Full MSD')
        plt.loglog(time_window, msd_window, 'r-', linewidth=2, label='Analysis Window')
        plt.xlabel('Time Step')
        plt.ylabel('MSD')
        plt.title(f'p = {p_value} - {strategy.upper()} Regime')
        plt.legend()
        plt.grid(True, alpha=0.3)
        
        # Log-log fit
        plt.subplot(2, 2, 2)
        if strategy != "solid":
            log_msd = np.log10(msd_window)
            log_time = np.log10(time_window)
            plt.plot(log_time, log_msd, 'ro', label='Data')
            
            # Fit line
            fit_line = alpha * log_time + np.mean(log_msd - alpha * log_time)
            plt.plot(log_time, fit_line, 'k-', label=f'Fit: α = {alpha:.3f}')
            plt.xlabel('log₁₀(Time)')
            plt.ylabel('log₁₀(MSD)')
            plt.title(f'Power Law Fit (R² = {r_squared:.3f})')
        else:
            plt.plot(time_window, msd_window, 'ro', label='Plateau Data')
            constant = np.mean(msd_window)
            plt.axhline(y=constant, color='k', linestyle='-', 
                       label=f'Constant: α = 0.0')
            plt.xlabel('Time Step')
            plt.ylabel('MSD')
            plt.title(f'Plateau Region (R² = {r_squared:.3f})')
        
        plt.legend()
        plt.grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(f'corrected_analysis_p{p_value:.4f}.png', dpi=150, bbox_inches='tight')
        plt.close()
    
    def analyze_all_p_values(self, df, p_values, plot_samples=False):
        """Analyze all p-values"""
        results = []
        
        print("Analyzing p-values with adaptive strategy:")
        print("-" * 60)
        
        for i, p_value in enumerate(p_values):
            print(f"Progress: {i+1}/{len(p_values)} - p = {p_value:.4f}")
            
            result = self.analyze_single_p_value(df, p_value, plot=plot_samples)
            if result:
                results.append(result)
                
                strategy = result['strategy']
                alpha = result['alpha_opt']
                expected = result['expected_alpha']
                r_squared = result['r_squared']
                
                print(f"  Strategy: {strategy.upper()}")
                print(f"  α = {alpha:.3f} (expected: {expected:.1f})")
                print(f"  R² = {r_squared:.3f}")
                print()
        
        return pd.DataFrame(results)
    
    def create_summary_plots(self, results_df):
        """Create summary plots of the analysis"""
        
        # Alpha vs p plot
        plt.figure(figsize=(15, 10))
        
        plt.subplot(2, 2, 1)
        colors = {'liquid': 'blue', 'critical': 'orange', 'solid': 'red'}
        
        for strategy in ['liquid', 'critical', 'solid']:
            mask = results_df['strategy'] == strategy
            if np.any(mask):
                p_vals = results_df.loc[mask, 'p']
                alphas = results_df.loc[mask, 'alpha_opt']
                plt.plot(p_vals, alphas, 'o', color=colors[strategy], 
                        label=f'{strategy.title()} (α ≈ {results_df.loc[mask, "expected_alpha"].iloc[0]:.1f})')
        
        # Add theoretical lines
        plt.axhline(y=1.0, color='blue', linestyle='--', alpha=0.5, label='α = 1.0 (liquid)')
        plt.axhline(y=0.5, color='orange', linestyle='--', alpha=0.5, label='α = 0.5 (critical)')
        plt.axhline(y=0.0, color='red', linestyle='--', alpha=0.5, label='α = 0.0 (solid)')
        plt.axvline(x=self.p_c_prime, color='black', linestyle=':', alpha=0.7, label=f"p_c' = {self.p_c_prime}")
        
        plt.xlabel('Percolation Probability (p)')
        plt.ylabel('Growth Exponent (α)')
        plt.title('Corrected Alpha Analysis: α vs p')
        plt.legend()
        plt.grid(True, alpha=0.3)
        
        # R² vs p plot
        plt.subplot(2, 2, 2)
        for strategy in ['liquid', 'critical', 'solid']:
            mask = results_df['strategy'] == strategy
            if np.any(mask):
                p_vals = results_df.loc[mask, 'p']
                r_squared = results_df.loc[mask, 'r_squared']
                plt.plot(p_vals, r_squared, 'o', color=colors[strategy], label=strategy.title())
        
        plt.xlabel('Percolation Probability (p)')
        plt.ylabel('R² (Fit Quality)')
        plt.title('Fit Quality vs p')
        plt.legend()
        plt.grid(True, alpha=0.3)
        
        # Error vs p plot
        plt.subplot(2, 2, 3)
        for strategy in ['liquid', 'critical', 'solid']:
            mask = results_df['strategy'] == strategy
            if np.any(mask):
                p_vals = results_df.loc[mask, 'p']
                errors = results_df.loc[mask, 'alpha_error']
                plt.plot(p_vals, errors, 'o', color=colors[strategy], label=strategy.title())
        
        plt.xlabel('Percolation Probability (p)')
        plt.ylabel('|α - α_expected|')
        plt.title('Deviation from Expected α')
        plt.legend()
        plt.grid(True, alpha=0.3)
        
        # Strategy distribution
        plt.subplot(2, 2, 4)
        strategy_counts = results_df['strategy'].value_counts()
        plt.pie(strategy_counts.values, labels=strategy_counts.index, autopct='%1.1f%%')
        plt.title('Analysis Strategy Distribution')
        
        plt.tight_layout()
        plt.savefig('corrected_alpha_analysis_summary.png', dpi=150, bbox_inches='tight')
        plt.close()
        
        print(f"Summary plots saved to: corrected_alpha_analysis_summary.png")

def main():
    """Main analysis function"""
    analyzer = CorrectedAlphaAnalyzer(p_c_prime=0.6884)
    
    # Load data
    df, p_values = analyzer.load_data('matlab/Clusters/p_output_C1.csv')
    
    # Analyze all p-values
    results_df = analyzer.analyze_all_p_values(df, p_values, plot_samples=True)
    
    # Save results
    results_df.to_csv('corrected_alpha_analysis_results.csv', index=False)
    print(f"\nResults saved to: corrected_alpha_analysis_results.csv")
    
    # Create summary plots
    analyzer.create_summary_plots(results_df)
    
    # Print summary statistics
    print("\n=== SUMMARY STATISTICS ===")
    for strategy in ['liquid', 'critical', 'solid']:
        mask = results_df['strategy'] == strategy
        if np.any(mask):
            subset = results_df.loc[mask]
            print(f"\n{strategy.upper()} REGIME:")
            print(f"  Count: {len(subset)} p-values")
            print(f"  α range: {subset['alpha_opt'].min():.3f} to {subset['alpha_opt'].max():.3f}")
            print(f"  α mean: {subset['alpha_opt'].mean():.3f}")
            print(f"  R² mean: {subset['r_squared'].mean():.3f}")
            print(f"  Error mean: {subset['alpha_error'].mean():.3f}")

if __name__ == "__main__":
    main() 