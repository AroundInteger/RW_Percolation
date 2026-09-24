#!/usr/bin/env python3
"""
Python implementation matching 3D MATLAB random walk algorithm
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from pathlib import Path

def rw3d_percolation_matlab_style(L=100, LW=100000, NW=100, p_values=None):
    """
    Python implementation matching 3D MATLAB RW3D_percolation_2.m
    """
    if p_values is None:
        p_values = np.arange(0, 0.65, 0.05)  # 0:0.05:0.6
    
    print(f"=== 3D MATLAB-Compatible Random Walk ===")
    print(f"Lattice size: {L}×{L}×{L}")
    print(f"Steps: {LW:,}")
    print(f"Walkers: {NW}")
    print(f"p-values: {p_values}")
    print()
    
    Np = len(p_values)
    msd = np.zeros((LW, Np))
    t = np.arange(1, LW + 1)
    
    for i_p, p in enumerate(p_values):
        print(f"Processing p = {p:.2f} ({i_p+1}/{Np})")
        
        # Generate 3D lattice (same as MATLAB: R < p)
        np.random.seed(42 + i_p)  # For reproducibility
        R = np.random.random((L, L, L))
        bw = R < p  # bw = 1 means occupied (obstacle), bw = 0 means free
        
        # Find free positions in 3D (same as MATLAB: find(~bw))
        free_positions = np.where(bw == 0)
        px, py, pz = free_positions[0], free_positions[1], free_positions[2]
        N_rsp = len(px)
        
        if N_rsp < NW:
            print(f"Warning: Only {N_rsp} free positions for {NW} walkers")
            continue
        
        # Initialize walkers at random free positions
        rp = np.random.randint(0, N_rsp, NW)
        rsp = np.column_stack([px[rp], py[rp], pz[rp]])
        
        # Arrays to store positions
        x = np.zeros((LW, NW))
        y = np.zeros((LW, NW))
        z = np.zeros((LW, NW))
        
        # Run random walks for each walker
        for i_rw in range(NW):
            xyz, xyzp = rw3d_p_sp_matlab_style(bw, LW, L, rsp[i_rw], wt=[20, 5])
            x[:, i_rw] = xyzp[:, 0]
            y[:, i_rw] = xyzp[:, 1]
            z[:, i_rw] = xyzp[:, 2]
        
        # Calculate MSD for every step (using unwrapped positions, no PBC correction needed)
        dx = x - np.tile(x[0, :], (LW, 1))
        dy = y - np.tile(y[0, :], (LW, 1))
        dz = z - np.tile(z[0, :], (LW, 1))
        
        # No PBC correction needed since we're using unwrapped positions
        sd = dx**2 + dy**2 + dz**2
        msd[:, i_p] = np.mean(sd, axis=1)
    
    return t, msd, p_values

def rw3d_p_sp_matlab_style(bw, LW, L, xyz0, wt):
    """
    Python implementation matching 3D MATLAB RW3D_P_SP.m
    """
    # Initialize
    r = np.random.randint(1, 7, LW)  # ceil(rand(LW,1)*6)
    Y = np.zeros((LW, 3))
    X = np.zeros((LW, 3))
    Y[0] = xyz0
    X[0] = xyz0
    
    flg = 0
    spc = 0
    
    for ii in range(1, LW):
        xyz0 = Y[ii-1]
        xn, yn, zn = xyz0[0], xyz0[1], xyz0[2]
        xyzp0 = X[ii-1]
        xp, yp, zp = xyzp0[0], xyzp0[1], xyzp0[2]
        
        if flg == 0:
            # Move in random direction (6 directions in 3D)
            if r[ii] == 1:
                xn += 1
                xp += 1
            elif r[ii] == 2:
                yn += 1
                yp += 1
            elif r[ii] == 3:
                zn += 1
                zp += 1
            elif r[ii] == 4:
                xn -= 1
                xp -= 1
            elif r[ii] == 5:
                yn -= 1
                yp -= 1
            elif r[ii] == 6:
                zn -= 1
                zp -= 1
            
            # Apply periodic boundary conditions (mod(xn-1,L) + 1)
            xn = ((xn - 1) % L) + 1
            yn = ((yn - 1) % L) + 1
            zn = ((zn - 1) % L) + 1
            
            # Check if move is allowed (convert to 0-based indexing for array access)
            if bw[int(xn)-1, int(yn)-1, int(zn)-1] == 0:  # Free position
                Y[ii] = [xn, yn, zn]
                X[ii] = [xp, yp, zp]
            else:  # Blocked
                Y[ii] = xyz0
                X[ii] = xyzp0
                flg = 1
                spc = 0
                WT = max(1, int(abs(np.random.normal(wt[0], wt[1]))))
        else:
            spc += 1
            if spc > WT:
                flg = 0
                spc = 0
            Y[ii] = xyz0
            X[ii] = xyzp0
    
    return Y, X

def test_3d_p0_every_step():
    """
    Focused test for 3D p=0 with sampling every step
    """
    L = 100
    LW = 100000  # 100,000 steps
    NW = 10
    
    print(f"=== Focused 3D p=0 Test (Every Step Sampling) ===")
    print(f"Lattice size: {L}×{L}×{L}")
    print(f"Steps: {LW:,}")
    print(f"Walkers: {NW}")
    print(f"Sampling: Every step")
    print()
    
    # Generate empty lattice (p=0 means all sites are free)
    bw = np.zeros((L, L, L), dtype=int)  # All sites are free
    
    # Initialize walkers at random positions
    np.random.seed(42)
    rsp = np.random.randint(0, L, (NW, 3))
    
    # Arrays to store positions
    x = np.zeros((LW, NW))
    y = np.zeros((LW, NW))
    z = np.zeros((LW, NW))
    
    print("Running 3D random walks...")
    
    # Run random walks for each walker
    for i_rw in range(NW):
        if i_rw % 2 == 0:
            print(f"  Walker {i_rw+1}/{NW}")
        
        xyz, xyzp = rw3d_p_sp_matlab_style(bw, LW, L, rsp[i_rw], wt=[20, 5])
        x[:, i_rw] = xyzp[:, 0]
        y[:, i_rw] = xyzp[:, 1]
        z[:, i_rw] = xyzp[:, 2]
    
    # Calculate MSD for every step (using unwrapped positions, no PBC correction needed)
    dx = x - np.tile(x[0, :], (LW, 1))
    dy = y - np.tile(y[0, :], (LW, 1))
    dz = z - np.tile(z[0, :], (LW, 1))
    
    # No PBC correction needed since we're using unwrapped positions
    sd = dx**2 + dy**2 + dz**2
    msd = np.mean(sd, axis=1)
    
    t = np.arange(1, LW + 1)
    
    # Analyze results
    print(f"\n=== Analysis ===")
    
    # Remove first 10 points (as in MATLAB)
    t_clean = t[10:]
    msd_clean = msd[10:]
    
    # Fit power law
    ln_t = np.log10(t_clean)
    ln_msd = np.log10(msd_clean)
    
    # Linear fit (power law)
    coeffs = np.polyfit(ln_t, ln_msd, 1)
    exponent = coeffs[0]
    intercept = coeffs[1]
    
    # Calculate R²
    msd_predicted = 10**(exponent * ln_t + intercept)
    ss_res = np.sum((msd_clean - msd_predicted) ** 2)
    ss_tot = np.sum((msd_clean - np.mean(msd_clean)) ** 2)
    r_squared = 1 - (ss_res / ss_tot)
    
    print(f"Growth exponent: α = {exponent:.3f}")
    print(f"R²: {r_squared:.6f}")
    print(f"Expected for 3D: α = 1.0")
    print(f"Ratio to expected: {exponent:.3f}")
    
    # Check linearity
    linear_coeffs = np.polyfit(t_clean, msd_clean, 1)
    linear_slope = linear_coeffs[0]
    msd_linear_pred = linear_slope * t_clean + linear_coeffs[1]
    ss_res_linear = np.sum((msd_clean - msd_linear_pred) ** 2)
    r_squared_linear = 1 - (ss_res_linear / ss_tot)
    
    print(f"Linear fit R²: {r_squared_linear:.6f}")
    print(f"Linear slope: {linear_slope:.6f}")
    
    # Check final values
    print(f"\nFinal MSD value: {msd[-1]:.2f}")
    print(f"Expected MSD for 3D: {t[-1]/6:.2f}")
    print(f"Ratio: {msd[-1]/(t[-1]/6):.3f}")
    
    # Check early vs late time behavior
    early_t = t[100:1000]  # Start from step 100 to avoid zero MSD
    early_msd = msd[100:1000]
    late_t = t[-1000:]
    late_msd = msd[-1000:]
    
    if len(early_t) > 10 and np.all(early_msd > 0):
        early_exponent = np.polyfit(np.log10(early_t), np.log10(early_msd), 1)[0]
        print(f"Early time exponent (steps 100-1000): α = {early_exponent:.3f}")
    else:
        print(f"Early time exponent: Cannot calculate (insufficient data or zero MSD)")
    
    if len(late_t) > 10 and np.all(late_msd > 0):
        late_exponent = np.polyfit(np.log10(late_t), np.log10(late_msd), 1)[0]
        print(f"Late time exponent (last 1000 steps): α = {late_exponent:.3f}")
    else:
        print(f"Late time exponent: Cannot calculate (insufficient data or zero MSD)")
    
    # Plot results
    plt.figure(figsize=(15, 5))
    
    # Linear scale
    plt.subplot(1, 3, 1)
    plt.plot(t, msd, 'b-', linewidth=2, label='p = 0.00 (Every Step)')
    
    # Add theoretical line for 3D
    theoretical_3d = t / 6  # D = 1/6 for 3D simple cubic
    plt.plot(t, theoretical_3d, 'r--', linewidth=2, label='Theoretical 3D (D=1/6)')
    
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('3D Free Random Walk (p=0) - Linear Scale')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    # Log-log scale
    plt.subplot(1, 3, 2)
    plt.loglog(t, msd, 'b-', linewidth=2, label='p = 0.00 (Every Step)')
    plt.loglog(t, theoretical_3d, 'r--', linewidth=2, label='Theoretical 3D (D=1/6)')
    plt.loglog(t, t, 'g:', linewidth=1, label='Slope = 1 (α = 1.0)')
    
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('3D Free Random Walk (p=0) - Log-Log Scale')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    # Focus on early time
    plt.subplot(1, 3, 3)
    early_range = slice(100, min(1000, len(t)))
    plt.loglog(t[early_range], msd[early_range], 'b-', linewidth=2, label='p = 0.00 (Early)')
    plt.loglog(t[early_range], theoretical_3d[early_range], 'r--', linewidth=2, label='Theoretical 3D')
    plt.loglog(t[early_range], t[early_range], 'g:', linewidth=1, label='Slope = 1')
    
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('Early Time Behavior (Steps 100-1000)')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('3d_p0_every_step_results.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    # Save results
    results_df = pd.DataFrame({
        'step': t,
        'msd': msd,
        'theoretical_3d': theoretical_3d
    })
    
    results_df.to_csv('3d_p0_every_step_results.csv', index=False)
    print(f"\nResults saved to: 3d_p0_every_step_results.csv")
    print(f"Plot saved to: 3d_p0_every_step_results.png")
    
    return t, msd, exponent, r_squared

def run_3d_templated_simulation():
    """
    Run 3D simulation with templating where higher p-values build upon lower ones
    """
    L = 100  # Smaller for testing
    LW = 100000  # 100,000 steps
    NW = 10
    p_values = [0, 0.3116, 0.6884, 0.75]
    
    print(f"=== 3D Templated Simulation ===")
    print(f"Lattice size: {L}×{L}×{L}")
    print(f"Steps: {LW:,}")
    print(f"Walkers: {NW}")
    print(f"p-values: {p_values}")
    print(f"Templating: Higher p-values build upon lower ones")
    print()
    
    Np = len(p_values)
    msd = np.zeros((LW, Np))
    t = np.arange(1, LW + 1)
    
    # Initialize base template for p = 0
    base_template = np.zeros((L, L, L), dtype=bool)
    
    for i_p, p in enumerate(p_values):
        print(f"Processing p = {p:.4f} ({i_p+1}/{Np})")
        
        # Generate random array
        np.random.seed(42 + i_p)  # For reproducibility
        R = np.random.random((L, L, L))
        
        if i_p == 0:
            # p = 0: no occupied sites
            bw = base_template
        else:
            # For higher p-values: start with previous template and add more sites
            if i_p == 1:
                # p = 0.3116: start with p = 0 template, add 31.16% more sites
                additional_sites = R < p
                bw = base_template | additional_sites
            elif i_p == 2:
                # p = 0.6884: need to achieve 68.84% total occupation
                # Current occupation from previous template
                current_occupied = np.sum(base_template)
                target_occupied = int(p * (L**3))
                additional_needed = target_occupied - current_occupied
                
                if additional_needed > 0:
                    # Find unoccupied sites
                    unoccupied = ~base_template
                    unoccupied_indices = np.where(unoccupied)
                    
                    # Randomly select additional_needed sites from unoccupied ones
                    if len(unoccupied_indices[0]) >= additional_needed:
                        selected_indices = np.random.choice(
                            len(unoccupied_indices[0]), 
                            additional_needed, 
                            replace=False
                        )
                        
                        # Create new template
                        bw = base_template.copy()
                        for idx in selected_indices:
                            x, y, z = unoccupied_indices[0][idx], unoccupied_indices[1][idx], unoccupied_indices[2][idx]
                            bw[x, y, z] = True
                    else:
                        bw = base_template.copy()
                else:
                    bw = base_template.copy()
                    
            elif i_p == 3:
                # p = 0.75: need to achieve 75% total occupation
                current_occupied = np.sum(base_template)
                target_occupied = int(p * (L**3))
                additional_needed = target_occupied - current_occupied
                
                if additional_needed > 0:
                    # Find unoccupied sites
                    unoccupied = ~base_template
                    unoccupied_indices = np.where(unoccupied)
                    
                    # Randomly select additional_needed sites from unoccupied ones
                    if len(unoccupied_indices[0]) >= additional_needed:
                        selected_indices = np.random.choice(
                            len(unoccupied_indices[0]), 
                            additional_needed, 
                            replace=False
                        )
                        
                        # Create new template
                        bw = base_template.copy()
                        for idx in selected_indices:
                            x, y, z = unoccupied_indices[0][idx], unoccupied_indices[1][idx], unoccupied_indices[2][idx]
                            bw[x, y, z] = True
                    else:
                        bw = base_template.copy()
                else:
                    bw = base_template.copy()
            
            # Update base template for next iteration
            base_template = bw.copy()
        
        # Find free positions in 3D
        free_positions = np.where(bw == 0)
        px, py, pz = free_positions[0], free_positions[1], free_positions[2]
        N_rsp = len(px)
        
        if N_rsp < NW:
            print(f"Warning: Only {N_rsp} free positions for {NW} walkers")
            continue
        
        # Initialize walkers at random free positions
        rp = np.random.randint(0, N_rsp, NW)
        rsp = np.column_stack([px[rp], py[rp], pz[rp]])
        
        # Arrays to store positions
        x = np.zeros((LW, NW))
        y = np.zeros((LW, NW))
        z = np.zeros((LW, NW))
        
        # Run random walks for each walker
        for i_rw in range(NW):
            xyz, xyzp = rw3d_p_sp_matlab_style(bw, LW, L, rsp[i_rw], wt=[20, 5])
            x[:, i_rw] = xyzp[:, 0]
            y[:, i_rw] = xyzp[:, 1]
            z[:, i_rw] = xyzp[:, 2]
        
        # Calculate MSD with proper PBC handling
        dx = x - np.tile(x[0, :], (LW, 1))
        dy = y - np.tile(y[0, :], (LW, 1))
        dz = z - np.tile(z[0, :], (LW, 1))
        
        # No PBC correction needed since we're using unwrapped positions
        sd = dx**2 + dy**2 + dz**2
        msd[:, i_p] = np.mean(sd, axis=1)
        
        # Print template statistics
        occupied_fraction = np.sum(bw) / (L**3)
        print(f"  Occupied fraction: {occupied_fraction:.4f} (target: {p:.4f})")
    
    return t, msd, p_values

def plot_templated_results(t, msd, p_values):
    """
    Plot results from templated simulation
    """
    plt.figure(figsize=(15, 10))
    
    # Main log-log plot
    plt.subplot(2, 2, 1)
    colors = plt.cm.viridis(np.linspace(0, 1, len(p_values)))
    
    for i, p in enumerate(p_values):
        plt.loglog(t, msd[:, i], color=colors[i], linewidth=2, label=f'p = {p:.4f}')
    
    # Add theoretical line for p=0
    theoretical_3d = t / 6  # D = 1/6 for 3D simple cubic
    plt.loglog(t, theoretical_3d, 'k--', linewidth=2, label='Theoretical 3D (p=0)')
    plt.loglog(t, t, 'k:', linewidth=1, label='Slope = 1 (α = 1.0)')
    
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('3D Templated MSD vs Time (Log-Log)')
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.grid(True, alpha=0.3)
    
    # Linear scale plot
    plt.subplot(2, 2, 2)
    for i, p in enumerate(p_values):
        plt.plot(t, msd[:, i], color=colors[i], linewidth=2, label=f'p = {p:.4f}')
    
    plt.plot(t, theoretical_3d, 'k--', linewidth=2, label='Theoretical 3D (p=0)')
    
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('3D Templated MSD vs Time (Linear)')
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.grid(True, alpha=0.3)
    
    # Focus on early time (first 5,000 steps)
    plt.subplot(2, 2, 3)
    early_range = slice(0, min(5000, len(t)))
    
    for i, p in enumerate(p_values):
        plt.loglog(t[early_range], msd[early_range, i], color=colors[i], linewidth=2, label=f'p = {p:.4f}')
    
    plt.loglog(t[early_range], theoretical_3d[early_range], 'k--', linewidth=2, label='Theoretical 3D (p=0)')
    plt.loglog(t[early_range], t[early_range], 'k:', linewidth=1, label='Slope = 1')
    
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('Early Time (First 5,000 Steps)')
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.grid(True, alpha=0.3)
    
    # Growth exponent analysis
    plt.subplot(2, 2, 4)
    
    exponents = []
    r_squared_values = []
    
    for i, p in enumerate(p_values):
        # Remove first 10 points and fit
        t_clean = t[10:]
        msd_clean = msd[10:, i]
        
        if np.all(msd_clean > 0):
            ln_t = np.log10(t_clean)
            ln_msd = np.log10(msd_clean)
            
            coeffs = np.polyfit(ln_t, ln_msd, 1)
            exponent = coeffs[0]
            
            msd_pred = 10**(exponent * ln_t + coeffs[1])
            ss_res = np.sum((msd_clean - msd_pred) ** 2)
            ss_tot = np.sum((msd_clean - np.mean(msd_clean)) ** 2)
            r_squared = 1 - (ss_res / ss_tot)
            
            exponents.append(exponent)
            r_squared_values.append(r_squared)
        else:
            exponents.append(np.nan)
            r_squared_values.append(np.nan)
    
    # Plot growth exponents
    valid_indices = ~np.isnan(exponents)
    if np.any(valid_indices):
        plt.plot(np.array(p_values)[valid_indices], np.array(exponents)[valid_indices], 'bo-', linewidth=2, markersize=8)
        plt.axhline(y=1.0, color='r', linestyle='--', linewidth=2, label='Theoretical (α = 1.0)')
    
    plt.xlabel('Occupation Probability (p)')
    plt.ylabel('Growth Exponent (α)')
    plt.title('Growth Exponent vs Occupation Probability (Templated)')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('3d_templated_results.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    # Print analysis
    print(f"\n=== Growth Exponent Analysis (Templated) ===")
    for i, p in enumerate(p_values):
        if not np.isnan(exponents[i]):
            print(f"p = {p:.4f}: α = {exponents[i]:.3f}, R² = {r_squared_values[i]:.6f}")
        else:
            print(f"p = {p:.4f}: Cannot calculate (insufficient data)")
    
    return exponents, r_squared_values

def main_templated():
    """Main function for templated simulation"""
    # Run templated simulation
    t, msd, p_values = run_3d_templated_simulation()
    
    # Plot results
    exponents, r_squared_values = plot_templated_results(t, msd, p_values)
    
    # Save results
    results_df = pd.DataFrame({
        'step': t,
        **{f'p_{p:.4f}': msd[:, i] for i, p in enumerate(p_values)}
    })
    
    results_df.to_csv('3d_templated_results.csv', index=False)
    print(f"\nResults saved to: 3d_templated_results.csv")
    print(f"Plot saved to: 3d_templated_results.png")
    
    return t, msd, p_values, exponents, r_squared_values

if __name__ == "__main__":
    # Run the focused 3D p=0 test
    test_3d_p0_every_step()
    
    # Run the templated simulation
    main_templated() 