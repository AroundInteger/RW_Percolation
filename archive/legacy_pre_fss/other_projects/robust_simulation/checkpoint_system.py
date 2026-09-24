"""
Robust Checkpointing System for Long-Running Simulations
"""

import pickle
import json
import time
import hashlib
import numpy as np
import pandas as pd
from pathlib import Path
from typing import Dict, Any, Optional, List, Tuple
from dataclasses import dataclass
import logging

@dataclass
class SimulationState:
    lattice_size: int
    p_value: float
    num_steps: int
    current_step: int
    random_seed: int
    walker_positions: np.ndarray
    initial_positions: np.ndarray
    msd_data: List[Dict]
    start_time: float
    checkpoint_time: float
    elapsed_time: float
    lattice_hash: str

class CheckpointManager:
    def __init__(self, output_dir: str, checkpoint_interval: int = 50000):
        self.output_dir = Path(output_dir)
        self.checkpoint_interval = checkpoint_interval
        self.checkpoint_dir = self.output_dir / "checkpoints"
        self.checkpoint_dir.mkdir(parents=True, exist_ok=True)
        self.logger = logging.getLogger('checkpoint_manager')
        self.checkpoint_history = []
        self.max_checkpoints = 5
    
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
                    'checkpoint_version': '1.0',
                    'creation_time': timestamp
                }
                pickle.dump(checkpoint_data, f, protocol=pickle.HIGHEST_PROTOCOL)
            
            self.logger.info(f"Checkpoint created: {checkpoint_name}")
            return str(checkpoint_file)
        except Exception as e:
            self.logger.error(f"Failed to create checkpoint: {e}")
            return None
    
    def find_latest_checkpoint(self) -> Optional[str]:
        checkpoint_files = list(self.checkpoint_dir.glob("checkpoint_step_*.pkl"))
        if not checkpoint_files:
            return None
        
        checkpoint_files.sort(key=lambda f: f.stat().st_mtime, reverse=True)
        return str(checkpoint_files[0])
    
    def load_checkpoint(self, checkpoint_file: str) -> Tuple[SimulationState, np.ndarray]:
        with open(checkpoint_file, 'rb') as f:
            checkpoint_data = pickle.load(f)
        
        state = checkpoint_data['state']
        lattice = checkpoint_data['lattice']
        
        self.logger.info(f"Loaded checkpoint: step {state.current_step:,}")
        return state, lattice
    
    def _calculate_lattice_hash(self, lattice: np.ndarray) -> str:
        return hashlib.md5(lattice.tobytes()).hexdigest()

class ResumableSimulation:
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
                self.logger.warning("Checkpoint parameters don't match. Starting new simulation.")
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
        
        return state
    
    def _initialize_walkers(self, lattice: np.ndarray, num_walkers: int, 
                          random_seed: int) -> np.ndarray:
        np.random.seed(random_seed)
        
        unoccupied_sites = np.where(lattice == 0)
        unoccupied_coords = list(zip(unoccupied_sites[0], unoccupied_sites[1], unoccupied_sites[2]))
        
        if len(unoccupied_coords) < num_walkers:
            raise ValueError(f"Not enough unoccupied sites for {num_walkers} walkers")
        
        selected_indices = np.random.choice(len(unoccupied_coords), num_walkers, replace=False)
        walker_positions = np.array([unoccupied_coords[i] for i in selected_indices])
        
        return walker_positions
    
    def should_checkpoint(self, step: int) -> bool:
        return self.checkpoint_manager.should_checkpoint(step)
    
    def create_checkpoint(self) -> bool:
        if self.current_state is None:
            return False
        
        current_time = time.time()
        self.current_state.checkpoint_time = current_time
        self.current_state.elapsed_time = current_time - self.start_time
        
        checkpoint_file = self.checkpoint_manager.create_checkpoint(self.current_state, self.lattice)
        return checkpoint_file is not None
    
    def step_walkers(self) -> None:
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
        return np.mean(squared_displacements)
    
    def save_final_results(self) -> str:
        df = pd.DataFrame(self.current_state.msd_data)
        results_file = self.output_dir / f"msd_results_L{self.current_state.lattice_size}_p{self.current_state.p_value:.4f}.csv"
        df.to_csv(results_file, index=False)
        self.logger.info(f"Results saved: {results_file}")
        return str(results_file)
