#!/bin/bash

# VieCut Build and Test Script
# This script builds the project, creates a 100k node graph, and tests all algorithms

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== VieCut Build and Test Script ===${NC}"
echo "Date: $(date)"
echo ""

# ================================
# 1. BUILD PROJECT
# ================================
echo -e "${YELLOW}[1/4] Building project...${NC}"
cd /home/user/VieCut
mkdir -p build
cd build

echo "Running CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release

echo "Compiling with $(nproc) cores..."
make -j$(nproc)

echo -e "${GREEN}Build completed!${NC}"
echo ""

# ================================
# 2. CREATE GRAPH
# ================================
echo -e "${YELLOW}[2/4] Creating 100,000 node graph...${NC}"
mkdir -p ../graphs

# Generate 100k node graph: 10x10 blocks, 1000 vertices per block
# Total nodes = 10*10*1000 = 100,000
./gnp_torus -n 1000 -b 10 -c 5 -s 42 -o ../graphs

# Rename to yuzbinlik.metis
if [ -f "../graphs/graph.metis" ]; then
    mv ../graphs/graph.metis ../graphs/yuzbinlik.metis
    echo -e "${GREEN}Graph created: ../graphs/yuzbinlik.metis${NC}"
else
    echo -e "${RED}ERROR: Graph file not created!${NC}"
    exit 1
fi
echo ""

# ================================
# 3. RUN ALL TESTS
# ================================
GRAPH="../graphs/yuzbinlik.metis"
LOG_FILE="test_results_$(date +%Y%m%d_%H%M%S).log"

echo -e "${YELLOW}[3/4] Running comprehensive tests...${NC}"
echo "Graph: $GRAPH"
echo "Log file: $LOG_FILE"
echo ""

# Initialize log file
cat > $LOG_FILE << EOF
=== VieCut Test Results ===
Graph: $GRAPH
Date: $(date)
System: $(uname -a)

EOF

# ================================
# SEQUENTIAL ALGORITHMS
# ================================
echo -e "${GREEN}=== Sequential Algorithms ===${NC}" | tee -a $LOG_FILE

SEQ_ALGOS=("ks" "noi" "matula" "vc" "pr" "cactus")

for algo in "${SEQ_ALGOS[@]}"; do
    echo -e "${YELLOW}Testing mincut with $algo...${NC}" | tee -a $LOG_FILE
    ./mincut $GRAPH $algo -r 42 -v 2>&1 | tee -a $LOG_FILE
    echo "" | tee -a $LOG_FILE
done

# ================================
# PARALLEL ALGORITHMS
# ================================
echo -e "${GREEN}=== Parallel Algorithms ===${NC}" | tee -a $LOG_FILE

PAR_ALGOS=("inexact" "exact" "cactus")
THREADS=("1" "2" "4" "8")

for algo in "${PAR_ALGOS[@]}"; do
    for thread in "${THREADS[@]}"; do
        echo -e "${YELLOW}Testing mincut_parallel with $algo (threads=$thread)...${NC}" | tee -a $LOG_FILE
        ./mincut_parallel $GRAPH $algo -p $thread -r 42 -v 2>&1 | tee -a $LOG_FILE
        echo "" | tee -a $LOG_FILE
    done
done

# ================================
# MINCUT_CONTRACT VARIANTS
# ================================
echo -e "${GREEN}=== Contract Variants ===${NC}" | tee -a $LOG_FILE

# Sequential
for algo in "${SEQ_ALGOS[@]}"; do
    echo -e "${YELLOW}Testing mincut_contract with $algo...${NC}" | tee -a $LOG_FILE
    ./mincut_contract $GRAPH $algo -r 42 -v 2>&1 | tee -a $LOG_FILE
    echo "" | tee -a $LOG_FILE
done

# Parallel
for algo in "${PAR_ALGOS[@]}"; do
    for thread in "${THREADS[@]}"; do
        echo -e "${YELLOW}Testing mincut_contract_parallel with $algo (threads=$thread)...${NC}" | tee -a $LOG_FILE
        ./mincut_contract_parallel $GRAPH $algo -p $thread -r 42 -v 2>&1 | tee -a $LOG_FILE
        echo "" | tee -a $LOG_FILE
    done
done

# ================================
# MINCUT_HEAVY VARIANTS
# ================================
echo -e "${GREEN}=== Heavy Variants ===${NC}" | tee -a $LOG_FILE

# Sequential
for algo in "${SEQ_ALGOS[@]}"; do
    echo -e "${YELLOW}Testing mincut_heavy with $algo...${NC}" | tee -a $LOG_FILE
    ./mincut_heavy $GRAPH $algo -r 42 -v 2>&1 | tee -a $LOG_FILE
    echo "" | tee -a $LOG_FILE
done

# Parallel
for algo in "${PAR_ALGOS[@]}"; do
    for thread in "${THREADS[@]}"; do
        echo -e "${YELLOW}Testing mincut_heavy_parallel with $algo (threads=$thread)...${NC}" | tee -a $LOG_FILE
        ./mincut_heavy_parallel $GRAPH $algo -p $thread -r 42 -v 2>&1 | tee -a $LOG_FILE
        echo "" | tee -a $LOG_FILE
    done
done

# ================================
# MINCUT_RECURSIVE VARIANTS
# ================================
echo -e "${GREEN}=== Recursive Variants ===${NC}" | tee -a $LOG_FILE

# Sequential
for algo in "${SEQ_ALGOS[@]}"; do
    echo -e "${YELLOW}Testing mincut_recursive with $algo...${NC}" | tee -a $LOG_FILE
    ./mincut_recursive $GRAPH $algo -r 42 -v 2>&1 | tee -a $LOG_FILE
    echo "" | tee -a $LOG_FILE
done

# Parallel
for algo in "${PAR_ALGOS[@]}"; do
    for thread in "${THREADS[@]}"; do
        echo -e "${YELLOW}Testing mincut_recursive_parallel with $algo (threads=$thread)...${NC}" | tee -a $LOG_FILE
        ./mincut_recursive_parallel $GRAPH $algo -p $thread -r 42 -v 2>&1 | tee -a $LOG_FILE
        echo "" | tee -a $LOG_FILE
    done
done

# ================================
# 4. SUMMARY
# ================================
echo "" | tee -a $LOG_FILE
echo -e "${GREEN}=== Test Summary ===${NC}" | tee -a $LOG_FILE
echo "Total tests completed: $(grep -c "RESULT" $LOG_FILE || echo "0")" | tee -a $LOG_FILE
echo "Log file: $LOG_FILE" | tee -a $LOG_FILE
echo ""
echo -e "${GREEN}All tests completed successfully!${NC}"

# Extract and summarize RESULT lines
echo ""
echo -e "${YELLOW}Quick Results Summary:${NC}"
grep "RESULT" $LOG_FILE | head -20

echo ""
echo -e "${GREEN}Full results saved to: build/$LOG_FILE${NC}"
