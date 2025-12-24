#!/bin/bash
#
# VieCut Automated Benchmarking Suite
# Tests parallel speedup on real-world AS-Skitter network
#

set -e  # Exit on error

# Configuration
GRAPH_DIR="graphs"
GRAPH_FILE="$GRAPH_DIR/real_network.metis"
LCC_GRAPH_FILE="$GRAPH_DIR/real_network.cc"
SNAP_FILE="$GRAPH_DIR/as-Skitter.txt"
SNAP_URL="https://snap.stanford.edu/data/as-skitter.txt.gz"
BUILD_DIR="build"
RESULTS_CSV="$BUILD_DIR/test_results.csv"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "VieCut Automated Benchmarking Suite"
echo "========================================="
echo ""

# Step 1: Smart Download - Check if graph exists
echo -e "${BLUE}[1/5] Checking for graph data...${NC}"
if [ -f "$GRAPH_FILE" ]; then
    echo -e "${GREEN}✓ Graph found, skipping download.${NC}"
    echo "  Using: $GRAPH_FILE"
else
    echo "Graph not found. Downloading AS-Skitter dataset..."

    # Create graphs directory
    mkdir -p "$GRAPH_DIR"

    # Download
    echo "  Downloading from: $SNAP_URL"
    curl -L -o "$GRAPH_DIR/as-Skitter.txt.gz" "$SNAP_URL" --progress-bar

    # Unzip
    echo "  Extracting..."
    gunzip -f "$GRAPH_DIR/as-Skitter.txt.gz"

    # Convert to METIS format
    echo "  Converting SNAP format to METIS format..."
    python3 convert_snap_to_metis.py "$SNAP_FILE" "$GRAPH_FILE"

    echo -e "${GREEN}✓ Graph prepared successfully.${NC}"
fi
echo ""

# Step 2: Build
echo -e "${BLUE}[2/5] Building VieCut...${NC}"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
cmake .. -DCMAKE_BUILD_TYPE=Release -DUSE_TCMALLOC=OFF > /dev/null
make -j$(nproc) > /dev/null 2>&1
cd ..
echo -e "${GREEN}✓ Build complete.${NC}"
echo ""

# Step 3: Extract Largest Connected Component
echo -e "${BLUE}[3/5] Extracting largest connected component...${NC}"
if [ -f "$LCC_GRAPH_FILE" ]; then
    echo -e "${GREEN}✓ LCC graph found, skipping extraction.${NC}"
    echo "  Using: $LCC_GRAPH_FILE"
else
    echo "  Extracting LCC from: $GRAPH_FILE"
    ./build/largest_cc "$GRAPH_FILE"
    echo -e "${GREEN}✓ LCC extraction complete.${NC}"
    echo "  LCC graph saved to: $LCC_GRAPH_FILE"
fi
echo ""

# Step 4: Benchmark
echo -e "${BLUE}[4/5] Running benchmarks...${NC}"
echo "This may take several minutes..."
echo ""

# Initialize CSV file
echo "Algorithm,Threads,Time,Cut" > "$RESULTS_CSV"

# Helper function to parse output and extract time and cut
parse_output() {
    local output="$1"
    local time=$(echo "$output" | grep -oP 'time=\K[0-9.]+' | head -1)
    local cut=$(echo "$output" | grep -oP 'cut=\K[0-9]+' | head -1)
    echo "$time,$cut"
}

# Run sequential algorithms
echo "  Running sequential algorithms..."

echo -n "    - vc (Sequential Heuristic)... "
output=$(./build/mincut "$LCC_GRAPH_FILE" vc -v 2>&1 || true)
result=$(parse_output "$output")
echo "vc,0,$result" >> "$RESULTS_CSV"
echo "done"

echo -n "    - noi (Sequential Exact)... "
output=$(./build/mincut "$LCC_GRAPH_FILE" noi -v 2>&1 || true)
result=$(parse_output "$output")
echo "noi,0,$result" >> "$RESULTS_CSV"
echo "done"

echo ""

# Run parallel exact algorithm
echo "  Running parallel exact algorithm..."
for threads in 1 2 4 8; do
    echo -n "    - exact with $threads thread(s)... "
    output=$(./build/mincut_parallel "$LCC_GRAPH_FILE" exact -p $threads -v 2>&1 || true)
    result=$(parse_output "$output")
    echo "exact,$threads,$result" >> "$RESULTS_CSV"
    echo "done"
done

echo ""

# Run parallel inexact algorithm
echo "  Running parallel inexact algorithm..."
for threads in 1 2 4 8; do
    echo -n "    - inexact with $threads thread(s)... "
    output=$(./build/mincut_parallel "$LCC_GRAPH_FILE" inexact -p $threads -v 2>&1 || true)
    result=$(parse_output "$output")
    echo "inexact,$threads,$result" >> "$RESULTS_CSV"
    echo "done"
done

echo ""
echo -e "${GREEN}✓ Benchmarks complete.${NC}"
echo "  Results saved to: $RESULTS_CSV"
echo ""

# Step 5: Visualize
echo -e "${BLUE}[5/5] Generating visualizations...${NC}"
python3 visualize_results.py "$RESULTS_CSV"
echo ""

# Done
echo "========================================="
echo -e "${GREEN}✓ Benchmarking suite complete!${NC}"
echo "========================================="
echo ""
echo "Results:"
echo "  - CSV data: $RESULTS_CSV"
echo "  - Speedup plot: $BUILD_DIR/parallel_speedup.png"
echo ""
