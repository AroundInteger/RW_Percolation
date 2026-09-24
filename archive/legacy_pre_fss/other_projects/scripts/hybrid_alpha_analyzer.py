#!/usr/bin/env python3
"""
Hybrid Alpha Analyzer with Sigmoid Fitting
Combines physics-based classification, transition detection, and continuous sigmoid fitting
for robust regime classification and smooth parameter interpolation.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats
from scipy.optimize import curve_fit
import warnings
warnings.filterwarnings('ignore')

class HybridAlphaAnalyzer:
    """
    Hybrid analyzer combining physics, transition detection, and sigmoid fitting
    """
    
    def __init__(self, p_c_prime: float = 0.6884):
        """
        Initialize the hybrid analyzer
        
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
        self.r2_threshold = 0.8
        self.confidence_threshold = 0.7
        
        # Sigmoid function for α(p) fitting
        self.sigmoid_params = None
        self.sigmoid_covariance = None
        self.sigmoid_r2 = None
        
    def analyze_dataset(self, df, p_values):
        """
        Analyze entire dataset with hybrid approach and sigmoid fitting
        """
        print(f"=== HYBRID ANALYSIS OF {len(p_values)} P-VALUES ===")
        
        # Analyze all p-values
        results = []
        for i, p in enumerate(p_values):
            print(f"  Progress: {i+1}/{len(p_values)} - p = {p:.4f}")
            
            result = self.analyze_single_p_value(df, p, plot=False)
            if result:
                results.append(result)
            else:
                print(f"    Warning: Analysis failed for p = {p:.4f}")
        
        # Create results DataFrame
        results_df = pd.DataFrame(results)
        
        # Fit sigmoid function to α(p) data
        print("\nFitting sigmoid function to α(p) data...")
        sigmoid_success = self.fit_sigmoid_function(results_df)
        
        if sigmoid_success:
            # Add sigmoid predictions to results
            results_df = self.add_sigmoid_predictions(results_df)
            
            # Calculate continuous viscoelastic parameters
            results_df = self.calculate_continuous_parameters(results_df)
        
        return results_df
    
    def analyze_single_p_value(self, df, p_value, plot=False):
        """
        Analyze a single p-value using hybrid classification
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
        
        # Hybrid classification
        classification_result = self._hybrid_classification(p_value, window_results)
        
        # Calculate overall statistics
        alpha_values = [w['alpha'] for w in window_results]
        r_squared_values = [w['r_squared'] for w in window_results]
        
        # Weighted average α (handle zero weights)
        if np.sum(r_squared_values) > 0:
            weighted_alpha = np.average(alpha_values, weights=r_squared_values)
        else:
            weighted_alpha = np.mean(alpha_values)
        mean_r2 = np.mean(r_squared_values)
        alpha_std = np.std(alpha_values)
        
        # Confidence score
        confidence = self._calculate_confidence(alpha_values, r_squared_values)
        
        result = {
            'p': p_value,
            'strategy': classification_result['strategy'],
            'alpha_opt': weighted_alpha,
            'alpha_std': alpha_std,
            'r_squared': mean_r2,
            'confidence': confidence,
            'tau_cr': window_results[0]['tau_cr'],
            'window_results': window_results,
            'classification_method': classification_result['method'],
            'classification_reason': classification_result['reason'],
            'physics_score': classification_result['physics_score'],
            'geometric_score': classification_result['geometric_score'],
            'transition_detected': classification_result['transition_detected'],
            'description': classification_result['description']
        }
        
        if plot:
            self._plot_analysis(msd_valid, time_valid, window_results, result)
        
        return result
    
    def _analyze_multiple_windows(self, msd_valid, time_valid):
        """Analyze multiple time windows for robust α determination"""
        
        # Define analysis windows
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
            
            if end_idx - start_idx < 50:
                continue
            
            msd_window = msd_valid[start_idx:end_idx]
            time_window = time_valid[start_idx:end_idx]
            
            window_result = self._analyze_single_window(
                msd_window, time_window, window['strategy'], window['name']
            )
            
            if window_result:
                results.append(window_result)
        
        return results
    
    def _analyze_single_window(self, msd_window, time_window, expected_strategy, window_name):
        """Analyze a single time window"""
        
        # Check if MSD is plateauing
        msd_ratio = msd_window[-1] / msd_window[0]
        
        if msd_ratio < 1.2:  # Truly plateauing
            constant = np.mean(msd_window)
            alpha = 0.0
            ss_res = np.sum((msd_window - constant)**2)
            ss_tot = np.sum((msd_window - np.mean(msd_window))**2)
            if ss_tot > 0:
                r_squared = 1.0 - ss_res / ss_tot
            else:
                r_squared = 1.0
        else:
            # MSD still growing, fit power law
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
    
    def _hybrid_classification(self, p_value, window_results):
        """
        Hybrid classification combining physics, transition detection, and geometry
        """
        
        # Extract α values and R² values
        alpha_values = [w['alpha'] for w in window_results]
        r_squared_values = [w['r_squared'] for w in window_results]
        
        # Calculate weighted average α (handle zero weights)
        if np.sum(r_squared_values) > 0:
            weighted_alpha = np.average(alpha_values, weights=r_squared_values)
        else:
            weighted_alpha = np.mean(alpha_values)
        mean_r2 = np.mean(r_squared_values)
        alpha_std = np.std(alpha_values)
        
        # Step 1: Check for clear physics-based classification
        if mean_r2 > self.r2_threshold:
            if weighted_alpha > 0.8:
                return self._create_result('liquid', 'physics_based', 'clear_liquid', 
                                        weighted_alpha, 1.0, 0.0, True)
            elif weighted_alpha < 0.2:
                return self._create_result('solid', 'physics_based', 'clear_solid', 
                                        weighted_alpha, 1.0, 0.0, True)
        
        # Step 2: Transition detection for critical region
        distance_from_critical = abs(p_value - self.p_c_prime)
        transition_behavior = self._detect_transition_behavior(alpha_values, r_squared_values)
        
        if distance_from_critical < 0.08:  # Wider critical region
            if transition_behavior['is_transition']:
                if 0.3 < weighted_alpha < 0.7:
                    return self._create_result('critical', 'transition_detected', 'gel_point_region', 
                                            weighted_alpha, 0.8, 0.2, True)
                elif transition_behavior['high_variability']:
                    return self._create_result('critical', 'transition_detected', 'high_variability', 
                                            weighted_alpha, 0.8, 0.2, True)
        
        # Step 3: Adaptive critical region analysis
        if self._adaptive_critical_region(p_value, alpha_values):
            return self._create_result('critical', 'adaptive_critical', 'adaptive_detection', 
                                    weighted_alpha, 0.7, 0.3, True)
        
        # Step 4: Physics-based for intermediate cases
        if mean_r2 > self.r2_threshold and 0.4 < weighted_alpha < 0.6:
            return self._create_result('critical', 'physics_based', 'intermediate_alpha', 
                                    weighted_alpha, 0.6, 0.4, False)
        
        # Step 5: Fallback to geometric classification
        geometric_result = self._geometric_classification(p_value)
        return self._create_result(geometric_result['strategy'], 'geometric_fallback', 
                                geometric_result['reason'], weighted_alpha, 0.0, 1.0, False)
    
    def _detect_transition_behavior(self, alpha_values, r_squared_values):
        """Detect if α values suggest transition behavior"""
        
        alpha_std = np.std(alpha_values)
        mean_alpha = np.mean(alpha_values)
        
        # High α variation across windows suggests transition
        high_variability = alpha_std > 0.3
        
        # Check if different windows show different regimes
        if len(alpha_values) >= 4:
            early_alpha = np.mean(alpha_values[:2])
            late_alpha = np.mean(alpha_values[-2:])
            alpha_difference = abs(early_alpha - late_alpha)
            regime_difference = alpha_difference > 0.4
        else:
            regime_difference = False
        
        # Transition indicators
        is_transition = high_variability or regime_difference
        intermediate_values = 0.3 < mean_alpha < 0.7
        
        return {
            'is_transition': is_transition,
            'high_variability': high_variability,
            'regime_difference': regime_difference,
            'intermediate_values': intermediate_values,
            'alpha_std': alpha_std
        }
    
    def _adaptive_critical_region(self, p_value, alpha_values):
        """Adaptively determine critical region width based on α behavior"""
        
        base_width = 0.05
        alpha_std = np.std(alpha_values)
        mean_alpha = np.mean(alpha_values)
        
        # Expand critical region if α shows transition behavior
        if 0.3 < mean_alpha < 0.7:
            if alpha_std > 0.2:  # High variability suggests transition
                adaptive_width = base_width * (1 + alpha_std)
            else:
                adaptive_width = base_width * 1.5  # Moderate expansion
        else:
            adaptive_width = base_width
        
        return abs(p_value - self.p_c_prime) < adaptive_width
    
    def _geometric_classification(self, p_value):
        """Geometric classification (fallback method)"""
        
        distance = abs(p_value - self.p_c_prime)
        
        if p_value <= self.p_c_prime - 0.05:
            return {'strategy': 'liquid', 'reason': 'below_critical'}
        elif distance < 0.05:
            return {'strategy': 'critical', 'reason': 'near_critical'}
        else:
            return {'strategy': 'solid', 'reason': 'above_critical'}
    
    def _create_result(self, strategy, method, reason, weighted_alpha, physics_score, 
                      geometric_score, transition_detected):
        """Create classification result dictionary"""
        
        if method == 'physics_based':
            description = f"Physics-based: α = {weighted_alpha:.3f}, {reason}"
        elif method == 'transition_detected':
            description = f"Transition detected: α = {weighted_alpha:.3f}, {reason}"
        elif method == 'adaptive_critical':
            description = f"Adaptive critical: α = {weighted_alpha:.3f}, {reason}"
        else:
            description = f"Geometric fallback: {reason}"
        
        return {
            'strategy': strategy,
            'method': method,
            'reason': reason,
            'physics_score': physics_score,
            'geometric_score': geometric_score,
            'transition_detected': transition_detected,
            'description': description,
            'weighted_alpha': weighted_alpha
        }
    
    def _calculate_confidence(self, alpha_values, r_squared_values):
        """Calculate confidence score based on consistency and quality"""
        
        alpha_std = np.std(alpha_values)
        consistency_score = 1.0 / (1.0 + alpha_std)
        mean_r2 = np.mean(r_squared_values)
        quality_score = mean_r2
        
        confidence = consistency_score * quality_score
        return confidence
    
    def fit_sigmoid_function(self, results_df):
        """Fit sigmoid function to α(p) data"""
        
        def sigmoid_function(p, p_c, width, alpha_min, alpha_max):
            """Sigmoid function for α(p) relationship"""
            alpha_min = max(0.0, alpha_min)
            alpha_max = min(1.0, alpha_max)
            return alpha_min + (alpha_max - alpha_min) / (1 + np.exp((p - p_c) / width))
        
        try:
            p_values = results_df['p'].values
            alpha_values = results_df['alpha_opt'].values
            
            # Initial parameter guesses
            p_c_guess = self.p_c_prime
            width_guess = 0.05
            alpha_min_guess = 0.0
            alpha_max_guess = 1.0
            
            # Fit sigmoid function
            popt, pcov = curve_fit(sigmoid_function, p_values, alpha_values,
                                 p0=[p_c_guess, width_guess, alpha_min_guess, alpha_max_guess],
                                 bounds=([0.6, 0.01, 0.0, 0.8], [0.8, 0.2, 0.1, 1.0]))
            
            self.sigmoid_params = popt
            self.sigmoid_covariance = pcov
            
            # Calculate R²
            alpha_pred = sigmoid_function(p_values, *popt)
            ss_res = np.sum((alpha_values - alpha_pred)**2)
            ss_tot = np.sum((alpha_values - np.mean(alpha_values))**2)
            self.sigmoid_r2 = 1 - ss_res / ss_tot
            
            print(f"✓ Sigmoid fit successful!")
            print(f"  p_c = {popt[0]:.4f} ± {np.sqrt(pcov[0,0]):.4f}")
            print(f"  width = {popt[1]:.4f} ± {np.sqrt(pcov[1,1]):.4f}")
            print(f"  α_min = {popt[2]:.4f} ± {np.sqrt(pcov[2,2]):.4f}")
            print(f"  α_max = {popt[3]:.4f} ± {np.sqrt(pcov[3,3]):.4f}")
            print(f"  R² = {self.sigmoid_r2:.4f}")
            
            return True
            
        except Exception as e:
            print(f"✗ Sigmoid fitting failed: {e}")
            return False
    
    def add_sigmoid_predictions(self, results_df):
        """Add sigmoid predictions to results DataFrame"""
        
        if self.sigmoid_params is None:
            return results_df
        
        def sigmoid_function(p, p_c, width, alpha_min, alpha_max):
            alpha_min = max(0.0, alpha_min)
            alpha_max = min(1.0, alpha_max)
            return alpha_min + (alpha_max - alpha_min) / (1 + np.exp((p - p_c) / width))
        
        # Add sigmoid predictions
        p_values = results_df['p'].values
        alpha_sigmoid = sigmoid_function(p_values, *self.sigmoid_params)
        
        results_df['alpha_sigmoid'] = alpha_sigmoid
        results_df['alpha_residual'] = results_df['alpha_opt'] - alpha_sigmoid
        
        return results_df
    
    def calculate_continuous_parameters(self, results_df):
        """Calculate continuous viscoelastic parameters using sigmoid α(p)"""
        
        if self.sigmoid_params is None:
            return results_df
        
        # Create fine p-grid for continuous parameters
        p_fine = np.linspace(min(results_df['p']), max(results_df['p']), 1000)
        alpha_fine = self.alpha_sigmoid_function(p_fine)
        
        # Calculate continuous parameters
        G_prime_fine = self.calculate_G_prime(alpha_fine)
        G_double_prime_fine = self.calculate_G_double_prime(alpha_fine)
        delta_fine = self.calculate_phase_angle(alpha_fine)
        tan_delta_fine = self.calculate_loss_tangent(alpha_fine)
        
        # Store continuous parameter functions
        self.continuous_params = {
            'p_fine': p_fine,
            'alpha_fine': alpha_fine,
            'G_prime_fine': G_prime_fine,
            'G_double_prime_fine': G_double_prime_fine,
            'delta_fine': delta_fine,
            'tan_delta_fine': tan_delta_fine
        }
        
        print(f"✓ Continuous parameters calculated for {len(p_fine)} p-values")
        
        return results_df
    
    def alpha_sigmoid_function(self, p_values):
        """Calculate α values using fitted sigmoid function"""
        
        if self.sigmoid_params is None:
            return None
        
        def sigmoid_function(p, p_c, width, alpha_min, alpha_max):
            alpha_min = max(0.0, alpha_min)
            alpha_max = min(1.0, alpha_max)
            return alpha_min + (alpha_max - alpha_min) / (1 + np.exp((p - p_c) / width))
        
        return sigmoid_function(p_values, *self.sigmoid_params)
    
    def calculate_G_prime(self, alpha_values, G0=1.0, omega=1.0):
        """Calculate storage modulus G'(ω)"""
        G_prime = np.zeros_like(alpha_values)
        
        for i, alpha in enumerate(alpha_values):
            if alpha <= 0:
                G_prime[i] = G0  # Solid: constant
            elif alpha >= 1:
                G_prime[i] = G0  # Liquid: constant
            else:
                G_prime[i] = G0 * (omega ** alpha)  # Viscoelastic: power law
        
        return G_prime
    
    def calculate_G_double_prime(self, alpha_values, G0=1.0, omega=1.0):
        """Calculate loss modulus G''(ω)"""
        G_double_prime = np.zeros_like(alpha_values)
        
        for i, alpha in enumerate(alpha_values):
            if alpha <= 0:
                G_double_prime[i] = 0.0  # Solid: no loss
            elif alpha >= 1:
                G_double_prime[i] = G0  # Liquid: viscous
            else:
                G_double_prime[i] = G0 * (omega ** alpha)  # Viscoelastic: power law
        
        return G_double_prime
    
    def calculate_phase_angle(self, alpha_values):
        """Calculate phase angle δ from α"""
        # δ = πα/2 for power law materials
        delta_rad = np.pi * alpha_values / 2
        delta_deg = delta_rad * 180 / np.pi
        return delta_deg
    
    def calculate_loss_tangent(self, alpha_values):
        """Calculate loss tangent tan δ from α"""
        # For power law materials, tan δ depends on α
        tan_delta = np.zeros_like(alpha_values)
        
        for i, alpha in enumerate(alpha_values):
            if alpha <= 0:
                tan_delta[i] = 0.0  # Solid: no loss
            elif alpha >= 1:
                tan_delta[i] = 100.0  # Liquid: purely viscous
            else:
                # For intermediate α, calculate based on material properties
                # This is a simplified model - could be refined
                tan_delta[i] = np.tan(np.pi * alpha / 2)
                # Ensure reasonable bounds
                tan_delta[i] = np.clip(tan_delta[i], 0.0, 100.0)
        
        return tan_delta
    
    def get_parameter_at_p(self, p_value, parameter_name):
        """Get continuous parameter value at specific p-value"""
        
        if self.continuous_params is None:
            return None
        
        # Find closest p-value in fine grid
        p_fine = self.continuous_params['p_fine']
        idx = np.argmin(np.abs(p_fine - p_value))
        
        if parameter_name == 'alpha':
            return self.continuous_params['alpha_fine'][idx]
        elif parameter_name == 'G_prime':
            return self.continuous_params['G_prime_fine'][idx]
        elif parameter_name == 'G_double_prime':
            return self.continuous_params['G_double_prime_fine'][idx]
        elif parameter_name == 'delta':
            return self.continuous_params['delta_fine'][idx]
        elif parameter_name == 'tan_delta':
            return self.continuous_params['tan_delta_fine'][idx]
        else:
            return None

def main():
    """Test the hybrid analyzer"""
    
    print("=== HYBRID ALPHA ANALYZER TEST ===")
    
    # Load the new dataset
    df = pd.read_csv("../matlab/p_output_NEW34.csv")
    
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
    print(f"Found {len(p_values)} p-values")
    
    # Initialize hybrid analyzer
    analyzer = HybridAlphaAnalyzer()
    
    # Analyze dataset
    results = analyzer.analyze_dataset(df, p_values)
    
    if results is not None and len(results) > 0:
        print(f"\n=== HYBRID ANALYSIS COMPLETE ===")
        print(f"Total p-values analyzed: {len(results)}")
        
        # Classification summary
        strategy_counts = results['strategy'].value_counts()
        print(f"\nRegime Classification:")
        for strategy, count in strategy_counts.items():
            print(f"  {strategy}: {count} p-values")
        
        method_counts = results['classification_method'].value_counts()
        print(f"\nClassification Methods:")
        for method, count in method_counts.items():
            print(f"  {method}: {count} p-values")
        
        # Check sigmoid fitting
        if analyzer.sigmoid_params is not None:
            print(f"\n✓ Sigmoid function fitted successfully!")
            print(f"  Can now calculate continuous parameters at any p-value")
            
            # Test parameter calculation
            test_p = 0.6384
            alpha_test = analyzer.get_parameter_at_p(test_p, 'alpha')
            delta_test = analyzer.get_parameter_at_p(test_p, 'delta')
            print(f"\nTest at p = {test_p}:")
            print(f"  α = {alpha_test:.4f}")
            print(f"  δ = {delta_test:.2f}°")
    
    else:
        print("Analysis failed")

if __name__ == "__main__":
    main()
