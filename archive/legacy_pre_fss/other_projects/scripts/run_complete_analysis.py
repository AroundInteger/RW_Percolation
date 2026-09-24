#!/usr/bin/env python3
"""
Master script to run complete analysis on both datasets:
1. Analyze original dataset (p_output_C1.csv)
2. Analyze new dataset (p_output_NEW34.csv)  
3. Create comparison analysis
"""

import os
import subprocess
import sys
import time

def run_script(script_name, description):
    """Run a Python script and handle any errors"""
    print(f"\n{'='*60}")
    print(f"RUNNING: {description}")
    print(f"Script: {script_name}")
    print(f"{'='*60}")
    
    start_time = time.time()
    
    try:
        # Run the script
        result = subprocess.run([sys.executable, script_name], 
                              capture_output=True, text=True, check=True)
        
        # Print output
        if result.stdout:
            print(result.stdout)
        if result.stderr:
            print("STDERR:", result.stderr)
        
        elapsed_time = time.time() - start_time
        print(f"\n✅ {description} COMPLETED SUCCESSFULLY")
        print(f"⏱️  Time taken: {elapsed_time:.1f} seconds")
        
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"\n❌ {description} FAILED")
        print(f"Exit code: {e.returncode}")
        if e.stdout:
            print("STDOUT:", e.stdout)
        if e.stderr:
            print("STDERR:", e.stderr)
        return False
        
    except Exception as e:
        print(f"\n❌ {description} FAILED with exception: {e}")
        return False

def main():
    """Main function to run all analyses"""
    print("🚀 COMPLETE MSD DATASET ANALYSIS PIPELINE")
    print("=" * 60)
    
    # Check if required scripts exist
    required_scripts = [
        "scripts/analyze_original_dataset.py",
        "scripts/analyze_new_dataset.py", 
        "scripts/create_comparison_analysis.py"
    ]
    
    missing_scripts = [script for script in required_scripts if not os.path.exists(script)]
    if missing_scripts:
        print(f"❌ Missing required scripts: {missing_scripts}")
        return
    
    # Check if required datasets exist
    required_datasets = [
        "matlab/Clusters/p_output_C1.csv",
        "matlab/p_output_NEW34.csv"
    ]
    
    missing_datasets = [dataset for dataset in required_datasets if not os.path.exists(dataset)]
    if missing_datasets:
        print(f"❌ Missing required datasets: {missing_datasets}")
        return
    
    print("✅ All required scripts and datasets found")
    print(f"📊 Original dataset: {os.path.getsize(required_datasets[0]) / (1024*1024):.1f} MB")
    print(f"📊 New dataset: {os.path.getsize(required_datasets[1]) / (1024*1024):.1f} MB")
    
    # Run analyses in sequence
    analyses = [
        ("scripts/analyze_original_dataset.py", "Original Dataset Analysis"),
        ("scripts/analyze_new_dataset.py", "New Dataset Analysis"),
        ("scripts/create_comparison_analysis.py", "Comparison Analysis")
    ]
    
    success_count = 0
    total_analyses = len(analyses)
    
    for script, description in analyses:
        if run_script(script, description):
            success_count += 1
        else:
            print(f"\n⚠️  Continuing with next analysis...")
    
    # Summary
    print(f"\n{'='*60}")
    print("📋 ANALYSIS PIPELINE SUMMARY")
    print(f"{'='*60}")
    print(f"✅ Successful analyses: {success_count}/{total_analyses}")
    
    if success_count == total_analyses:
        print("\n🎉 ALL ANALYSES COMPLETED SUCCESSFULLY!")
        print("\n📁 Output folders created:")
        print("   • output_original_dataset/ - Original dataset results")
        print("   • output_new_dataset/ - New dataset results") 
        print("   • output_comparison/ - Comparison analysis")
        
        print("\n📊 Key files generated:")
        print("   • corrected_alpha_analysis_results.csv - Alpha analysis results")
        print("   • alpha_vs_p_*.png - Growth exponent plots")
        print("   • viscoelastic_analysis.png - Viscoelastic analysis")
        print("   • *_comparison.png - Side-by-side comparisons")
        print("   • statistical_comparison.csv - Statistical summary")
        
    else:
        print(f"\n⚠️  {total_analyses - success_count} analysis(es) failed")
        print("Check the error messages above for details")
    
    print(f"\n⏱️  Total pipeline time: {time.time() - start_time:.1f} seconds")

if __name__ == "__main__":
    start_time = time.time()
    main()
