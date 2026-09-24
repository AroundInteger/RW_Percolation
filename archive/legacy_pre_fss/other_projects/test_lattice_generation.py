#!/usr/bin/env python3
"""
Test lattice generation logic
"""

import numpy as np

def test_lattice_generation():
    print("=== Testing Lattice Generation ===")
    
    lattice_size = 10
    random_seed = 42
    
    # Test p = 0.0000 (should be all zeros - free random walk)
    print(f"\nTesting p = 0.0000:")
    np.random.seed(random_seed)
    lattice_p0 = np.random.random((lattice_size, lattice_size, lattice_size)) < 0.0000
    lattice_p0 = lattice_p0.astype(np.uint8)
    
    print(f"  Lattice shape: {lattice_p0.shape}")
    print(f"  Unique values: {np.unique(lattice_p0)}")
    print(f"  Sum of occupied sites: {np.sum(lattice_p0)}")
    print(f"  Fraction occupied: {np.sum(lattice_p0) / lattice_p0.size:.6f}")
    
    # Test p = 0.3116 (should be ~31.16% occupied)
    print(f"\nTesting p = 0.3116:")
    np.random.seed(random_seed)
    lattice_p03116 = np.random.random((lattice_size, lattice_size, lattice_size)) < 0.3116
    lattice_p03116 = lattice_p03116.astype(np.uint8)
    
    print(f"  Lattice shape: {lattice_p03116.shape}")
    print(f"  Unique values: {np.unique(lattice_p03116)}")
    print(f"  Sum of occupied sites: {np.sum(lattice_p03116)}")
    print(f"  Fraction occupied: {np.sum(lattice_p03116) / lattice_p03116.size:.6f}")
    
    # Test p = 1.0000 (should be all ones - completely blocked)
    print(f"\nTesting p = 1.0000:")
    np.random.seed(random_seed)
    lattice_p1 = np.random.random((lattice_size, lattice_size, lattice_size)) < 1.0000
    lattice_p1 = lattice_p1.astype(np.uint8)
    
    print(f"  Lattice shape: {lattice_p1.shape}")
    print(f"  Unique values: {np.unique(lattice_p1)}")
    print(f"  Sum of occupied sites: {np.sum(lattice_p1)}")
    print(f"  Fraction occupied: {np.sum(lattice_p1) / lattice_p1.size:.6f}")
    
    # Test walker initialization logic
    print(f"\n=== Testing Walker Initialization ===")
    
    # For p = 0.0000 (all sites should be available)
    unoccupied_sites_p0 = np.where(lattice_p0 == 0)
    unoccupied_coords_p0 = list(zip(unoccupied_sites_p0[0], unoccupied_sites_p0[1], unoccupied_sites_p0[2]))
    
    print(f"p = 0.0000:")
    print(f"  Total lattice sites: {lattice_p0.size}")
    print(f"  Unoccupied sites: {len(unoccupied_coords_p0)}")
    print(f"  Can place 10 walkers: {len(unoccupied_coords_p0) >= 10}")
    
    # For p = 0.3116
    unoccupied_sites_p03116 = np.where(lattice_p03116 == 0)
    unoccupied_coords_p03116 = list(zip(unoccupied_sites_p03116[0], unoccupied_sites_p03116[1], unoccupied_sites_p03116[2]))
    
    print(f"p = 0.3116:")
    print(f"  Total lattice sites: {lattice_p03116.size}")
    print(f"  Unoccupied sites: {len(unoccupied_coords_p03116)}")
    print(f"  Can place 10 walkers: {len(unoccupied_coords_p03116) >= 10}")
    
    # For p = 1.0000
    unoccupied_sites_p1 = np.where(lattice_p1 == 0)
    unoccupied_coords_p1 = list(zip(unoccupied_sites_p1[0], unoccupied_sites_p1[1], unoccupied_sites_p1[2]))
    
    print(f"p = 1.0000:")
    print(f"  Total lattice sites: {lattice_p1.size}")
    print(f"  Unoccupied sites: {len(unoccupied_coords_p1)}")
    print(f"  Can place 10 walkers: {len(unoccupied_coords_p1) >= 10}")

if __name__ == "__main__":
    test_lattice_generation() 