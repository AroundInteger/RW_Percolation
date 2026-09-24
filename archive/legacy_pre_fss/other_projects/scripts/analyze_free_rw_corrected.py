#!/usr/bin/env python3
"""
Analyze free random walk with CORRECTED periodic boundary conditions
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path
import sys

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))

def calculate_corrected_msd(walker_positions, initial_positions, lattice_size):
    """
    Calculate MSD with proper handling of periodic boundary conditions
    """
    displacements = walker_positions - initial_positions
    
    # Apply minimum image convention for periodic boundary conditions
    for dim in range(3):
        # Calculate the shortest distance across the periodic boundary
        displacements[:, dim] = np.where(
            displacements[:, dim] > lattice_size/2,
            displacements[:, dim] - lattice_size,
            displacements[:, dim]
        )
        displacements[:, dim] = np.where(
            displacements[:, dim] < -lattice_size/2,
            displacements[:, dim] + lattice_size,
            displacements[:, dim]
        )
    
    squared_displacements = np.sum(displacements**2, axis=1)
    return np.mean(squared_displacements)

def simulate_free_rw_with_tracking(num_steps=10000, num_walkers=10, lattice_size=100):
    """
    Simulate free random walk with proper displacement tracking
    """
    print(f"=== Free Random Walk with Corrected PBCs ===")
    print(f"Steps: {num_steps}")
    print(f"Walkers: {num_walkers}")
    print(f"Lattice size: {lattice_size}")
    print()
    
    # Initialize walkers
    np.random.seed(42)
    walker_positions = np.random.randint(0, lattice_size, size=(num_walkers, 3))
    initial_positions = walker_positions.copy()
    
    # Track actual displacements (accounting for boundary crossings)
    actual_displacements = np.zeros((num_walkers, 3))
    
    # Possible moves
    moves = np.array([
        [1, 0, 0], [-1, 0, 0],
        [0, 1, 0], [0, -1, 0],
        [0, 0, 1], [0, 0, -1]
    ])
    
    # Track MSD
    msd_data = []
    interval = 100
    
    for step in range(num_steps + 1):
        # Calculate MSD every interval steps
        if step % interval == 0 and step > 0:
            # Use corrected MSD calculation
            msd = calculate_corrected_msd(walker_positions, initial_positions, lattice_size)
            
            msd_data.append({
                'step': step,
                'msd': msd,
                'msd_per_step': msd / step
            })
            
            if len(msd_data) <= 10:
                print(f"Step {step:5d}: MSD = {msd:8.2f}, MSD/step = {msd/step:.6f}")
        
        # Move walkers
        if step < num_steps:
            move_indices = np.random.randint(0, 6, num_walkers)
            proposed_moves = moves[move_indices]
            new_positions = (walker_positions + proposed_moves) % lattice_size
            
            # Update actual displacements (accounting for boundary crossings)
            for i in range(num_walkers):
                for dim in range(3):
                    # Check if boundary was crossed
                    old_pos = walker_positions[i, dim]
                    new_pos = new_positions[i, dim]
                    
                    # If we wrapped around, adjust the actual displacement
                    if new_pos - old_pos > lattice_size/2:  # Wrapped from high to low
                        actual_displacements[i, dim] -= lattice_size
                    elif new_pos - old_pos < -lattice_size/2:  # Wrapped from low to high
                        actual_displacements[i, dim] += lattice_size
                    else:
                        actual_displacements[i, dim] += proposed_moves[i, dim]
            
            walker_positions = new_positions
    
    return msd_data

def analyze_corrected_results(msd_data):
    """
    Analyze the corrected MSD results
    """
    steps = np.array([d['step'] for d in msd_data])
    msd_values = np.array([d['msd'] for d in msd_data])
    msd_per_step = np.array([d['msd_per_step'] for d in msd_data])
    
    # Fit linear model
    coeffs = np.polyfit(steps, msd_values, 1)
    slope = coeffs[0]
    intercept = coeffs[1]
    
    # Calculate R²
    msd_predicted = slope * steps + intercept
    ss_res = np.sum((msd_values - msd_predicted) ** 2)
    ss_tot = np.sum((msd_values - np.mean(msd_values)) ** 2)
    r_squared = 1 - (ss_res / ss_tot)
    
    print(f"\n=== Corrected Analysis ===")
    print(f"Linear fit: MSD = {slope:.6f} × t + {intercept:.2f}")
    print(f"R²: {r_squared:.6f}")
    print(f"Effective diffusion coefficient: D = {slope/6:.6f}")
    print(f"Theoretical D for simple cubic: D = 0.166667")
    print(f"Ratio: {slope/6/0.166667:.3f}")
    
    # Check if MSD/step is constant (should be for free random walk)
    mean_msd_per_step = np.mean(msd_per_step)
    std_msd_per_step = np.std(msd_per_step)
    print(f"MSD/step: mean = {mean_msd_per_step:.6f}, std = {std_msd_per_step:.6f}")
    print(f"Variation in MSD/step: {std_msd_per_step/mean_msd_per_step:.3f}")
    
    return slope, r_squared, mean_msd_per_step

def compare_with_original_data():
    """
    Compare corrected simulation with original data
    """
    print(f"\n=== Comparison with Original Data ===")
    
    # Load original data
    original_file = 'enhanced_output_fine/msd_results_L100_p0.0000.csv'
    if Path(original_file).exists():
        df = pd.read_csv(original_file)
        original_steps = df['step'].values
        original_msd = df['msd'].values
        
        # Fit original data
        coeffs_orig = np.polyfit(original_steps, original_msd, 1)
        slope_orig = coeffs_orig[0]
        r_squared_orig = 1 - (np.sum((original_msd - (slope_orig * original_steps + coeffs_orig[1])) ** 2) / 
                              np.sum((original_msd - np.mean(original_msd)) ** 2))
        
        print(f"Original data:")
        print(f"  Slope: {slope_orig:.6f}")
        print(f"  R²: {r_squared_orig:.6f}")
        print(f"  D = {slope_orig/6:.6f}")
        print(f"  Ratio to theoretical: {slope_orig/6/0.166667:.3f}")
    
    return slope_orig, r_squared_orig

def main():
    # Run corrected simulation
    msd_data = simulate_free_rw_with_tracking(10000, 10, 100)
    
    # Analyze results
    slope_corr, r_squared_corr, msd_per_step = analyze_corrected_results(msd_data)
    
    # Compare with original
    try:
        slope_orig, r_squared_orig = compare_with_original_data()
        
        print(f"\n=== Improvement ===")
        print(f"Slope improvement: {slope_corr/slope_orig:.3f}x")
        print(f"R² improvement: {r_squared_corr/r_squared_orig:.3f}x")
        
    except:
        print("Could not load original data for comparison")
    
    # Plot results
    steps = np.array([d['step'] for d in msd_data])
    msd_values = np.array([d['msd'] for d in msd_data])
    
    plt.figure(figsize=(15, 5))
    
    # Linear scale
    plt.subplot(1, 3, 1)
    plt.plot(steps, msd_values, 'b-', linewidth=2, label='Corrected Simulation')
    
    # Add theoretical line
    theoretical_msd = steps / 6  # D = 1/6
    plt.plot(steps, theoretical_msd, 'r--', linewidth=2, label='Theoretical (D=1/6)')
    
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('Corrected Free Random Walk - Linear Scale')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    # Log-log scale
    plt.subplot(1, 3, 2)
    plt.loglog(steps, msd_values, 'b-', linewidth=2, label='Corrected Simulation')
    plt.loglog(steps, theoretical_msd, 'r--', linewidth=2, label='Theoretical (D=1/6)')
    plt.loglog(steps, steps, 'g:', linewidth=1, label='Slope = 1 (α = 1.0)')
    
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('Corrected Free Random Walk - Log-Log Scale')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    # MSD per step (should be constant)
    plt.subplot(1, 3, 3)
    msd_per_step_values = np.array([d['msd_per_step'] for d in msd_data])
    plt.plot(steps, msd_per_step_values, 'b-', linewidth=2)
    plt.axhline(y=1/6, color='r', linestyle='--', label='Theoretical (1/6)')
    plt.xlabel('Time Step')
    plt.ylabel('MSD / Step')
    plt.title('MSD per Step (Should be Constant)')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('free_rw_corrected_analysis.png', dpi=300, bbox_inches='tight')
    plt.show()

if __name__ == "__main__":
    main() 