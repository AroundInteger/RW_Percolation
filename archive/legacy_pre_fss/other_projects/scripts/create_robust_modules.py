#!/usr/bin/env python3
"""
Script to create all robust simulation module files

This script generates all the required module files for the ultra-robust
simulation system. Run this script from the repository root directory.

Usage:
    python scripts/create_robust_modules.py
"""

import os
from pathlib import Path

def create_directory_structure():
    """Create the required directory structure"""
    
    directories = [
        "robust_simulation",
        "robust_simulation/examples", 
        "docs",
        "scripts",
        "tests",
        "examples"
    ]
    
    for directory in directories:
        Path(directory).mkdir(parents=True, exist_ok=True)
        print(f"Created directory: {directory}")

def create_resource_manager():
    """Create robust_simulation/resource_manager.py"""
    
    content = '''# robust_simulation/resource_manager.py
"""
Resource Management and Error Handling for Robust Percolation Simulations

This module provides comprehensive resource monitoring, error handling,
and safety systems for long-running simulation processes.
"""

import os
import sys
import time
import signal
import logging
import psutil
import traceback
from pathlib import Path
from typing import Optional, Callable, Any
from contextlib import contextmanager
from dataclasses import dataclass

@dataclass
class ResourceLimits:
    """Define resource limits for simulation safety"""
    max_memory_gb: float = 8.0
    max_runtime_hours: float = 48.0
    min_disk_space_gb: float = 5.0
    memory_check_interval: int = 1000
    
    def __post_init__(self):
        total_memory_gb = psutil.virtual_memory().total / (1024**3)
        self.max_memory_gb = min(self.max_memory_gb, total_memory_gb * 0.8)
        
        print(f"Resource limits set:")
        print(f"  Max memory: {self.max_memory_gb:.1f} GB")
        print(f"  Max runtime: {self.max_runtime_hours:.1f} hours")
        print(f"  Min disk space: {self.min_disk_space_gb:.1f} GB")

class SimulationError(Exception):
    """Custom exception for simulation-specific errors"""
    pass

class ResourceExhaustionError(SimulationError):
    """Raised when system resources are exhausted"""
    pass

class InterruptionHandler:
    """Handle graceful shutdown on interruption"""
    
    def __init__(self):
        self.interrupted = False
        self.cleanup_functions = []
        self._setup_signal_handlers()
    
    def _setup_signal_handlers(self):
        def signal_handler(signum, frame):
            print(f"\\nReceived signal {signum}. Initiating graceful shutdown...")
            self.interrupted = True
            self._run_cleanup()
        
        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)
        
        if sys.platform == "win32":
            signal.signal(signal.SIGBREAK, signal_handler)
    
    def add_cleanup_function(self, func: Callable, *args, **kwargs):
        self.cleanup_functions.append((func, args, kwargs))
    
    def _run_cleanup(self):
        for func, args, kwargs in self.cleanup_functions:
            try:
                func(*args, **kwargs)
            except Exception as e:
                print(f"Error during cleanup: {e}")
    
    def check_interruption(self):
        if self.interrupted:
            raise KeyboardInterrupt("Simulation interrupted by user")

class ResourceMonitor:
    """Monitor and enforce resource limits during simulation"""
    
    def __init__(self, limits: ResourceLimits, output_dir: str):
        self.limits = limits
        self.output_dir = Path(output_dir)
        self.start_time = time.time()
        self.process = psutil.Process()
        
        self.log_file = self.output_dir / "resource_monitor.log"
        self._setup_logging()
        self._validate_initial_resources()
    
    def _setup_logging(self):
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        self.logger = logging.getLogger('resource_monitor')
        self.logger.setLevel(logging.INFO)
        
        file_handler = logging.FileHandler(self.log_file)
        file_handler.setFormatter(
            logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        )
        self.logger.addHandler(file_handler)
        
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.WARNING)
        console_handler.setFormatter(
            logging.Formatter('RESOURCE WARNING: %(message)s')
        )
        self.logger.addHandler(console_handler)
    
    def _validate_initial_resources(self):
        available_memory_gb = psutil.virtual_memory().available / (1024**3)
        if available_memory_gb < self.limits.max_memory_gb:
            raise ResourceExhaustionError(
                f"Insufficient memory: {available_memory_gb:.1f}GB available, "
                f"{self.limits.max_memory_gb:.1f}GB required"
            )
        
        disk_usage = psutil.disk_usage(self.output_dir.parent)
        available_disk_gb = disk_usage.free / (1024**3)
        if available_disk_gb < self.limits.min_disk_space_gb:
            raise ResourceExhaustionError(
                f"Insufficient disk space: {available_disk_gb:.1f}GB available, "
                f"{self.limits.min_disk_space_gb:.1f}GB required"
            )
        
        self.logger.info(f"Initial resource validation passed")
        self.logger.info(f"Available memory: {available_memory_gb:.1f}GB")
        self.logger.info(f"Available disk: {available_disk_gb:.1f}GB")
    
    def check_resources(self, step: int, total_steps: int) -> dict:
        current_time = time.time()
        
        memory_info = self.process.memory_info()
        memory_gb = memory_info.rss / (1024**3)
        
        if memory_gb > self.limits.max_memory_gb:
            error_msg = f"Memory limit exceeded: {memory_gb:.2f}GB > {self.limits.max_memory_gb:.1f}GB"
            self.logger.error(error_msg)
            raise ResourceExhaustionError(error_msg)
        
        elapsed_hours = (current_time - self.start_time) / 3600
        if elapsed_hours > self.limits.max_runtime_hours:
            error_msg = f"Runtime limit exceeded: {elapsed_hours:.1f}h > {self.limits.max_runtime_hours:.1f}h"
            self.logger.error(error_msg)
            raise ResourceExhaustionError(error_msg)
        
        if step % (self.limits.memory_check_interval * 10) == 0:
            disk_usage = psutil.disk_usage(self.output_dir)
            available_disk_gb = disk_usage.free / (1024**3)
            if available_disk_gb < self.limits.min_disk_space_gb:
                error_msg = f"Disk space low: {available_disk_gb:.1f}GB < {self.limits.min_disk_space_gb:.1f}GB"
                self.logger.error(error_msg)
                raise ResourceExhaustionError(error_msg)
        
        if step > 0:
            steps_per_second = step / (current_time - self.start_time)
            eta_seconds = (total_steps - step) / steps_per_second if steps_per_second > 0 else float('inf')
        else:
            steps_per_second = 0
            eta_seconds = float('inf')
        
        if step % self.limits.memory_check_interval == 0:
            self.logger.info(
                f"Step {step:,}/{total_steps:,} ({step/total_steps*100:.1f}%) - "
                f"Memory: {memory_gb:.2f}GB - "
                f"Rate: {steps_per_second:.0f} steps/s - "
                f"ETA: {eta_seconds/60:.1f}min"
            )
        
        return {
            'memory_gb': memory_gb,
            'elapsed_hours': elapsed_hours,
            'steps_per_second': steps_per_second,
            'eta_minutes': eta_seconds / 60,
            'progress_percent': step / total_steps * 100
        }

class SafeFileHandler:
    """Safe file operations with error handling and atomic writes"""
    
    def __init__(self, base_path: str):
        self.base_path = Path(base_path)
        self.base_path.mkdir(parents=True, exist_ok=True)
    
    @contextmanager
    def safe_write(self, filename: str, mode: str = 'w'):
        filepath = self.base_path / filename
        temp_filepath = filepath.with_suffix(filepath.suffix + '.tmp')
        
        try:
            with open(temp_filepath, mode) as f:
                yield f
            temp_filepath.replace(filepath)
        except Exception as e:
            if temp_filepath.exists():
                temp_filepath.unlink()
            raise e
    
    def safe_read(self, filename: str, mode: str = 'r'):
        filepath = self.base_path / filename
        
        if not filepath.exists():
            raise FileNotFoundError(f"File not found: {filepath}")
        
        try:
            with open(filepath, mode) as f:
                return f.read()
        except Exception as e:
            raise IOError(f"Error reading file {filepath}: {e}")
    
    def cleanup_temp_files(self):
        temp_files = list(self.base_path.glob("*.tmp"))
        for temp_file in temp_files:
            try:
                temp_file.unlink()
            except Exception:
                pass

class RobustSimulationWrapper:
    """Main wrapper class that combines all safety features"""
    
    def __init__(self, output_dir: str, limits: Optional[ResourceLimits] = None):
        self.output_dir = output_dir
        self.limits = limits or ResourceLimits()
        
        self.interruption_handler = InterruptionHandler()
        self.resource_monitor = ResourceMonitor(self.limits, output_dir)
        self.file_handler = SafeFileHandler(output_dir)
        
        self.interruption_handler.add_cleanup_function(
            self.file_handler.cleanup_temp_files
        )
        
        self._setup_main_logging()
    
    def _setup_main_logging(self):
        log_file = Path(self.output_dir) / "simulation.log"
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler(sys.stdout)
            ]
        )
        
        self.logger = logging.getLogger('simulation')
        self.logger.info("Robust simulation wrapper initialized")
    
    def run_with_safety(self, simulation_func: Callable, *args, **kwargs) -> Any:
        self.logger.info("Starting simulation with safety wrapper")
        start_time = time.time()
        
        try:
            result = simulation_func(self, *args, **kwargs)
            elapsed_time = time.time() - start_time
            self.logger.info(f"Simulation completed successfully in {elapsed_time/60:.2f} minutes")
            return result
            
        except KeyboardInterrupt:
            self.logger.warning("Simulation interrupted by user")
            raise
            
        except ResourceExhaustionError as e:
            self.logger.error(f"Resource exhaustion: {e}")
            raise
            
        except Exception as e:
            self.logger.error(f"Simulation failed with error: {e}")
            self.logger.error(f"Traceback: {traceback.format_exc()}")
            raise SimulationError(f"Simulation failed: {e}") from e
    
    def check_progress(self, step: int, total_steps: int):
        self.interruption_handler.check_interruption()
        
        if step % self.limits.memory_check_interval == 0:
            return self.resource_monitor.check_resources(step, total_steps)
        
        return None
'''
    
    with open("robust_simulation/resource_manager.py", "w") as f:
        f.write(content)
    print("Created: robust_simulation/resource_manager.py")

def create_checkpoint_system():
    """Create robust_simulation/checkpoint_system.py"""
    
    content = '''# robust_simulation/checkpoint_system.py
"""
Robust Checkpointing System for Long-Running Simulations

This module provides comprehensive checkpointing capabilities that allow
simulations to be interrupted and resumed without losing progress.
"""

import os
import pickle
import json
import time
import hashlib
import numpy as np
import pandas as pd
from pathlib import Path
from typing import Dict, Any, Optional, List, Tuple
from dataclasses import dataclass, asdict
import logging

@dataclass
class SimulationState:
    """Complete simulation state for checkpointing"""
    
    lattice_size: int
    p_value: float
    num_steps: int
    current_step: int
    random_seed: int
    
    walker_positions: np.ndarray
    initial_positions: np.ndarray
    
    msd_data: List[Dict]
    trajectory_data: Optional[np.ndarray] = None
    
    start_time: float
    checkpoint_time: float
    elapsed_time: float
    
    lattice_hash: str
    
    def to_dict(self) -> Dict:
        state_dict = asdict(self)
        if isinstance(self.walker_positions, np.ndarray):
            state_dict['walker_positions_shape'] = list(self.walker_positions.shape)
        if isinstance(self.initial_positions, np.ndarray):
            state_dict['initial_positions_shape'] = list(self.initial_positions.shape)
        return state_dict

class CheckpointManager:
    """Manages simulation checkpoints with validation and recovery"""
    
    def __init__(self, output_dir: str, checkpoint_interval: int = 50000):
        self.output_dir = Path(output_dir)
        self.checkpoint_interval = checkpoint_interval
        self.checkpoint_dir = self.output_dir / "checkpoints"
        self.checkpoint_dir.mkdir(parents=True, exist_ok=True)
        
        self.logger = logging.getLogger('checkpoint_manager')
        self.checkpoint_history = []
        self.max_checkpoints = 5
        
        self.logger.info(f"Checkpoint manager initialized: {self.checkpoint_dir}")
        self.logger.info(f"Checkpoint interval: {checkpoint_interval:,} steps")
    
    def should_checkpoint(self, step: int) -> bool:
        return step > 0 and step % self.checkpoint_interval == 0
    
    def create_checkpoint(self, state: SimulationState, lattice: np.ndarray) -> str:
        timestamp = int(time.time())
        checkpoint_name = f"checkpoint_step_{state.current_step}_{timestamp}"
        
        try:
            checkpoint_file = self.checkpoint_dir / f"{checkpoint_name}.pkl"
            
            with open(checkpoint_file, 'wb') as f:
                checkpoint_data = {
                    'state': state,
                    'lattice': lattice,
                    'lattice_shape': lattice.shape,
                    'checkpoint_version': '1.0',
                    'creation_time': timestamp
                }
                pickle.dump(checkpoint_data, f, protocol=pickle.HIGHEST_PROTOCOL)
            
            metadata_file = self.checkpoint_dir / f"{checkpoint_name}_metadata.json"
            
            metadata = {
                'checkpoint_name': checkpoint_name,
                'step': state.current_step,
                'total_steps': state.num_steps,
                'progress_percent': (state.current_step / state.num_steps) * 100,
                'lattice_size': state.lattice_size,
                'p_value': state.p_value,
                'elapsed_time_hours': state.elapsed_time / 3600,
                'num_walkers': len(state.walker_positions),
                'msd_data_points': len(state.msd_data),
                'checkpoint_size_mb': checkpoint_file.stat().st_size / (1024 * 1024),
                'creation_timestamp': timestamp,
                'lattice_hash': state.lattice_hash
            }
            
            with open(metadata_file, 'w') as f:
                json.dump(metadata, f, indent=2)
            
            self.checkpoint_history.append({
                'file': checkpoint_file,
                'metadata_file': metadata_file,
                'step': state.current_step,
                'timestamp': timestamp
            })
            
            self._cleanup_old_checkpoints()
            
            if self._verify_checkpoint(checkpoint_file):
                self.logger.info(
                    f"Checkpoint created: {checkpoint_name} "
                    f"(step {state.current_step:,}, "
                    f"{metadata['checkpoint_size_mb']:.1f}MB)"
                )
                return str(checkpoint_file)
            else:
                self.logger.error(f"Checkpoint verification failed: {checkpoint_name}")
                return None
                
        except Exception as e:
            self.logger.error(f"Failed to create checkpoint: {e}")
            return None
    
    def _verify_checkpoint(self, checkpoint_file: Path) -> bool:
        try:
            with open(checkpoint_file, 'rb') as f:
                data = pickle.load(f)
            
            required_keys = ['state', 'lattice', 'checkpoint_version']
            if not all(key in data for key in required_keys):
                return False
            
            state = data['state']
            if not isinstance(state, SimulationState):
                return False
            
            lattice = data['lattice']
            if not isinstance(lattice, np.ndarray):
                return False
            
            return True
            
        except Exception as e:
            self.logger.error(f"Checkpoint verification error: {e}")
            return False
    
    def _cleanup_old_checkpoints(self):
        if len(self.checkpoint_history) > self.max_checkpoints:
            self.checkpoint_history.sort(key=lambda x: x['timestamp'])
            
            while len(self.checkpoint_history) > self.max_checkpoints:
                old_checkpoint = self.checkpoint_history.pop(0)
                
                try:
                    if old_checkpoint['file'].exists():
                        old_checkpoint['file'].unlink()
                    
                    if old_checkpoint['metadata_file'].exists():
                        old_checkpoint['metadata_file'].unlink()
                    
                    self.logger.info(f"Removed old checkpoint: step {old_checkpoint['step']}")
                    
                except Exception as e:
                    self.logger.warning(f"Error removing old checkpoint: {e}")
    
    def find_latest_checkpoint(self) -> Optional[str]:
        checkpoint_files = list(self.checkpoint_dir.glob("checkpoint_step_*.pkl"))
        
        if not checkpoint_files:
            return None
        
        checkpoint_files.sort(key=lambda f: f.stat().st_mtime, reverse=True)
        
        for checkpoint_file in checkpoint_files:
            if self._verify_checkpoint(checkpoint_file):
                self.logger.info(f"Found valid checkpoint: {checkpoint_file.name}")
                return str(checkpoint_file)
        
        self.logger.warning("No valid checkpoints found")
        return None
    
    def load_checkpoint(self, checkpoint_file: str) -> Tuple[SimulationState, np.ndarray]:
        checkpoint_path = Path(checkpoint_file)
        
        if not checkpoint_path.exists():
            raise FileNotFoundError(f"Checkpoint file not found: {checkpoint_file}")
        
        try:
            with open(checkpoint_path, 'rb') as f:
                checkpoint_data = pickle.load(f)
            
            state = checkpoint_data['state']
            lattice = checkpoint_data['lattice']
            
            if not isinstance(state, SimulationState):
                raise ValueError("Invalid state object in checkpoint")
            
            if not isinstance(lattice, np.ndarray):
                raise ValueError("Invalid lattice data in checkpoint")
            
            if hasattr(state, 'lattice_hash') and state.lattice_hash:
                current_hash = self._calculate_lattice_hash(lattice)
                if current_hash != state.lattice_hash:
                    self.logger.warning("Lattice hash mismatch - lattice may have changed")
            
            self.logger.info(
                f"Loaded checkpoint: step {state.current_step:,}/{state.num_steps:,} "
                f"({state.current_step/state.num_steps*100:.1f}%)"
            )
            
            return state, lattice
            
        except Exception as e:
            raise RuntimeError(f"Failed to load checkpoint: {e}")
    
    def _calculate_lattice_hash(self, lattice: np.ndarray) -> str:
        return hashlib.md5(lattice.tobytes()).hexdigest()
    
    def list_checkpoints(self) -> List[Dict]:
        checkpoint_files = list(self.checkpoint_dir.glob("checkpoint_step_*.pkl"))
        checkpoints = []
        
        for checkpoint_file in checkpoint_files:
            metadata_file = checkpoint_file.with_suffix('').with_suffix('_metadata.json')
            
            try:
                if metadata_file.exists():
                    with open(metadata_file, 'r') as f:
                        metadata = json.load(f)
                else:
                    parts = checkpoint_file.stem.split('_')
                    if len(parts) >= 3:
                        step = int(parts[2])
                    else:
                        step = 0
                    
                    metadata = {
                        'step': step,
                        'checkpoint_size_mb': checkpoint_file.stat().st_size / (1024 * 1024),
                        'creation_timestamp': checkpoint_file.stat().st_mtime
                    }
                
                metadata['file_path'] = str(checkpoint_file)
                metadata['valid'] = self._verify_checkpoint(checkpoint_file)
                checkpoints.append(metadata)
                
            except Exception as e:
                self.logger.warning(f"Error reading checkpoint metadata: {e}")
        
        checkpoints.sort(key=lambda x: x.get('step', 0), reverse=True)
        return checkpoints

class ResumableSimulation:
    """Enhanced simulation class that integrates checkpointing"""
    
    def __init__(self, output_dir: str, checkpoint_interval: int = 50000):
        self.output_dir = Path(output_dir)
        self.checkpoint_manager = CheckpointManager(output_dir, checkpoint_interval)
        self.logger = logging.getLogger('resumable_simulation')
        
        self.current_state = None
        self.lattice = None
        self.start_time = None
    
    def initialize_simulation(self, lattice_size: int, p_value: float, 
                            num_steps: int, num_walkers: int, 
                            random_seed: int = 42) -> SimulationState:
        latest_checkpoint = self.checkpoint_manager.find_latest_checkpoint()
        
        if latest_checkpoint:
            self.logger.info("Resuming from checkpoint...")
            state, lattice = self.checkpoint_manager.load_checkpoint(latest_checkpoint)
            
            if (state.lattice_size != lattice_size or 
                state.p_value != p_value or 
                state.num_steps != num_steps):
                
                self.logger.warning(
                    "Checkpoint parameters don't match current simulation. "
                    "Starting new simulation."
                )
                state = None
                lattice = None
        else:
            state = None
            lattice = None
        
        if state is None:
            self.logger.info("Starting new simulation...")
            
            np.random.seed(random_seed)
            lattice = np.random.random((lattice_size, lattice_size, lattice_size)) < p_value
            lattice = lattice.astype(np.uint8)
            
            walker_positions = self._initialize_walkers(lattice, num_walkers, random_seed)
            
            state = SimulationState(
                lattice_size=lattice_size,
                p_value=p_value,
                num_steps=num_steps,
                current_step=0,
                random_seed=random_seed,
                walker_positions=walker_positions,
                initial_positions=walker_positions.copy(),
                msd_data=[],
                start_time=time.time(),
                checkpoint_time=time.time(),
                elapsed_time=0.0,
                lattice_hash=self.checkpoint_manager._calculate_lattice_hash(lattice)
            )
        
        self.current_state = state
        self.lattice = lattice
        self.start_time = time.time()
        
        self.logger.info(
            f"Simulation initialized: L={lattice_size}, p={p_value:.4f}, "
            f"steps={num_steps:,}, walkers={len(state.walker_positions)}"
        )
        
        if state.current_step > 0:
            self.logger.info(f"Resuming from step {state.current_step:,}")
        
        return state
    
    def _initialize_walkers(self, lattice: np.ndarray, num_walkers: int, 
                          random_seed: int) -> np.ndarray:
        np.random.seed(random_seed)
        
        unoccupied_sites = np.where(lattice == 0)
        unoccupied_coords = list(zip(unoccupied_sites[0], unoccupied_sites[1], unoccupied_sites[2]))
        
        if len(unoccupied_coords) < num_walkers:
            raise ValueError(
                f"Not enough unoccupied sites ({len(unoccupied_coords)}) "
                f"for {num_walkers} walkers"
            )
        
        selected_indices = np.random.choice(
            len(unoccupied_coords), num_walkers, replace=False
        )
        
        walker_positions = np.array([unoccupied_coords[i] for i in selected_indices])
        
        return walker_positions
    
    def should_checkpoint(self, step: int) -> bool:
        return self.checkpoint_manager.should_checkpoint(step)
    
    def create_checkpoint(self) -> bool:
        if self.current_state is None:
            self.logger.error("No simulation state to checkpoint")
            return False
        
        current_time = time.time()
        self.current_state.checkpoint_time = current_time
        self.current_state.elapsed_time = current_time - self.start_time
        
        checkpoint_file = self.checkpoint_manager.create_checkpoint(
            self.current_state, self.lattice
        )
        
        return checkpoint_file is not None
    
    def step_walkers(self) -> None:
        if self.current_state is None or self.lattice is None:
            raise RuntimeError("Simulation not initialized")
        
        moves = np.array([
            [1, 0, 0], [-1, 0, 0],
            [0, 1, 0], [0, -1, 0],
            [0, 0, 1], [0, 0, -1]
        ])
        
        L = self.current_state.lattice_size
        
        move_indices = np.random.randint(0, 6, len(self.current_state.walker_positions))
        proposed_moves = moves[move_indices]
        
        new_positions = (self.current_state.walker_positions + proposed_moves) % L
        
        for i, new_pos in enumerate(new_positions):
            if self.lattice[new_pos[0], new_pos[1], new_pos[2]] == 0:
                self.current_state.walker_positions[i] = new_pos
        
        self.current_state.current_step += 1
    
    def calculate_msd(self) -> float:
        if self.current_state is None:
            raise RuntimeError("Simulation not initialized")
        
        displacements = self.current_state.walker_positions - self.current_state.initial_positions
        L = self.current_state.lattice_size
        
        for dim in range(3):
            displacements[:, dim] = np.where(
                displacements[:, dim] > L/2,
                displacements[:, dim] - L,
                displacements[:, dim]
            )
            displacements[:, dim] = np.where(
                displacements[:, dim] < -L/2,
                displacements[:, dim] + L,
                displacements[:, dim]
            )
        
        squared_displacements = np.sum(displacements**2, axis=1)
        msd = np.mean(squared_displacements)
        
        return msd
    
    def save_final_results(self) -> str:
        if self.current_state is None:
            raise RuntimeError("No simulation state to save")
        
        df = pd.DataFrame(self.current_state.msd_data)
        
        df.attrs['lattice_size'] = self.current_state.lattice_size
        df.attrs['p_value'] = self.current_state.p_value
        df.attrs['num_steps'] = self.current_state.num_steps
        df.attrs['total_walkers'] = len(self.current_state.walker_positions)
        df.attrs['random_seed'] = self.current_state.random_seed
        df.attrs['elapsed_time'] = self.current_state.elapsed_time
        
        results_file = self.output_dir / f"msd_results_L{self.current_state.lattice_size}_p{self.current_state.p_value:.4f}.csv"
        df.to_csv(results_file, index=False)
        
        self.logger.info(f"Final results saved: {results_file}")
        return str(results_file)
'''
    
    with open("robust_simulation/checkpoint_system.py", "w") as f:
        f.write(content)
    print("Created: robust_simulation/checkpoint_system.py")

def create_ultra_robust_sim():
    """Create robust_simulation/ultra_robust_sim.py"""
    
    content = '''# robust_simulation/ultra_robust_sim.py
"""
Ultra-Robust Percolation Simulation - Complete Integration

This module combines resource management and checkpointing into a single,
easy-to-use interface for production-quality percolation simulations.
"""

import numpy as np
import pandas as pd
import time
import logging
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from .resource_manager import (
    RobustSimulationWrapper, ResourceLimits, 
    InterruptionHandler, ResourceMonitor, SafeFileHandler
)
from .checkpoint_system import (
    ResumableSimulation, CheckpointManager, SimulationState
)

class UltraRobustPercolationSimulation:
    """
    The ultimate robust simulation class that combines:
    - Resource monitoring and limits
    - Automatic checkpointing and recovery
    - Error handling and graceful shutdown
    - Progress monitoring and logging
    - Safe file operations
    """
    
    def __init__(self, 
                 output_dir: str,
                 resource_limits: Optional[ResourceLimits] = None,
                 checkpoint_interval: int = 50_000,
                 msd_calculation_interval: int = 1_000):
        
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        self.resource_limits = resource_limits or ResourceLimits(
            max_memory_gb=8.0,
            max_runtime_hours=24.0,
            min_disk_space_gb=5.0,
            memory_check_interval=1000
        )
        
        self.safety_wrapper = RobustSimulationWrapper(
            str(self.output_dir), 
            self.resource_limits
        )
        
        self.resumable_sim = ResumableSimulation(
            str(self.output_dir),
            checkpoint_interval
        )
        
        self.msd_interval = msd_calculation_interval
        self.logger = logging.getLogger('ultra_robust_simulation')
        
        self.performance_stats = {
            'steps_completed': 0,
            'checkpoints_created': 0,
            'msd_calculations': 0,
            'total_runtime': 0.0,
            'average_steps_per_second': 0.0
        }
        
        self.logger.info("Ultra-robust percolation simulation initialized")
        self.logger.info(f"Output directory: {self.output_dir}")
        self.logger.info(f"Checkpoint interval: {checkpoint_interval:,} steps")
        self.logger.info(f"MSD calculation interval: {msd_calculation_interval:,} steps")
    
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
            
            start_step = state.current_step
            simulation_start_time = time.time()
            
            self.logger.info(
                f"Running simulation: L={lattice_size}, p={p_value:.4f}, "
                f"steps={num_steps:,}, walkers={num_walkers}"
            )
            
            if start_step > 0:
                self.logger.info(f"Resuming from step {start_step:,}")
            
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
                        
                        self.performance_stats['msd_calculations'] += 1
                    
                    if state.current_step % self.resource_limits.memory_check_interval == 0:
                        progress_info = safety_wrapper.check_progress(
                            state.current_step, num_steps
                        )
                        
                        if progress_info:
                            self.performance_stats['average_steps_per_second'] = progress_info['steps_per_second']
                    
                    if self.resumable_sim.should_checkpoint(state.current_step):
                        self.logger.info(f"Creating checkpoint at step {state.current_step:,}")
                        
                        if self.resumable_sim.create_checkpoint():
                            self.performance_stats['checkpoints_created'] += 1
                            self.logger.info("Checkpoint created successfully")
                        else:
                            self.logger.warning("Checkpoint creation failed")
                    
                    self.performance_stats['steps_completed'] = state.current_step
                
                total_runtime = time.time() - simulation_start_time
                self.performance_stats['total_runtime'] = total_runtime
                
                self.logger.info(
                    f"Simulation completed! "
                    f"Steps: {state.current_step:,}/{num_steps:,}, "
                    f"Runtime: {total_runtime/60:.2f} minutes"
                )
                
                results_file = self.resumable_sim.save_final_results()
                self._save_performance_summary(state, total_runtime)
                
                return pd.DataFrame(state.msd_data)
                
            except KeyboardInterrupt:
                self.logger.warning("Simulation interrupted by user")
                self.logger.info("Creating final checkpoint...")
                self.resumable_sim.create_checkpoint()
                
                if state.msd_data:
                    self.logger.info(f"Returning {len(state.msd_data)} partial results")
                    return pd.DataFrame(state.msd_data)
                else:
                    self.logger.warning("No data collected before interruption")
                    return pd.DataFrame()
        
        return self.safety_wrapper.run_with_safety(_safe_simulation)
    
    def _save_performance_summary(self, state: SimulationState, runtime: float):
        summary = {
            'simulation_parameters': {
                'lattice_size': state.lattice_size,
                'p_value': state.p_value,
                'total_steps': state.num_steps,
                'completed_steps': state.current_step,
                'num_walkers': len(state.walker_positions),
                'random_seed': state.random_seed
            },
            'performance_metrics': {
                'total_runtime_hours': runtime / 3600,
                'steps_per_second': state.current_step / runtime if runtime > 0 else 0,
                'msd_data_points': len(state.msd_data),
                'checkpoints_created': self.performance_stats['checkpoints_created'],
                'memory_checks': state.current_step // self.resource_limits.memory_check_interval,
                'completion_percentage': (state.current_step / state.num_steps) * 100
            },
            'data_quality': {
                'msd_calculation_interval': self.msd_interval,
                'checkpoint_interval': self.resumable_sim.checkpoint_manager.checkpoint_interval,
                'final_msd': state.msd_data[-1]['msd'] if state.msd_data else None,
                'msd_growth_rate': self._calculate_msd_growth_rate(state.msd_data)
            }
        }
        
        summary_file = self.output_dir / f"simulation_summary_p_{state.p_value:.4f}.json"
        
        import json
        with open(summary_file, 'w') as f:
            json.dump(summary, f, indent=2)
        
        self.logger.info(f"Performance summary saved: {summary_file}")
    
    def _calculate_msd_growth_rate(self, msd_data: List[Dict]) -> Optional[float]:
        if len(msd_data) < 10:
            return None
        
        tau_values = np.array([d['tau'] for d in msd_data[-100:]])
        msd_values = np.array([d['msd'] for d in msd_data[-100:]])
        
        if np.any(msd_values <= 0) or np.any(tau_values <= 0):
            return None
        
        try:
            log_tau = np.log10(tau_values)
            log_msd = np.log10(msd_values)
            
            coeffs = np.polyfit(log_tau, log_msd, 1)
            growth_exponent = coeffs[0]
            
            return float(growth_exponent)
            
        except Exception:
            return None
    
    def get_simulation_status(self) -> Dict:
        checkpoints = self.resumable_sim.checkpoint_manager.list_checkpoints()
        
        status = {
            'output_directory': str(self.output_dir),
            'resource_limits': {
                'max_memory_gb': self.resource_limits.max_memory_gb,
                'max_runtime_hours': self.resource_limits.max_runtime_hours,
                'min_disk_space_gb': self.resource_limits.min_disk_space_gb
            },
            'available_checkpoints': len(checkpoints),
            'latest_checkpoint': checkpoints[0] if checkpoints else None,
            'performance_stats': self.performance_stats.copy()
        }
        
        return status
    
    def cleanup_old_files(self, keep_checkpoints: int = 3):
        self.logger.info("Cleaning up old files...")
        
        self.resumable_sim.checkpoint_manager.max_checkpoints = keep_checkpoints
        self.resumable_sim.checkpoint_manager._cleanup_old_checkpoints()
        
        self.safety_wrapper.file_handler.cleanup_temp_files()
        
        self.logger.info("Cleanup completed")
'''
    
    with open("robust_simulation/ultra_robust_sim.py", "w") as f:
        f.write(content)
    print("Created: robust_simulation/ultra_robust_sim.py")

def create_init_file():
    """Create robust_simulation/__init__.py"""
    
    # Use the content from the earlier artifact
    with open("robust_simulation/__init__.py", "w") as f:
        # Copy the content from the robust_simulation_init artifact
        pass
    print("Created: robust_simulation/__init__.py")

def main():
    """Main function to create all module files"""
    
    print("Creating enhanced robust simulation module files...")
    print("=" * 60)
    
    # Create directory structure
    create_directory_structure()
    print()
    
    # Create module files
    create_resource_manager()
    create_checkpoint_system() 
    create_ultra_robust_sim()
    create_init_file()
    
    print()
    print("=" * 60)
    print("✅ All module files created successfully!")
    print()
    print("Next steps:")
    print("1. Test the modules: python -c 'from robust_simulation import quick_test; quick_test()'")
    print("2. Run enhanced simulation: python robust_simulation/examples/enhanced_random_walk.py --test")
    print("3. Set up environment: ./scripts/setup_robust_environment.sh")
    print()
    print("Files created:")
    print("- robust_simulation/resource_manager.py")
    print("- robust_simulation/checkpoint_system.py")
    print("- robust_simulation/ultra_robust_sim.py")
    print("- robust_simulation/__init__.py")

if __name__ == "__main__":
    main()
'''

    with open("scripts/create_robust_modules.py", "w") as f:
        f.write(content)
    print("Created: scripts/create_robust_modules.py")

def main():
    """Create all the files needed for GitHub integration"""
    
    print("🚀 Creating GitHub integration files...")
    print("=" * 60)
    
    create_directory_structure()
    create_module_files_script()
    
    print("\n" + "=" * 60)
    print("✅ GitHub integration files created!")
    print("\nNext steps:")
    print("1. Run: python scripts/create_robust_modules.py")
    print("2. Run: chmod +x scripts/setup_robust_environment.sh")
    print("3. Test: python robust_simulation/examples/enhanced_random_walk.py --test")
    print("4. Commit and push to GitHub using the instructions above")

if __name__ == "__main__":
    main()