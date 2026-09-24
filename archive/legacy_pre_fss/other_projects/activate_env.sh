#!/bin/bash
# RW_Percolation Environment Activation Script

echo "🐍 Activating RW_Percolation Virtual Environment..."
echo "=================================================="

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found!"
    echo "Please run: python3 -m venv venv"
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

# Check if activation was successful
if [ $? -eq 0 ]; then
    echo "✅ Virtual environment activated successfully!"
    echo "📦 Python version: $(python --version)"
    echo "📦 Working directory: $(pwd)"
    echo ""
    echo "🚀 Quick commands:"
    echo "  • Test modules: python -c 'from robust_simulation import quick_test; quick_test()'"
    echo "  • Run example: python robust_simulation/examples/enhanced_random_walk.py --test"
    echo "  • Run tests: python -m pytest tests/"
    echo ""
    echo "💡 To deactivate: deactivate"
else
    echo "❌ Failed to activate virtual environment!"
    exit 1
fi 