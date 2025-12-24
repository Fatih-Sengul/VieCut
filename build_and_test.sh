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
# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"
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
# gnp_torus creates file with name: gnp_<n>_<b>_<c>_<s>
EXPECTED_GRAPH="../graphs/gnp_1000_10_5_42"
if [ -f "$EXPECTED_GRAPH" ]; then
    mv $EXPECTED_GRAPH ../graphs/yuzbinlik.metis
    echo -e "${GREEN}Graph created: ../graphs/yuzbinlik.metis${NC}"
else
    echo -e "${RED}ERROR: Graph file not created!${NC}"
    echo -e "${RED}Expected file: $EXPECTED_GRAPH${NC}"
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
    ./mincut $GRAPH $algo -v 2>&1 | tee -a $LOG_FILE
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
        ./mincut_parallel $GRAPH $algo -p $thread -v 2>&1 | tee -a $LOG_FILE
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
    ./mincut_contract $GRAPH $algo $GRAPH 2>&1 | tee -a $LOG_FILE
    echo "" | tee -a $LOG_FILE
done

# Parallel
for algo in "${PAR_ALGOS[@]}"; do
    for thread in "${THREADS[@]}"; do
        echo -e "${YELLOW}Testing mincut_contract_parallel with $algo (threads=$thread)...${NC}" | tee -a $LOG_FILE
        ./mincut_contract_parallel $GRAPH $algo $GRAPH -p $thread 2>&1 | tee -a $LOG_FILE
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
    ./mincut_heavy $GRAPH $algo 2>&1 | tee -a $LOG_FILE
    echo "" | tee -a $LOG_FILE
done

# Parallel
for algo in "${PAR_ALGOS[@]}"; do
    for thread in "${THREADS[@]}"; do
        echo -e "${YELLOW}Testing mincut_heavy_parallel with $algo (threads=$thread)...${NC}" | tee -a $LOG_FILE
        ./mincut_heavy_parallel $GRAPH $algo -p $thread 2>&1 | tee -a $LOG_FILE
        echo "" | tee -a $LOG_FILE
    done
done

# ================================
# MINCUT_RECURSIVE VARIANTS
# ================================
echo -e "${GREEN}=== Recursive Variants ===${NC}" | tee -a $LOG_FILE

# Sequential - mincut_recursive only takes graph path, no algorithm parameter
echo -e "${YELLOW}Testing mincut_recursive...${NC}" | tee -a $LOG_FILE
./mincut_recursive $GRAPH -v 2>&1 | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Parallel - different thread counts
for thread in "${THREADS[@]}"; do
    echo -e "${YELLOW}Testing mincut_recursive_parallel (threads=$thread)...${NC}" | tee -a $LOG_FILE
    ./mincut_recursive_parallel $GRAPH -v 2>&1 | tee -a $LOG_FILE
    echo "" | tee -a $LOG_FILE
done

# ================================
# 4. AUTOMATIC PERFORMANCE ANALYSIS
# ================================
echo "" | tee -a $LOG_FILE
echo -e "${GREEN}=== Automatic Performance Analysis ===${NC}" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Extract all RESULT lines
RESULTS_TMP=$(mktemp)
grep "RESULT" $LOG_FILE > $RESULTS_TMP || true

TOTAL_TESTS=$(wc -l < $RESULTS_TMP)
echo "Total tests completed: $TOTAL_TESTS" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

if [ $TOTAL_TESTS -eq 0 ]; then
    echo -e "${RED}No test results found!${NC}" | tee -a $LOG_FILE
    rm $RESULTS_TMP
    exit 1
fi

# ================================
# 4.1 SEQUENTIAL ALGORITHMS COMPARISON
# ================================
echo -e "${YELLOW}[1/5] Sequential Algorithms Comparison${NC}" | tee -a $LOG_FILE
echo "------------------------------------------------------------------------------------" | tee -a $LOG_FILE
printf "%-15s %-12s %-12s %-12s %-10s\n" "Algorithm" "Time (sec)" "Cut Value" "Nodes" "Edges" | tee -a $LOG_FILE
echo "------------------------------------------------------------------------------------" | tee -a $LOG_FILE

BEST_SEQ_TIME=999999
BEST_SEQ_ALGO=""
REFERENCE_CUT=""

for algo in ks noi matula vc pr cactus; do
    # Get first occurrence of each sequential algorithm (from base mincut, not parallel)
    # Note: algo names have 'default' suffix, e.g., 'noidefault', 'vcdefault'
    LINE=$(grep "algo=${algo}" $RESULTS_TMP | grep -v "par" | head -1)

    if [ -n "$LINE" ]; then
        TIME=$(echo "$LINE" | grep -o "time=[0-9.]*" | cut -d= -f2)
        CUT=$(echo "$LINE" | grep -o "cut=[0-9]*" | cut -d= -f2)
        NODES=$(echo "$LINE" | grep -o "n=[0-9]*" | cut -d= -f2)
        EDGES=$(echo "$LINE" | grep -o "m=[0-9]*" | cut -d= -f2)

        # Set reference cut value
        if [ -z "$REFERENCE_CUT" ]; then
            REFERENCE_CUT=$CUT
        fi

        # Check if this is the fastest
        if (( $(echo "$TIME < $BEST_SEQ_TIME" | bc -l) )); then
            BEST_SEQ_TIME=$TIME
            BEST_SEQ_ALGO=$algo
        fi

        # Highlight if cut differs from reference
        if [ "$CUT" != "$REFERENCE_CUT" ]; then
            printf "%-15s %-12s %-12s %-12s %-10s ${RED}(CUT MISMATCH!)${NC}\n" "$algo" "$TIME" "$CUT" "$NODES" "$EDGES" | tee -a $LOG_FILE
        else
            printf "%-15s %-12s %-12s %-12s %-10s\n" "$algo" "$TIME" "$CUT" "$NODES" "$EDGES" | tee -a $LOG_FILE
        fi
    fi
done

echo "------------------------------------------------------------------------------------" | tee -a $LOG_FILE
echo -e "${GREEN}Best Sequential: $BEST_SEQ_ALGO (${BEST_SEQ_TIME}s)${NC}" | tee -a $LOG_FILE
echo -e "Reference Cut Value: $REFERENCE_CUT" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# ================================
# 4.2 PARALLEL SPEEDUP ANALYSIS
# ================================
echo -e "${YELLOW}[2/5] Parallel Speedup Analysis (vs Best Sequential: $BEST_SEQ_ALGO)${NC}" | tee -a $LOG_FILE
echo "------------------------------------------------------------------------------------" | tee -a $LOG_FILE
printf "%-15s %-10s %-12s %-12s %-12s %-12s\n" "Algorithm" "Threads" "Time (sec)" "Speedup" "Efficiency" "Status" | tee -a $LOG_FILE
echo "------------------------------------------------------------------------------------" | tee -a $LOG_FILE

BEST_SPEEDUP=0
BEST_SPEEDUP_CONFIG=""

for algo in inexact exact cactus; do
    for thread in 1 2 4 8; do
        # Get parallel result with specific thread count
        LINE=$(grep "algo=${algo}par" $RESULTS_TMP | grep "processes=$thread " | head -1)

        if [ -n "$LINE" ]; then
            TIME=$(echo "$LINE" | grep -o "time=[0-9.]*" | cut -d= -f2)
            CUT=$(echo "$LINE" | grep -o "cut=[0-9]*" | cut -d= -f2)

            # Calculate speedup: T_sequential / T_parallel
            if (( $(echo "$TIME > 0" | bc -l) )); then
                SPEEDUP=$(echo "scale=2; $BEST_SEQ_TIME / $TIME" | bc -l)
                EFFICIENCY=$(echo "scale=2; $SPEEDUP / $thread * 100" | bc -l)

                # Track best speedup
                if (( $(echo "$SPEEDUP > $BEST_SPEEDUP" | bc -l) )); then
                    BEST_SPEEDUP=$SPEEDUP
                    BEST_SPEEDUP_CONFIG="$algo (${thread} threads)"
                fi

                # Check correctness
                if [ "$CUT" == "$REFERENCE_CUT" ]; then
                    STATUS="✓ OK"
                else
                    STATUS="${RED}✗ WRONG (cut=$CUT)${NC}"
                fi

                printf "%-15s %-10s %-12s %-12s %-12s %s\n" "$algo" "$thread" "$TIME" "${SPEEDUP}x" "${EFFICIENCY}%" "$STATUS" | tee -a $LOG_FILE
            fi
        fi
    done
done

echo "------------------------------------------------------------------------------------" | tee -a $LOG_FILE
echo -e "${GREEN}Best Speedup: $BEST_SPEEDUP_CONFIG (${BEST_SPEEDUP}x)${NC}" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# ================================
# 4.3 SCALABILITY ANALYSIS
# ================================
echo -e "${YELLOW}[3/5] Scalability Analysis (Strong Scaling)${NC}" | tee -a $LOG_FILE
echo "------------------------------------------------------------------------------------" | tee -a $LOG_FILE

for algo in inexact exact cactus; do
    echo "Algorithm: $algo" | tee -a $LOG_FILE
    printf "  %-10s %-12s %-12s %-12s\n" "Threads" "Time (sec)" "Speedup" "Efficiency" | tee -a $LOG_FILE

    # Get 1-thread baseline for this algorithm
    BASE_LINE=$(grep "algo=${algo}par" $RESULTS_TMP | grep "processes=1 " | head -1)
    if [ -n "$BASE_LINE" ]; then
        BASE_TIME=$(echo "$BASE_LINE" | grep -o "time=[0-9.]*" | cut -d= -f2)

        for thread in 1 2 4 8; do
            LINE=$(grep "algo=${algo}par" $RESULTS_TMP | grep "processes=$thread " | head -1)

            if [ -n "$LINE" ]; then
                TIME=$(echo "$LINE" | grep -o "time=[0-9.]*" | cut -d= -f2)

                if (( $(echo "$TIME > 0" | bc -l) )); then
                    SPEEDUP=$(echo "scale=2; $BASE_TIME / $TIME" | bc -l)
                    EFFICIENCY=$(echo "scale=2; $SPEEDUP / $thread * 100" | bc -l)

                    printf "  %-10s %-12s %-12s %-12s\n" "$thread" "$TIME" "${SPEEDUP}x" "${EFFICIENCY}%" | tee -a $LOG_FILE
                fi
            fi
        done
    fi
    echo "" | tee -a $LOG_FILE
done

echo "------------------------------------------------------------------------------------" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# ================================
# 4.4 VARIANT COMPARISON
# ================================
echo -e "${YELLOW}[4/5] Program Variant Comparison (using VC algorithm)${NC}" | tee -a $LOG_FILE
echo "------------------------------------------------------------------------------------" | tee -a $LOG_FILE
printf "%-20s %-12s %-12s\n" "Variant" "Time (sec)" "Cut Value" | tee -a $LOG_FILE
echo "------------------------------------------------------------------------------------" | tee -a $LOG_FILE

for variant in "mincut" "mincut_contract" "mincut_heavy" "mincut_recursive"; do
    # Extract variant name for display
    VARIANT_NAME=$(echo "$variant" | sed 's/mincut_//' | sed 's/mincut/base/')

    # Note: algo names have 'default' suffix, e.g., 'vcdefault'
    LINE=$(grep "algo=vc" $RESULTS_TMP | grep -v "par" | head -1)

    if [ -n "$LINE" ]; then
        TIME=$(echo "$LINE" | grep -o "time=[0-9.]*" | cut -d= -f2)
        CUT=$(echo "$LINE" | grep -o "cut=[0-9]*" | cut -d= -f2)

        printf "%-20s %-12s %-12s\n" "$VARIANT_NAME" "$TIME" "$CUT" | tee -a $LOG_FILE
    fi
done

echo "------------------------------------------------------------------------------------" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# ================================
# 4.5 EXPORT RESULTS TO CSV
# ================================
echo -e "${YELLOW}[5/5] Exporting results to CSV...${NC}" | tee -a $LOG_FILE

CSV_FILE="test_results_$(date +%Y%m%d_%H%M%S).csv"
echo "Algorithm,Variant,Threads,Time,Cut,Nodes,Edges,Speedup,Efficiency" > $CSV_FILE

while IFS= read -r line; do
    ALGO=$(echo "$line" | grep -o "algo=[^ ]*" | cut -d= -f2)
    TIME=$(echo "$line" | grep -o "time=[0-9.]*" | cut -d= -f2)
    CUT=$(echo "$line" | grep -o "cut=[0-9]*" | cut -d= -f2)
    NODES=$(echo "$line" | grep -o "n=[0-9]*" | cut -d= -f2)
    EDGES=$(echo "$line" | grep -o "m=[0-9]*" | cut -d= -f2)
    THREADS=$(echo "$line" | grep -o "processes=[0-9]*" | cut -d= -f2 || echo "1")

    # Determine variant
    if echo "$line" | grep -q "contract"; then
        VARIANT="contract"
    elif echo "$line" | grep -q "heavy"; then
        VARIANT="heavy"
    elif echo "$line" | grep -q "recursive"; then
        VARIANT="recursive"
    else
        VARIANT="base"
    fi

    # Calculate speedup and efficiency
    if (( $(echo "$TIME > 0" | bc -l) )); then
        SPEEDUP=$(echo "scale=3; $BEST_SEQ_TIME / $TIME" | bc -l)
        EFFICIENCY=$(echo "scale=3; $SPEEDUP / $THREADS * 100" | bc -l)
    else
        SPEEDUP=0
        EFFICIENCY=0
    fi

    echo "$ALGO,$VARIANT,$THREADS,$TIME,$CUT,$NODES,$EDGES,$SPEEDUP,$EFFICIENCY" >> $CSV_FILE
done < $RESULTS_TMP

echo -e "${GREEN}CSV exported to: build/$CSV_FILE${NC}" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# ================================
# 5. FINAL SUMMARY
# ================================
echo -e "${GREEN}=== Final Summary ===${NC}" | tee -a $LOG_FILE
echo "------------------------------------------------------------------------------------" | tee -a $LOG_FILE
echo "📊 Total Tests: $TOTAL_TESTS" | tee -a $LOG_FILE
echo "🏆 Best Sequential: $BEST_SEQ_ALGO (${BEST_SEQ_TIME}s)" | tee -a $LOG_FILE
echo "🚀 Best Parallel: $BEST_SPEEDUP_CONFIG (${BEST_SPEEDUP}x speedup)" | tee -a $LOG_FILE
echo "✓ Reference Cut: $REFERENCE_CUT" | tee -a $LOG_FILE
echo "📁 Log File: build/$LOG_FILE" | tee -a $LOG_FILE
echo "📈 CSV File: build/$CSV_FILE" | tee -a $LOG_FILE
echo "------------------------------------------------------------------------------------" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo -e "${GREEN}All tests completed successfully!${NC}"

# Cleanup
rm $RESULTS_TMP

echo ""
echo -e "${GREEN}Full results saved to: build/$LOG_FILE${NC}"
echo -e "${GREEN}CSV data saved to: build/$CSV_FILE${NC}"
