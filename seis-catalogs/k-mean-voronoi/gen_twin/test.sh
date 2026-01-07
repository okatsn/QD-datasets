#!/bin/bash
# Quick test script to validate the digital twin generator

set -e  # Exit on error

echo "========================================"
echo "  Digital Twin Generator Test"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Check if Julia is available
if ! command -v julia &> /dev/null; then
    echo "❌ Julia not found. Please install Julia 1.12+"
    exit 1
fi

echo "✓ Julia found: $(julia --version)"

# Check if project environment is set up
if [ ! -f "Project.toml" ]; then
    echo "❌ Project.toml not found. Are you in the right directory?"
    exit 1
fi

echo "✓ Project.toml found"

# Instantiate dependencies
echo ""
echo "📦 Installing dependencies..."
julia --project=. -e 'using Pkg; Pkg.instantiate()' || {
    echo "❌ Failed to instantiate project dependencies"
    exit 1
}

echo "✓ Dependencies installed"

# Clean previous fake data
echo ""
echo "🧹 Cleaning previous fake-data..."
rm -rf fake-data/
mkdir -p fake-data/

# Run the generator
echo ""
echo "🚀 Running digital twin generator..."
julia --project=. gen_twin/generate_all_entrypoint.jl || {
    echo "❌ Generator failed"
    exit 1
}

# Verify the structure
echo ""
echo "🔍 Verifying generated structure..."
julia --project=. gen_twin/verify_structure.jl || {
    echo "❌ Verification failed"
    exit 1
}

# Report disk usage
echo ""
echo "📊 Disk usage:"
du -sh fake-data/

echo ""
echo "========================================"
echo "  ✅ Test completed successfully!"
echo "========================================"
echo "Fake data location: $PROJECT_DIR/fake-data/"
