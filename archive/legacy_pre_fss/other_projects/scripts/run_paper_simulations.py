#!/usr/bin/env python3
"""
Paper Simulation Runner - 1M steps, 1000 walkers
Runs the exact p-values from the paper: [0, 0.3116, 0.6884, 0.75]
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
sys.path.append(str(Path(__file__).parent.parent.parent))

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

def calculate_resource_requirements():
    """Calculate resource requirements for 1M steps, 1000 walkers"""
    
    # Memory estimation per simulation
    # - Lattice: 100³ × 8 bytes = 8 MB
    # - Walker positions: 1000 × 3 × 8 bytes = 24 KB
    # - MSD data: 10,000 points × 8 bytes = 80 KB
    # - Overhead: ~50 MB per simulation
    memory_per_sim_gb = 0.1  # Conservative estimate
    
    # Time estimation (rough)
    # - 1M steps with 1000 walkers
    # - Assuming ~1000 steps/second on modern CPU
    # - Estimated time: ~17 minutes per simulation
    estimated_time_per_sim_minutes = 20
    
    return {
        'memory_per_sim_gb': memory_per_sim_gb,
        'estimated_time_per_sim_minutes': estimated_time_per_sim_minutes
    }

def create_simulation_script(p_value: float, output_dir: str, 
                           lattice_size: int = 500, num_steps: int = 1_000_000, 
                           num_walkers: int = 1000, random_seed: int = 42) -> str:
    """Create a Python script for a single simulation"""
    
    script_content = f'''#!/usr/bin/env python3
"""
Paper simulation for p = {p_value:.4f}
Generated automatically by run_paper_simulations.py
"""

import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent.parent))

from robust_simulation import UltraRobustPercolationSimulation

def main():
    print(f"🚀 Starting simulation: p = {p_value:.4f}")
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
            random_seed={random_seed}
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
    
    script_path = Path(output_dir) / f"run_p{p_value:.4f}.py"
    script_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(script_path, 'w') as f:
        f.write(script_content)
    
    # Make executable
    os.chmod(script_path, 0o755)
    
    return str(script_path)

def run_single_simulation(script_path: str, p_value: float) -> Dict:
    """Run a single simulation and return results"""
    
    start_time = time.time()
    
    print(f"🎯 Running p = {p_value:.4f}...")
    
    try:
        # Run the simulation script
        result = subprocess.run(
            [sys.executable, script_path],
            capture_output=True,
            text=True,
            timeout=3600  # 1 hour timeout
        )
        
        elapsed_time = time.time() - start_time
        
        if result.returncode == 0:
            print(f"✅ p = {p_value:.4f} completed in {elapsed_time/60:.1f} minutes")
            return {
                'p_value': p_value,
                'success': True,
                'elapsed_time': elapsed_time,
                'output': result.stdout
            }
        else:
            print(f"❌ p = {p_value:.4f} failed after {elapsed_time/60:.1f} minutes")
            print(f"   Error: {result.stderr}")
            return {
                'p_value': p_value,
                'success': False,
                'elapsed_time': elapsed_time,
                'error': result.stderr
            }
            
    except subprocess.TimeoutExpired:
        elapsed_time = time.time() - start_time
        print(f"⏰ p = {p_value:.4f} timed out after {elapsed_time/60:.1f} minutes")
        return {
            'p_value': p_value,
            'success': False,
            'elapsed_time': elapsed_time,
            'error': 'Timeout'
        }
    except Exception as e:
        elapsed_time = time.time() - start_time
        print(f"💥 p = {p_value:.4f} crashed after {elapsed_time/60:.1f} minutes: {e}")
        return {
            'p_value': p_value,
            'success': False,
            'elapsed_time': elapsed_time,
            'error': str(e)
        }

def run_parallel_simulations(p_values: List[float], base_output_dir: str, 
                           max_parallel: int = 2, test_mode: bool = False) -> List[Dict]:
    """Run simulations in parallel with resource management"""
    
    print(f"🔄 Running {len(p_values)} simulations with max {max_parallel} parallel")
    
    # Set parameters based on mode
    if test_mode:
        lattice_size = 50
        num_steps = 10_000
        num_walkers = 100
        print(f"   Test mode: L={lattice_size}³, steps={num_steps:,}, walkers={num_walkers}")
    else:
        lattice_size = 500
        num_steps = 1_000_000
        num_walkers = 1000
        print(f"   Full mode: L={lattice_size}³, steps={num_steps:,}, walkers={num_walkers}")
    
    # Create simulation scripts
    script_paths = []
    for p_value in p_values:
        output_dir = Path(base_output_dir) / f"p_{p_value:.4f}"
        script_path = create_simulation_script(
            p_value, str(output_dir), 
            lattice_size=lattice_size,
            num_steps=num_steps,
            num_walkers=num_walkers
        )
        script_paths.append(script_path)
    
    # Run simulations with limited parallelism
    results = []
    
    if max_parallel == 1:
        # Sequential execution
        for script_path, p_value in zip(script_paths, p_values):
            result = run_single_simulation(script_path, p_value)
            results.append(result)
    else:
        # Parallel execution with limited workers
        with mp.Pool(processes=max_parallel) as pool:
            # Submit all jobs
            jobs = []
            for script_path, p_value in zip(script_paths, p_values):
                job = pool.apply_async(run_single_simulation, (script_path, p_value))
                jobs.append(job)
            
            # Collect results
            for job in jobs:
                result = job.get()
                results.append(result)
    
    return results

def create_summary_report(results: List[Dict], base_output_dir: str):
    """Create a summary report of all simulations"""
    
    report_path = Path(base_output_dir) / "simulation_summary.md"
    
    successful = [r for r in results if r['success']]
    failed = [r for r in results if not r['success']]
    
    total_time = sum(r['elapsed_time'] for r in results)
    
    report_content = f"""# Paper Simulation Summary

## Overview
- **Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
- **Total simulations:** {len(results)}
- **Successful:** {len(successful)}
- **Failed:** {len(failed)}
- **Total runtime:** {total_time/60:.1f} minutes

## Parameters
- **Lattice size:** 500³
- **Steps:** 1,000,000
- **Walkers:** 1,000
- **MSD interval:** 1 step (MSD calculated at every step)

## Results

### Successful Simulations
"""
    
    for result in successful:
        report_content += f"""
#### p = {result['p_value']:.4f}
- **Status:** ✅ Success
- **Runtime:** {result['elapsed_time']/60:.1f} minutes
- **Output directory:** `p_{result['p_value']:.4f}/`
"""
    
    if failed:
        report_content += "\n### Failed Simulations\n"
        for result in failed:
            report_content += f"""
#### p = {result['p_value']:.4f}
- **Status:** ❌ Failed
- **Runtime:** {result['elapsed_time']/60:.1f} minutes
- **Error:** {result.get('error', 'Unknown')}
"""
    
    report_content += f"""

## Data Files
Each successful simulation generates:
- `msd_results_L100_p{{p_value}}.csv` - MSD data
- `simulation_summary_p_{{p_value}}.json` - Performance summary
- `checkpoints/` - Checkpoint files for resuming

## Next Steps
1. Run analysis scripts on the generated data
2. Create comparison plots
3. Calculate growth exponents and rheological properties
"""
    
    with open(report_path, 'w') as f:
        f.write(report_content)
    
    print(f"📊 Summary report saved: {report_path}")

def main():
    parser = argparse.ArgumentParser(description="Run Paper Simulations - 1M steps, 1000 walkers")
    parser.add_argument('--output-dir', type=str, default='paper_simulations', 
                       help='Base output directory')
    parser.add_argument('--parallel', type=int, default=2, 
                       help='Maximum parallel simulations (default: 2)')
    parser.add_argument('--test', action='store_true', 
                       help='Test mode with reduced parameters')
    parser.add_argument('--p-values', nargs='+', type=float,
                       default=[0.0, 0.3116, 0.6884, 0.75],
                       help='P-values to simulate')
    
    args = parser.parse_args()
    
    # Get system information
    system_info = get_system_info()
    resource_req = calculate_resource_requirements()
    
    print(f"\n📋 Simulation Plan:")
    print(f"   P-values: {args.p_values}")
    print(f"   Lattice size: 500³")
    print(f"   Steps: 1,000,000")
    print(f"   Walkers: 1,000")
    print(f"   Parallel: {args.parallel}")
    print(f"   Estimated time: {len(args.p_values) * resource_req['estimated_time_per_sim_minutes']:.0f} minutes")
    print(f"   Estimated memory: {len(args.p_values) * resource_req['memory_per_sim_gb']:.1f} GB")
    
    if args.test:
        print("\n🧪 TEST MODE: Using reduced parameters")
        # Override for test mode
        args.p_values = [0.0, 0.3116]  # Just test first two
        test_params = {
            'lattice_size': 50,
            'num_steps': 10_000,
            'num_walkers': 100
        }
        print(f"   Test parameters: {test_params}")
    
    # Check available resources
    if system_info['available_memory_gb'] < len(args.p_values) * resource_req['memory_per_sim_gb']:
        print(f"⚠️  Warning: Limited memory available")
        print(f"   Required: {len(args.p_values) * resource_req['memory_per_sim_gb']:.1f} GB")
        print(f"   Available: {system_info['available_memory_gb']:.1f} GB")
        print(f"   Consider reducing parallel processes")
    
    # Create output directory
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"\n🚀 Starting simulations...")
    start_time = time.time()
    
    # Run simulations
    results = run_parallel_simulations(
        args.p_values, 
        str(output_dir), 
        max_parallel=args.parallel,
        test_mode=args.test
    )
    
    total_time = time.time() - start_time
    
    # Create summary
    create_summary_report(results, str(output_dir))
    
    # Final status
    successful = sum(1 for r in results if r['success'])
    print(f"\n🎉 Simulations completed!")
    print(f"   Total time: {total_time/60:.1f} minutes")
    print(f"   Success rate: {successful}/{len(results)} ({successful/len(results)*100:.1f}%)")
    print(f"   Results in: {output_dir}")
    
    if successful == len(results):
        print("✅ All simulations successful!")
        return 0
    else:
        print("⚠️  Some simulations failed - check logs")
        return 1

if __name__ == "__main__":
    sys.exit(main()) 