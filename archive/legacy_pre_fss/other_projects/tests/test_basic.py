#!/usr/bin/env python3
"""
Basic tests for robust simulation features
"""

import sys
import tempfile
from pathlib import Path

# Add parent directory to path
sys.path.append(str(Path(__file__).parent.parent))

def test_import():
    """Test basic imports"""
    try:
        from robust_simulation import UltraRobustPercolationSimulation
        from robust_simulation import ResourceLimits
        print("✅ Import test passed")
        return True
    except ImportError as e:
        print(f"❌ Import test failed: {e}")
        return False

def test_quick_simulation():
    """Test basic simulation"""
    try:
        from robust_simulation import UltraRobustPercolationSimulation
        
        with tempfile.TemporaryDirectory() as temp_dir:
            sim = UltraRobustPercolationSimulation(temp_dir)
            results = sim.run_simulation(
                lattice_size=20,
                p_value=0.5,
                num_steps=1000,
                num_walkers=10
            )
            
            if len(results) > 0:
                print("✅ Simulation test passed")
                return True
            else:
                print("❌ Simulation test failed: no results")
                return False
                
    except Exception as e:
        print(f"❌ Simulation test failed: {e}")
        return False

def main():
    """Run all tests"""
    print("Running basic tests...")
    
    tests = [test_import, test_quick_simulation]
    passed = 0
    
    for test in tests:
        if test():
            passed += 1
    
    print(f"\nResults: {passed}/{len(tests)} tests passed")
    
    if passed == len(tests):
        print("🎉 All tests passed!")
        return 0
    else:
        print("❌ Some tests failed")
        return 1

if __name__ == "__main__":
    sys.exit(main())
