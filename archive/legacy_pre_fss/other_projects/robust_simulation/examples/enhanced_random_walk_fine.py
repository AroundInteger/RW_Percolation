#!/usr/bin/env python3
"""
Enhanced version of random_walk_3d.py with ultra-robust features
FINE RESOLUTION VERSION - MSD calculated every 100 steps
"""

import argparse
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent.parent))

from robust_simulation import UltraRobustPercolationSimulation, ResourceLimits

def main():
    parser = argparse.ArgumentParser(description="Enhanced Percolation Random Walk (Fine Resolution)")
    
    parser.add_argument('--L', type=int, default=100, help='Lattice size')
    parser.add_argument('--p', type=float, default=0.3116, help='Occupation probability')  
    parser.add_argument('--steps', type=int, default=100000, help='Number of steps')
    parser.add_argument('--walkers', type=int, default=50, help='Number of walkers')
    parser.add_argument('--output-dir', type=str, default='enhanced_output_fine', help='Output directory')
    parser.add_argument('--test', action='store_true', help='Run quick test')
    
    args = parser.parse_args()
    
    if args.test:
        print("Running quick test...")
        lattice_size, p_value, num_steps, num_walkers = 30, 0.5, 5000, 20
        output_dir = "test_output_fine"
    else:
        lattice_size, p_value, num_steps, num_walkers = args.L, args.p, args.steps, args.walkers
        output_dir = args.output_dir
    
    print(f"Enhanced simulation (FINE RESOLUTION): L={lattice_size}, p={p_value:.4f}, steps={num_steps:,}")
    print(f"MSD calculation interval: 100 steps (will generate {num_steps//100} data points)")
    
    # Create enhanced simulation with FINE resolution
    sim = UltraRobustPercolationSimulation(
        output_dir=output_dir,
        checkpoint_interval=max(num_steps // 10, 5_000),
        msd_calculation_interval=100  # FIXED: Calculate MSD every 100 steps
    )
    
    try:
        results = sim.run_simulation(
            lattice_size=lattice_size,
            p_value=p_value,
            num_steps=num_steps,
            num_walkers=num_walkers,
            random_seed=42
        )
        
        print(f"✅ Success! Generated {len(results)} MSD data points")
        if len(results) > 0:
            print(f"Final MSD: {results['msd'].iloc[-1]:.6f}")
            print(f"First MSD: {results['msd'].iloc[0]:.6f} (at step {results['step'].iloc[0]})")
            print(f"Data range: steps {results['step'].iloc[0]} to {results['step'].iloc[-1]}")
        
        return results
        
    except KeyboardInterrupt:
        print("⚠️  Interrupted - checkpoint saved")
        return None
    except Exception as e:
        print(f"❌ Failed: {e}")
        return None

if __name__ == "__main__":
    main() 