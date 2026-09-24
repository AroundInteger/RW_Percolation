#!/bin/bash
# run_paper_batch.sh
# Run MATLAB paper simulations in batch mode

echo "🚀 Starting MATLAB Paper Simulations"
echo "======================================"

# Check if MATLAB is available
if ! command -v matlab &> /dev/null; then
    echo "❌ MATLAB not found in PATH"
    echo "Please ensure MATLAB is installed and accessible"
    exit 1
fi

# Create output directory
mkdir -p matlab_output
cd matlab_output

echo "📁 Working directory: $(pwd)"
echo "🖥️  Running 4 simulations sequentially..."

# Run each simulation
for i in {1..4}; do
    echo ""
    echo "🎯 Running job $i/4 (p_idx = $i)"
    echo "----------------------------------------"
    
    # Run MATLAB job
    matlab -nodisplay -r "RW3D_paper_batch($i); exit"
    
    if [ $? -eq 0 ]; then
        echo "✅ Job $i completed successfully"
    else
        echo "❌ Job $i failed"
        exit 1
    fi
done

echo ""
echo "📊 Collecting results..."
echo "----------------------------------------"

# Collect all results
matlab -nodisplay -r "collect_paper_results; exit"

if [ $? -eq 0 ]; then
    echo "✅ Results collected successfully"
    echo ""
    echo "📁 Output files:"
    ls -la *.csv *.mat *.png *.fig 2>/dev/null || echo "No output files found"
else
    echo "❌ Results collection failed"
    exit 1
fi

echo ""
echo "🎉 All MATLAB simulations completed!"
echo "📂 Results saved in: $(pwd)" 