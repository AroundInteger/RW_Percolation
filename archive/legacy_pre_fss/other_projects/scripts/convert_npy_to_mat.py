#!/usr/bin/env python3
"""
Convert .npy files to MATLAB-compatible .mat files
This allows the MATLAB consolidated verification system to work with the surface data.
"""

import numpy as np
import scipy.io as sio
import os
import pandas as pd

def convert_npy_to_mat():
    """Convert all .npy files to .mat files for MATLAB compatibility"""
    
    print("=== CONVERTING .NPY FILES TO MATLAB .MAT FILES ===")
    
    # Define paths
    surface_data_dir = "output_3d_surfaces/surface_data"
    output_dir = "output_3d_surfaces/surface_data"
    
    # Files to convert
    npy_files = [
        'p_grid.npy',
        'omega_grid.npy', 
        'G_prime_surface.npy',
        'G_double_prime_surface.npy',
        'delta_surface.npy',
        'tan_delta_surface.npy'
    ]
    
    print(f"Converting {len(npy_files)} .npy files to .mat format...")
    
    for npy_file in npy_files:
        npy_path = os.path.join(surface_data_dir, npy_file)
        mat_file = npy_file.replace('.npy', '.mat')
        mat_path = os.path.join(output_dir, mat_file)
        
        if os.path.exists(npy_path):
            try:
                # Load .npy file
                data = np.load(npy_path)
                
                # Save as .mat file
                sio.savemat(mat_path, {npy_file.replace('.npy', ''): data})
                
                print(f"  ✓ {npy_file} → {mat_file}")
                print(f"    Shape: {data.shape}, Data type: {data.dtype}")
                
            except Exception as e:
                print(f"  ✗ Error converting {npy_file}: {e}")
        else:
            print(f"  ⚠ File not found: {npy_path}")
    
    # Also create a comprehensive .mat file with all data
    print(f"\nCreating comprehensive MATLAB data file...")
    
    try:
        # Load all data
        p_grid = np.load(os.path.join(surface_data_dir, 'p_grid.npy'))
        omega_grid = np.load(os.path.join(surface_data_dir, 'omega_grid.npy'))
        G_prime_surface = np.load(os.path.join(surface_data_dir, 'G_prime_surface.npy'))
        G_double_prime_surface = np.load(os.path.join(surface_data_dir, 'G_double_prime_surface.npy'))
        delta_surface = np.load(os.path.join(surface_data_dir, 'delta_surface.npy'))
        tan_delta_surface = np.load(os.path.join(surface_data_dir, 'tan_delta_surface.npy'))
        
        # Create comprehensive data structure
        comprehensive_data = {
            'p_grid': p_grid,
            'omega_grid': omega_grid,
            'G_prime_surface': G_prime_surface,
            'G_double_prime_surface': G_double_prime_surface,
            'delta_surface': delta_surface,
            'tan_delta_surface': tan_delta_surface,
            'metadata': {
                'description': '3D Viscoelastic Surface Data for MATLAB',
                'p_range': [float(p_grid.min()), float(p_grid.max())],
                'omega_range': [float(omega_grid.min()), float(omega_grid.max())],
                'grid_shape': [int(omega_grid.shape[0]), int(p_grid.shape[0])],
                'generated_by': 'Python viscoelastic_3d_surfaces.py',
                'converted_by': 'convert_npy_to_mat.py'
            }
        }
        
        # Save comprehensive .mat file
        comprehensive_path = os.path.join(output_dir, 'viscoelastic_surfaces_comprehensive.mat')
        sio.savemat(comprehensive_path, comprehensive_data)
        
        print(f"  ✓ Comprehensive data saved: viscoelastic_surfaces_comprehensive.mat")
        print(f"    Contains all surfaces and metadata for MATLAB")
        
    except Exception as e:
        print(f"  ✗ Error creating comprehensive file: {e}")
    
    print(f"\n=== CONVERSION COMPLETE ===")
    print(f"MATLAB-compatible .mat files created in: {output_dir}")
    print(f"You can now use these files in MATLAB!")

if __name__ == "__main__":
    convert_npy_to_mat()
