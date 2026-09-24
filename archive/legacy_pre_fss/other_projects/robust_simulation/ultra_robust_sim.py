"""
Ultra-Robust Percolation Simulation - Complete Integration
"""

import numpy as np
import pandas as pd
import time
import logging
from pathlib import Path
from typing import Dict, Optional

from .resource_manager import RobustSimulationWrapper, ResourceLimits
from .checkpoint_system import ResumableSimulation, SimulationState

class UltraRobustPercolationSimulation:
    def __init__(self, 
                 output_dir: str,
                 resource_limits: Optional[ResourceLimits] = None,
                 checkpoint_interval: int = 50_000,
                 msd_calculation_interval: int = 1_000):
        
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        self.resource_limits = resource_limits or ResourceLimits()
        
        self.safety_wrapper = RobustSimulationWrapper(str(self.output_dir), self.resource_limits)
        self.resumable_sim = ResumableSimulation(str(self.output_dir), checkpoint_interval)
        
        self.msd_interval = msd_calculation_interval
        self.logger = logging.getLogger('ultra_robust_simulation')
        
        self.performance_stats = {
            'steps_completed': 0,
            'checkpoints_created': 0,
            'average_steps_per_second': 0.0
        }
    
    def run_simulation(self, 
                      lattice_size: int = 100,
                      p_value: float = 0.3116,
                      num_steps: int = 1_000_000,
                      num_walkers: int = 100,
                      random_seed: int = 42,
                      resume_if_available: bool = True) -> pd.DataFrame:
        
        def _safe_simulation(safety_wrapper):
            state = self.resumable_sim.initialize_simulation(
                lattice_size=lattice_size,
                p_value=p_value,
                num_steps=num_steps,
                num_walkers=num_walkers,
                random_seed=random_seed
            )
            
            simulation_start_time = time.time()
            
            self.logger.info(f"Running simulation: L={lattice_size}, p={p_value:.4f}, steps={num_steps:,}")
            
            try:
                while state.current_step < num_steps:
                    self.resumable_sim.step_walkers()
                    
                    if state.current_step % self.msd_interval == 0:
                        msd = self.resumable_sim.calculate_msd()
                        state.msd_data.append({
                            'step': state.current_step,
                            'tau': state.current_step,
                            'msd': msd,
                            'p_value': p_value,
                            'lattice_size': lattice_size,
                            'timestamp': time.time()
                        })
                    
                    if state.current_step % self.resource_limits.memory_check_interval == 0:
                        progress_info = safety_wrapper.check_progress(state.current_step, num_steps)
                        if progress_info:
                            self.performance_stats['average_steps_per_second'] = progress_info['steps_per_second']
                    
                    if self.resumable_sim.should_checkpoint(state.current_step):
                        if self.resumable_sim.create_checkpoint():
                            self.performance_stats['checkpoints_created'] += 1
                    
                    self.performance_stats['steps_completed'] = state.current_step
                
                total_runtime = time.time() - simulation_start_time
                self.logger.info(f"Simulation completed! Runtime: {total_runtime/60:.2f} minutes")
                
                self.resumable_sim.save_final_results()
                return pd.DataFrame(state.msd_data)
                
            except KeyboardInterrupt:
                self.logger.warning("Simulation interrupted by user")
                self.resumable_sim.create_checkpoint()
                
                if state.msd_data:
                    return pd.DataFrame(state.msd_data)
                else:
                    return pd.DataFrame()
        
        return self.safety_wrapper.run_with_safety(_safe_simulation)
    
    def get_simulation_status(self) -> Dict:
        return {
            'output_directory': str(self.output_dir),
            'performance_stats': self.performance_stats.copy()
        }
    
    def cleanup_old_files(self, keep_checkpoints: int = 3):
        self.logger.info("Cleaning up old files...")
        self.safety_wrapper.file_handler.cleanup_temp_files()
