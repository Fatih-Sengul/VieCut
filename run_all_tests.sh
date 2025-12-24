#!/bin/bash

#===============================================================================
# VieCut Benchmark Script
# Graf: yuzbinlik.metis
# Tüm algoritmalar + Single/Multi thread testleri
#===============================================================================

set -e  # Hata olursa dur

GRAPH="../graphs/yuzbinlik.metis"
RESULTS="benchmark_results.txt"

echo "=============================================="
echo "VieCut Benchmark Suite"
echo "Graf: $GRAPH"
echo "Tarih: $(date)"
echo "=============================================="

# Grafın varlığını kontrol et
if [ ! -f "$GRAPH" ]; then
    echo "HATA: $GRAPH bulunamadı!"
    echo "Önce grafı oluşturun veya doğru path'i girin."
    exit 1
fi

# Graf bilgisi
echo ""
echo "=== Graf Bilgisi ==="
head -1 $GRAPH
echo ""

#-------------------------------------------------------------------------------
# PART 1: SINGLE-THREAD TESTLER (mincut)
#-------------------------------------------------------------------------------
echo "=============================================="
echo "PART 1: SINGLE-THREAD TESTLER"
echo "=============================================="

echo ""
echo "--- [1/6] VieCut (Heuristic) ---"
./mincut $GRAPH vc -v

echo ""
echo "--- [2/6] NOI (Exact) ---"
./mincut $GRAPH noi -v

echo ""
echo "--- [3/6] Karger-Stein (Randomized) ---"
./mincut $GRAPH ks -v

echo ""
echo "--- [4/6] Matula (2-Approximation) ---"
./mincut $GRAPH matula -v

echo ""
echo "--- [5/6] Padberg-Rinaldi ---"
./mincut $GRAPH pr -v

echo ""
echo "--- [6/6] Cactus (All Minimum Cuts) ---"
./mincut $GRAPH cactus -s -v

echo ""
echo "--- [BONUS] Cactus + Most Balanced Cut ---"
./mincut $GRAPH cactus -s -b -v


#-------------------------------------------------------------------------------
# PART 2: MULTI-THREAD TESTLER (mincut_parallel)
#-------------------------------------------------------------------------------
echo ""
echo "=============================================="
echo "PART 2: MULTI-THREAD TESTLER"
echo "=============================================="

# Mevcut CPU sayısını al
NPROC=$(nproc)
echo "Mevcut CPU: $NPROC"
echo ""

# Paralel executable var mı kontrol et
if [ ! -f "./mincut_parallel" ]; then
    echo "UYARI: mincut_parallel bulunamadı!"
    echo "Parallel testler için 'cmake .. -DPARALLEL=ON' ile build edin."
    echo "Parallel testler atlanıyor..."
else
    echo "--- Parallel VieCut (2 thread) ---"
    ./mincut_parallel $GRAPH vc -p 2 -v

    echo ""
    echo "--- Parallel VieCut (4 thread) ---"
    ./mincut_parallel $GRAPH vc -p 4 -v

    echo ""
    echo "--- Parallel VieCut ($NPROC thread - MAX) ---"
    ./mincut_parallel $GRAPH vc -p $NPROC -v

    echo ""
    echo "--- Parallel NOI (2 thread) ---"
    ./mincut_parallel $GRAPH noi -p 2 -v

    echo ""
    echo "--- Parallel NOI (4 thread) ---"
    ./mincut_parallel $GRAPH noi -p 4 -v

    echo ""
    echo "--- Parallel NOI ($NPROC thread - MAX) ---"
    ./mincut_parallel $GRAPH noi -p $NPROC -v

    echo ""
    echo "--- Parallel Cactus (4 thread) ---"
    ./mincut_parallel $GRAPH cactus -p 4 -s -v
fi


#-------------------------------------------------------------------------------
# PART 3: KARŞILAŞTIRMALI BENCHMARK (5 tekrar)
#-------------------------------------------------------------------------------
echo ""
echo "=============================================="
echo "PART 3: BENCHMARK (5 İTERASYON)"
echo "=============================================="

echo ""
echo "--- VieCut x5 ---"
./mincut $GRAPH vc -i 5

echo ""
echo "--- NOI x5 ---"
./mincut $GRAPH noi -i 5

echo ""
echo "--- Karger-Stein x5 ---"
./mincut $GRAPH ks -i 5


echo ""
echo "=============================================="
echo "TÜM TESTLER TAMAMLANDI!"
echo "=============================================="
