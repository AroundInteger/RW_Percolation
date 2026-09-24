#!/usr/bin/env python3
"""
Simple test of free random walk behavior
"""

import numpy as np
import matplotlib.pyplot as plt

def simple_free_random_walk(num_steps=10000, num_walkers=100, lattice_size=100):
    """
    Simple free random walk simulation
    """
    print(f"=== Simple Free Random Walk Test ===")
    print(f"Steps: {num_steps}")
    print(f"Walkers: {num_walkers}")
    print(f"Lattice size: {lattice_size}")
    print()
    
    # Initialize walkers at random positions
    np.random.seed(42)
    walker_positions = np.random.randint(0, lattice_size, size=(num_walkers, 3))
    initial_positions = walker_positions.copy()
    
    # Possible moves (6 directions in 3D)
    moves = np.array([
        [1, 0, 0], [-1, 0, 0],
        [0, 1, 0], [0, -1, 0],
        [0, 0, 1], [0, 0, -1]
    ])
    
    # Track MSD at regular intervals
    msd_data = []
    interval = 100
    
    for step in range(num_steps + 1):
        # Calculate MSD every interval steps
        if step % interval == 0 and step > 0:
            displacements = walker_positions - initial_positions
            
            # Apply periodic boundary conditions
            for dim in range(3):
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
            msd = np.mean(squared_displacements)
            
            msd_data.append({
                'step': step,
                'msd': msd
            })
            
            if len(msd_data) <= 10:  # Print first 10 data points
                print(f"Step {step:5d}: MSD = {msd:8.2f}")
        
        # Move walkers (free random walk - no obstacles)
        if step < num_steps:
            move_indices = np.random.randint(0, 6, num_walkers)
            proposed_moves = moves[move_indices]
            new_positions = (walker_positions + proposed_moves) % lattice_size
            walker_positions = new_positions
    
    # Analyze results
    steps = np.array([d['step'] for d in msd_data])
    msd_values = np.array([d['msd'] for d in msd_data])
    
    # Fit linear model
    coeffs = np.polyfit(steps, msd_values, 1)
    slope = coeffs[0]
    intercept = coeffs[1]
    
    # Calculate R²
    msd_predicted = slope * steps + intercept
    ss_res = np.sum((msd_values - msd_predicted) ** 2)
    ss_tot = np.sum((msd_values - np.mean(msd_values)) ** 2)
    r_squared = 1 - (ss_res / ss_tot)
    
    print(f"\n=== Analysis ===")
    print(f"Linear fit: MSD = {slope:.6f} × t + {intercept:.2f}")
    print(f"R²: {r_squared:.6f}")
    print(f"Effective diffusion coefficient: D = {slope/6:.6f}")
    print(f"Theoretical D for simple cubic: D = 0.166667")
    print(f"Ratio: {slope/6/0.166667:.3f}")
    
    # Plot results
    plt.figure(figsize=(12, 5))
    
    # Linear scale
    plt.subplot(1, 2, 1)
    plt.plot(steps, msd_values, 'b-', linewidth=2, label='Simulation')
    plt.plot(steps, slope * steps + intercept, 'r--', linewidth=2, label=f'Linear fit (R²={r_squared:.3f})')
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('Free Random Walk - Linear Scale')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    # Log-log scale
    plt.subplot(1, 2, 2)
    plt.loglog(steps, msd_values, 'b-', linewidth=2, label='Simulation')
    plt.loglog(steps, steps, 'g:', linewidth=1, label='Slope = 1 (α = 1.0)')
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('Free Random Walk - Log-Log Scale')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('free_rw_simple_test.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    return msd_data, slope, r_squared

if __name__ == "__main__":
    # Test with different parameters
    print("Test 1: 100 walkers, 10k steps")
    msd_data1, slope1, r1 = simple_free_random_walk(10000, 100, 100)
    
    print(f"\n" + "="*50)
    print("Test 2: 10 walkers, 10k steps (like our simulation)")
    msd_data2, slope2, r2 = simple_free_random_walk(10000, 10, 100)
    
    print(f"\n" + "="*50)
    print("Comparison:")
    print(f"100 walkers: slope = {slope1:.6f}, R² = {r1:.6f}")
    print(f"10 walkers:  slope = {slope2:.6f}, R² = {r2:.6f}") 