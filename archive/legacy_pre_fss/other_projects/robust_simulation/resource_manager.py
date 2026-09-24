"""
Resource Management and Error Handling for Robust Percolation Simulations
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
    max_memory_gb: float = 8.0
    max_runtime_hours: float = 48.0
    min_disk_space_gb: float = 5.0
    memory_check_interval: int = 1000
    
    def __post_init__(self):
        total_memory_gb = psutil.virtual_memory().total / (1024**3)
        self.max_memory_gb = min(self.max_memory_gb, total_memory_gb * 0.8)

class SimulationError(Exception):
    pass

class ResourceExhaustionError(SimulationError):
    pass

class ResourceMonitor:
    def __init__(self, limits: ResourceLimits, output_dir: str):
        self.limits = limits
        self.output_dir = Path(output_dir)
        self.start_time = time.time()
        self.process = psutil.Process()
        self._setup_logging()
        self._validate_initial_resources()
    
    def _setup_logging(self):
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.logger = logging.getLogger('resource_monitor')
        self.logger.setLevel(logging.INFO)
        
        log_file = self.output_dir / "resource_monitor.log"
        file_handler = logging.FileHandler(log_file)
        file_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
        self.logger.addHandler(file_handler)
    
    def _validate_initial_resources(self):
        available_memory_gb = psutil.virtual_memory().available / (1024**3)
        if available_memory_gb < self.limits.max_memory_gb:
            raise ResourceExhaustionError(f"Insufficient memory: {available_memory_gb:.1f}GB available")
        
        disk_usage = psutil.disk_usage(self.output_dir.parent)
        available_disk_gb = disk_usage.free / (1024**3)
        if available_disk_gb < self.limits.min_disk_space_gb:
            raise ResourceExhaustionError(f"Insufficient disk space: {available_disk_gb:.1f}GB available")
        
        self.logger.info("Initial resource validation passed")
    
    def check_resources(self, step: int, total_steps: int) -> dict:
        current_time = time.time()
        memory_gb = self.process.memory_info().rss / (1024**3)
        
        if memory_gb > self.limits.max_memory_gb:
            raise ResourceExhaustionError(f"Memory limit exceeded: {memory_gb:.2f}GB")
        
        elapsed_hours = (current_time - self.start_time) / 3600
        if elapsed_hours > self.limits.max_runtime_hours:
            raise ResourceExhaustionError(f"Runtime limit exceeded: {elapsed_hours:.1f}h")
        
        if step > 0:
            steps_per_second = step / (current_time - self.start_time)
            eta_seconds = (total_steps - step) / steps_per_second if steps_per_second > 0 else float('inf')
        else:
            steps_per_second = 0
            eta_seconds = float('inf')
        
        if step % self.limits.memory_check_interval == 0:
            self.logger.info(
                f"Step {step:,}/{total_steps:,} ({step/total_steps*100:.1f}%) - "
                f"Memory: {memory_gb:.2f}GB - Rate: {steps_per_second:.0f} steps/s - "
                f"ETA: {eta_seconds/60:.1f}min"
            )
        
        return {
            'memory_gb': memory_gb,
            'steps_per_second': steps_per_second,
            'eta_minutes': eta_seconds / 60,
            'progress_percent': step / total_steps * 100
        }

class SafeFileHandler:
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
    
    def cleanup_temp_files(self):
        temp_files = list(self.base_path.glob("*.tmp"))
        for temp_file in temp_files:
            try:
                temp_file.unlink()
            except Exception:
                pass

class RobustSimulationWrapper:
    def __init__(self, output_dir: str, limits: Optional[ResourceLimits] = None):
        self.output_dir = output_dir
        self.limits = limits or ResourceLimits()
        self.resource_monitor = ResourceMonitor(self.limits, output_dir)
        self.file_handler = SafeFileHandler(output_dir)
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
            self.logger.info(f"Simulation completed in {elapsed_time/60:.2f} minutes")
            return result
        except Exception as e:
            self.logger.error(f"Simulation failed: {e}")
            raise SimulationError(f"Simulation failed: {e}") from e
    
    def check_progress(self, step: int, total_steps: int):
        if step % self.limits.memory_check_interval == 0:
            return self.resource_monitor.check_resources(step, total_steps)
        return None
