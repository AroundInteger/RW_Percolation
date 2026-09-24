#!/usr/bin/env python3
"""
Complete study for the paper with four critical p-values
"""

import argparse
import sys
import time
from pathlib import Path

sys.path.append(str(Path(__file__).parent.parent.parent))

from robust_simulation import UltraRobustPercolationSimulation

def run_paper_study(test_mode=False):
    p_values = [
        {"p": 0.0, "name": "free_diffusion", "description": "Free diffusion regime"},
        {"p": 0.3116, "name": "true_gel_point", "description": "True gel point (p_c)"},
        {"p": 0.6884, "name": "apparent_gel_point", "description": "Apparent gel point (p_c')"},
        {"p": 0.75, "name": "confined_regime", "description": "Confined regime"}
    ]
    
    if test_mode:
        sim_params = {"lattice_size": 30, "num_steps": 10_000, "num_walkers": 20}
        print("🧪 Test mode: reduced parameters")
    else:
        sim_params = {"lattice_size": 100, "num_steps": 1_000_000, "num_walkers": 100}
        print("🔬 Research mode: full parameters")
    
    all_results = {}
    successful_runs = 0
    
    for p_info in p_values:
        p_value = p_info["p"]
        description = p_info["description"]
        
        print(f"\n🎯 Starting: {description} (p = {p_value:.4f})")
        
        try:
            output_dir = f"paper_study_results/p_{p_value:.4f}_{p_info['name']}"
            
            sim = UltraRobustPercolationSimulation(
                output_dir=output_dir,
                checkpoint_interval=max(sim_params['num_steps'] // 20, 5_000)
            )
            
            results = sim.run_simulation(
                lattice_size=sim_params['lattice_size'],
                p_value=p_value,
                num_steps=sim_params['num_steps'],
                num_walkers=sim_params['num_walkers'],
                random_seed=42
            )
            
            if results is not None and len(results) > 0:
                print(f"✅ SUCCESS: {len(results)} data points")
                all_results[p_value] = results
                successful_runs += 1
            else:
                print(f"⚠️  FAILED: No data generated")
                
        except Exception as e:
            print(f"❌ FAILED: {e}")
            continue
    
    print(f"\n🎉 Study completed: {successful_runs}/{len(p_values)} successful")
    return all_results

def main():
    parser = argparse.ArgumentParser(description="Complete Percolation Study for Paper")
    parser.add_argument('--test', action='store_true', help='Test mode with reduced parameters')
    
    args = parser.parse_args()
    
    try:
        results = run_paper_study(test_mode=args.test)
        
        if len(results) >= 3:
            print("🎉 Study successful!")
            sys.exit(0)
        else:
            print("⚠️  Partial success")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("⚠️  Study interrupted")
        sys.exit(130)

if __name__ == "__main__":
    main()
