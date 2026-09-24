#!/usr/bin/env python3
"""
Diagnose Sigmoid α Function
Examine why the sigmoid function is not working correctly for liquid and p_c regimes
"""

import numpy as np
import matplotlib.pyplot as plt

def sigmoid_alpha_function(p_values, p_c, width, alpha_min, alpha_max):
    """Calculate α values using sigmoid function"""
    
    # Sigmoid function: α(p) = α_min + (α_max - α_min) / (1 + exp((p - p_c) / width))
    alpha = alpha_min + (alpha_max - alpha_min) / (1 + np.exp((p_values - p_c) / width))
    
    # Ensure bounds
    alpha = np.clip(alpha, 0.0, 1.0)
    
    return alpha

def main():
    """Main diagnostic function"""
    
    print("=== SIGMOID α FUNCTION DIAGNOSTIC ===\n")
    
    # Parameters from our 3D surface generator
    p_c = 0.6884  # Critical threshold
    width = 0.015  # Width parameter
    alpha_min = 0.0
    alpha_max = 1.0
    
    print(f"Parameters:")
    print(f"  p_c = {p_c:.4f}")
    print(f"  width = {width:.4f}")
    print(f"  α_min = {alpha_min:.4f}")
    print(f"  α_max = {alpha_max:.4f}")
    
    # Test specific p-values
    test_p_values = [0.1, 0.3116, 0.6884, 0.8]
    
    print(f"\nTest Results:")
    print(f"{'p-value':<10} {'α (sigmoid)':<12} {'Expected α':<12} {'Agreement':<10}")
    print("-" * 50)
    
    for p in test_p_values:
        alpha = sigmoid_alpha_function(p, p_c, width, alpha_min, alpha_max)
        
        if p < 0.6:  # Liquid regime
            expected = 1.0
        elif abs(p - 0.6884) < 0.05:  # Critical regime
            expected = 0.5
        else:  # Solid regime
            expected = 0.0
            
        agreement = "✓" if abs(alpha - expected) < 0.1 else "❌"
        
        print(f"{p:<10.4f} {alpha:<12.4f} {expected:<12.4f} {agreement:<10}")
    
    # Plot the sigmoid function
    p_range = np.linspace(0.0, 1.0, 1000)
    alpha_range = sigmoid_alpha_function(p_range, p_c, width, alpha_min, alpha_max)
    
    plt.figure(figsize=(12, 8))
    
    # Plot sigmoid function
    plt.plot(p_range, alpha_range, 'b-', linewidth=3, label='Sigmoid α(p)')
    
    # Mark critical points
    plt.axvline(x=p_c, color='red', linestyle='--', alpha=0.7, 
                label=f'p_c = {p_c:.4f}')
    plt.axhline(y=0.5, color='orange', linestyle=':', alpha=0.7, 
                label='α = 0.5 (critical)')
    
    # Mark test points
    for p in test_p_values:
        alpha = sigmoid_alpha_function(p, p_c, width, alpha_min, alpha_max)
        plt.plot(p, alpha, 'ro', markersize=8, label=f'p={p:.4f}, α={alpha:.3f}')
    
    # Mark expected regions
    plt.axvspan(0.0, 0.6, alpha=0.2, color='blue', label='Liquid (α ≈ 1)')
    plt.axvspan(0.65, 1.0, alpha=0.2, color='green', label='Solid (α ≈ 0)')
    plt.axvspan(0.6, 0.65, alpha=0.2, color='orange', label='Critical (α ≈ 0.5)')
    
    plt.xlabel('Percolation Probability (p)', fontsize=14)
    plt.ylabel('Growth Exponent α', fontsize=14)
    plt.title('Sigmoid α Function Analysis\nDiagnosing the Issue with Liquid and p_c Regimes', 
              fontsize=16, fontweight='bold')
    plt.legend(fontsize=12)
    plt.grid(True, alpha=0.3)
    plt.xlim(0, 1)
    plt.ylim(-0.1, 1.1)
    
    plt.tight_layout()
    plt.savefig('sigmoid_diagnostic.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    print(f"\nDiagnostic plot saved as 'sigmoid_diagnostic.png'")
    
    # Analyze the issue
    print(f"\n=== ISSUE ANALYSIS ===")
    print(f"The problem is clear:")
    print(f"1. For p = 0.1 (liquid): sigmoid gives α = {sigmoid_alpha_function(0.1, p_c, width, alpha_min, alpha_max):.4f}")
    print(f"   Expected: α = 1.0")
    print(f"2. For p = 0.3116 (p_c): sigmoid gives α = {sigmoid_alpha_function(0.3116, p_c, width, alpha_min, alpha_max):.4f}")
    print(f"   Expected: α = 0.5")
    print(f"3. For p = 0.6884 (p_c'): sigmoid gives α = {sigmoid_alpha_function(0.6884, p_c, width, alpha_min, alpha_max):.4f}")
    print(f"   Expected: α = 0.5 ✓")
    print(f"4. For p = 0.8 (solid): sigmoid gives α = {sigmoid_alpha_function(0.8, p_c, width, alpha_min, alpha_max):.4f}")
    print(f"   Expected: α = 0.0 ✓")
    
    print(f"\nThe issue is that our sigmoid is centered at p_c' = 0.6884,")
    print(f"but we need different behavior for p_c = 0.3116.")
    print(f"We need a more sophisticated α(p) function that captures both critical points!")

if __name__ == "__main__":
    main()
