#!/usr/bin/env python3
"""
ANALYZE ALPHA DETERMINATION
Detailed examination of how α values are determined and changepoints are located
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path
import sys

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))

def load_ensemble_data(p: float, seed: int):
    """Load ensemble simulation data"""
    data_path = Path(f"../ensemble_simulations/seed_{seed:02d}/p_{p:.4f}/msd_results_L500_p{p:.4f}.csv")
    data = pd.read_csv(data_path)
    
    if 'tau' in data.columns:
        t = data['tau'].values
    else:
        t = data.iloc[:, 0].values
    
    if 'msd' in data.columns:
        msd = data['msd'].values
    else:
        msd = data.iloc[:, 1].values
    
    t = np.maximum(t, 1e-3)
    msd = np.maximum(msd, 1e-6)
    
    return t, msd

def robust_alpha_analysis_detailed(t, msd, p, seed):
    """Detailed α analysis with full output for examination"""
    
    # Parameters
    window_size = min(50, len(t) // 20)
    start_idx = max(10, window_size // 2)
    end_idx = len(t) - window_size // 2
    
    print(f"=== DETAILED α ANALYSIS ===")
    print(f"p = {p:.4f}, seed = {seed:02d}")
    print(f"Data points: {len(t)}")
    print(f"Window size: {window_size}")
    print(f"Analysis range: {start_idx} to {end_idx}")
    print(f"Time range: {t[start_idx]:.1f} to {t[end_idx]:.1f}")
    print()
    
    alpha_values = []
    alpha_errors = []
    tau_values = []
    r_squared_values = []
    intercept_values = []
    
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
                intercept = coeffs[1]
                
                # Calculate R²
                msd_pred = 10**(alpha * log_t + intercept)
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
                intercept_values.append(intercept)
                
            except (np.linalg.LinAlgError, ValueError):
                continue
    
    if not alpha_values:
        print("No valid α values found!")
        return None
    
    # Find changepoint
    good_quality = np.array(alpha_errors) < 0.1
    
    if not np.any(good_quality):
        best_idx = np.argmin(alpha_errors)
        tau_cr = tau_values[best_idx]
        alpha_opt = alpha_values[best_idx]
        alpha_error = alpha_errors[best_idx]
        method = "best_available"
    else:
        first_good_idx = np.where(good_quality)[0][0]
        tau_cr = tau_values[first_good_idx]
        alpha_opt = alpha_values[first_good_idx]
        alpha_error = alpha_errors[first_good_idx]
        method = "first_good_quality"
    
    # Analysis summary
    print(f"=== ANALYSIS RESULTS ===")
    print(f"Total points analyzed: {len(alpha_values)}")
    print(f"Good quality points (error < 0.1): {np.sum(good_quality)}")
    print(f"Changepoint method: {method}")
    print(f"τ_cr = {tau_cr:.2e}")
    print(f"α_opt = {alpha_opt:.6f}")
    print(f"α_error = {alpha_error:.6f}")
    print(f"R² = {1 - alpha_error:.6f}")
    print()
    
    # Statistical summary
    print(f"=== STATISTICAL SUMMARY ===")
    print(f"α range: [{min(alpha_values):.3f}, {max(alpha_values):.3f}]")
    print(f"α mean: {np.mean(alpha_values):.3f}")
    print(f"α std: {np.std(alpha_values):.3f}")
    print(f"Error range: [{min(alpha_errors):.3f}, {max(alpha_errors):.3f}]")
    print(f"Error mean: {np.mean(alpha_errors):.3f}")
    print(f"R² range: [{min(r_squared_values):.3f}, {max(r_squared_values):.3f}]")
    print(f"R² mean: {np.mean(r_squared_values):.3f}")
    print()
    
    # Find optimal range
    print(f"=== OPTIMAL RANGE ANALYSIS ===")
    
    # Find the range where α is most stable
    alpha_array = np.array(alpha_values)
    error_array = np.array(alpha_errors)
    
    # Find consecutive good quality points
    good_indices = np.where(error_array < 0.1)[0]
    
    if len(good_indices) > 0:
        # Find longest consecutive sequence
        consecutive_ranges = []
        start_idx = good_indices[0]
        prev_idx = good_indices[0]
        
        for idx in good_indices[1:]:
            if idx != prev_idx + 1:
                consecutive_ranges.append((start_idx, prev_idx))
                start_idx = idx
            prev_idx = idx
        consecutive_ranges.append((start_idx, prev_idx))
        
        # Find longest range
        longest_range = max(consecutive_ranges, key=lambda x: x[1] - x[0])
        start_range, end_range = longest_range
        
        print(f"Longest consecutive good quality range: {start_range} to {end_range}")
        print(f"Range length: {end_range - start_range + 1} points")
        print(f"Time range: {tau_values[start_range]:.2e} to {tau_values[end_range]:.2e}")
        print(f"α in range: {alpha_array[start_range:end_range+1]}")
        print(f"α mean in range: {np.mean(alpha_array[start_range:end_range+1]):.6f}")
        print(f"α std in range: {np.std(alpha_array[start_range:end_range+1]):.6f}")
        
        # Check if our selected point is in the optimal range
        if method == "first_good_quality":
            if start_range <= first_good_idx <= end_range:
                print(f"✓ Selected point is in optimal range")
            else:
                print(f"⚠ Selected point is outside optimal range")
    else:
        print("No consecutive good quality ranges found")
    
    print()
    
    return {
        'tau_values': tau_values,
        'alpha_values': alpha_values,
        'alpha_errors': alpha_errors,
        'r_squared_values': r_squared_values,
        'intercept_values': intercept_values,
        'tau_cr': tau_cr,
        'alpha_opt': alpha_opt,
        'alpha_error': alpha_error,
        'method': method,
        'window_size': window_size,
        'total_points_analyzed': len(alpha_values)
    }

def plot_alpha_analysis(results, p, seed):
    """Plot detailed α analysis"""
    
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 10))
    
    tau_values = results['tau_values']
    alpha_values = results['alpha_values']
    alpha_errors = results['alpha_errors']
    r_squared_values = results['r_squared_values']
    tau_cr = results['tau_cr']
    alpha_opt = results['alpha_opt']
    
    # Plot 1: α vs time
    ax1.semilogx(tau_values, alpha_values, 'b-', alpha=0.7, linewidth=1)
    ax1.axvline(tau_cr, color='red', linestyle='--', label=f'τ_cr = {tau_cr:.2e}')
    ax1.axhline(alpha_opt, color='green', linestyle='--', label=f'α_opt = {alpha_opt:.3f}')
    ax1.set_xlabel('Time (τ)')
    ax1.set_ylabel('α')
    ax1.set_title(f'α vs Time (p = {p:.4f}, seed = {seed:02d})')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: Error vs time
    ax2.semilogx(tau_values, alpha_errors, 'r-', alpha=0.7, linewidth=1)
    ax2.axvline(tau_cr, color='red', linestyle='--', label=f'τ_cr = {tau_cr:.2e}')
    ax2.axhline(0.1, color='orange', linestyle='--', label='Quality threshold')
    ax2.set_xlabel('Time (τ)')
    ax2.set_ylabel('Error (1 - R²)')
    ax2.set_title('Error vs Time')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: R² vs time
    ax3.semilogx(tau_values, r_squared_values, 'g-', alpha=0.7, linewidth=1)
    ax3.axvline(tau_cr, color='red', linestyle='--', label=f'τ_cr = {tau_cr:.2e}')
    ax3.axhline(0.9, color='orange', linestyle='--', label='R² threshold')
    ax3.set_xlabel('Time (τ)')
    ax3.set_ylabel('R²')
    ax3.set_title('R² vs Time')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: α histogram
    ax4.hist(alpha_values, bins=20, alpha=0.7, color='blue', edgecolor='black')
    ax4.axvline(alpha_opt, color='red', linestyle='--', label=f'α_opt = {alpha_opt:.3f}')
    ax4.axvline(np.mean(alpha_values), color='green', linestyle='--', label=f'Mean = {np.mean(alpha_values):.3f}')
    ax4.set_xlabel('α')
    ax4.set_ylabel('Frequency')
    ax4.set_title('α Distribution')
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(f'alpha_analysis_p{p:.4f}_seed{seed:02d}.png', dpi=300, bbox_inches='tight')
    plt.show()

def main():
    """Main analysis function"""
    
    # Test cases
    test_cases = [
        (0.0000, 1, "LIQUID"),
        (0.3116, 1, "LIQUID"), 
        (0.6884, 1, "CRITICAL"),
        (0.7500, 1, "SOLID")
    ]
    
    print("=== ALPHA DETERMINATION ANALYSIS ===")
    print("Examining how α values are determined and changepoints are located")
    print("=" * 60)
    
    for p, seed, regime in test_cases:
        print(f"\n{'='*60}")
        print(f"ANALYZING: p = {p:.4f}, seed = {seed:02d}, regime = {regime}")
        print(f"{'='*60}")
        
        try:
            # Load data
            t, msd = load_ensemble_data(p, seed)
            
            # Perform detailed analysis
            results = robust_alpha_analysis_detailed(t, msd, p, seed)
            
            if results:
                # Plot results
                plot_alpha_analysis(results, p, seed)
            
        except Exception as e:
            print(f"Error analyzing p = {p:.4f}, seed = {seed:02d}: {e}")
        
        print(f"\n{'-'*60}")

if __name__ == "__main__":
    main() 