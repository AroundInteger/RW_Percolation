#!/usr/bin/env python3
"""
Robust Comprehensive MSD Analysis
Based on the working definitive ensemble analysis approach
Adapted for the large MSD dataset with 34 p-values
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats
import warnings
warnings.filterwarnings('ignore')

class RobustComprehensiveAnalyzer:
    """Robust comprehensive analysis using the working sliding window approach"""
    
    def __init__(self, p_c_prime: float = 0.6884):
        self.p_c_prime = p_c_prime
        self.logger = self.setup_logging()
        
        self.logger.info("=== ROBUST COMPREHENSIVE MSD ANALYSIS ===")
        self.logger.info(f"Critical point: p_c' = {self.p_c_prime}")
    
    def setup_logging(self):
        """Setup logging"""
        import logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('robust_comprehensive_analysis.log'),
                logging.StreamHandler()
            ]
        )
        return logging.getLogger(__name__)
    
    def load_msd_data(self, file_path: str):
        """Load MSD data from CSV file"""
        self.logger.info(f"Loading MSD data from: {file_path}")
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
        self.logger.info(f"Loaded {len(p_values)} p-values: {p_values[0]} to {p_values[-1]}")
        
        return df, p_values
    
    def determine_regime(self, p: float) -> tuple:
        """Determine regime and expected α for given p"""
        if p < self.p_c_prime - 0.05:
            regime = 'LIQUID'
            expected_alpha = 1.0
        elif abs(p - self.p_c_prime) < 0.05:
            regime = 'CRITICAL'
            expected_alpha = 0.5
        else:
            regime = 'SOLID'
            expected_alpha = 0.0
        
        return regime, expected_alpha
    
    def robust_alpha_analysis(self, t: np.ndarray, msd: np.ndarray, p: float) -> tuple:
        """
        Robust α analysis with sliding window approach (from working code)
        Returns: (tau_cr, alpha_opt, alpha_error, analysis_details)
        """
        # Use larger window for better stability with 1M step data
        window_size = min(50, len(t) // 20)
        
        start_idx = max(10, window_size // 2)
        end_idx = len(t) - window_size // 2
        
        alpha_values = []
        alpha_errors = []
        tau_values = []
        r_squared_values = []
        
        self.logger.info(f"Performing α analysis for p={p:.4f}: window_size={window_size}, range={start_idx}-{end_idx}")
        
        # Sample every 1% for speed
        step_size = max(1, (end_idx - start_idx) // 100)
        
        for i in range(start_idx, end_idx, step_size):
            window_start = max(0, i - window_size // 2)
            window_end = min(len(t), i + window_size // 2)
            
            t_window = t[window_start:window_end]
            msd_window = msd[window_start:window_end]
            
            if len(t_window) >= 20 and all(msd_window > 0):
                try:
                    # Log-log analysis
                    log_t = np.log10(t_window)
                    log_msd = np.log10(msd_window)
                    
                    # Linear fit
                    coeffs = np.polyfit(log_t, log_msd, 1)
                    alpha = coeffs[0]
                    
                    # Calculate R²
                    msd_pred = 10**(alpha * log_t + coeffs[1])
                    ss_res = np.sum((msd_window - msd_pred)**2)
                    ss_tot = np.sum((msd_window - np.mean(msd_window))**2)
                    
                    if ss_tot > 0:
                        r_squared = 1 - (ss_res / ss_tot)
                    else:
                        r_squared = 0
                    
                    alpha_values.append(alpha)
                    alpha_errors.append(1 - r_squared)
                    tau_values.append(t[i])
                    r_squared_values.append(r_squared)
                    
                except (np.linalg.LinAlgError, ValueError):
                    continue
        
        if not alpha_values:
            return np.nan, np.nan, np.nan, {}
        
        # Find first good quality point (from working code)
        good_quality = np.array(alpha_errors) < 0.1
        
        if not np.any(good_quality):
            # If no good quality points, use best available
            best_idx = np.argmin(alpha_errors)
            tau_cr = tau_values[best_idx]
            alpha_opt = alpha_values[best_idx]
            alpha_error = alpha_errors[best_idx]
        else:
            first_good_idx = np.where(good_quality)[0][0]
            tau_cr = tau_values[first_good_idx]
            alpha_opt = alpha_values[first_good_idx]
            alpha_error = alpha_errors[first_good_idx]
        
        # Store detailed analysis
        analysis_details = {
            'tau_values': tau_values,
            'alpha_values': alpha_values,
            'alpha_errors': alpha_errors,
            'r_squared_values': r_squared_values,
            'window_size': window_size,
            'total_points_analyzed': len(alpha_values)
        }
        
        return tau_cr, alpha_opt, alpha_error, analysis_details
    
    def analyze_single_p_value(self, df: pd.DataFrame, p: float) -> dict:
        """Analyze a single p-value using the robust approach"""
        # Handle different column name formats
        if p == 0.0:
            col_name = "MSD_0"
        else:
            col_name = f"MSD_{p}"
        
        if col_name not in df.columns:
            self.logger.warning(f"Column {col_name} not found for p = {p}")
            return None
        
        # Extract data
        msd_values = df[col_name].values
        time_steps = np.arange(len(msd_values))
        
        # Remove zero values at the beginning
        non_zero_mask = msd_values > 0
        if non_zero_mask.sum() < 100:
            self.logger.warning(f"Insufficient non-zero data for p = {p}")
            return None
        
        # Start from first non-zero value
        start_idx = np.where(non_zero_mask)[0][0]
        time_steps = time_steps[start_idx:]
        msd_values = msd_values[start_idx:]
        
        # Determine regime
        regime, expected_alpha = self.determine_regime(p)
        
        # Perform robust α analysis
        tau_cr, alpha_opt, alpha_error, analysis_details = self.robust_alpha_analysis(time_steps, msd_values, p)
        
        # Calculate distance from critical point
        distance_from_critical = abs(p - self.p_c_prime)
        
        result = {
            'p': p,
            'regime': regime,
            'expected_alpha': expected_alpha,
            'tau_cr': tau_cr,
            'alpha_opt': alpha_opt,
            'alpha_error': alpha_error,
            'distance_from_critical': distance_from_critical,
            'data_points': len(time_steps),
            'analysis_details': analysis_details,
            'success': not np.isnan(tau_cr)
        }
        
        if result['success']:
            self.logger.info(f"  Result: τ_cr = {tau_cr:.2e}, α = {alpha_opt:.3f}, error = {alpha_error:.3f} ({regime})")
        else:
            self.logger.warning(f"  No changepoint found ({regime})")
        
        return result
    
    def analyze_all_p_values(self, df: pd.DataFrame, p_values: list) -> list:
        """Analyze all p-values using the robust approach"""
        self.logger.info(f"Analyzing {len(p_values)} p-values...")
        
        results = []
        successful_count = 0
        
        for i, p in enumerate(p_values):
            self.logger.info(f"Progress: {i+1}/{len(p_values)} - Analyzing p = {p:.4f}")
            
            result = self.analyze_single_p_value(df, p)
            
            if result is not None and result['success']:
                results.append(result)
                successful_count += 1
            elif result is not None:
                results.append(result)  # Include failed results for analysis
        
        self.logger.info(f"Analysis complete: {successful_count}/{len(p_values)} successful")
        return results
    
    def create_summary_plots(self, results: list):
        """Create summary plots of the analysis results"""
        if not results:
            self.logger.warning("No results to plot")
            return
        
        # Extract data
        p_values = [r['p'] for r in results]
        tau_cr_values = [r['tau_cr'] for r in results]
        alpha_values = [r['alpha_opt'] for r in results]
        alpha_errors = [r['alpha_error'] for r in results]
        regimes = [r['regime'] for r in results]
        
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
        
        # Plot 2: α vs p with error bars
        axes[0, 1].errorbar(p_values, alpha_values, yerr=alpha_errors, fmt='ro-', 
                           linewidth=2, markersize=6, capsize=5)
        axes[0, 1].axvline(0.3116, color='r', linestyle='--', alpha=0.7, label='p_c')
        axes[0, 1].axvline(0.6884, color='g', linestyle='--', alpha=0.7, label="p_c'")
        axes[0, 1].axhline(1.0, color='k', linestyle=':', alpha=0.7, label='Normal Diffusion')
        axes[0, 1].axhline(0.0, color='k', linestyle=':', alpha=0.7, label='No Diffusion')
        axes[0, 1].set_xlabel('Percolation Probability p')
        axes[0, 1].set_ylabel('Growth Exponent α')
        axes[0, 1].set_title('Anomalous Diffusion Exponent vs Percolation Probability')
        axes[0, 1].legend()
        axes[0, 1].grid(True, alpha=0.3)
        
        # Plot 3: α error vs p
        axes[1, 0].plot(p_values, alpha_errors, 'go-', linewidth=2, markersize=6)
        axes[1, 0].axvline(0.3116, color='r', linestyle='--', alpha=0.7, label='p_c')
        axes[1, 0].axvline(0.6884, color='g', linestyle='--', alpha=0.7, label="p_c'")
        axes[1, 0].axhline(0.1, color='k', linestyle=':', alpha=0.7, label='Good Quality Threshold')
        axes[1, 0].set_xlabel('Percolation Probability p')
        axes[1, 0].set_ylabel('α Error (1 - R²)')
        axes[1, 0].set_title('Fit Quality vs Percolation Probability')
        axes[1, 0].legend()
        axes[1, 0].grid(True, alpha=0.3)
        
        # Plot 4: Regime classification
        regime_colors = {'LIQUID': 'blue', 'CRITICAL': 'orange', 'SOLID': 'red'}
        for regime in set(regimes):
            mask = [r == regime for r in regimes]
            axes[1, 1].scatter([p_values[i] for i, m in enumerate(mask) if m], 
                              [alpha_values[i] for i, m in enumerate(mask) if m], 
                              c=regime_colors[regime], label=regime, s=50, alpha=0.7)
        
        axes[1, 1].axvline(0.3116, color='r', linestyle='--', alpha=0.7, label='p_c')
        axes[1, 1].axvline(0.6884, color='g', linestyle='--', alpha=0.7, label="p_c'")
        axes[1, 1].set_xlabel('Percolation Probability p')
        axes[1, 1].set_ylabel('Growth Exponent α')
        axes[1, 1].set_title('Regime Classification')
        axes[1, 1].legend()
        axes[1, 1].grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.savefig('robust_comprehensive_analysis_summary.png', dpi=300, bbox_inches='tight')
        plt.show()
        
        self.logger.info("Summary plots saved to: robust_comprehensive_analysis_summary.png")
    
    def generate_summary_report(self, results: list) -> str:
        """Generate a comprehensive summary report"""
        if not results:
            return "No results to report"
        
        successful_results = [r for r in results if r['success']]
        
        report = []
        report.append("=== ROBUST COMPREHENSIVE MSD ANALYSIS REPORT ===")
        report.append(f"Analysis Date: {pd.Timestamp.now()}")
        report.append(f"Critical Point: p_c' = {self.p_c_prime}")
        report.append(f"Total p-values analyzed: {len(results)}")
        report.append(f"Successful analyses: {len(successful_results)}")
        report.append(f"Success rate: {len(successful_results)/len(results):.1%}")
        report.append("")
        
        # Summary statistics
        if successful_results:
            alpha_values = [r['alpha_opt'] for r in successful_results]
            tau_cr_values = [r['tau_cr'] for r in successful_results]
            alpha_errors = [r['alpha_error'] for r in successful_results]
            
            report.append("SUMMARY STATISTICS:")
            report.append(f"  Average α: {np.mean(alpha_values):.3f} ± {np.std(alpha_values):.3f}")
            report.append(f"  Average τ_cr: {np.mean(tau_cr_values):.2e}")
            report.append(f"  Average α error: {np.mean(alpha_errors):.3f}")
            report.append("")
        
        # Regime breakdown
        regime_counts = {}
        for r in results:
            regime = r['regime']
            regime_counts[regime] = regime_counts.get(regime, 0) + 1
        
        report.append("REGIME BREAKDOWN:")
        for regime, count in regime_counts.items():
            report.append(f"  {regime}: {count} p-values")
        report.append("")
        
        # Key p-value results
        key_p_values = [0.0, 0.3116, 0.6884, 0.7425]
        report.append("KEY P-VALUE RESULTS:")
        report.append("p-value    Regime     τ_cr         α         Error")
        report.append("-" * 55)
        
        for p in key_p_values:
            result = next((r for r in results if abs(r['p'] - p) < 1e-6), None)
            if result:
                regime = result['regime']
                tau_cr = result['tau_cr']
                alpha = result['alpha_opt']
                error = result['alpha_error']
                success = "✓" if result['success'] else "✗"
                
                if np.isnan(tau_cr):
                    tau_str = "N/A"
                    alpha_str = "N/A"
                    error_str = "N/A"
                else:
                    tau_str = f"{tau_cr:.2e}"
                    alpha_str = f"{alpha:.3f}"
                    error_str = f"{error:.3f}"
                
                report.append(f"{p:<8.4f} {regime:<10} {tau_str:<12} {alpha_str:<8} {error_str:<8} {success}")
        
        report.append("")
        report.append("=" * 60)
        
        return "\n".join(report)

def main():
    """Main execution function"""
    print("=== ROBUST COMPREHENSIVE MSD ANALYSIS ===")
    print("Using the working sliding window approach")
    print("Analyzing all 34 p-values in the dataset")
    print()
    
    # Create analyzer
    analyzer = RobustComprehensiveAnalyzer()
    
    # Load data
    file_path = "matlab/Clusters/p_output_C1.csv"
    df, p_values = analyzer.load_msd_data(file_path)
    
    # Analyze all p-values
    results = analyzer.analyze_all_p_values(df, p_values)
    
    # Create summary plots
    analyzer.create_summary_plots(results)
    
    # Generate and display report
    report = analyzer.generate_summary_report(results)
    print(report)
    
    # Save results to CSV
    if results:
        results_df = pd.DataFrame(results)
        results_df.to_csv('robust_comprehensive_analysis_results.csv', index=False)
        print(f"\nResults saved to: robust_comprehensive_analysis_results.csv")
        
        # Save report
        with open('robust_comprehensive_analysis_report.txt', 'w') as f:
            f.write(report)
        print("Report saved to: robust_comprehensive_analysis_report.txt")
    
    print("\n=== ANALYSIS COMPLETE ===")
    print("Check the generated files for detailed results.")

if __name__ == "__main__":
    main()
