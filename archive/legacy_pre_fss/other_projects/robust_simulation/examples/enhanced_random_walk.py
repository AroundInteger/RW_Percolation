#!/usr/bin/env python3
"""
Enhanced version of random_walk_3d.py with ultra-robust features
"""

import argparse
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent.parent))

from robust_simulation import UltraRobustPercolationSimulation, ResourceLimits

def main():
    parser = argparse.ArgumentParser(description="Enhanced Percolation Random Walk")
    
    parser.add_argument('--L', type=int, default=100, help='Lattice size')
    parser.add_argument('--p', type=float, default=0.3116, help='Occupation probability')  
    parser.add_argument('--steps', type=int, default=100000, help='Number of steps')
    parser.add_argument('--walkers', type=int, default=50, help='Number of walkers')
    parser.add_argument('--output-dir', type=str, default='enhanced_output', help='Output directory')
    parser.add_argument('--test', action='store_true', help='Run quick test')
    
    args = parser.parse_args()
    
    if args.test:
        print("Running quick test...")
        lattice_size, p_value, num_steps, num_walkers = 30, 0.5, 5000, 20
        output_dir = "test_output"
    else:
        lattice_size, p_value, num_steps, num_walkers = args.L, args.p, args.steps, args.walkers
        output_dir = args.output_dir
    
    print(f"Enhanced simulation: L={lattice_size}, p={p_value:.4f}, steps={num_steps:,}")
    
    # Create enhanced simulation
    sim = UltraRobustPercolationSimulation(
        output_dir=output_dir,
        checkpoint_interval=max(num_steps // 10, 5_000),
        msd_calculation_interval=1  # Calculate MSD at every step for accurate analysis
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
        
        return results
        
    except KeyboardInterrupt:
        print("⚠️  Interrupted - checkpoint saved")
        return None
    except Exception as e:
        print(f"❌ Failed: {e}")
        return None

if __name__ == "__main__":
    main()
