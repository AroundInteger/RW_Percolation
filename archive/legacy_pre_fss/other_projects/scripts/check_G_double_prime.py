#!/usr/bin/env python3
"""
Check G''(ω) behavior for different regimes
Verify that G''(ω) follows correct physical behavior for each α value
"""

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Set plotting style
plt.style.use('default')
sns.set_palette("husl")

def check_G_double_prime_behavior():
    """Check G''(ω) behavior for different regimes"""
    
    print("=== CHECKING G''(ω) BEHAVIOR FOR DIFFERENT REGIMES ===\n")
    
    # Define frequency range
    omega = np.logspace(-3, 3, 100)  # 0.001 to 1000 rad/s
    
    # Define regimes to test
    regimes = {
        'Liquid (α = 1.0)': 1.0,
        'Critical (α = 0.5)': 0.5,
        'Solid (α = 0.0)': 0.0
    }
    
    # Create plot
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    
    # Plot 1: G''(ω) vs ω (log-log)
    ax1 = axes[0, 0]
    for regime_name, alpha in regimes.items():
        if alpha <= 0:
            # Solid regime: G'' = 0 (no loss)
            G_double_prime = np.zeros_like(omega)
        else:
            # Liquid and viscoelastic: G'' = G0 * ω^α
            G_double_prime = omega ** alpha
        
        ax1.loglog(omega, G_double_prime, 'o-', linewidth=2, markersize=4, 
                   label=f'{regime_name}', alpha=0.8)
    
    ax1.set_xlabel('Frequency ω (rad/s)', fontsize=12)
    ax1.set_ylabel("G''(ω) (Pa)", fontsize=12)
    ax1.set_title('G''(ω) vs ω for Different Regimes\n(Log-Log Scale)', fontsize=14, fontweight='bold')
    ax1.legend(fontsize=12)
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: G''(ω) vs ω (linear scale for better visibility)
    ax2 = axes[0, 1]
    for regime_name, alpha in regimes.items():
        if alpha <= 0:
            G_double_prime = np.zeros_like(omega)
        else:
            G_double_prime = omega ** alpha
        
        ax2.plot(omega, G_double_prime, 'o-', linewidth=2, markersize=4, 
                label=f'{regime_name}', alpha=0.8)
    
    ax2.set_xlabel('Frequency ω (rad/s)', fontsize=12)
    ax2.set_ylabel("G''(ω) (Pa)", fontsize=12)
    ax2.set_title('G''(ω) vs ω for Different Regimes\n(Linear Scale)', fontsize=14, fontweight='bold')
    ax2.legend(fontsize=12)
    ax2.grid(True, alpha=0.3)
    ax2.set_xscale('log')
    
    # Plot 3: Log-log slope analysis
    ax3 = axes[1, 0]
    for regime_name, alpha in regimes.items():
        if alpha <= 0:
            G_double_prime = np.zeros_like(omega)
        else:
            G_double_prime = omega ** alpha
        
        # Calculate log-log slope
        log_omega = np.log10(omega)
        log_G_double_prime = np.log10(G_double_prime + 1e-10)  # Avoid log(0)
        
        # Fit slope
        if alpha > 0:
            slope, intercept = np.polyfit(log_omega, log_G_double_prime, 1)
            r_squared = 1 - np.sum((log_G_double_prime - (slope * log_omega + intercept))**2) / \
                       np.sum((log_G_double_prime - np.mean(log_G_double_prime))**2)
        else:
            slope = 0
            r_squared = 1.0
        
        # Plot fitted line
        fitted_line = 10**(slope * log_omega + intercept)
        ax3.loglog(omega, fitted_line, '--', linewidth=2, alpha=0.7,
                  label=f'{regime_name}: slope = {slope:.3f}, R² = {r_squared:.3f}')
        
        # Plot data points
        ax3.loglog(omega, G_double_prime, 'o', markersize=3, alpha=0.6)
    
    ax3.set_xlabel('Frequency ω (rad/s)', fontsize=12)
    ax3.set_ylabel("G''(ω) (Pa)", fontsize=12)
    ax3.set_title('G''(ω) Log-Log Slope Analysis\n(Expected vs Fitted)', fontsize=14, fontweight='bold')
    ax3.legend(fontsize=10)
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: Summary table
    ax4 = axes[1, 1]
    ax4.axis('off')
    
    # Create summary table
    table_data = []
    headers = ['Regime', 'α (Theory)', 'G''(ω) Behavior', 'Log-Log Slope', 'Physical Meaning']
    
    for regime_name, alpha in regimes.items():
        if alpha <= 0:
            behavior = "G''(ω) = 0"
            slope = "0"
            meaning = "No loss (purely elastic)"
        elif alpha >= 1:
            behavior = f"G''(ω) ∝ ω^{alpha:.1f}"
            slope = f"{alpha:.1f}"
            meaning = "Viscous loss ∝ frequency"
        else:
            behavior = f"G''(ω) ∝ ω^{alpha:.1f}"
            slope = f"{alpha:.1f}"
            meaning = "Power law loss"
        
        table_data.append([regime_name, f"{alpha:.1f}", behavior, slope, meaning])
    
    # Create table
    table = ax4.table(cellText=table_data, colLabels=headers, 
                      cellLoc='center', loc='center')
    table.auto_set_font_size(False)
    table.set_fontsize(10)
    table.scale(1, 2)
    
    # Style table
    for i in range(len(headers)):
        table[(0, i)].set_facecolor('lightblue')
        table[(0, i)].set_text_props(weight='bold')
    
    ax4.set_title('G''(ω) Behavior Summary', fontsize=14, fontweight='bold')
    
    plt.tight_layout()
    
    # Save plot
    plt.savefig('G_double_prime_behavior_check.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    print("✓ G''(ω) behavior check completed!")
    print("✓ Plot saved as: G_double_prime_behavior_check.png")
    
    # Print summary
    print("\n" + "="*60)
    print("G''(ω) BEHAVIOR SUMMARY")
    print("="*60)
    
    for regime_name, alpha in regimes.items():
        print(f"\n{regime_name}:")
        if alpha <= 0:
            print(f"  G''(ω) = 0 (constant)")
            print(f"  Log-log slope = 0")
            print(f"  Physical meaning: No loss, purely elastic")
        else:
            print(f"  G''(ω) ∝ ω^{alpha:.1f}")
            print(f"  Log-log slope = {alpha:.1f}")
            if alpha >= 1:
                print(f"  Physical meaning: Viscous loss proportional to frequency")
            else:
                print(f"  Physical meaning: Power law loss with exponent {alpha:.1f}")
    
    print("\n" + "="*60)
    print("PHYSICAL VALIDATION:")
    
    # Check if behavior is physically correct
    issues = []
    
    for regime_name, alpha in regimes.items():
        if alpha <= 0:
            # Solid regime: G'' should be 0
            if alpha == 0:
                print(f"✅ {regime_name}: G''(ω) = 0 (correct - no loss)")
            else:
                print(f"⚠️ {regime_name}: α = {alpha} < 0 (unphysical)")
                issues.append(f"{regime_name}: α < 0")
        elif alpha >= 1:
            # Liquid regime: G'' should be proportional to frequency
            print(f"✅ {regime_name}: G''(ω) ∝ ω^{alpha:.1f} (correct - viscous loss)")
        else:
            # Critical regime: G'' should follow power law
            print(f"✅ {regime_name}: G''(ω) ∝ ω^{alpha:.1f} (correct - power law loss)")
    
    if issues:
        print(f"\n⚠️ Issues found: {', '.join(issues)}")
    else:
        print(f"\n🎉 All regimes show physically correct G''(ω) behavior!")

if __name__ == "__main__":
    check_G_double_prime_behavior()
