#!/usr/bin/env python3
"""
Improved fine resolution MSD generation with better parameters and analysis
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import os
from pathlib import Path
import time
from datetime import datetime

def rw3d_p_sp_matlab_style(bw, LW, L, xyz0, wt):
    """
    Python implementation matching 3D MATLAB RW3D_P_SP.m
    """
    # Initialize
    r = np.random.randint(1, 7, LW)  # ceil(rand(LW,1)*6)
    Y = np.zeros((LW, 3))
    X = np.zeros((LW, 3))
    Y[0] = xyz0
    X[0] = xyz0
    
    flg = 0
    spc = 0
    
    for ii in range(1, LW):
        xyz0 = Y[ii-1]
        xn, yn, zn = xyz0[0], xyz0[1], xyz0[2]
        xyzp0 = X[ii-1]
        xp, yp, zp = xyzp0[0], xyzp0[1], xyzp0[2]
        
        if flg == 0:
            # Move in random direction (6 directions in 3D)
            if r[ii] == 1:
                xn += 1
                xp += 1
            elif r[ii] == 2:
                yn += 1
                yp += 1
            elif r[ii] == 3:
                zn += 1
                zp += 1
            elif r[ii] == 4:
                xn -= 1
                xp -= 1
            elif r[ii] == 5:
                yn -= 1
                yp -= 1
            elif r[ii] == 6:
                zn -= 1
                zp -= 1
            
            # Apply periodic boundary conditions (mod(xn-1,L) + 1)
            xn = ((xn - 1) % L) + 1
            yn = ((yn - 1) % L) + 1
            zn = ((zn - 1) % L) + 1
            
            # Check if move is allowed (convert to 0-based indexing for array access)
            if bw[int(xn)-1, int(yn)-1, int(zn)-1] == 0:  # Free position
                Y[ii] = [xn, yn, zn]
                X[ii] = [xp, yp, zp]
            else:  # Blocked
                Y[ii] = xyz0
                X[ii] = xyzp0
                flg = 1
                spc = 0
                WT = max(1, int(abs(np.random.normal(wt[0], wt[1]))))
        else:
            spc += 1
            if spc > WT:
                flg = 0
                spc = 0
            Y[ii] = xyz0
            X[ii] = xyzp0
    
    return Y, X

def generate_3d_lattice(L, p, seed=None):
    """
    Generate 3D lattice with occupation probability p
    """
    if seed is not None:
        np.random.seed(seed)
    
    R = np.random.random((L, L, L))
    bw = R < p  # bw = 1 means occupied (obstacle), bw = 0 means free
    
    return bw

def run_single_simulation(L, LW, NW, p, seed=None, save_data=True, output_dir="improved_fine_resolution_data"):
    """
    Run single simulation for given p value
    """
    print(f"Running simulation: p = {p:.4f}, L = {L}, LW = {LW}, NW = {NW}")
    
    # Create output directory
    if save_data:
        os.makedirs(output_dir, exist_ok=True)
        p_dir = os.path.join(output_dir, f"p_{p:.4f}")
        os.makedirs(p_dir, exist_ok=True)
    
    # Generate 3D lattice
    bw = generate_3d_lattice(L, p, seed)
    
    # Find free positions in 3D
    free_positions = np.where(bw == 0)
    px, py, pz = free_positions[0], free_positions[1], free_positions[2]
    N_rsp = len(px)
    
    if N_rsp < NW:
        print(f"Warning: Only {N_rsp} free positions for {NW} walkers")
        return None, None, None
    
    # Initialize walkers at random free positions
    if seed is not None:
        np.random.seed(seed + 1000)  # Different seed for walker initialization
    rp = np.random.randint(0, N_rsp, NW)
    rsp = np.column_stack([px[rp], py[rp], pz[rp]])
    
    # Arrays to store positions
    x = np.zeros((LW, NW))
    y = np.zeros((LW, NW))
    z = np.zeros((LW, NW))
    
    # Run random walks for each walker
    for i_rw in range(NW):
        if i_rw % 5 == 0:
            print(f"  Walker {i_rw+1}/{NW}")
        
        xyz, xyzp = rw3d_p_sp_matlab_style(bw, LW, L, rsp[i_rw], wt=[20, 5])
        x[:, i_rw] = xyzp[:, 0]
        y[:, i_rw] = xyzp[:, 1]
        z[:, i_rw] = xyzp[:, 2]
    
    # Calculate MSD for every step
    dx = x - np.tile(x[0, :], (LW, 1))
    dy = y - np.tile(y[0, :], (LW, 1))
    dz = z - np.tile(z[0, :], (LW, 1))
    
    # No PBC correction needed since we're using unwrapped positions
    sd = dx**2 + dy**2 + dz**2
    msd = np.mean(sd, axis=1)
    
    t = np.arange(1, LW + 1)
    
    # Save data
    if save_data:
        results_df = pd.DataFrame({
            'tau': t,
            'msd': msd
        })
        
        filename = os.path.join(p_dir, f"msd_results_L{L}_p{p:.4f}.csv")
        results_df.to_csv(filename, index=False)
        print(f"  Data saved to: {filename}")
    
    return t, msd, bw

def improved_local_alpha_analysis(t, msd, window_size=None, min_points=10):
    """
    Improved local α analysis for changepoint detection
    """
    if window_size is None:
        window_size = min(50, len(t) // 20)  # Larger window for better statistics
    
    # Remove first few points to avoid zero MSD
    start_idx = max(20, window_size // 2)
    end_idx = len(t) - window_size // 2
    
    alpha_values = []
    alpha_errors = []
    tau_values = []
    
    for i in range(start_idx, end_idx):
        # Define window
        window_start = i - window_size // 2
        window_end = i + window_size // 2
        
        t_window = t[window_start:window_end]
        msd_window = msd[window_start:window_end]
        
        # Check if we have enough points and all MSD values are positive
        if len(t_window) >= min_points and np.all(msd_window > 0):
            # Fit power law
            ln_t = np.log10(t_window)
            ln_msd = np.log10(msd_window)
            
            try:
                coeffs = np.polyfit(ln_t, ln_msd, 1)
                alpha = coeffs[0]
                
                # Calculate R² for quality assessment
                msd_pred = 10**(alpha * ln_t + coeffs[1])
                ss_res = np.sum((msd_window - msd_pred) ** 2)
                ss_tot = np.sum((msd_window - np.mean(msd_window)) ** 2)
                
                # Avoid division by zero
                if ss_tot > 0:
                    r_squared = 1 - (ss_res / ss_tot)
                else:
                    r_squared = 0
                
                alpha_values.append(alpha)
                alpha_errors.append(1 - r_squared)  # Use (1 - R²) as error measure
                tau_values.append(t[i])
                
            except (np.linalg.LinAlgError, ValueError):
                # Skip this point if fitting fails
                continue
    
    return np.array(tau_values), np.array(alpha_values), np.array(alpha_errors)

def find_changepoint(tau_values, alpha_values, alpha_errors, quality_threshold=0.1):
    """
    Find changepoint based on α analysis
    """
    if len(alpha_values) == 0:
        return None, None, None
    
    # Find points with good quality (low error)
    good_quality = alpha_errors < quality_threshold
    
    if not np.any(good_quality):
        return None, None, None
    
    # Use the first point with good quality as changepoint
    first_good_idx = np.where(good_quality)[0][0]
    tau_cr = tau_values[first_good_idx]
    alpha_opt = alpha_values[first_good_idx]
    alpha_error = alpha_errors[first_good_idx]
    
    return tau_cr, alpha_opt, alpha_error

def run_improved_fine_resolution(p_c_prime=0.6884, transition_width=0.08, resolution=0.01):
    """
    Run improved fine resolution MSD generation
    """
    print("=== Improved Fine Resolution MSD Generation ===")
    print(f"Critical point: p_c' = {p_c_prime}")
    print(f"Transition width: ±{transition_width}")
    print(f"Resolution: {resolution}")
    print()
    
    # Better parameters
    L = 80  # Larger lattice
    LW = 50000  # More steps
    NW = 8  # More walkers
    
    # Define p values with fine resolution in transition region
    p_min = max(0, p_c_prime - transition_width)
    p_max = min(1, p_c_prime + transition_width)
    
    # Create p values
    p_values = []
    
    # Coarse resolution outside transition region
    p_values.extend([0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6])
    p_values.append(p_min)
    
    # Fine resolution in transition region
    p_values.extend(np.arange(p_min + resolution, p_max, resolution))
    p_values.append(p_max)
    
    # Coarse resolution beyond transition region
    p_values.extend([0.75, 0.8, 0.85, 0.9])
    
    p_values = np.array(p_values)
    p_values = p_values[p_values <= 0.95]  # Avoid p = 1.0
    p_values = np.unique(p_values)  # Remove duplicates
    
    print(f"Total p values: {len(p_values)}")
    print(f"p range: [{p_values.min():.4f}, {p_values.max():.4f}]")
    print(f"p values: {p_values}")
    print()
    
    # Results storage
    results = {
        'p_values': [],
        'tau_cr': [],
        'alpha_opt': [],
        'alpha_error': [],
        'regime': [],
        'distance_from_critical': []
    }
    
    # Run simulations
    start_time = time.time()
    
    for i, p in enumerate(p_values):
        print(f"Progress: {i+1}/{len(p_values)} ({(i+1)/len(p_values)*100:.1f}%)")
        
        # Run simulation
        t, msd, bw = run_single_simulation(L, LW, NW, p, seed=42+i, save_data=True)
        
        if t is None:
            print(f"  Skipping p = {p:.4f} (insufficient free space)")
            continue
        
        # Analyze α and find changepoint
        tau_alpha, alpha_values, alpha_errors = improved_local_alpha_analysis(t, msd)
        tau_cr, alpha_opt, alpha_error = find_changepoint(tau_alpha, alpha_values, alpha_errors)
        
        # Determine regime
        if p < p_c_prime - 0.05:
            regime = 'LIQUID'
        elif abs(p - p_c_prime) < 0.05:
            regime = 'CRITICAL'
        else:
            regime = 'SOLID'
        
        # Store results
        results['p_values'].append(p)
        results['tau_cr'].append(tau_cr if tau_cr is not None else np.nan)
        results['alpha_opt'].append(alpha_opt if alpha_opt is not None else np.nan)
        results['alpha_error'].append(alpha_error if alpha_error is not None else np.nan)
        results['regime'].append(regime)
        results['distance_from_critical'].append(abs(p - p_c_prime))
        
        # Print summary
        if tau_cr is not None:
            print(f"  p = {p:.4f} ({regime}): τ_cr = {tau_cr:.2e}, α = {alpha_opt:.3f}, error = {alpha_error:.3f}")
        else:
            print(f"  p = {p:.4f} ({regime}): No changepoint found")
    
    elapsed_time = time.time() - start_time
    print(f"\nTotal time: {elapsed_time/60:.2f} minutes")
    
    # Convert to DataFrame
    results_df = pd.DataFrame(results)
    
    # Save results
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    results_filename = f"improved_fine_resolution_results_{timestamp}.csv"
    results_df.to_csv(results_filename, index=False)
    print(f"Results saved to: {results_filename}")
    
    return results_df, p_values

def analyze_improved_results(results_df, p_c_prime=0.6884):
    """
    Analyze results from improved fine resolution MSD generation
    """
    print("\n=== Improved Fine Resolution Analysis ===")
    
    # Filter out NaN values for analysis
    valid_data = results_df.dropna()
    
    if len(valid_data) == 0:
        print("No valid data for analysis")
        return None, None
    
    print(f"Valid data points: {len(valid_data)}")
    
    # Power-law analysis
    dist_from_critical = valid_data['distance_from_critical'].values
    tau_cr = valid_data['tau_cr'].values
    
    # Exclude critical point (distance = 0)
    non_critical_mask = dist_from_critical > 0
    dist_non_critical = dist_from_critical[non_critical_mask]
    tau_non_critical = tau_cr[non_critical_mask]
    
    if len(dist_non_critical) > 1:
        # Fit power law
        log_dist = np.log10(dist_non_critical)
        log_tau = np.log10(tau_non_critical)
        
        coeffs = np.polyfit(log_dist, log_tau, 1)
        exponent = coeffs[0]
        intercept = coeffs[1]
        
        # Calculate R²
        tau_pred = 10**(exponent * log_dist + intercept)
        ss_res = np.sum((tau_non_critical - tau_pred) ** 2)
        ss_tot = np.sum((tau_non_critical - np.mean(tau_non_critical)) ** 2)
        r_squared = 1 - (ss_res / ss_tot)
        
        print(f"Power-law exponent: ν = {exponent:.3f}")
        print(f"R² = {r_squared:.3f}")
        print(f"Equation: τ_cr ∝ |p - p_c'|^{exponent:.3f}")
    else:
        print("Insufficient data for power-law analysis")
        exponent = None
        r_squared = None
    
    # Regime analysis
    print(f"\nRegime distribution:")
    regime_counts = results_df['regime'].value_counts()
    for regime, count in regime_counts.items():
        print(f"  {regime}: {count} points")
    
    # α analysis by regime
    print(f"\nα analysis by regime:")
    for regime in ['LIQUID', 'CRITICAL', 'SOLID']:
        regime_data = valid_data[valid_data['regime'] == regime]
        if len(regime_data) > 0:
            alpha_mean = regime_data['alpha_opt'].mean()
            alpha_std = regime_data['alpha_opt'].std()
            print(f"  {regime}: α = {alpha_mean:.3f} ± {alpha_std:.3f} (n={len(regime_data)})")
    
    return exponent, r_squared

def plot_improved_results(results_df, p_c_prime=0.6884):
    """
    Plot results from improved fine resolution MSD generation
    """
    print("\n=== Generating Plots ===")
    
    # Filter out NaN values
    valid_data = results_df.dropna()
    
    if len(valid_data) == 0:
        print("No valid data for plotting")
        return
    
    # Create figure
    fig, axes = plt.subplots(2, 2, figsize=(15, 12))
    
    # Plot 1: τ_cr vs p
    ax1 = axes[0, 0]
    
    # Color by regime
    colors = {'LIQUID': 'blue', 'CRITICAL': 'red', 'SOLID': 'green'}
    
    for regime in ['LIQUID', 'CRITICAL', 'SOLID']:
        regime_data = valid_data[valid_data['regime'] == regime]
        if len(regime_data) > 0:
            ax1.semilogy(regime_data['p_values'], regime_data['tau_cr'], 
                        'o', color=colors[regime], label=regime, markersize=6)
    
    ax1.axvline(p_c_prime, color='black', linestyle='--', linewidth=2, label='p_c\'')
    ax1.set_xlabel('p')
    ax1.set_ylabel('τ_cr')
    ax1.set_title('Changepoint Time vs p')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: Power-law relationship
    ax2 = axes[0, 1]
    
    dist_from_critical = valid_data['distance_from_critical'].values
    tau_cr = valid_data['tau_cr'].values
    
    # Exclude critical point
    non_critical_mask = dist_from_critical > 0
    dist_non_critical = dist_from_critical[non_critical_mask]
    tau_non_critical = tau_cr[non_critical_mask]
    
    if len(dist_non_critical) > 1:
        ax2.loglog(dist_non_critical, tau_non_critical, 'bo', markersize=6, label='Data')
        
        # Fit and plot power law
        log_dist = np.log10(dist_non_critical)
        log_tau = np.log10(tau_non_critical)
        coeffs = np.polyfit(log_dist, log_tau, 1)
        exponent = coeffs[0]
        
        dist_range = np.logspace(np.log10(dist_non_critical.min()), 
                                np.log10(dist_non_critical.max()), 100)
        tau_fit = 10**(exponent * np.log10(dist_range) + coeffs[1])
        ax2.loglog(dist_range, tau_fit, 'r-', linewidth=2, 
                  label=f'Fit: ν = {exponent:.3f}')
    
    ax2.set_xlabel('|p - p_c\'|')
    ax2.set_ylabel('τ_cr')
    ax2.set_title('Power-Law Relationship')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: α vs p
    ax3 = axes[1, 0]
    
    for regime in ['LIQUID', 'CRITICAL', 'SOLID']:
        regime_data = valid_data[valid_data['regime'] == regime]
        if len(regime_data) > 0:
            ax3.plot(regime_data['p_values'], regime_data['alpha_opt'], 
                    'o', color=colors[regime], label=regime, markersize=6)
    
    # Add theoretical lines
    ax3.axhline(1.0, color='blue', linestyle='--', alpha=0.5, label='α = 1.0 (Liquid)')
    ax3.axhline(0.5, color='red', linestyle='--', alpha=0.5, label='α = 0.5 (Critical)')
    ax3.axhline(0.0, color='green', linestyle='--', alpha=0.5, label='α = 0.0 (Solid)')
    ax3.axvline(p_c_prime, color='black', linestyle='--', linewidth=2, label='p_c\'')
    
    ax3.set_xlabel('p')
    ax3.set_ylabel('α')
    ax3.set_title('Optimal α vs p')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    ax3.set_ylim(-0.1, 1.1)
    
    # Plot 4: α error vs p
    ax4 = axes[1, 1]
    
    for regime in ['LIQUID', 'CRITICAL', 'SOLID']:
        regime_data = valid_data[valid_data['regime'] == regime]
        if len(regime_data) > 0:
            ax4.semilogy(regime_data['p_values'], regime_data['alpha_error'], 
                        'o', color=colors[regime], label=regime, markersize=6)
    
    ax4.axhline(0.1, color='black', linestyle='--', alpha=0.5, label='Quality threshold')
    ax4.axvline(p_c_prime, color='black', linestyle='--', linewidth=2, label='p_c\'')
    
    ax4.set_xlabel('p')
    ax4.set_ylabel('α Error (1 - R²)')
    ax4.set_title('α Quality vs p')
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    # Save plot
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    plot_filename = f"improved_fine_resolution_analysis_{timestamp}.png"
    plt.savefig(plot_filename, dpi=300, bbox_inches='tight')
    print(f"Plot saved to: {plot_filename}")
    
    plt.show()

def main():
    """
    Main function for improved fine resolution MSD generation
    """
    print("=== Improved Fine Resolution MSD Generation ===")
    print("This will generate MSD curves with fine resolution through the transition region")
    print("This should take about 30-60 minutes")
    print()
    
    # Parameters
    p_c_prime = 0.6884  # Critical point
    transition_width = 0.08  # Width of transition region
    resolution = 0.01  # Resolution in transition region
    
    # Generate improved fine resolution MSD curves
    results_df, p_values = run_improved_fine_resolution(
        p_c_prime=p_c_prime,
        transition_width=transition_width,
        resolution=resolution
    )
    
    # Analyze results
    exponent, r_squared = analyze_improved_results(results_df, p_c_prime)
    
    # Plot results
    plot_improved_results(results_df, p_c_prime)
    
    print("\n=== Analysis Complete ===")
    if exponent is not None:
        print(f"Power-law exponent: ν = {exponent:.3f}")
        print(f"R² = {r_squared:.3f}")
        print(f"Equation: τ_cr ∝ |p - p_c'|^{exponent:.3f}")
    else:
        print("Could not determine power-law exponent (insufficient data)")
    
    return results_df, exponent, r_squared

if __name__ == "__main__":
    main() 