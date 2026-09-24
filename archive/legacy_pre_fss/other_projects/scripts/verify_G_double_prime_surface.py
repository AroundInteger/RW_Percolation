#!/usr/bin/env python3
"""
Verify G''(ω) behavior in our 3D surface data
Check that the actual calculated values match theoretical expectations
"""

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os

# Set plotting style
plt.style.use('default')
sns.set_palette("husl")

def verify_G_double_prime_surface():
    """Verify G''(ω) behavior in our 3D surface data"""
    
    print("=== VERIFYING G''(ω) BEHAVIOR IN 3D SURFACE DATA ===\n")
    
    # Load surface data
    surface_data_dir = "output_3d_surfaces/surface_data"
    
    try:
        p_grid = np.load(os.path.join(surface_data_dir, 'p_grid.npy'))
        omega_grid = np.load(os.path.join(surface_data_dir, 'omega_grid.npy'))
        G_double_prime_surface = np.load(os.path.join(surface_data_dir, 'G_double_prime_surface.npy'))
        
        print(f"✓ Surface data loaded successfully!")
        print(f"  Grid shape: {G_double_prime_surface.shape}")
        print(f"  p range: {p_grid.min():.4f} to {p_grid.max():.4f}")
        print(f"  ω range: {omega_grid.min():.3e} to {omega_grid.max():.3e}")
        
    except Exception as e:
        print(f"✗ Error loading surface data: {e}")
        return
    
    # Define test p-values and expected α values
    test_cases = {
        'Liquid (p = 0.1)': {'p': 0.1, 'expected_alpha': 1.0},
        'Critical (p = 0.6884)': {'p': 0.6884, 'expected_alpha': 0.5},
        'Solid (p = 0.8)': {'p': 0.8, 'expected_alpha': 0.0}
    }
    
    # Create plot
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    
    # Plot 1: G''(ω) vs ω for different p-values
    ax1 = axes[0, 0]
    for case_name, case_data in test_cases.items():
        p_val = case_data['p']
        expected_alpha = case_data['expected_alpha']
        
        # Find closest p-value in grid
        p_idx = np.argmin(np.abs(p_grid - p_val))
        p_actual = p_grid[p_idx]
        
        # Extract G''(ω) for this p-value
        G_double_prime = G_double_prime_surface[:, p_idx]
        
        # Plot data
        ax1.loglog(omega_grid, G_double_prime, 'o-', linewidth=2, markersize=4, 
                   label=f'{case_name}\np = {p_actual:.4f}', alpha=0.8)
        
        print(f"\n{case_name}:")
        print(f"  Target p: {p_val:.4f}, Actual p: {p_actual:.4f}")
        print(f"  Expected α: {expected_alpha:.1f}")
    
    ax1.set_xlabel('Frequency ω (rad/s)', fontsize=12)
    ax1.set_ylabel("G''(ω) (Pa)", fontsize=12)
    ax1.set_title('G''(ω) vs ω from 3D Surface Data\n(Log-Log Scale)', fontsize=14, fontweight='bold')
    ax1.legend(fontsize=10)
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: Log-log slope analysis
    ax2 = axes[0, 1]
    for case_name, case_data in test_cases.items():
        p_val = case_data['p']
        expected_alpha = case_data['expected_alpha']
        
        # Find closest p-value in grid
        p_idx = np.argmin(np.abs(p_grid - p_val))
        G_double_prime = G_double_prime_surface[:, p_idx]
        
        # Calculate log-log slope
        log_omega = np.log10(omega_grid)
        log_G_double_prime = np.log10(G_double_prime + 1e-10)  # Avoid log(0)
        
        # Fit slope in middle frequency range (avoid edge effects)
        mid_start = len(log_omega) // 4
        mid_end = 3 * len(log_omega) // 4
        
        if mid_end > mid_start:
            slope, intercept = np.polyfit(log_omega[mid_start:mid_end], 
                                        log_G_double_prime[mid_start:mid_end], 1)
            r_squared = 1 - np.sum((log_G_double_prime[mid_start:mid_end] - 
                                   (slope * log_omega[mid_start:mid_end] + intercept))**2) / \
                       np.sum((log_G_double_prime[mid_start:mid_end] - 
                              np.mean(log_G_double_prime[mid_start:mid_end]))**2)
        else:
            slope = r_squared = 0.0
        
        # Plot fitted line
        fitted_line = 10**(slope * log_omega + intercept)
        ax2.loglog(omega_grid, fitted_line, '--', linewidth=2, alpha=0.7,
                  label=f'{case_name}: slope = {slope:.3f}, R² = {r_squared:.3f}')
        
        # Plot data points
        ax2.loglog(omega_grid, G_double_prime, 'o', markersize=3, alpha=0.6)
        
        print(f"  Calculated α (slope): {slope:.3f}")
        print(f"  R²: {r_squared:.3f}")
        print(f"  Agreement: {'✓' if abs(slope - expected_alpha) < 0.1 else '⚠'}")
    
    ax2.set_xlabel('Frequency ω (rad/s)', fontsize=12)
    ax2.set_ylabel("G''(ω) (Pa)", fontsize=12)
    ax2.set_title('G''(ω) Log-Log Slope Analysis\n(Expected vs Calculated)', fontsize=14, fontweight='bold')
    ax2.legend(fontsize=10)
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: G''(ω) vs p at fixed frequency
    ax3 = axes[1, 0]
    
    # Select a few frequencies to show
    test_frequencies = [0.01, 1.0, 100.0]  # rad/s
    
    for omega_val in test_frequencies:
        # Find closest frequency in grid
        omega_idx = np.argmin(np.abs(omega_grid - omega_val))
        omega_actual = omega_grid[omega_idx]
        
        # Extract G''(p) for this frequency
        G_double_prime_p = G_double_prime_surface[omega_idx, :]
        
        # Plot
        ax3.plot(p_grid, G_double_prime_p, 'o-', linewidth=2, markersize=3, 
                label=f'ω = {omega_actual:.2f} rad/s', alpha=0.8)
    
    ax3.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax3.set_ylabel("G''(ω, p) (Pa)", fontsize=12)
    ax3.set_title('G''(ω, p) vs p at Fixed Frequencies', fontsize=14, fontweight='bold')
    ax3.legend(fontsize=10)
    ax3.grid(True, alpha=0.3)
    
    # Add critical threshold line
    p_c = 0.6884
    ax3.axvline(x=p_c, color='red', linestyle='--', alpha=0.7, linewidth=2, 
                label=f"p_c' = {p_c:.4f}")
    
    # Plot 4: Summary table
    ax4 = axes[1, 1]
    ax4.axis('off')
    
    # Create summary table
    table_data = []
    headers = ['Regime', 'p-value', 'Expected α', 'Calculated α', 'R²', 'Agreement']
    
    for case_name, case_data in test_cases.items():
        p_val = case_data['p']
        expected_alpha = case_data['expected_alpha']
        
        # Find closest p-value in grid
        p_idx = np.argmin(np.abs(p_grid - p_val))
        G_double_prime = G_double_prime_surface[:, p_idx]
        
        # Calculate slope
        log_omega = np.log10(omega_grid)
        log_G_double_prime = np.log10(G_double_prime + 1e-10)
        
        mid_start = len(log_omega) // 4
        mid_end = 3 * len(log_omega) // 4
        
        if mid_end > mid_start:
            slope, _ = np.polyfit(log_omega[mid_start:mid_end], 
                                 log_G_double_prime[mid_start:mid_end], 1)
            r_squared = 1 - np.sum((log_G_double_prime[mid_start:mid_end] - 
                                   (slope * log_omega[mid_start:mid_end] + intercept))**2) / \
                       np.sum((log_G_double_prime[mid_start:mid_end] - 
                              np.mean(log_G_double_prime[mid_start:mid_end]))**2)
        else:
            slope = r_squared = 0.0
        
        agreement = "✓" if abs(slope - expected_alpha) < 0.1 else "⚠"
        
        table_data.append([
            case_name.split('(')[0].strip(),
            f"{p_val:.4f}",
            f"{expected_alpha:.1f}",
            f"{slope:.3f}",
            f"{r_squared:.3f}",
            agreement
        ])
    
    # Create table
    table = ax4.table(cellText=table_data, colLabels=headers, 
                      cellLoc='center', loc='center')
    table.auto_set_font_size(False)
    table.set_fontsize(9)
    table.scale(1, 2)
    
    # Style table
    for i in range(len(headers)):
        table[(0, i)].set_facecolor('lightblue')
        table[(0, i)].set_text_props(weight='bold')
    
    ax4.set_title('G''(ω) Surface Validation Summary', fontsize=14, fontweight='bold')
    
    plt.tight_layout()
    
    # Save plot
    plt.savefig('G_double_prime_surface_verification.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"\n✓ G''(ω) surface verification completed!")
    print(f"✓ Plot saved as: G_double_prime_surface_verification.png")
    
    # Final validation summary
    print("\n" + "="*60)
    print("FINAL G''(ω) VALIDATION SUMMARY")
    print("="*60)
    
    all_correct = True
    for case_name, case_data in test_cases.items():
        p_val = case_data['p']
        expected_alpha = case_data['expected_alpha']
        
        # Find closest p-value in grid
        p_idx = np.argmin(np.abs(p_grid - p_val))
        G_double_prime = G_double_prime_surface[:, p_idx]
        
        # Calculate slope
        log_omega = np.log10(omega_grid)
        log_G_double_prime = np.log10(G_double_prime + 1e-10)
        
        mid_start = len(log_omega) // 4
        mid_end = 3 * len(log_omega) // 4
        
        if mid_end > mid_start:
            slope, _ = np.polyfit(log_omega[mid_start:mid_end], 
                                 log_G_double_prime[mid_start:mid_end], 1)
        else:
            slope = 0.0
        
        error = abs(slope - expected_alpha)
        is_correct = error < 0.1
        
        if is_correct:
            print(f"✅ {case_name}: α = {slope:.3f} (expected {expected_alpha:.1f})")
        else:
            print(f"❌ {case_name}: α = {slope:.3f} (expected {expected_alpha:.1f}, error = {error:.3f})")
            all_correct = False
    
    if all_correct:
        print(f"\n🎉 ALL G''(ω) BEHAVIORS ARE PHYSICALLY CORRECT!")
    else:
        print(f"\n⚠️ Some G''(ω) behaviors need attention")

if __name__ == "__main__":
    verify_G_double_prime_surface()
