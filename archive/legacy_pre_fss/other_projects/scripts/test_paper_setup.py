#!/usr/bin/env python3
"""
Test script for paper simulation setup
Runs a quick test with reduced parameters to verify everything works
"""

import sys
import subprocess
from pathlib import Path

def test_simulation_runner():
    """Test the simulation runner with reduced parameters"""
    
    print("🧪 Testing paper simulation setup...")
    
    # Test with reduced parameters
    cmd = [
        sys.executable, 
        "scripts/run_paper_simulations.py",
        "--test",
        "--parallel", "1",
        "--output-dir", "test_paper_simulations"
    ]
    
    print(f"Running: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        
        if result.returncode == 0:
            print("✅ Simulation runner test passed!")
            print("Output:", result.stdout)
            return True
        else:
            print("❌ Simulation runner test failed!")
            print("Error:", result.stderr)
            return False
            
    except subprocess.TimeoutExpired:
        print("⏰ Test timed out (5 minutes)")
        return False
    except Exception as e:
        print(f"💥 Test failed: {e}")
        return False

def test_analysis_script():
    """Test the analysis script with sample data"""
    
    print("\n🧪 Testing analysis script...")
    
    # Check if test data exists
    test_data_dir = Path("test_paper_simulations")
    if not test_data_dir.exists():
        print("⚠️  No test data found - skipping analysis test")
        return True
    
    cmd = [
        sys.executable,
        "scripts/analyze_paper_results.py",
        "--input-dir", "test_paper_simulations",
        "--output-dir", "test_paper_analysis",
        "--p-values", "0.0", "0.3116"
    ]
    
    print(f"Running: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        
        if result.returncode == 0:
            print("✅ Analysis script test passed!")
            return True
        else:
            print("❌ Analysis script test failed!")
            print("Error:", result.stderr)
            return False
            
    except Exception as e:
        print(f"💥 Analysis test failed: {e}")
        return False

def main():
    """Run all tests"""
    
    print("🚀 Paper Simulation Setup Test")
    print("=" * 50)
    
    # Test simulation runner
    sim_success = test_simulation_runner()
    
    # Test analysis script
    analysis_success = test_analysis_script()
    
    print("\n" + "=" * 50)
    print("📊 Test Results:")
    print(f"   Simulation runner: {'✅ PASS' if sim_success else '❌ FAIL'}")
    print(f"   Analysis script: {'✅ PASS' if analysis_success else '❌ FAIL'}")
    
    if sim_success and analysis_success:
        print("\n🎉 All tests passed! Ready for full paper simulations.")
        print("\n📋 Next steps:")
        print("1. Run full simulations: python scripts/run_paper_simulations.py")
        print("2. Analyze results: python scripts/analyze_paper_results.py")
        print("3. Check results in paper_simulations/ and paper_analysis/")
        return 0
    else:
        print("\n⚠️  Some tests failed. Check the output above.")
        return 1

if __name__ == "__main__":
    sys.exit(main()) 