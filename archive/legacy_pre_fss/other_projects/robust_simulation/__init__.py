"""
Ultra-Robust Percolation Simulation System
"""

from .resource_manager import (
    RobustSimulationWrapper,
    ResourceLimits,
    SimulationError,
    ResourceExhaustionError
)

from .checkpoint_system import (
    ResumableSimulation,
    CheckpointManager,
    SimulationState
)

from .ultra_robust_sim import (
    UltraRobustPercolationSimulation
)

__version__ = "1.0.0"

__all__ = [
    'UltraRobustPercolationSimulation',
    'RobustSimulationWrapper',
    'ResourceLimits',
    'ResumableSimulation', 
    'CheckpointManager',
    'SimulationState',
    'SimulationError',
    'ResourceExhaustionError'
]

def quick_test():
    """Quick test to verify installation"""
    try:
        from .ultra_robust_sim import UltraRobustPercolationSimulation
        from .resource_manager import ResourceLimits
        
        print("✅ Robust simulation system loaded successfully!")
        print(f"   Version: {__version__}")
        return True
        
    except ImportError as e:
        print(f"❌ Import error: {e}")
        return False

if __name__ == "__main__":
    quick_test()
