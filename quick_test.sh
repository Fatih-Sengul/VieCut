#!/bin/bash

# Quick Test Script - Sadece temel algoritmalarla hızlı test
# Tam test için build_and_test.sh kullanın

set -e

GRAPH="../graphs/yuzbinlik.metis"

if [ ! -f "$GRAPH" ]; then
    echo "ERROR: Graph file not found: $GRAPH"
    echo "First run: ./gnp_torus -n 1000 -b 10 -c 5 -s 42 -o ../graphs && mv ../graphs/graph.metis $GRAPH"
    exit 1
fi

echo "=== Quick Test - Main Algorithms Only ==="
echo "Graph: $GRAPH"
echo ""

# Sequential - sadece en önemli algoritmalar
echo "--- Sequential Tests ---"
echo "1. VieCut (vc)..."
./mincut $GRAPH vc -r 42 -v

echo ""
echo "2. Karger-Stein (ks)..."
./mincut $GRAPH ks -r 42 -v

echo ""
echo "3. Noi (noi)..."
./mincut $GRAPH noi -r 42 -v

# Parallel - sadece 4 thread ile
echo ""
echo "--- Parallel Tests (4 threads) ---"
echo "1. Inexact (parallel VieCut)..."
./mincut_parallel $GRAPH inexact -p 4 -r 42 -v

echo ""
echo "2. Exact..."
./mincut_parallel $GRAPH exact -p 4 -r 42 -v

echo ""
echo "=== Quick Test Completed ==="
