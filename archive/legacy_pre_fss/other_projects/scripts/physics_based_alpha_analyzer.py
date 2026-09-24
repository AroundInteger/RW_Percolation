#!/usr/bin/env python3
"""
Physics-Based Alpha Analyzer
Classify percolation regimes based on actual physical behavior (α values) 
rather than arbitrary geometric thresholds.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats
import warnings
warnings.filterwarnings('ignore')

class PhysicsBasedAlphaAnalyzer:
    """
    Physics-based analyzer that classifies regimes by actual MSD behavior
    rather than arbitrary geometric thresholds.
    """
    
    def __init__(self, p_c_prime: float = 0.6884):
        """
        Initialize the physics-based analyzer
        
        Parameters:
        - p_c_prime: Critical percolation threshold
        """
        self.p_c_prime = p_c_prime
        
        # Physics-based classification thresholds
        self.alpha_thresholds = {
            'liquid': {'min': 0.8, 'max': float('inf')},
            'critical': {'min': 0.3, 'max': 0.7},
            'solid': {'min': 0.0, 'max': 0.2}
        }
        
        # Quality thresholds
        self.r2_threshold = 0.8  # Minimum R² for reliable classification
        self.confidence_threshold = 0.7  # Minimum confidence for physics-based classification
        
    def analyze_single_p_value(self, df, p_value, plot=False):
        """
        Analyze a single p-value using physics-based classification
        
        Returns:
        - Dictionary with analysis results
        """
        # Get column name
        if p_value == 0.0:
            col_name = "MSD_0"
        else:
            col_name = f"MSD_{p_value}"
        
        if col_name not in df.columns:
            print(f"Warning: Column {col_name} not found")
            return None
        
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
        
        # Multi-window analysis for robust α determination
        window_results = self._analyze_multiple_windows(msd_valid, time_valid)
        
        if not window_results:
            print(f"Warning: No valid windows for p = {p_value}")
            return None
        
        # Physics-based classification
        classification_result = self._classify_by_physics(p_value, window_results)
        
        # Calculate overall statistics
        alpha_values = [w['alpha'] for w in window_results]
        r_squared_values = [w['r_squared'] for w in window_results]
        
        # Weighted average α (weighted by R² quality)
        weighted_alpha = np.average(alpha_values, weights=r_squared_values)
        
        # Overall fit quality
        mean_r2 = np.mean(r_squared_values)
        alpha_std = np.std(alpha_values)
        
        # Confidence score based on consistency and quality
        confidence = self._calculate_confidence(alpha_values, r_squared_values)
        
        result = {
            'p': p_value,
            'strategy': classification_result['strategy'],
            'alpha_opt': weighted_alpha,
            'alpha_std': alpha_std,
            'r_squared': mean_r2,
            'confidence': confidence,
            'tau_cr': window_results[0]['tau_cr'],  # Use first window as reference
            'window_results': window_results,
            'classification_method': classification_result['method'],
            'physics_score': classification_result['physics_score'],
            'geometric_score': classification_result['geometric_score'],
            'description': classification_result['description']
        }
        
        if plot:
            self._plot_analysis(msd_valid, time_valid, window_results, result)
        
        return result
    
    def _analyze_multiple_windows(self, msd_valid, time_valid):
        """Analyze multiple time windows for robust α determination"""
        
        # Define analysis windows with different strategies
        windows = [
            {'name': 'Early', 'start_frac': 0.1, 'end_frac': 0.5, 'strategy': 'liquid'},
            {'name': 'Middle', 'start_frac': 0.25, 'end_frac': 0.75, 'strategy': 'critical'},
            {'name': 'Late', 'start_frac': 0.5, 'end_frac': 1.0, 'strategy': 'liquid'},
            {'name': 'Very Late', 'start_frac': 0.75, 'end_frac': 1.0, 'strategy': 'solid'}
        ]
        
        results = []
        
        for window in windows:
            start_idx = int(len(msd_valid) * window['start_frac'])
            end_idx = int(len(msd_valid) * window['end_frac'])
            
            # Ensure minimum window size
            if end_idx - start_idx < 50:
                continue
            
            msd_window = msd_valid[start_idx:end_idx]
            time_window = time_valid[start_idx:end_idx]
            
            # Analyze this window
            window_result = self._analyze_single_window(
                msd_window, time_window, window['strategy'], window['name']
            )
            
            if window_result:
                results.append(window_result)
        
        return results
    
    def _analyze_single_window(self, msd_window, time_window, expected_strategy, window_name):
        """Analyze a single time window"""
        
        if expected_strategy == "solid":
            # For solid regime, check if MSD is actually plateauing
            # Calculate the ratio of final to initial MSD
            msd_ratio = msd_window[-1] / msd_window[0]
            
            if msd_ratio < 1.2:  # If MSD is truly plateauing (very little growth)
                # Fit constant: MSD = constant
                constant = np.mean(msd_window)
                alpha = 0.0
                # Calculate R² for constant fit: R² = 1 - SS_res/SS_tot
                ss_res = np.sum((msd_window - constant)**2)
                ss_tot = np.sum((msd_window - np.mean(msd_window))**2)
                if ss_tot > 0:
                    r_squared = 1.0 - ss_res / ss_tot
                else:
                    r_squared = 1.0  # Perfect fit if no variance
            else:
                # MSD is still growing (even if slowly), fit power law
                log_msd = np.log10(msd_window)
                log_time = np.log10(time_window)
                slope, intercept, r_value, p_value_fit, std_err = stats.linregress(log_time, log_msd)
                alpha = slope
                r_squared = r_value ** 2
        else:
            # For liquid/critical, fit power law
            log_msd = np.log10(msd_window)
            log_time = np.log10(time_window)
            
            slope, intercept, r_value, p_value_fit, std_err = stats.linregress(log_time, log_msd)
            alpha = slope
            r_squared = r_value ** 2
        
        return {
            'window_name': window_name,
            'strategy': expected_strategy,
            'alpha': alpha,
            'r_squared': r_squared,
            'tau_cr': time_window[len(time_window)//2],
            'window_size': len(time_window),
            'msd_start': msd_window[0],
            'msd_end': msd_window[-1]
        }
    
    def _classify_by_physics(self, p_value, window_results):
        """
        Classify regime based on actual physical behavior
        """
        
        # Extract α values and R² values
        alpha_values = [w['alpha'] for w in window_results]
        r_squared_values = [w['r_squared'] for w in window_results]
        
        # Calculate weighted average α
        weighted_alpha = np.average(alpha_values, weights=r_squared_values)
        mean_r2 = np.mean(r_squared_values)
        alpha_std = np.std(alpha_values)
        
        # Physics-based classification
        physics_classification = self._classify_by_alpha(weighted_alpha, mean_r2)
        
        # Geometric classification (fallback)
        geometric_classification = self._classify_by_geometry(p_value)
        
        # Calculate confidence and decide on final classification
        confidence = self._calculate_confidence(alpha_values, r_squared_values)
        
        # Check if we have good physics-based classification
        if (mean_r2 > self.r2_threshold and 
            physics_classification['strategy'] != 'uncertain' and
            weighted_alpha > 0.8):  # If α is clearly liquid-like
            
            # Use physics-based classification for clear liquid behavior
            final_strategy = physics_classification['strategy']
            method = 'physics_based'
            physics_score = 1.0
            geometric_score = 0.0
        elif confidence > self.confidence_threshold and mean_r2 > self.r2_threshold:
            # High confidence: use physics-based classification
            final_strategy = physics_classification['strategy']
            method = 'physics_based'
            physics_score = 1.0
            geometric_score = 0.0
        else:
            # Low confidence: use geometric classification
            final_strategy = geometric_classification['strategy']
            method = 'geometric_fallback'
            physics_score = 0.0
            geometric_score = 1.0
        
        # Create description
        if method == 'physics_based':
            description = f"Physics-based: α_avg = {weighted_alpha:.3f}, R²_avg = {mean_r2:.3f}, confidence = {confidence:.3f}"
        else:
            description = f"Geometric fallback: |p - p_c'| = {abs(p_value - self.p_c_prime):.4f}"
        
        return {
            'strategy': final_strategy,
            'method': method,
            'physics_score': physics_score,
            'geometric_score': geometric_score,
            'description': description,
            'weighted_alpha': weighted_alpha,
            'confidence': confidence
        }
    
    def _classify_by_alpha(self, alpha, r_squared):
        """Classify based on α value and fit quality"""
        
        if r_squared < self.r2_threshold:
            return {'strategy': 'uncertain', 'reason': 'poor_fit'}
        
        if alpha > self.alpha_thresholds['liquid']['min']:
            return {'strategy': 'liquid', 'reason': 'high_alpha'}
        elif self.alpha_thresholds['critical']['min'] <= alpha <= self.alpha_thresholds['critical']['max']:
            return {'strategy': 'critical', 'reason': 'intermediate_alpha'}
        elif alpha < self.alpha_thresholds['solid']['max']:
            return {'strategy': 'solid', 'reason': 'low_alpha'}
        else:
            return {'strategy': 'uncertain', 'reason': 'alpha_out_of_range'}
    
    def _classify_by_geometry(self, p_value):
        """Geometric classification (fallback method)"""
        
        distance = abs(p_value - self.p_c_prime)
        
        if p_value <= self.p_c_prime - 0.05:
            return {'strategy': 'liquid', 'reason': 'below_critical'}
        elif distance < 0.05:
            return {'strategy': 'critical', 'reason': 'near_critical'}
        else:
            return {'strategy': 'solid', 'reason': 'above_critical'}
    
    def _calculate_confidence(self, alpha_values, r_squared_values):
        """Calculate confidence score based on consistency and quality"""
        
        # Consistency: lower std = higher confidence
        alpha_std = np.std(alpha_values)
        consistency_score = 1.0 / (1.0 + alpha_std)
        
        # Quality: higher R² = higher confidence
        mean_r2 = np.mean(r_squared_values)
        quality_score = mean_r2
        
        # Overall confidence
        confidence = consistency_score * quality_score
        
        return confidence
    
    def _plot_analysis(self, msd_full, time_full, window_results, result):
        """Plot the analysis results"""
        
        fig, axes = plt.subplots(2, 2, figsize=(16, 12))
        
        # Plot 1: Full MSD curve
        ax1 = axes[0, 0]
        ax1.loglog(time_full, msd_full, 'b-', linewidth=2, label=f'p = {result["p"]:.4f}')
        ax1.set_xlabel('Time Step')
        ax1.set_ylabel('MSD')
        ax1.set_title(f'Full MSD Curve\nClassification: {result["strategy"].upper()}')
        ax1.grid(True, alpha=0.3)
        ax1.legend()
        
        # Plot 2: Different time windows
        ax2 = axes[0, 1]
        colors = ['red', 'orange', 'green', 'blue']
        for i, window in enumerate(window_results):
            start_idx = int(len(msd_full) * {'Early': 0.1, 'Middle': 0.25, 'Late': 0.5, 'Very Late': 0.75}[window['window_name']])
            end_idx = int(len(msd_full) * {'Early': 0.5, 'Middle': 0.75, 'Late': 1.0, 'Very Late': 1.0}[window['window_name']])
            
            msd_window = msd_full[start_idx:end_idx]
            time_window = time_full[start_idx:end_idx]
            
            ax2.loglog(time_window, msd_window, 'o-', color=colors[i], 
                      label=f'{window["window_name"]} (α = {window["alpha"]:.3f})')
        
        ax2.set_xlabel('Time Step')
        ax2.set_ylabel('MSD')
        ax2.set_title('MSD in Different Time Windows')
        ax2.grid(True, alpha=0.3)
        ax2.legend()
        
        # Plot 3: α values across windows
        ax3 = axes[1, 0]
        window_names = [w['window_name'] for w in window_results]
        alphas = [w['alpha'] for w in window_results]
        r2_values = [w['r_squared'] for w in window_results]
        
        bars = ax3.bar(range(len(window_results)), alphas, color='skyblue', alpha=0.7)
        ax3.set_xlabel('Time Window')
        ax3.set_ylabel('Growth Exponent (α)')
        ax3.set_title('α Values for Different Time Windows')
        ax3.set_xticks(range(len(window_results)))
        ax3.set_xticklabels(window_names, rotation=45)
        ax3.axhline(y=1.0, color='blue', linestyle='--', alpha=0.7, label='α = 1.0 (liquid)')
        ax3.axhline(y=0.5, color='orange', linestyle='--', alpha=0.7, label='α = 0.5 (critical)')
        ax3.axhline(y=0.0, color='red', linestyle='--', alpha=0.7, label='α = 0.0 (solid)')
        ax3.axhline(y=result['alpha_opt'], color='black', linestyle='-', alpha=0.8, 
                   label=f'Weighted avg: {result["alpha_opt"]:.3f}')
        ax3.legend()
        ax3.grid(True, alpha=0.3)
        
        # Plot 4: Classification summary
        ax4 = axes[1, 1]
        ax4.text(0.1, 0.8, f"Classification: {result['strategy'].upper()}", fontsize=14, fontweight='bold')
        ax4.text(0.1, 0.7, f"Method: {result['classification_method']}", fontsize=12)
        ax4.text(0.1, 0.6, f"Confidence: {result['confidence']:.3f}", fontsize=12)
        ax4.text(0.1, 0.5, f"Physics Score: {result['physics_score']:.3f}", fontsize=12)
        ax4.text(0.1, 0.4, f"Geometric Score: {result['geometric_score']:.3f}", fontsize=12)
        ax4.text(0.1, 0.3, f"α_avg: {result['alpha_opt']:.4f}", fontsize=12)
        ax4.text(0.1, 0.2, f"R²_avg: {result['r_squared']:.4f}", fontsize=12)
        ax4.text(0.1, 0.1, f"α_std: {result['alpha_std']:.4f}", fontsize=12)
        
        ax4.set_xlim(0, 1)
        ax4.set_ylim(0, 1)
        ax4.set_title('Classification Summary')
        ax4.axis('off')
        
        plt.tight_layout()
        plt.savefig(f'physics_based_analysis_p{result["p"]:.4f}.png', dpi=300, bbox_inches='tight')
        plt.close()

def main():
    """Test the physics-based analyzer"""
    
    print("=== PHYSICS-BASED ALPHA ANALYZER TEST ===")
    
    # Load the new dataset
    df = pd.read_csv("matlab/p_output_NEW34.csv")
    
    # Test the problematic case: p = 0.6384
    p_value = 0.6384
    print(f"\nTesting p = {p_value} (previously misclassified as solid)")
    
    analyzer = PhysicsBasedAlphaAnalyzer()
    result = analyzer.analyze_single_p_value(df, p_value, plot=True)
    
    if result:
        print(f"\n=== ANALYSIS RESULTS ===")
        print(f"Classification: {result['strategy'].upper()}")
        print(f"Method: {result['classification_method']}")
        print(f"Confidence: {result['confidence']:.3f}")
        print(f"Weighted α: {result['alpha_opt']:.4f}")
        print(f"R² average: {result['r_squared']:.4f}")
        print(f"α standard deviation: {result['alpha_std']:.4f}")
        print(f"Description: {result['description']}")
        
        print(f"\n=== WINDOW ANALYSIS ===")
        for window in result['window_results']:
            print(f"{window['window_name']}: α = {window['alpha']:.4f}, R² = {window['r_squared']:.4f}")
    else:
        print("Analysis failed")

if __name__ == "__main__":
    main()
