#!/usr/bin/env python3
"""
Paper simulation for p = 0.0000
Generated automatically by run_paper_simulations.py
"""

import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))

from robust_simulation import UltraRobustPercolationSimulation

def main():
    print(f"🚀 Starting simulation: p = 0.0000")
    print(f"   Lattice size: 50³")
    print(f"   Steps: 10,000")
    print(f"   Walkers: 100")
    print(f"   Output: test_paper_simulations/p_0.0000")
    
    # Create simulation with optimized settings
    sim = UltraRobustPercolationSimulation(
        output_dir="test_paper_simulations/p_0.0000",
        checkpoint_interval=50000,  # Checkpoint every 50k steps
        msd_calculation_interval=1000  # MSD every 1000 steps (1000 data points)
    )
    
    try:
        results = sim.run_simulation(
            lattice_size=50,
            p_value=0.0,
            num_steps=10000,
            num_walkers=100,
            random_seed=42
        )
        
        if results is not None and len(results) > 0:
            print(f"✅ SUCCESS: {len(results)} data points generated")
            print(f"   Final MSD: {results['msd'].iloc[-1]:.2f}")
            return True
        else:
            print(f"❌ FAILED: No data generated")
            return False
            
    except Exception as e:
        print(f"❌ FAILED: {e}")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
