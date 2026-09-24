#!/usr/bin/env python3
"""
Python implementation matching MATLAB random walk algorithm
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from pathlib import Path

def rw_percolation_2d_matlab_style(L=400, LW=100000, NW=100, p_values=None):
    """
    Python implementation matching MATLAB RW_percolation_2.m
    """
    if p_values is None:
        p_values = np.arange(0, 0.65, 0.05)  # 0:0.05:0.6
    
    print(f"=== MATLAB-Compatible 2D Random Walk ===")
    print(f"Lattice size: {L}×{L}")
    print(f"Steps: {LW}")
    print(f"Walkers: {NW}")
    print(f"p-values: {p_values}")
    print()
    
    Np = len(p_values)
    msd = np.zeros((LW, Np))
    t = np.arange(1, LW + 1)
    
    for i_p, p in enumerate(p_values):
        print(f"Processing p = {p:.2f} ({i_p+1}/{Np})")
        
        # Generate lattice (same as MATLAB: R < p)
        np.random.seed(42)  # For reproducibility
        R = np.random.random((L, L))
        bw = R < p  # bw = 1 means occupied (obstacle), bw = 0 means free
        
        # Find free positions (same as MATLAB: find(~bw))
        free_positions = np.where(bw == 0)
        px, py = free_positions[0], free_positions[1]
        N_rsp = len(px)
        
        if N_rsp < NW:
            print(f"Warning: Only {N_rsp} free positions for {NW} walkers")
            continue
        
        # Initialize walkers at random free positions
        rp = np.random.randint(0, N_rsp, NW)
        rsp = np.column_stack([px[rp], py[rp]])
        
        # Arrays to store positions
        x = np.zeros((LW, NW))
        y = np.zeros((LW, NW))
        
        # Run random walks for each walker
        for i_rw in range(NW):
            xy, xyp = rw_p_sp_matlab_style(bw, LW, L, rsp[i_rw], wt=[20, 5])
            x[:, i_rw] = xy[:, 0]
            y[:, i_rw] = xy[:, 1]
        
        # Calculate MSD for every step with proper PBC handling
        dx = x - np.tile(x[0, :], (LW, 1))  # repmat(x(1,:),LW,1)
        dy = y - np.tile(y[0, :], (LW, 1))  # repmat(y(1,:),LW,1)
        
        # Apply PBC correction to displacements (same as our corrected 3D version)
        L = 400
        for dim in range(2):  # x and y dimensions
            if dim == 0:
                displacements = dx
            else:
                displacements = dy
            
            # Correct for PBCs
            displacements = np.where(
                displacements > L/2,
                displacements - L,
                displacements
            )
            displacements = np.where(
                displacements < -L/2,
                displacements + L,
                displacements
            )
            
            if dim == 0:
                dx = displacements
            else:
                dy = displacements
        
        sd = dx**2 + dy**2  # (dx.*dx + dy.*dy)
        msd[:, i_p] = np.mean(sd, axis=1)
    
    return t, msd, p_values

def rw_p_sp_matlab_style(bw, LW, L, xy0, wt):
    """
    Python implementation matching MATLAB RW_P_SP.m
    """
    # Initialize
    r = np.random.randint(1, 5, LW)  # ceil(rand(LW,1)*4)
    Y = np.zeros((LW, 2))
    X = np.zeros((LW, 2))
    Y[0] = xy0
    X[0] = xy0
    
    flg = 0
    spc = 0
    
    for ii in range(1, LW):
        xy0 = Y[ii-1]
        xn, yn = xy0[0], xy0[1]
        xyp0 = X[ii-1]
        xp, yp = xyp0[0], xyp0[1]
        
        if flg == 0:
            # Move in random direction
            if r[ii] == 1:
                xn += 1
                xp += 1
            elif r[ii] == 2:
                yn += 1
                yp += 1
            elif r[ii] == 3:
                xn -= 1
                xp -= 1
            elif r[ii] == 4:
                yn -= 1
                yp -= 1
            
            # Apply periodic boundary conditions (mod(xn-1,L) + 1)
            xn = ((xn - 1) % L) + 1
            yn = ((yn - 1) % L) + 1
            
            # Check if move is allowed
            if bw[int(xn)-1, int(yn)-1] == 0:  # Free position
                Y[ii] = [xn, yn]
                X[ii] = [xp, yp]
            else:  # Blocked
                Y[ii] = xy0
                X[ii] = xyp0
                flg = 1
                spc = 0
                WT = max(1, int(abs(np.random.normal(wt[0], wt[1]))))
        else:
            spc += 1
            if spc > WT:
                flg = 0
                spc = 0
            Y[ii] = xy0
            X[ii] = xyp0
    
    return Y, X

def analyze_matlab_style_results(t, msd, p_values):
    """
    Analyze results in MATLAB style
    """
    print(f"\n=== MATLAB-Style Analysis ===")
    
    # Focus on p = 0 (free random walk)
    p0_idx = np.where(p_values == 0)[0]
    if len(p0_idx) > 0:
        p0_idx = p0_idx[0]
        msd_p0 = msd[:, p0_idx]
        
        # Remove first 10 points (as in MATLAB)
        t_clean = t[10:]
        msd_clean = msd_p0[10:]
        
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
        
        print(f"p = 0.00 (Free Random Walk):")
        print(f"  Growth exponent: α = {exponent:.3f}")
        print(f"  R²: {r_squared:.6f}")
        print(f"  Expected for 2D: α = 1.0")
        print(f"  Ratio to expected: {exponent:.3f}")
        
        # Check linearity
        linear_coeffs = np.polyfit(t_clean, msd_clean, 1)
        linear_slope = linear_coeffs[0]
        msd_linear_pred = linear_slope * t_clean + linear_coeffs[1]
        ss_res_linear = np.sum((msd_clean - msd_linear_pred) ** 2)
        r_squared_linear = 1 - (ss_res_linear / ss_tot)
        
        print(f"  Linear fit R²: {r_squared_linear:.6f}")
        print(f"  Linear slope: {linear_slope:.6f}")
        
        return exponent, r_squared, linear_slope, r_squared_linear
    
    return None, None, None, None

def plot_matlab_style_results(t, msd, p_values):
    """
    Plot results in MATLAB style
    """
    plt.figure(figsize=(15, 5))
    
    # Log-log plot (like MATLAB figure 3)
    plt.subplot(1, 3, 1)
    for i, p in enumerate(p_values):
        plt.loglog(t, msd[:, i], label=f'p = {p:.2f}')
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('MSD vs Time (Log-Log) - MATLAB Style')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    # Focus on p = 0
    p0_idx = np.where(p_values == 0)[0]
    if len(p0_idx) > 0:
        p0_idx = p0_idx[0]
        msd_p0 = msd[:, p0_idx]
        
        # Linear scale
        plt.subplot(1, 3, 2)
        plt.plot(t, msd_p0, 'b-', linewidth=2, label='p = 0.00')
        
        # Add theoretical line for 2D
        theoretical_2d = t / 4  # D = 1/4 for 2D simple cubic
        plt.plot(t, theoretical_2d, 'r--', linewidth=2, label='Theoretical 2D (D=1/4)')
        
        plt.xlabel('Time Step')
        plt.ylabel('MSD')
        plt.title('Free Random Walk (p=0) - Linear Scale')
        plt.legend()
        plt.grid(True, alpha=0.3)
        
        # Log-log scale for p = 0
        plt.subplot(1, 3, 3)
        plt.loglog(t, msd_p0, 'b-', linewidth=2, label='p = 0.00')
        plt.loglog(t, theoretical_2d, 'r--', linewidth=2, label='Theoretical 2D (D=1/4)')
        plt.loglog(t, t, 'g:', linewidth=1, label='Slope = 1 (α = 1.0)')
        
        plt.xlabel('Time Step')
        plt.ylabel('MSD')
        plt.title('Free Random Walk (p=0) - Log-Log Scale')
        plt.legend()
        plt.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('matlab_style_results.png', dpi=300, bbox_inches='tight')
    plt.show()

def main():
    # Run MATLAB-compatible simulation with longer steps
    print("Running longer simulation for better statistics...")
    t, msd, p_values = rw_percolation_2d_matlab_style(L=400, LW=50000, NW=100)
    
    # Analyze results
    exponent, r_squared, linear_slope, r_squared_linear = analyze_matlab_style_results(t, msd, p_values)
    
    # Plot results
    plot_matlab_style_results(t, msd, p_values)
    
    # Save results
    results_df = pd.DataFrame({
        'step': t,
        **{f'p_{p:.2f}': msd[:, i] for i, p in enumerate(p_values)}
    })
    
    results_df.to_csv('matlab_style_results.csv', index=False)
    print(f"\nResults saved to: matlab_style_results.csv")
    print(f"Plot saved to: matlab_style_results.png")
    
    # Additional analysis for p = 0
    p0_idx = np.where(p_values == 0)[0]
    if len(p0_idx) > 0:
        p0_idx = p0_idx[0]
        msd_p0 = msd[:, p0_idx]
        
        print(f"\n=== Detailed Analysis for p = 0 ===")
        print(f"Final MSD value: {msd_p0[-1]:.2f}")
        print(f"Expected MSD for 2D: {t[-1]/4:.2f}")
        print(f"Ratio: {msd_p0[-1]/(t[-1]/4):.3f}")
        
        # Check early vs late time behavior
        early_t = t[100:1000]  # Start from step 100 to avoid zero MSD
        early_msd = msd_p0[100:1000]
        late_t = t[-1000:]
        late_msd = msd_p0[-1000:]
        
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
        
        # Also check steps 100-500 for a shorter early time window
        short_early_t = t[100:500]
        short_early_msd = msd_p0[100:500]
        
        if len(short_early_t) > 10 and np.all(short_early_msd > 0):
            short_early_exponent = np.polyfit(np.log10(short_early_t), np.log10(short_early_msd), 1)[0]
            print(f"Short early time exponent (steps 100-500): α = {short_early_exponent:.3f}")
        else:
            print(f"Short early time exponent: Cannot calculate")

def test_p0_every_step():
    """
    Focused test for p=0 with sampling every step to catch boundary crossings
    """
    L = 400
    LW = 10000  # 10,000 steps
    NW = 100
    
    print(f"=== Focused p=0 Test (Every Step Sampling) ===")
    print(f"Lattice size: {L}×{L}")
    print(f"Steps: {LW}")
    print(f"Walkers: {NW}")
    print(f"Sampling: Every step")
    print()
    
    # Generate empty lattice (p=0 means all sites are free)
    bw = np.zeros((L, L), dtype=int)  # All sites are free
    
    # Initialize walkers at random positions
    np.random.seed(42)
    rsp = np.random.randint(0, L, (NW, 2))
    
    # Arrays to store positions
    x = np.zeros((LW, NW))
    y = np.zeros((LW, NW))
    
    print("Running random walks...")
    
    # Run random walks for each walker
    for i_rw in range(NW):
        if i_rw % 20 == 0:
            print(f"  Walker {i_rw+1}/{NW}")
        
        xy, xyp = rw_p_sp_matlab_style_exact(bw, LW, L, rsp[i_rw], wt=[20, 5])
        x[:, i_rw] = xy[:, 0]
        y[:, i_rw] = xy[:, 1]
    
    # Calculate MSD for every step with proper PBC handling
    dx = x - np.tile(x[0, :], (LW, 1))  # repmat(x(1,:),LW,1)
    dy = y - np.tile(y[0, :], (LW, 1))  # repmat(y(1,:),LW,1)
    
    # Apply PBC correction to displacements (same as our corrected 3D version)
    L = 400
    for dim in range(2):  # x and y dimensions
        if dim == 0:
            displacements = dx
        else:
            displacements = dy
            
        # Correct for PBCs
        displacements = np.where(
            displacements > L/2,
            displacements - L,
            displacements
        )
        displacements = np.where(
            displacements < -L/2,
            displacements + L,
            displacements
        )
        
        if dim == 0:
            dx = displacements
        else:
            dy = displacements
    
    sd = dx**2 + dy**2  # (dx.*dx + dy.*dy)
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
    print(f"Expected for 2D: α = 1.0")
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
    print(f"Expected MSD for 2D: {t[-1]/4:.2f}")
    print(f"Ratio: {msd[-1]/(t[-1]/4):.3f}")
    
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
    
    # Also check steps 100-500 for a shorter early time window
    short_early_t = t[100:500]
    short_early_msd = msd[100:500]
    
    if len(short_early_t) > 10 and np.all(short_early_msd > 0):
        short_early_exponent = np.polyfit(np.log10(short_early_t), np.log10(short_early_msd), 1)[0]
        print(f"Short early time exponent (steps 100-500): α = {short_early_exponent:.3f}")
    else:
        print(f"Short early time exponent: Cannot calculate")
    
    # Plot results
    plt.figure(figsize=(15, 5))
    
    # Linear scale
    plt.subplot(1, 3, 1)
    plt.plot(t, msd, 'b-', linewidth=2, label='p = 0.00 (Every Step)')
    
    # Add theoretical line for 2D
    theoretical_2d = t / 4  # D = 1/4 for 2D simple cubic
    plt.plot(t, theoretical_2d, 'r--', linewidth=2, label='Theoretical 2D (D=1/4)')
    
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('Free Random Walk (p=0) - Linear Scale')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    # Log-log scale
    plt.subplot(1, 3, 2)
    plt.loglog(t, msd, 'b-', linewidth=2, label='p = 0.00 (Every Step)')
    plt.loglog(t, theoretical_2d, 'r--', linewidth=2, label='Theoretical 2D (D=1/4)')
    plt.loglog(t, t, 'g:', linewidth=1, label='Slope = 1 (α = 1.0)')
    
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('Free Random Walk (p=0) - Log-Log Scale')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    # Focus on early time
    plt.subplot(1, 3, 3)
    early_range = slice(0, min(1000, len(t)))
    plt.loglog(t[early_range], msd[early_range], 'b-', linewidth=2, label='p = 0.00 (Early)')
    plt.loglog(t[early_range], theoretical_2d[early_range], 'r--', linewidth=2, label='Theoretical 2D')
    plt.loglog(t[early_range], t[early_range], 'g:', linewidth=1, label='Slope = 1')
    
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('Early Time Behavior (First 1000 Steps)')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('p0_every_step_results.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    # Save results
    results_df = pd.DataFrame({
        'step': t,
        'msd': msd,
        'theoretical_2d': theoretical_2d
    })
    
    results_df.to_csv('p0_every_step_results.csv', index=False)
    print(f"\nResults saved to: p0_every_step_results.csv")
    print(f"Plot saved to: p0_every_step_results.png")
    
    return t, msd, exponent, r_squared

def rw_p_sp_matlab_style_exact(bw, LW, L, xy0, wt):
    """
    Exact MATLAB-style implementation with proper boundary handling
    """
    # Initialize
    r = np.random.randint(1, 5, LW)  # ceil(rand(LW,1)*4)
    Y = np.zeros((LW, 2))
    X = np.zeros((LW, 2))
    Y[0] = xy0
    X[0] = xy0
    
    flg = 0
    spc = 0
    
    for ii in range(1, LW):
        xy0 = Y[ii-1]
        xn, yn = xy0[0], xy0[1]
        xyp0 = X[ii-1]
        xp, yp = xyp0[0], xyp0[1]
        
        if flg == 0:
            # Move in random direction
            if r[ii] == 1:
                xn += 1
                xp += 1
            elif r[ii] == 2:
                yn += 1
                yp += 1
            elif r[ii] == 3:
                xn -= 1
                xp -= 1
            elif r[ii] == 4:
                yn -= 1
                yp -= 1
            
            # Apply periodic boundary conditions EXACTLY like MATLAB
            # MATLAB: xn = mod(xn-1,L) + 1
            xn = ((xn - 1) % L) + 1
            yn = ((yn - 1) % L) + 1
            
            # Check if move is allowed (convert to 0-based indexing for array access)
            if bw[int(xn)-1, int(yn)-1] == 0:  # Free position
                Y[ii] = [xn, yn]
                X[ii] = [xp, yp]
            else:  # Blocked
                Y[ii] = xy0
                X[ii] = xyp0
                flg = 1
                spc = 0
                WT = max(1, int(abs(np.random.normal(wt[0], wt[1]))))
        else:
            spc += 1
            if spc > WT:
                flg = 0
                spc = 0
            Y[ii] = xy0
            X[ii] = xyp0
    
    return Y, X

def run_2d_multiple_p_values():
    """
    Run 2D simulation with p = 0:0.1:0.7, 10 walkers, 100,000 steps
    """
    L = 400
    LW = 100000  # 100,000 steps
    NW = 10      # 10 walkers
    p_values = np.arange(0, 0.8, 0.1)  # 0:0.1:0.7
    
    print(f"=== 2D Multiple p-values Simulation ===")
    print(f"Lattice size: {L}×{L}")
    print(f"Steps: {LW:,}")
    print(f"Walkers: {NW}")
    print(f"p-values: {p_values}")
    print(f"Sampling: Every step")
    print()
    
    Np = len(p_values)
    msd = np.zeros((LW, Np))
    t = np.arange(1, LW + 1)
    
    for i_p, p in enumerate(p_values):
        print(f"Processing p = {p:.1f} ({i_p+1}/{Np})")
        
        # Generate lattice
        np.random.seed(42 + i_p)  # Different seed for each p
        R = np.random.random((L, L))
        bw = R < p  # bw = 1 means occupied (obstacle), bw = 0 means free
        
        # Find free positions
        free_positions = np.where(bw == 0)
        px, py = free_positions[0], free_positions[1]
        N_rsp = len(px)
        
        if N_rsp < NW:
            print(f"Warning: Only {N_rsp} free positions for {NW} walkers")
            continue
        
        # Initialize walkers at random free positions
        rp = np.random.randint(0, N_rsp, NW)
        rsp = np.column_stack([px[rp], py[rp]])
        
        # Arrays to store positions
        x = np.zeros((LW, NW))
        y = np.zeros((LW, NW))
        
        # Run random walks for each walker
        for i_rw in range(NW):
            xy, xyp = rw_p_sp_matlab_style_exact(bw, LW, L, rsp[i_rw], wt=[20, 5])
            x[:, i_rw] = xy[:, 0]
            y[:, i_rw] = xy[:, 1]
        
        # Calculate MSD with proper PBC handling
        dx = x - np.tile(x[0, :], (LW, 1))
        dy = y - np.tile(y[0, :], (LW, 1))
        
        # Apply PBC correction to displacements
        for dim in range(2):
            if dim == 0:
                displacements = dx
            else:
                displacements = dy
            
            # Correct for PBCs
            displacements = np.where(
                displacements > L/2,
                displacements - L,
                displacements
            )
            displacements = np.where(
                displacements < -L/2,
                displacements + L,
                displacements
            )
            
            if dim == 0:
                dx = displacements
            else:
                dy = displacements
        
        sd = dx**2 + dy**2
        msd[:, i_p] = np.mean(sd, axis=1)
    
    return t, msd, p_values

def plot_multiple_p_values(t, msd, p_values):
    """
    Plot all MSD curves on the same graph
    """
    plt.figure(figsize=(15, 10))
    
    # Main log-log plot
    plt.subplot(2, 2, 1)
    colors = plt.cm.viridis(np.linspace(0, 1, len(p_values)))
    
    for i, p in enumerate(p_values):
        plt.loglog(t, msd[:, i], color=colors[i], linewidth=2, label=f'p = {p:.1f}')
    
    # Add theoretical line for p=0
    theoretical_2d = t / 4  # D = 1/4 for 2D
    plt.loglog(t, theoretical_2d, 'k--', linewidth=2, label='Theoretical 2D (p=0)')
    plt.loglog(t, t, 'k:', linewidth=1, label='Slope = 1 (α = 1.0)')
    
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('MSD vs Time - All p-values (Log-Log)')
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.grid(True, alpha=0.3)
    
    # Linear scale plot
    plt.subplot(2, 2, 2)
    for i, p in enumerate(p_values):
        plt.plot(t, msd[:, i], color=colors[i], linewidth=2, label=f'p = {p:.1f}')
    
    plt.plot(t, theoretical_2d, 'k--', linewidth=2, label='Theoretical 2D (p=0)')
    
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('MSD vs Time - All p-values (Linear)')
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.grid(True, alpha=0.3)
    
    # Focus on early time (first 10,000 steps)
    plt.subplot(2, 2, 3)
    early_range = slice(0, min(10000, len(t)))
    
    for i, p in enumerate(p_values):
        plt.loglog(t[early_range], msd[early_range, i], color=colors[i], linewidth=2, label=f'p = {p:.1f}')
    
    plt.loglog(t[early_range], theoretical_2d[early_range], 'k--', linewidth=2, label='Theoretical 2D (p=0)')
    plt.loglog(t[early_range], t[early_range], 'k:', linewidth=1, label='Slope = 1')
    
    plt.xlabel('Time Step')
    plt.ylabel('MSD')
    plt.title('Early Time (First 10,000 Steps)')
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
    plt.title('Growth Exponent vs Occupation Probability')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('2d_multiple_p_values.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    # Print analysis
    print(f"\n=== Growth Exponent Analysis ===")
    for i, p in enumerate(p_values):
        if not np.isnan(exponents[i]):
            print(f"p = {p:.1f}: α = {exponents[i]:.3f}, R² = {r_squared_values[i]:.6f}")
        else:
            print(f"p = {p:.1f}: Cannot calculate (insufficient data)")
    
    return exponents, r_squared_values

def main_multiple_p():
    """Main function for multiple p-values simulation"""
    # Run simulation
    t, msd, p_values = run_2d_multiple_p_values()
    
    # Plot results
    exponents, r_squared_values = plot_multiple_p_values(t, msd, p_values)
    
    # Save results
    results_df = pd.DataFrame({
        'step': t,
        **{f'p_{p:.1f}': msd[:, i] for i, p in enumerate(p_values)}
    })
    
    results_df.to_csv('2d_multiple_p_values.csv', index=False)
    print(f"\nResults saved to: 2d_multiple_p_values.csv")
    print(f"Plot saved to: 2d_multiple_p_values.png")
    
    return t, msd, p_values, exponents, r_squared_values

if __name__ == "__main__":
    # Run the focused p=0 test with every step sampling
    test_p0_every_step()
    
    # Run the multiple p-values simulation
    main_multiple_p() 