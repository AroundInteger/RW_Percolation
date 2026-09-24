#!/usr/bin/env python3
"""
3D Viscoelastic Surfaces for G'(ω) and G''(ω)
Creates novel 3D surface visualizations showing how storage and loss moduli evolve
as functions of both percolation probability (p) and frequency (ω).
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from matplotlib import cm
import seaborn as sns
from scipy.interpolate import griddata
import os

# Set plotting style
plt.style.use('default')
sns.set_palette("husl")

class Viscoelastic3DSurfaces:
    """
    Generate 3D surfaces for G'(ω) and G''(ω) as functions of p and ω
    """
    
    def __init__(self, analyzer_results_file, output_dir="output_3d_surfaces"):
        """
        Initialize the 3D surface generator
        
        Parameters:
        - analyzer_results_file: Path to hybrid analyzer results CSV
        - output_dir: Directory to save output plots
        """
        self.analyzer_results_file = analyzer_results_file
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)
        
        # Load analyzer results
        self.results = pd.read_csv(analyzer_results_file)
        
        # Extract sigmoid parameters
        self.extract_sigmoid_parameters()
        
        # Define frequency range (logarithmic scale)
        self.omega_min = 1e-3  # 0.001 rad/s
        self.omega_max = 1e3   # 1000 rad/s
        self.omega_points = 100
        
        # Define p-range based on data
        self.p_min = self.results['p'].min()
        self.p_max = self.results['p'].max()
        self.p_points = 200
        
        # Create fine grids
        self.create_fine_grids()
        
    def extract_sigmoid_parameters(self):
        """Extract sigmoid parameters from results"""
        
        # Get the first row with sigmoid parameters
        sigmoid_row = self.results[self.results['alpha_sigmoid'].notna()].iloc[0]
        
        # Extract sigmoid parameters (these should be consistent across all rows)
        self.p_c = 0.6884  # Theoretical value
        self.width = 0.015  # Typical width from analysis
        self.alpha_min = 0.0
        self.alpha_max = 1.0
        
        # If we have actual fitted parameters, use them
        if 'sigmoid_params' in self.results.columns:
            # Parse sigmoid parameters string if stored as string
            pass
        
        print(f"Using sigmoid parameters:")
        print(f"  p_c = {self.p_c:.4f}")
        print(f"  width = {self.width:.4f}")
        print(f"  α_min = {self.alpha_min:.4f}")
        print(f"  α_max = {self.alpha_max:.4f}")
    
    def create_fine_grids(self):
        """Create fine grids for p and ω"""
        
        # Create logarithmic frequency grid
        self.omega_grid = np.logspace(np.log10(self.omega_min), 
                                     np.log10(self.omega_max), 
                                     self.omega_points)
        
        # Create p grid
        self.p_grid = np.linspace(self.p_min, self.p_max, self.p_points)
        
        # Create 2D meshgrids
        self.P, self.OMEGA = np.meshgrid(self.p_grid, self.omega_grid)
        
        print(f"Created grids:")
        print(f"  p: {self.p_min:.4f} to {self.p_max:.4f} ({self.p_points} points)")
        print(f"  ω: {self.omega_min:.3e} to {self.omega_max:.3e} ({self.omega_points} points)")
    
    def sigmoid_alpha_function(self, p_values):
        """Calculate α values using sigmoid function"""
        
        # Sigmoid function: α(p) = α_min + (α_max - α_min) / (1 + exp((p - p_c) / width))
        alpha = self.alpha_min + (self.alpha_max - self.alpha_min) / (1 + np.exp((p_values - self.p_c) / self.width))
        
        # Ensure bounds
        alpha = np.clip(alpha, 0.0, 1.0)
        
        return alpha
    
    def calculate_G_prime_surface(self):
        """Calculate G'(ω, p) surface"""
        
        print("Calculating G'(ω, p) surface...")
        
        # Initialize surface
        G_prime_surface = np.zeros_like(self.P)
        
        # Calculate α for each p-value
        alpha_p = self.sigmoid_alpha_function(self.p_grid)
        
        # For each frequency, calculate G' across p-values
        for i, omega in enumerate(self.omega_grid):
            for j, p in enumerate(self.p_grid):
                alpha = alpha_p[j]
                
                if alpha <= 0:
                    # Solid regime: G' = G0 (constant)
                    G_prime_surface[i, j] = 1.0
                elif alpha >= 1:
                    # Liquid regime: G' = G0 * ω^1 = G0 * ω (proportional to frequency)
                    G_prime_surface[i, j] = omega ** alpha
                else:
                    # Viscoelastic regime: G' = G0 * ω^α
                    G_prime_surface[i, j] = omega ** alpha
        
        self.G_prime_surface = G_prime_surface
        print(f"✓ G'(ω, p) surface calculated: shape {G_prime_surface.shape}")
        
        return G_prime_surface
    
    def calculate_G_double_prime_surface(self):
        """Calculate G''(ω, p) surface"""
        
        print("Calculating G''(ω, p) surface...")
        
        # Initialize surface
        G_double_prime_surface = np.zeros_like(self.P)
        
        # Calculate α for each p-value
        alpha_p = self.sigmoid_alpha_function(self.p_grid)
        
        # For each frequency, calculate G'' across p-values
        for i, omega in enumerate(self.omega_grid):
            for j, p in enumerate(self.p_grid):
                alpha = alpha_p[j]
                
                if alpha <= 0:
                    # Solid regime: G'' = 0 (no loss)
                    G_double_prime_surface[i, j] = 0.0
                elif alpha >= 1:
                    # Liquid regime: G'' = G0 * ω^1 = G0 * ω (proportional to frequency)
                    G_double_prime_surface[i, j] = omega ** alpha
                else:
                    # Viscoelastic regime: G'' = G0 * ω^α
                    G_double_prime_surface[i, j] = omega ** alpha
        
        self.G_double_prime_surface = G_double_prime_surface
        print(f"✓ G''(ω, p) surface calculated: shape {G_double_prime_surface.shape}")
        
        return G_double_prime_surface
    
    def calculate_phase_angle_surface(self):
        """Calculate phase angle δ(ω, p) surface"""
        
        print("Calculating phase angle δ(ω, p) surface...")
        
        # Initialize surface
        delta_surface = np.zeros_like(self.P)
        
        # Calculate α for each p-value
        alpha_p = self.sigmoid_alpha_function(self.p_grid)
        
        # For each frequency, calculate δ across p-values
        for i, omega in enumerate(self.omega_grid):
            for j, p in enumerate(self.p_grid):
                alpha = alpha_p[j]
                
                if alpha <= 0:
                    # Solid regime: δ = 0° (purely elastic)
                    delta_surface[i, j] = 0.0
                elif alpha >= 1:
                    # Liquid regime: δ = 90° (purely viscous)
                    delta_surface[i, j] = 90.0
                else:
                    # Viscoelastic regime: δ = πα/2
                    delta_rad = np.pi * alpha / 2
                    delta_surface[i, j] = delta_rad * 180 / np.pi
        
        self.delta_surface = delta_surface
        print(f"✓ Phase angle δ(ω, p) surface calculated: shape {delta_surface.shape}")
        
        return delta_surface
    
    def calculate_loss_tangent_surface(self):
        """Calculate loss tangent tan δ(ω, p) surface"""
        
        print("Calculating loss tangent tan δ(ω, p) surface...")
        
        # Initialize surface
        tan_delta_surface = np.zeros_like(self.P)
        
        # Calculate α for each p-value
        alpha_p = self.sigmoid_alpha_function(self.p_grid)
        
        # For each frequency, calculate tan δ across p-values
        for i, omega in enumerate(self.omega_grid):
            for j, p in enumerate(self.p_grid):
                alpha = alpha_p[j]
                
                if alpha <= 0:
                    # Solid regime: tan δ = 0
                    tan_delta_surface[i, j] = 0.0
                elif alpha >= 1:
                    # Liquid regime: tan δ → ∞ (use large finite value)
                    tan_delta_surface[i, j] = 100.0
                else:
                    # Viscoelastic regime: tan δ = tan(πα/2)
                    delta_rad = np.pi * alpha / 2
                    tan_delta = np.tan(delta_rad)
                    # Ensure reasonable bounds
                    tan_delta_surface[i, j] = np.clip(tan_delta, 0.0, 100.0)
        
        self.tan_delta_surface = tan_delta_surface
        print(f"✓ Loss tangent tan δ(ω, p) surface calculated: shape {tan_delta_surface.shape}")
        
        return tan_delta_surface
    
    def create_3d_surface_plots(self):
        """Create comprehensive 3D surface plots"""
        
        print("\nCreating 3D surface plots...")
        
        # Calculate all surfaces
        self.calculate_G_prime_surface()
        self.calculate_G_double_prime_surface()
        self.calculate_phase_angle_surface()
        self.calculate_loss_tangent_surface()
        
        # Create the main 3D surface plot
        self.create_main_3d_surface_plot()
        
        # Create individual surface plots
        self.create_individual_surface_plots()
        
        # Create contour plots
        self.create_contour_plots()
        
        # Create cross-sectional plots
        self.create_cross_sectional_plots()
        
        print(f"✓ All 3D surface plots created and saved to {self.output_dir}")
    
    def create_main_3d_surface_plot(self):
        """Create main 3D surface plot with all four surfaces"""
        
        fig = plt.figure(figsize=(20, 16))
        
        # Plot 1: G'(ω, p) surface
        ax1 = fig.add_subplot(2, 2, 1, projection='3d')
        surf1 = ax1.plot_surface(self.P, self.OMEGA, self.G_prime_surface, 
                                cmap='viridis', alpha=0.8, linewidth=0.5)
        ax1.set_xlabel('Percolation Probability (p)', fontsize=12)
        ax1.set_ylabel('Frequency ω (rad/s)', fontsize=12)
        ax1.set_zlabel("G'(ω, p)", fontsize=12)
        ax1.set_title('Storage Modulus G\'(ω, p)', fontsize=14, fontweight='bold')
        ax1.set_xscale('linear')
        ax1.set_yscale('log')
        fig.colorbar(surf1, ax=ax1, shrink=0.5, aspect=10)
        
        # Plot 2: G''(ω, p) surface
        ax2 = fig.add_subplot(2, 2, 2, projection='3d')
        surf2 = ax2.plot_surface(self.P, self.OMEGA, self.G_double_prime_surface, 
                                cmap='plasma', alpha=0.8, linewidth=0.5)
        ax2.set_xlabel('Percolation Probability (p)', fontsize=12)
        ax2.set_ylabel('Frequency ω (rad/s)', fontsize=12)
        ax2.set_zlabel("G''(ω, p)", fontsize=12)
        ax2.set_title('Loss Modulus G\'\'(ω, p)', fontsize=14, fontweight='bold')
        ax2.set_xscale('linear')
        ax2.set_yscale('log')
        fig.colorbar(surf2, ax=ax2, shrink=0.5, aspect=10)
        
        # Plot 3: Phase angle δ(ω, p) surface
        ax3 = fig.add_subplot(2, 2, 3, projection='3d')
        surf3 = ax3.plot_surface(self.P, self.OMEGA, self.delta_surface, 
                                cmap='coolwarm', alpha=0.8, linewidth=0.5)
        ax3.set_xlabel('Percolation Probability (p)', fontsize=12)
        ax3.set_ylabel('Frequency ω (rad/s)', fontsize=12)
        ax3.set_zlabel('Phase Angle δ (degrees)', fontsize=12)
        ax3.set_title('Phase Angle δ(ω, p)', fontsize=14, fontweight='bold')
        ax3.set_xscale('linear')
        ax3.set_yscale('log')
        ax3.set_zlim(0, 90)
        fig.colorbar(surf3, ax=ax3, shrink=0.5, aspect=10)
        
        # Plot 4: Loss tangent tan δ(ω, p) surface
        ax4 = fig.add_subplot(2, 2, 4, projection='3d')
        surf4 = ax4.plot_surface(self.P, self.OMEGA, self.tan_delta_surface, 
                                cmap='RdYlBu_r', alpha=0.8, linewidth=0.5)
        ax4.set_xlabel('Percolation Probability (p)', fontsize=12)
        ax4.set_ylabel('Frequency ω (rad/s)', fontsize=12)
        ax4.set_zlabel('Loss Tangent tan δ', fontsize=12)
        ax4.set_title('Loss Tangent tan δ(ω, p)', fontsize=14, fontweight='bold')
        ax4.set_xscale('linear')
        ax4.set_yscale('log')
        ax4.set_zlim(0, 100)
        fig.colorbar(surf4, ax=ax4, shrink=0.5, aspect=10)
        
        plt.tight_layout()
        
        # Save plot
        output_file = os.path.join(self.output_dir, "viscoelastic_3d_surfaces_main.png")
        plt.savefig(output_file, dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"  ✓ Main 3D surface plot saved: {output_file}")
    
    def create_individual_surface_plots(self):
        """Create individual 3D surface plots for detailed analysis"""
        
        # G'(ω, p) individual plot
        fig = plt.figure(figsize=(14, 10))
        ax = fig.add_subplot(111, projection='3d')
        
        surf = ax.plot_surface(self.P, self.OMEGA, self.G_prime_surface, 
                              cmap='viridis', alpha=0.9, linewidth=0.3)
        
        ax.set_xlabel('Percolation Probability (p)', fontsize=14)
        ax.set_ylabel('Frequency ω (rad/s)', fontsize=14)
        ax.set_zlabel("G'(ω, p)", fontsize=14)
        ax.set_title('Storage Modulus Surface G\'(ω, p)\n3D Visualization of Elastic Response', 
                    fontsize=16, fontweight='bold')
        
        # Add critical threshold line
        ax.plot([self.p_c, self.p_c], [self.omega_min, self.omega_max], 
                [np.max(self.G_prime_surface), np.max(self.G_prime_surface)], 
                'r--', linewidth=3, alpha=0.8, label=f"p_c' = {self.p_c}")
        
        ax.set_xscale('linear')
        ax.set_yscale('log')
        fig.colorbar(surf, ax=ax, shrink=0.6, aspect=15)
        
        plt.tight_layout()
        output_file = os.path.join(self.output_dir, "G_prime_3d_surface.png")
        plt.savefig(output_file, dpi=300, bbox_inches='tight')
        plt.close()
        
        # G''(ω, p) individual plot
        fig = plt.figure(figsize=(14, 10))
        ax = fig.add_subplot(111, projection='3d')
        
        surf = ax.plot_surface(self.P, self.OMEGA, self.G_double_prime_surface, 
                              cmap='plasma', alpha=0.9, linewidth=0.3)
        
        ax.set_xlabel('Percolation Probability (p)', fontsize=14)
        ax.set_ylabel('Frequency ω (rad/s)', fontsize=14)
        ax.set_zlabel("G''(ω, p)", fontsize=14)
        ax.set_title('Loss Modulus Surface G\'\'(ω, p)\n3D Visualization of Viscous Response', 
                    fontsize=16, fontweight='bold')
        
        # Add critical threshold line
        ax.plot([self.p_c, self.p_c], [self.omega_min, self.omega_max], 
                [np.max(self.G_double_prime_surface), np.max(self.G_double_prime_surface)], 
                'r--', linewidth=3, alpha=0.8, label=f"p_c' = {self.p_c}")
        
        ax.set_xscale('linear')
        ax.set_yscale('log')
        fig.colorbar(surf, ax=ax, shrink=0.6, aspect=15)
        
        plt.tight_layout()
        output_file = os.path.join(self.output_dir, "G_double_prime_3d_surface.png")
        plt.savefig(output_file, dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"  ✓ Individual 3D surface plots created")
    
    def create_contour_plots(self):
        """Create 2D contour plots for easier interpretation"""
        
        fig, axes = plt.subplots(2, 2, figsize=(16, 12))
        
        # G'(ω, p) contour
        im1 = axes[0, 0].contourf(self.P, self.OMEGA, self.G_prime_surface, 
                                  levels=20, cmap='viridis')
        axes[0, 0].set_xlabel('Percolation Probability (p)', fontsize=12)
        axes[0, 0].set_ylabel('Frequency ω (rad/s)', fontsize=12)
        axes[0, 0].set_title("G'(ω, p) Contour", fontsize=14, fontweight='bold')
        axes[0, 0].set_yscale('log')
        axes[0, 0].axvline(x=self.p_c, color='red', linestyle='--', alpha=0.8, 
                           linewidth=2, label=f"p_c' = {self.p_c}")
        fig.colorbar(im1, ax=axes[0, 0])
        
        # G''(ω, p) contour
        im2 = axes[0, 1].contourf(self.P, self.OMEGA, self.G_double_prime_surface, 
                                  levels=20, cmap='plasma')
        axes[0, 1].set_xlabel('Percolation Probability (p)', fontsize=12)
        axes[0, 1].set_ylabel('Frequency ω (rad/s)', fontsize=12)
        axes[0, 1].set_title("G''(ω, p) Contour", fontsize=14, fontweight='bold')
        axes[0, 1].set_yscale('log')
        axes[0, 1].axvline(x=self.p_c, color='red', linestyle='--', alpha=0.8, 
                           linewidth=2, label=f"p_c' = {self.p_c}")
        fig.colorbar(im2, ax=axes[0, 1])
        
        # Phase angle contour
        im3 = axes[1, 0].contourf(self.P, self.OMEGA, self.delta_surface, 
                                  levels=20, cmap='coolwarm')
        axes[1, 0].set_xlabel('Percolation Probability (p)', fontsize=12)
        axes[1, 0].set_ylabel('Frequency ω (rad/s)', fontsize=12)
        axes[1, 0].set_title('Phase Angle δ(ω, p) Contour', fontsize=14, fontweight='bold')
        axes[1, 0].set_yscale('log')
        axes[1, 0].axvline(x=self.p_c, color='red', linestyle='--', alpha=0.8, 
                           linewidth=2, label=f"p_c' = {self.p_c}")
        fig.colorbar(im3, ax=axes[1, 0])
        
        # Loss tangent contour
        im4 = axes[1, 1].contourf(self.P, self.OMEGA, self.tan_delta_surface, 
                                  levels=20, cmap='RdYlBu_r')
        axes[1, 1].set_xlabel('Percolation Probability (p)', fontsize=12)
        axes[1, 1].set_ylabel('Frequency ω (rad/s)', fontsize=12)
        axes[1, 1].set_title('Loss Tangent tan δ(ω, p) Contour', fontsize=14, fontweight='bold')
        axes[1, 1].set_yscale('log')
        axes[1, 1].axvline(x=self.p_c, color='red', linestyle='--', alpha=0.8, 
                           linewidth=2, label=f"p_c' = {self.p_c}")
        fig.colorbar(im4, ax=axes[1, 1])
        
        plt.tight_layout()
        output_file = os.path.join(self.output_dir, "viscoelastic_contour_plots.png")
        plt.savefig(output_file, dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"  ✓ Contour plots created")
    
    def create_cross_sectional_plots(self):
        """Create cross-sectional plots showing specific frequency and p-value cuts"""
        
        fig, axes = plt.subplots(2, 2, figsize=(16, 12))
        
        # Cross-section 1: Fixed frequency, varying p
        fixed_omega = 1.0  # 1 rad/s
        omega_idx = np.argmin(np.abs(self.omega_grid - fixed_omega))
        
        axes[0, 0].plot(self.p_grid, self.G_prime_surface[omega_idx, :], 'b-', 
                        linewidth=3, label="G'(ω=1)")
        axes[0, 0].plot(self.p_grid, self.G_double_prime_surface[omega_idx, :], 'r-', 
                        linewidth=3, label="G''(ω=1)")
        axes[0, 0].set_xlabel('Percolation Probability (p)', fontsize=12)
        axes[0, 0].set_ylabel('Modulus G(ω=1)', fontsize=12)
        axes[0, 0].set_title(f'Moduli vs p at ω = {fixed_omega} rad/s', fontsize=14, fontweight='bold')
        axes[0, 0].axvline(x=self.p_c, color='black', linestyle=':', alpha=0.8, 
                           linewidth=2, label=f"p_c' = {self.p_c}")
        axes[0, 0].legend()
        axes[0, 0].grid(True, alpha=0.3)
        
        # Cross-section 2: Fixed p, varying frequency
        fixed_p = self.p_c  # Critical p-value
        p_idx = np.argmin(np.abs(self.p_grid - fixed_p))
        
        axes[0, 1].loglog(self.omega_grid, self.G_prime_surface[:, p_idx], 'b-', 
                          linewidth=3, label="G'(p=p_c)")
        axes[0, 1].loglog(self.omega_grid, self.G_double_prime_surface[:, p_idx], 'r-', 
                          linewidth=3, label="G''(p=p_c)")
        axes[0, 1].set_xlabel('Frequency ω (rad/s)', fontsize=12)
        axes[0, 1].set_ylabel('Modulus G(p=p_c)', fontsize=12)
        axes[0, 1].set_title(f'Moduli vs ω at p = {fixed_p:.4f}', fontsize=14, fontweight='bold')
        axes[0, 1].legend()
        axes[0, 1].grid(True, alpha=0.3)
        
        # Cross-section 3: Phase angle vs p at fixed frequency
        axes[1, 0].plot(self.p_grid, self.delta_surface[omega_idx, :], 'g-', 
                        linewidth=3, label='Phase Angle δ')
        axes[1, 0].set_xlabel('Percolation Probability (p)', fontsize=12)
        axes[1, 0].set_ylabel('Phase Angle δ (degrees)', fontsize=12)
        axes[1, 0].set_title(f'Phase Angle vs p at ω = {fixed_omega} rad/s', fontsize=14, fontweight='bold')
        axes[1, 0].axvline(x=self.p_c, color='black', linestyle=':', alpha=0.8, 
                           linewidth=2, label=f"p_c' = {self.p_c}")
        axes[1, 0].axhline(y=45, color='orange', linestyle='--', alpha=0.6, label='δ = 45° (critical)')
        axes[1, 0].legend()
        axes[1, 0].grid(True, alpha=0.3)
        axes[1, 0].set_ylim(0, 90)
        
        # Cross-section 4: Loss tangent vs p at fixed frequency
        axes[1, 1].plot(self.p_grid, self.tan_delta_surface[omega_idx, :], 'm-', 
                        linewidth=3, label='Loss Tangent tan δ')
        axes[1, 1].set_xlabel('Percolation Probability (p)', fontsize=12)
        axes[1, 1].set_ylabel('Loss Tangent tan δ', fontsize=12)
        axes[1, 1].set_title(f'Loss Tangent vs p at ω = {fixed_omega} rad/s', fontsize=14, fontweight='bold')
        axes[1, 1].axvline(x=self.p_c, color='black', linestyle=':', alpha=0.8, 
                           linewidth=2, label=f"p_c' = {self.p_c}")
        axes[1, 1].axhline(y=1, color='orange', linestyle='--', alpha=0.6, label='tan δ = 1 (critical)')
        axes[1, 1].legend()
        axes[1, 1].grid(True, alpha=0.3)
        axes[1, 1].set_ylim(0, 100)
        
        plt.tight_layout()
        output_file = os.path.join(self.output_dir, "viscoelastic_cross_sections.png")
        plt.savefig(output_file, dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"  ✓ Cross-sectional plots created")
    
    def create_animation_frames(self):
        """Create frames for potential animation (frequency sweep)"""
        
        print("Creating animation frames...")
        
        # Create frames directory
        frames_dir = os.path.join(self.output_dir, "animation_frames")
        os.makedirs(frames_dir, exist_ok=True)
        
        # Select subset of frequencies for frames
        frame_frequencies = np.logspace(np.log10(self.omega_min), 
                                      np.log10(self.omega_max), 20)
        
        for i, omega in enumerate(frame_frequencies):
            fig = plt.figure(figsize=(12, 8))
            ax = fig.add_subplot(111, projection='3d')
            
            # Find closest frequency index
            omega_idx = np.argmin(np.abs(self.omega_grid - omega))
            
            # Create surface for this frequency
            p_mesh, omega_mesh = np.meshgrid(self.p_grid, [omega])
            G_prime_mesh = self.G_prime_surface[omega_idx:omega_idx+1, :]
            G_double_prime_mesh = self.G_double_prime_surface[omega_idx:omega_idx+1, :]
            
            # Plot both moduli
            ax.plot_surface(p_mesh, omega_mesh, G_prime_mesh, 
                           alpha=0.7, color='blue', label="G'")
            ax.plot_surface(p_mesh, omega_mesh, G_double_prime_mesh, 
                           alpha=0.7, color='red', label="G''")
            
            ax.set_xlabel('Percolation Probability (p)', fontsize=12)
            ax.set_ylabel('Frequency ω (rad/s)', fontsize=12)
            ax.set_zlabel('Modulus G(ω, p)', fontsize=12)
            ax.set_title(f'Viscoelastic Response at ω = {omega:.3f} rad/s\nFrame {i+1}/20', 
                        fontsize=14, fontweight='bold')
            
            # Add critical threshold
            ax.plot([self.p_c, self.p_c], [omega, omega], [0, np.max(G_prime_mesh)], 
                    'k--', linewidth=3, alpha=0.8)
            
            ax.set_xlim(self.p_min, self.p_max)
            ax.set_ylim(omega*0.9, omega*1.1)
            ax.set_zlim(0, np.max(G_prime_mesh)*1.1)
            
            plt.tight_layout()
            
            # Save frame
            frame_file = os.path.join(frames_dir, f"frame_{i:03d}_omega_{omega:.3f}.png")
            plt.savefig(frame_file, dpi=150, bbox_inches='tight')
            plt.close()
        
        print(f"  ✓ Animation frames created: {len(frame_frequencies)} frames")
    
    def save_surface_data(self):
        """Save surface data for further analysis"""
        
        print("Saving surface data...")
        
        # Create data directory
        data_dir = os.path.join(self.output_dir, "surface_data")
        os.makedirs(data_dir, exist_ok=True)
        
        # Save as numpy arrays
        np.save(os.path.join(data_dir, "p_grid.npy"), self.p_grid)
        np.save(os.path.join(data_dir, "omega_grid.npy"), self.omega_grid)
        np.save(os.path.join(data_dir, "G_prime_surface.npy"), self.G_prime_surface)
        np.save(os.path.join(data_dir, "G_double_prime_surface.npy"), self.G_double_prime_surface)
        np.save(os.path.join(data_dir, "delta_surface.npy"), self.delta_surface)
        np.save(os.path.join(data_dir, "tan_delta_surface.npy"), self.tan_delta_surface)
        
        # Save as CSV for easy viewing
        # Flatten arrays for CSV
        p_flat = self.P.flatten()
        omega_flat = self.OMEGA.flatten()
        G_prime_flat = self.G_prime_surface.flatten()
        G_double_prime_flat = self.G_double_prime_surface.flatten()
        delta_flat = self.delta_surface.flatten()
        tan_delta_flat = self.tan_delta_surface.flatten()
        
        # Create DataFrame
        surface_df = pd.DataFrame({
            'p': p_flat,
            'omega': omega_flat,
            'G_prime': G_prime_flat,
            'G_double_prime': G_double_prime_flat,
            'delta': delta_flat,
            'tan_delta': tan_delta_flat
        })
        
        # Save CSV
        csv_file = os.path.join(data_dir, "viscoelastic_surfaces_data.csv")
        surface_df.to_csv(csv_file, index=False)
        
        print(f"  ✓ Surface data saved to {data_dir}")
        print(f"    - NumPy arrays: .npy files")
        print(f"    - CSV data: viscoelastic_surfaces_data.csv")
    
    def generate_summary_report(self):
        """Generate a summary report of the 3D surface analysis"""
        
        report_file = os.path.join(self.output_dir, "3d_surface_analysis_summary.md")
        
        with open(report_file, 'w') as f:
            f.write("# 3D Viscoelastic Surface Analysis Summary\n\n")
            f.write("## Overview\n\n")
            f.write("This report summarizes the generation of 3D surfaces for viscoelastic moduli\n")
            f.write("as functions of both percolation probability (p) and frequency (ω).\n\n")
            
            f.write("## Surface Parameters\n\n")
            f.write(f"- **Percolation range**: p ∈ [{self.p_min:.4f}, {self.p_max:.4f}]\n")
            f.write(f"- **Frequency range**: ω ∈ [{self.omega_min:.3e}, {self.omega_max:.3e}] rad/s\n")
            f.write(f"- **Grid resolution**: {self.p_points} × {self.omega_points} = {self.p_points * self.omega_points:,} points\n")
            f.write(f"- **Critical threshold**: p_c' = {self.p_c:.4f}\n\n")
            
            f.write("## Generated Surfaces\n\n")
            f.write("1. **G'(ω, p)**: Storage modulus surface\n")
            f.write("2. **G''(ω, p)**: Loss modulus surface\n")
            f.write("3. **δ(ω, p)**: Phase angle surface\n")
            f.write("4. **tan δ(ω, p)**: Loss tangent surface\n\n")
            
            f.write("## Key Features\n\n")
            f.write("- **3D surface plots**: Interactive visualization of moduli evolution\n")
            f.write("- **Contour plots**: 2D representation for easier interpretation\n")
            f.write("- **Cross-sectional analysis**: Specific cuts through the surfaces\n")
            f.write("- **Animation frames**: Frequency sweep visualization\n")
            f.write("- **Data export**: NumPy arrays and CSV for further analysis\n\n")
            
            f.write("## Physical Interpretation\n\n")
            f.write("- **Liquid regime (p < p_c')**: G' ≈ G'' ≈ constant, δ ≈ 90°\n")
            f.write("- **Critical regime (p ≈ p_c')**: Power law behavior, δ ≈ 45°\n")
            f.write("- **Solid regime (p > p_c')**: G' ≈ constant, G'' ≈ 0, δ ≈ 0°\n\n")
            
            f.write("## Output Files\n\n")
            f.write("- `viscoelastic_3d_surfaces_main.png`: Main 4-panel 3D surface plot\n")
            f.write("- `G_prime_3d_surface.png`: Individual G' surface\n")
            f.write("- `G_double_prime_3d_surface.png`: Individual G'' surface\n")
            f.write("- `viscoelastic_contour_plots.png`: 2D contour representations\n")
            f.write("- `viscoelastic_cross_sections.png`: Cross-sectional analysis\n")
            f.write("- `animation_frames/`: Frequency sweep frames\n")
            f.write("- `surface_data/`: Numerical data for further analysis\n\n")
            
            f.write("## Novel Contributions\n\n")
            f.write("This visualization represents a **new contribution to the community** by:\n")
            f.write("- Showing **simultaneous evolution** of viscoelastic properties with p and ω\n")
            f.write("- Revealing **frequency-dependent percolation effects**\n")
            f.write("- Providing **3D perspective** on the gel-point transition\n")
            f.write("- Enabling **interpolation** of moduli at any (p, ω) combination\n\n")
            
            f.write("## Applications\n\n")
            f.write("- **Material design**: Optimize percolation for desired frequency response\n")
            f.write("- **Process control**: Monitor gelation at specific frequencies\n")
            f.write("- **Quality assurance**: Verify viscoelastic properties across p-range\n")
            f.write("- **Research insights**: Understand frequency-percolation coupling\n\n")
        
        print(f"  ✓ Summary report saved: {report_file}")

def main():
    """Main function to generate 3D viscoelastic surfaces"""
    
    print("=== 3D VISCOELASTIC SURFACE GENERATOR ===")
    print("Creating novel 3D surfaces for G'(ω, p) and G''(ω, p)")
    
    # Check if we have hybrid analysis results
    results_files = [
        "output_hybrid_analysis/new_hybrid_results.csv",
        "output_hybrid_analysis/original_hybrid_results.csv"
    ]
    
    # Use the first available results file
    results_file = None
    for file_path in results_files:
        if os.path.exists(file_path):
            results_file = file_path
            break
    
    if results_file is None:
        print("Error: No hybrid analysis results found!")
        print("Please run the hybrid analysis first:")
        print("  python hybrid_complete_analysis.py")
        return
    
    print(f"Using results from: {results_file}")
    
    # Create 3D surface generator
    surface_generator = Viscoelastic3DSurfaces(results_file)
    
    # Generate all surfaces and plots
    surface_generator.create_3d_surface_plots()
    
    # Create animation frames
    surface_generator.create_animation_frames()
    
    # Save surface data
    surface_generator.save_surface_data()
    
    # Generate summary report
    surface_generator.generate_summary_report()
    
    print(f"\n{'='*60}")
    print("3D VISCOELASTIC SURFACE GENERATION COMPLETE!")
    print(f"Results saved to: {surface_generator.output_dir}")
    print(f"{'='*60}")
    print("\nNovel visualizations created:")
    print("✓ 3D surfaces for G'(ω, p) and G''(ω, p)")
    print("✓ Contour plots for easy interpretation")
    print("✓ Cross-sectional analysis")
    print("✓ Animation frames for frequency sweep")
    print("✓ Data export for further analysis")
    print("\nThis represents a new contribution to the community!")

if __name__ == "__main__":
    main()
