#!/usr/bin/env python3
"""
Ensemble Simulation Runner - 10 runs with different random seeds
Runs the full production simulation 10 times with different seeds for statistical analysis
"""

import argparse
import sys
import time
import os
import subprocess
import json
from pathlib import Path
from datetime import datetime
import multiprocessing as mp
from typing import List, Dict, Optional

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent.parent.parent))

def get_system_info():
    """Get system information for resource planning"""
    import psutil
    
    cpu_count = mp.cpu_count()
    memory_gb = psutil.virtual_memory().total / (1024**3)
    
    print(f"🖥️  System Information:")
    print(f"   CPU cores: {cpu_count}")
    print(f"   Total RAM: {memory_gb:.1f} GB")
    print(f"   Available RAM: {psutil.virtual_memory().available / (1024**3):.1f} GB")
    
    return {
        'cpu_count': cpu_count,
        'memory_gb': memory_gb,
        'available_memory_gb': psutil.virtual_memory().available / (1024**3)
    }

def calculate_ensemble_requirements():
    """Calculate resource requirements for 10 ensemble runs"""
    
    # Memory estimation per simulation
    # - Lattice: 500³ × 8 bytes = 1 GB
    # - Walker positions: 1000 × 3 × 8 bytes = 24 KB
    # - MSD data: 1,000,000 points × 8 bytes = 8 MB
    # - Overhead: ~100 MB per simulation
    memory_per_sim_gb = 1.2  # Conservative estimate for 500³ lattice
    
    # Time estimation (rough)
    # - 1M steps with 1000 walkers on 500³ lattice
    # - Assuming ~500 steps/second on modern CPU
    # - Estimated time: ~33 minutes per simulation
    estimated_time_per_sim_minutes = 40
    
    return {
        'memory_per_sim_gb': memory_per_sim_gb,
        'estimated_time_per_sim_minutes': estimated_time_per_sim_minutes
    }

def create_ensemble_simulation_script(p_value: float, output_dir: str, seed: int,
                                    lattice_size: int = 500, num_steps: int = 1_000_000, 
                                    num_walkers: int = 1000) -> str:
    """Create a Python script for a single ensemble simulation"""
    
    script_content = f'''#!/usr/bin/env python3
"""
Ensemble simulation for p = {p_value:.4f}, seed = {seed}
Generated automatically by run_ensemble_simulations.py
"""

import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent.parent.parent))

from robust_simulation import UltraRobustPercolationSimulation

def main():
    print(f"🚀 Starting ensemble simulation: p = {p_value:.4f}, seed = {seed}")
    print(f"   Lattice size: {lattice_size}³")
    print(f"   Steps: {num_steps:,}")
    print(f"   Walkers: {num_walkers}")
    print(f"   Output: {output_dir}")
    
    # Create simulation with optimized settings
    sim = UltraRobustPercolationSimulation(
        output_dir="{output_dir}",
        checkpoint_interval=50000,  # Checkpoint every 50k steps
        msd_calculation_interval=1  # MSD at every step for accurate analysis
    )
    
    try:
        results = sim.run_simulation(
            lattice_size={lattice_size},
            p_value={p_value},
            num_steps={num_steps},
            num_walkers={num_walkers},
            random_seed={seed}
        )
        
        if results is not None and len(results) > 0:
            print(f"✅ SUCCESS: {{len(results)}} data points generated")
            print(f"   Final MSD: {{results['msd'].iloc[-1]:.2f}}")
            return True
        else:
            print(f"❌ FAILED: No data generated")
            return False
            
    except Exception as e:
        print(f"❌ FAILED: {{e}}")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
'''
    
    script_path = Path(output_dir) / f"run_p{p_value:.4f}_seed{seed}.py"
    script_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(script_path, 'w') as f:
        f.write(script_content)
    
    # Make executable
    os.chmod(script_path, 0o755)
    
    return str(script_path)

def run_single_ensemble_simulation(script_path: str, p_value: float, seed: int) -> Dict:
    """Run a single ensemble simulation and return results"""
    
    start_time = time.time()
    
    print(f"🎯 Running p = {p_value:.4f}, seed = {seed}...")
    
    try:
        # Run the simulation script
        result = subprocess.run(
            [sys.executable, script_path],
            capture_output=True,
            text=True,
            timeout=7200  # 2 hour timeout for 500³ lattice
        )
        
        elapsed_time = time.time() - start_time
        
        if result.returncode == 0:
            print(f"✅ p = {p_value:.4f}, seed = {seed} completed in {elapsed_time/60:.1f} minutes")
            return {
                'p_value': p_value,
                'seed': seed,
                'success': True,
                'elapsed_time': elapsed_time,
                'output': result.stdout
            }
        else:
            print(f"❌ p = {p_value:.4f}, seed = {seed} failed after {elapsed_time/60:.1f} minutes")
            print(f"   Error: {result.stderr}")
            return {
                'p_value': p_value,
                'seed': seed,
                'success': False,
                'elapsed_time': elapsed_time,
                'error': result.stderr
            }
            
    except subprocess.TimeoutExpired:
        elapsed_time = time.time() - start_time
        print(f"⏰ p = {p_value:.4f}, seed = {seed} timed out after {elapsed_time/60:.1f} minutes")
        return {
            'p_value': p_value,
            'seed': seed,
            'success': False,
            'elapsed_time': elapsed_time,
            'error': 'Timeout'
        }
    except Exception as e:
        elapsed_time = time.time() - start_time
        print(f"💥 p = {p_value:.4f}, seed = {seed} crashed after {elapsed_time/60:.1f} minutes: {e}")
        return {
            'p_value': p_value,
            'seed': seed,
            'success': False,
            'elapsed_time': elapsed_time,
            'error': str(e)
        }

def is_simulation_completed(output_dir: str, p_value: float, seed: int) -> bool:
    """Check if a simulation is already completed"""
    sim_dir = Path(output_dir) / f"seed_{seed:02d}" / f"p_{p_value:.4f}"
    msd_file = sim_dir / f"msd_results_L500_p{p_value:.4f}.csv"
    
    if not msd_file.exists():
        return False
    
    # Check if the file has the expected number of lines (1M + header)
    try:
        with open(msd_file, 'r') as f:
            line_count = sum(1 for _ in f)
        return line_count >= 1_000_001  # 1M data points + header
    except:
        return False

def run_ensemble_simulations(p_values: List[float], seeds: List[int], base_output_dir: str, 
                           max_parallel: int = 2) -> List[Dict]:
    """Run ensemble simulations with different seeds"""
    
    print(f"🔄 Running ensemble simulations:")
    print(f"   P-values: {len(p_values)} ({p_values})")
    print(f"   Seeds: {len(seeds)} ({seeds})")
    print(f"   Total simulations: {len(p_values) * len(seeds)}")
    print(f"   Max parallel: {max_parallel}")
    print(f"   Lattice size: 500³")
    print(f"   Steps: 1,000,000")
    print(f"   Walkers: 1,000")
    
    # Check for already completed simulations
    completed_simulations = []
    pending_simulations = []
    
    for seed in seeds:
        for p_value in p_values:
            if is_simulation_completed(base_output_dir, p_value, seed):
                completed_simulations.append((p_value, seed))
                print(f"✅ Skipping p={p_value:.4f}, seed={seed} (already completed)")
            else:
                pending_simulations.append((p_value, seed))
    
    print(f"📊 Found {len(completed_simulations)} completed simulations")
    print(f"📊 {len(pending_simulations)} simulations pending")
    
    if not pending_simulations:
        print("🎉 All simulations are already completed!")
        return [{'p_value': p, 'seed': s, 'success': True, 'elapsed_time': 0, 'output': 'Already completed'} 
                for p, s in completed_simulations]
    
    # Create simulation scripts for pending combinations
    script_paths = []
    simulation_configs = []
    
    for p_value, seed in pending_simulations:
        output_dir = Path(base_output_dir) / f"seed_{seed:02d}" / f"p_{p_value:.4f}"
        script_path = create_ensemble_simulation_script(
            p_value, str(output_dir), seed
        )
        script_paths.append(script_path)
        simulation_configs.append((p_value, seed))
    
    # Run simulations with limited parallelism
    results = []
    
    # Add already completed simulations to results
    for p_value, seed in completed_simulations:
        results.append({
            'p_value': p_value,
            'seed': seed,
            'success': True,
            'elapsed_time': 0,
            'output': 'Already completed'
        })
    
    if max_parallel == 1:
        # Sequential execution
        for script_path, (p_value, seed) in zip(script_paths, simulation_configs):
            result = run_single_ensemble_simulation(script_path, p_value, seed)
            results.append(result)
    else:
        # Parallel execution with limited workers
        with mp.Pool(processes=max_parallel) as pool:
            # Submit all jobs
            jobs = []
            for script_path, (p_value, seed) in zip(script_paths, simulation_configs):
                job = pool.apply_async(run_single_ensemble_simulation, (script_path, p_value, seed))
                jobs.append(job)
            
            # Collect results
            for job in jobs:
                result = job.get()
                results.append(result)
    
    return results

def create_ensemble_summary_report(results: List[Dict], base_output_dir: str):
    """Create a summary report of all ensemble simulations"""
    
    report_path = Path(base_output_dir) / "ensemble_simulation_summary.md"
    
    successful = [r for r in results if r['success']]
    failed = [r for r in results if not r['success']]
    
    total_time = sum(r['elapsed_time'] for r in results)
    
    # Group by p-value
    p_value_groups = {}
    for result in successful:
        p_val = result['p_value']
        if p_val not in p_value_groups:
            p_value_groups[p_val] = []
        p_value_groups[p_val].append(result)
    
    report_content = f"""# Ensemble Simulation Summary

## Overview
- **Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
- **Total simulations:** {len(results)}
- **Successful:** {len(successful)}
- **Failed:** {len(failed)}
- **Total runtime:** {total_time/60:.1f} minutes ({total_time/3600:.1f} hours)

## Parameters
- **Lattice size:** 500³
- **Steps:** 1,000,000
- **Walkers:** 1,000
- **MSD interval:** 1 step (MSD calculated at every step)
- **P-values:** {list(p_value_groups.keys())}
- **Seeds:** {list(set(r['seed'] for r in successful))}

## Results by P-value

"""
    
    for p_val in sorted(p_value_groups.keys()):
        group_results = p_value_groups[p_val]
        seeds = [r['seed'] for r in group_results]
        avg_time = sum(r['elapsed_time'] for r in group_results) / len(group_results)
        
        report_content += f"""### p = {p_val:.4f}
- **Successful runs:** {len(group_results)}/10
- **Seeds:** {seeds}
- **Average runtime:** {avg_time/60:.1f} minutes
- **Output directories:** `seed_XX/p_{p_val:.4f}/`

"""
    
    if failed:
        report_content += "\n### Failed Simulations\n"
        for result in failed:
            report_content += f"""
#### p = {result['p_value']:.4f}, seed = {result['seed']}
- **Status:** ❌ Failed
- **Runtime:** {result['elapsed_time']/60:.1f} minutes
- **Error:** {result.get('error', 'Unknown')}
"""
    
    report_content += f"""

## Data Files
Each successful simulation generates:
- `msd_results_L500_p{{p_value}}.csv` - MSD data (1M data points)
- `simulation_summary_p_{{p_value}}.json` - Performance summary
- `checkpoints/` - Checkpoint files for resuming

## Directory Structure
```
ensemble_simulations/
├── seed_01/
│   ├── p_0.0000/
│   ├── p_0.3116/
│   ├── p_0.6884/
│   └── p_0.7500/
├── seed_02/
│   └── ...
└── ...
```

## Next Steps
1. Run statistical analysis across ensemble
2. Calculate mean and standard deviation of MSD curves
3. Analyze growth exponents and rheological properties
4. Create ensemble comparison plots
"""
    
    with open(report_path, 'w') as f:
        f.write(report_content)
    
    print(f"📊 Ensemble summary report saved: {report_path}")

def main():
    parser = argparse.ArgumentParser(description="Run Ensemble Simulations - 10 runs with different seeds")
    parser.add_argument('--output-dir', type=str, default='ensemble_simulations', 
                       help='Base output directory')
    parser.add_argument('--parallel', type=int, default=2, 
                       help='Maximum parallel simulations (default: 2)')
    parser.add_argument('--p-values', nargs='+', type=float,
                       default=[0.0, 0.3116, 0.6884, 0.75],
                       help='P-values to simulate')
    parser.add_argument('--seeds', nargs='+', type=int,
                       default=list(range(1, 11)),  # Seeds 1-10
                       help='Random seeds to use')
    
    args = parser.parse_args()
    
    # Get system information
    system_info = get_system_info()
    resource_req = calculate_ensemble_requirements()
    
    total_simulations = len(args.p_values) * len(args.seeds)
    estimated_total_time = total_simulations * resource_req['estimated_time_per_sim_minutes']
    estimated_total_memory = total_simulations * resource_req['memory_per_sim_gb']
    
    print(f"\n📋 Ensemble Simulation Plan:")
    print(f"   P-values: {args.p_values}")
    print(f"   Seeds: {args.seeds}")
    print(f"   Total simulations: {total_simulations}")
    print(f"   Lattice size: 500³")
    print(f"   Steps: 1,000,000")
    print(f"   Walkers: 1,000")
    print(f"   Parallel: {args.parallel}")
    print(f"   Estimated time: {estimated_total_time:.0f} minutes ({estimated_total_time/60:.1f} hours)")
    print(f"   Estimated memory: {estimated_total_memory:.1f} GB")
    
    # Check available resources
    if system_info['available_memory_gb'] < estimated_total_memory:
        print(f"⚠️  Warning: Limited memory available")
        print(f"   Required: {estimated_total_memory:.1f} GB")
        print(f"   Available: {system_info['available_memory_gb']:.1f} GB")
        print(f"   Consider reducing parallel processes or running fewer simulations")
    
    # Create output directory
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"\n🚀 Starting ensemble simulations...")
    start_time = time.time()
    
    # Run ensemble simulations
    results = run_ensemble_simulations(
        args.p_values, 
        args.seeds,
        str(output_dir), 
        max_parallel=args.parallel
    )
    
    total_time = time.time() - start_time
    
    # Create summary
    create_ensemble_summary_report(results, str(output_dir))
    
    # Final status
    successful = sum(1 for r in results if r['success'])
    print(f"\n🎉 Ensemble simulations completed!")
    print(f"   Total time: {total_time/60:.1f} minutes ({total_time/3600:.1f} hours)")
    print(f"   Success rate: {successful}/{total_simulations} ({successful/total_simulations*100:.1f}%)")
    print(f"   Results in: {output_dir}")
    
    if successful == total_simulations:
        print("✅ All ensemble simulations successful!")
        return 0
    else:
        print("⚠️  Some simulations failed - check logs")
        return 1

if __name__ == "__main__":
    sys.exit(main()) 