#!/usr/bin/env python3
"""
Comprehensive MSD Analysis with Forward-Looking Optimization
Implements the forward-looking optimization approach to detect τ_cr and α values
for all p-values in the MSD dataset.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats
from scipy.optimize import curve_fit
import warnings
warnings.filterwarnings('ignore')

class ForwardLookingMSDAnalyzer:
    def __init__(self, min_region2_size=50, max_region2_size=None, 
                 early_stopping_r2=0.5, early_stopping_rms_factor=1.2):
        """
        Initialize the forward-looking MSD analyzer.
        
        Parameters:
        - min_region2_size: Minimum number of points for Region 2
        - max_region2_size: Maximum number of points for Region 2 (None = auto)
        - early_stopping_r2: R² threshold for early stopping
        - early_stopping_rms_factor: RMS degradation factor for early stopping
        """
        self.min_region2_size = min_region2_size
        self.max_region2_size = max_region2_size
        self.early_stopping_r2 = early_stopping_r2
        self.early_stopping_rms_factor = early_stopping_rms_factor
        
    def load_msd_data(self, file_path):
        """Load MSD data from CSV file."""
        print(f"Loading MSD data from: {file_path}")
        df = pd.read_csv(file_path)
        
        # Extract p-values from column names
        p_values = []
        for col in df.columns:
            if col.startswith('MSD_'):
                p_str = col.replace('MSD_', '')
                # Handle different formats (0 vs 0.0)
                if p_str == '0':
                    p_val = 0.0
                else:
                    p_val = float(p_str)
                p_values.append(p_val)
        
        p_values = sorted(p_values)
        print(f"Loaded {len(p_values)} p-values: {p_values[0]} to {p_values[-1]}")
        
        return df, p_values
    
    def fit_power_law(self, x, y):
        """Fit power law y = A * x^alpha using log-log linear fit."""
        # Remove zero and negative values
        mask = (x > 0) & (y > 0)
        if mask.sum() < 10:  # Need at least 10 points
            return None, None, None, None
        
        x_fit = x[mask]
        y_fit = y[mask]
        
        # Log-log fit
        log_x = np.log(x_fit)
        log_y = np.log(y_fit)
        
        try:
            slope, intercept, r_value, p_value, std_err = stats.linregress(log_x, log_y)
            alpha = slope
            A = np.exp(intercept)
            r_squared = r_value ** 2
            
            # Calculate RMS error
            y_pred = A * x_fit ** alpha
            rms_error = np.sqrt(np.mean((y_fit - y_pred) ** 2))
            
            return alpha, A, r_squared, rms_error
            
        except:
            return None, None, None, None
    
    def fit_polynomial(self, x, y, degree=3):
        """Fit polynomial in log-log space."""
        # Remove zero and negative values
        mask = (x > 0) & (y > 0)
        if mask.sum() < degree + 5:  # Need enough points
            return None, None, None
        
        x_fit = x[mask]
        y_fit = y[mask]
        
        # Log-log fit
        log_x = np.log(x_fit)
        log_y = np.log(y_fit)
        
        try:
            coeffs = np.polyfit(log_x, log_y, degree)
            y_pred_log = np.polyval(coeffs, log_x)
            y_pred = np.exp(y_pred_log)
            
            r_squared = 1 - np.sum((y_fit - y_pred) ** 2) / np.sum((y_fit - np.mean(y_fit)) ** 2)
            rms_error = np.sqrt(np.mean((y_fit - y_pred) ** 2))
            
            return coeffs, r_squared, rms_error
            
        except:
            return None, None, None
    
    def forward_looking_optimization(self, time_steps, msd_values):
        """
        Implement forward-looking optimization to find optimal τ_cr.
        
        Returns:
        - tau_cr: Critical transition time
        - alpha_1, alpha_2: Exponents for both regions
        - r2_1, r2_2: R² values for both regions
        - region2_size: Number of points in Region 2
        - region2_quality: Quality metric for Region 2
        """
        n_points = len(time_steps)
        
        # Set maximum Region 2 size
        if self.max_region2_size is None:
            max_region2_size = n_points - 100  # Leave points for Region 1
        else:
            max_region2_size = min(self.max_region2_size, n_points - 100)
        
        # Test different Region 2 sizes
        region2_sizes = np.linspace(self.min_region2_size, max_region2_size, 50, dtype=int)
        
        best_result = None
        best_combined_rms = float('inf')
        best_region2_size = None
        
        for region2_size in region2_sizes:
            # Define Region 2 (anomalous diffusion region)
            region2_start = n_points - region2_size
            region2_end = n_points
            
            # Define Region 1 (early-time behavior)
            region1_end = region2_start
            region1_start = max(0, region1_end - 200)  # Use up to 200 points for Region 1
            
            # Extract data for both regions
            t1 = time_steps[region1_start:region1_end]
            msd1 = msd_values[region1_start:region1_end]
            
            t2 = time_steps[region2_start:region2_end]
            msd2 = msd_values[region2_start:region2_end]
            
            # Fit Region 1 (try power law first, then polynomial)
            alpha_1, A_1, r2_1, rms_1 = self.fit_power_law(t1, msd1)
            
            if r2_1 is None or r2_1 < 0.8:
                # Try polynomial fit
                poly_coeffs, r2_1, rms_1 = self.fit_polynomial(t1, msd1)
                alpha_1 = np.nan  # No alpha for polynomial
            else:
                poly_coeffs = None
            
            # Fit Region 2 (power law only)
            alpha_2, A_2, r2_2, rms_2 = self.fit_power_law(t2, msd2)
            
            if alpha_2 is None or r2_2 is None:
                continue
            
            # Check early stopping criteria
            if r2_2 < self.early_stopping_r2 and rms_2 > best_combined_rms * self.early_stopping_rms_factor:
                break
            
            # Calculate combined RMS error
            combined_rms = np.sqrt((rms_1**2 + rms_2**2) / 2)
            
            # Update best result
            if combined_rms < best_combined_rms:
                best_combined_rms = combined_rms
                best_region2_size = region2_size
                best_result = {
                    'tau_cr': time_steps[region2_start],
                    'alpha_1': alpha_1,
                    'alpha_2': alpha_2,
                    'r2_1': r2_1,
                    'r2_2': r2_2,
                    'rms_1': rms_1,
                    'rms_2': rms_2,
                    'combined_rms': combined_rms,
                    'region2_size': region2_size,
                    'region2_start': region2_start,
                    'region2_end': region2_end,
                    'region1_start': region1_start,
                    'region1_end': region1_end
                }
        
        return best_result
    
    def analyze_single_p_value(self, df, p_value, plot=False):
        """Analyze a single p-value using forward-looking optimization."""
        # Handle different column name formats
        if p_value == 0.0:
            col_name = "MSD_0"
        else:
            col_name = f"MSD_{p_value}"
        
        if col_name not in df.columns:
            print(f"Warning: Column {col_name} not found for p = {p_value}")
            return None
        
        # Extract data
        msd_values = df[col_name].values
        time_steps = np.arange(len(msd_values))
        
        # Remove zero values at the beginning
        non_zero_mask = msd_values > 0
        if non_zero_mask.sum() < 100:
            print(f"Warning: Insufficient non-zero data for p = {p_value}")
            return None
        
        # Start from first non-zero value
        start_idx = np.where(non_zero_mask)[0][0]
        time_steps = time_steps[start_idx:]
        msd_values = msd_values[start_idx:]
        
        # Apply forward-looking optimization
        result = self.forward_looking_optimization(time_steps, msd_values)
        
        if result is None:
            print(f"Warning: Could not find optimal fit for p = {p_value}")
            return None
        
        # Add p-value to result
        result['p_value'] = p_value
        
        if plot:
            self.plot_analysis_result(time_steps, msd_values, result, p_value)
        
        return result
    
    def plot_analysis_result(self, time_steps, msd_values, result, p_value):
        """Plot the analysis result showing both regions."""
        plt.figure(figsize=(12, 8))
        
        # Plot full MSD curve
        plt.loglog(time_steps, msd_values, 'k-', alpha=0.5, label='MSD Data')
        
        # Plot Region 1
        r1_start = result['region1_start']
        r1_end = result['region1_end']
        t1 = time_steps[r1_start:r1_end]
        msd1 = msd_values[r1_start:r1_end]
        plt.loglog(t1, msd1, 'b-', linewidth=2, label='Region 1')
        
        # Plot Region 2
        r2_start = result['region2_start']
        r2_end = result['region2_end']
        t2 = time_steps[r2_start:r2_end]
        msd2 = msd_values[r2_start:r2_end]
        plt.loglog(t2, msd2, 'r-', linewidth=2, label='Region 2')
        
        # Mark τ_cr
        tau_cr = result['tau_cr']
        plt.axvline(tau_cr, color='g', linestyle='--', linewidth=2, label=f'τ_cr = {tau_cr:.0f}')
        
        # Add fit information
        alpha_1 = result['alpha_1']
        alpha_2 = result['alpha_2']
        r2_1 = result['r2_1']
        r2_2 = result['r2_2']
        
        plt.title(f'MSD Analysis for p = {p_value}\n'
                 f'α₁ = {alpha_1:.3f} (R² = {r2_1:.3f}), α₂ = {alpha_2:.3f} (R² = {r2_2:.3f})')
        plt.xlabel('Time Step')
        plt.ylabel('MSD')
        plt.legend()
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        
        # Save plot
        plt.savefig(f'msd_analysis_p{p_value:.4f}.png', dpi=300, bbox_inches='tight')
        plt.close()
    
    def analyze_all_p_values(self, df, p_values, plot_key_values=True):
        """Analyze all p-values and return comprehensive results."""
        results = []
        
        # Key p-values for plotting
        key_p_values = [0.0, 0.3116, 0.6884, 0.7425]
        
        print(f"Analyzing {len(p_values)} p-values...")
        
        for i, p in enumerate(p_values):
            print(f"Progress: {i+1}/{len(p_values)} - Analyzing p = {p:.4f}")
            
            # Determine if we should plot this p-value
            should_plot = plot_key_values and p in key_p_values
            
            result = self.analyze_single_p_value(df, p, plot=should_plot)
            
            if result is not None:
                results.append(result)
                print(f"  ✓ τ_cr = {result['tau_cr']:.0f}, α₂ = {result['alpha_2']:.3f}, R² = {result['r2_2']:.3f}")
            else:
                print(f"  ✗ Failed to analyze p = {p:.4f}")
        
        return results
    
    def create_summary_plots(self, results):
        """Create summary plots of the analysis results."""
        if not results:
            print("No results to plot")
            return
        
        # Extract data
        p_values = [r['p_value'] for r in results]
        tau_cr_values = [r['tau_cr'] for r in results]
        alpha_2_values = [r['alpha_2'] for r in results]
        r2_2_values = [r['r2_2'] for r in results]
        region2_sizes = [r['region2_size'] for r in results]
        
        # Create summary plots
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        
        # Plot 1: τ_cr vs p
        axes[0, 0].semilogy(p_values, tau_cr_values, 'bo-', linewidth=2, markersize=6)
        axes[0, 0].axvline(0.3116, color='r', linestyle='--', alpha=0.7, label='p_c')
        axes[0, 0].axvline(0.6884, color='g', linestyle='--', alpha=0.7, label="p_c'")
        axes[0, 0].set_xlabel('Percolation Probability p')
        axes[0, 0].set_ylabel('Critical Time τ_cr')
        axes[0, 0].set_title('Critical Transition Time vs Percolation Probability')
        axes[0, 0].legend()
        axes[0, 0].grid(True, alpha=0.3)
        
        # Plot 2: α₂ vs p
        axes[0, 1].plot(p_values, alpha_2_values, 'ro-', linewidth=2, markersize=6)
        axes[0, 1].axvline(0.3116, color='r', linestyle='--', alpha=0.7, label='p_c')
        axes[0, 1].axvline(0.6884, color='g', linestyle='--', alpha=0.7, label="p_c'")
        axes[0, 1].axhline(1.0, color='k', linestyle=':', alpha=0.7, label='Normal Diffusion')
        axes[0, 1].axhline(0.0, color='k', linestyle=':', alpha=0.7, label='No Diffusion')
        axes[0, 1].set_xlabel('Percolation Probability p')
        axes[0, 1].set_ylabel('Growth Exponent α₂')
        axes[0, 1].set_title('Anomalous Diffusion Exponent vs Percolation Probability')
        axes[0, 1].legend()
        axes[0, 1].grid(True, alpha=0.3)
        
        # Plot 3: R² vs p
        axes[1, 0].plot(p_values, r2_2_values, 'go-', linewidth=2, markersize=6)
        axes[1, 0].axvline(0.3116, color='r', linestyle='--', alpha=0.7, label='p_c')
        axes[1, 0].axvline(0.6884, color='g', linestyle='--', alpha=0.7, label="p_c'")
        axes[1, 0].axhline(0.8, color='k', linestyle=':', alpha=0.7, label='Good Fit Threshold')
        axes[1, 0].set_xlabel('Percolation Probability p')
        axes[1, 0].set_ylabel('R² for Region 2')
        axes[1, 0].set_title('Fit Quality vs Percolation Probability')
        axes[1, 0].legend()
        axes[1, 0].grid(True, alpha=0.3)
        
        # Plot 4: Region 2 size vs p
        axes[1, 1].plot(p_values, region2_sizes, 'mo-', linewidth=2, markersize=6)
        axes[1, 1].axvline(0.3116, color='r', linestyle='--', alpha=0.7, label='p_c')
        axes[1, 1].axvline(0.6884, color='g', linestyle='--', alpha=0.7, label="p_c'")
        axes[1, 1].set_xlabel('Percolation Probability p')
        axes[1, 1].set_ylabel('Region 2 Size (points)')
        axes[1, 1].set_title('Anomalous Diffusion Region Size vs Percolation Probability')
        axes[1, 1].legend()
        axes[1, 1].grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.savefig('comprehensive_msd_analysis_summary.png', dpi=300, bbox_inches='tight')
        plt.show()
        
        print("Summary plots saved to: comprehensive_msd_analysis_summary.png")

def main():
    """Main analysis function."""
    # Initialize analyzer
    analyzer = ForwardLookingMSDAnalyzer(
        min_region2_size=50,
        early_stopping_r2=0.5,
        early_stopping_rms_factor=1.2
    )
    
    # Load data
    file_path = "matlab/Clusters/p_output_C1.csv"
    df, p_values = analyzer.load_msd_data(file_path)
    
    # Analyze all p-values
    results = analyzer.analyze_all_p_values(df, p_values, plot_key_values=True)
    
    # Create summary plots
    analyzer.create_summary_plots(results)
    
    # Save results to CSV
    if results:
        results_df = pd.DataFrame(results)
        results_df.to_csv('comprehensive_msd_analysis_results.csv', index=False)
        print(f"\nResults saved to: comprehensive_msd_analysis_results.csv")
        print(f"Successfully analyzed {len(results)} out of {len(p_values)} p-values")
        
        # Print summary statistics
        print(f"\n=== SUMMARY STATISTICS ===")
        print(f"Average α₂: {np.mean([r['alpha_2'] for r in results]):.3f}")
        print(f"Average R²: {np.mean([r['r2_2'] for r in results]):.3f}")
        print(f"Average τ_cr: {np.mean([r['tau_cr'] for r in results]):.0f}")
    else:
        print("No successful analyses completed")

if __name__ == "__main__":
    main()
