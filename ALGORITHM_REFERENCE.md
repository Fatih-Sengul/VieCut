# VieCut Algoritma Referansı

## Hızlı Başlangıç

```bash
# 1. Projeyi build et
cd /home/user/VieCut
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release && make -j$(nproc)

# 2. Graf oluştur
./gnp_torus -n 1000 -b 10 -c 5 -s 42 -o ../graphs
mv ../graphs/graph.metis ../graphs/yuzbinlik.metis

# 3. Test çalıştır (seçenekler)
cd /home/user/VieCut

# Opsyon A: Hızlı test (5 algoritma)
./quick_test.sh

# Opsyon B: Tam test (~96 test kombinasyonu)
./build_and_test.sh
```

## Algoritma Matrisi

### Sequential Program Varyantları

| Program | Algoritmalar | Kullanım |
|---------|-------------|----------|
| `mincut` | ks, noi, matula, vc, pr, cactus | `./mincut <graph> <algo> -r 42 -v` |
| `mincut_contract` | ks, noi, matula, vc, pr, cactus | `./mincut_contract <graph> <algo> -r 42 -v` |
| `mincut_heavy` | ks, noi, matula, vc, pr, cactus | `./mincut_heavy <graph> <algo> -r 42 -v` |
| `mincut_recursive` | ks, noi, matula, vc, pr, cactus | `./mincut_recursive <graph> <algo> -r 42 -v` |

### Parallel Program Varyantları

| Program | Algoritmalar | Kullanım |
|---------|-------------|----------|
| `mincut_parallel` | inexact, exact, cactus | `./mincut_parallel <graph> <algo> -p 4 -r 42 -v` |
| `mincut_contract_parallel` | inexact, exact, cactus | `./mincut_contract_parallel <graph> <algo> -p 4 -r 42 -v` |
| `mincut_heavy_parallel` | inexact, exact, cactus | `./mincut_heavy_parallel <graph> <algo> -p 4 -r 42 -v` |
| `mincut_recursive_parallel` | inexact, exact, cactus | `./mincut_recursive_parallel <graph> <algo> -p 4 -r 42 -v` |

## Algoritma Açıklamaları

### Sequential Algoritmalar

| Algoritma | Açıklama | Kompleksite |
|-----------|----------|-------------|
| `ks` | Karger-Stein | O(n² log³ n) randomized |
| `noi` | Nagamochi, Ono, Ibaraki | O(nm + n² log n) deterministic |
| `matula` | Matula Approximation | Heuristic/approximation |
| `vc` | VieCut | Pratik heuristic |
| `pr` | Padberg-Rinaldi | Exact, cutting plane |
| `cactus` | Cactus Graph | Tüm minimum cut'ları bulur |

### Parallel Algoritmalar

| Algoritma | Açıklama |
|-----------|----------|
| `inexact` | Parallel VieCut (heuristic) |
| `exact` | Parallel exact algorithm |
| `cactus` | Parallel cactus construction |

## Parametre Referansı

| Parametre | Açıklama | Örnek |
|-----------|----------|-------|
| `-r <seed>` | Random seed | `-r 42` |
| `-v` | Verbose mode | `-v` |
| `-p <threads>` | Thread sayısı (parallel only) | `-p 4` |
| `-i <n>` | İterasyon sayısı | `-i 10` |
| `-s` | Cut'ı kaydet | `-s` |
| `-o <path>` | Output dosyası (requires -s) | `-o output.txt` |
| `-q <pq>` | Priority queue tipi | `-q heap` |
| `-c <factor>` | Contraction factor | `-c 0.5` |

## Test Yapılandırmaları

### Minimal Test (5 komut)
```bash
./mincut ../graphs/yuzbinlik.metis vc -r 42
./mincut ../graphs/yuzbinlik.metis ks -r 42
./mincut ../graphs/yuzbinlik.metis noi -r 42
./mincut_parallel ../graphs/yuzbinlik.metis inexact -p 4 -r 42
./mincut_parallel ../graphs/yuzbinlik.metis exact -p 4 -r 42
```

### Orta Test (24 komut)
- 6 sequential algo × 1 varyant = 6
- 3 parallel algo × 1 thread config × 1 varyant = 3
- 4 program varyantı × 6 = 24 toplam

### Tam Test (96 komut)
- 6 sequential algo × 4 varyant = 24
- 3 parallel algo × 4 thread config × 4 varyant = 48
- Toplamda 72 test (build_and_test.sh)

## Çıktı Formatı

Her test şu formatta sonuç verir:
```
RESULT algo=<name> graph=<file> time=<seconds> cut=<value> n=<nodes> m=<edges> processes=<threads> seed=<seed>
```

Örnek:
```
RESULT algo=vc graph=yuzbinlik.metis time=1.234 cut=50 n=100000 m=500000 processes=1 seed=42
```

## Otomatik Performans Analizi

`build_and_test.sh` scripti testleri tamamladıktan sonra otomatik olarak 5 aşamalı analiz yapar:

### [1/5] Sequential Algorithms Comparison
Tüm sequential algoritmaları karşılaştırır ve en hızlısını bulur:
```
Algorithm       Time (sec)   Cut Value    Nodes        Edges
------------------------------------------------------------------------------------
ks              2.345        50          100000       500000
noi             1.234        50          100000       500000
matula          0.987        50          100000       500000
vc              0.543        50          100000       500000
pr              3.456        50          100000       500000
cactus          4.567        50          100000       500000
------------------------------------------------------------------------------------
Best Sequential: vc (0.543s)
```

### [2/5] Parallel Speedup Analysis
Parallel algoritmalar için speedup (hızlanma) ve efficiency (verimlilik) hesaplar:
```
Algorithm       Threads    Time (sec)   Speedup      Efficiency   Status
------------------------------------------------------------------------------------
inexact         1          0.612        0.89x        88.72%       ✓ OK
inexact         2          0.334        1.63x        81.44%       ✓ OK
inexact         4          0.189        2.87x        71.83%       ✓ OK
inexact         8          0.125        4.34x        54.29%       ✓ OK
exact           1          0.589        0.92x        92.19%       ✓ OK
exact           2          0.312        1.74x        87.02%       ✓ OK
exact           4          0.167        3.25x        81.29%       ✓ OK
exact           8          0.098        5.54x        69.23%       ✓ OK
------------------------------------------------------------------------------------
Best Speedup: exact (8 threads) (5.54x)
```

**Metrikler:**
- **Speedup**: T_sequential / T_parallel (ne kadar hızlandı)
- **Efficiency**: (Speedup / Thread_sayısı) × 100% (kaynaklar ne kadar verimli kullanıldı)
- **Status**: Cut değeri referans ile eşleşiyor mu?

### [3/5] Scalability Analysis (Strong Scaling)
Her parallel algoritma için 1-thread baseline'a göre ölçeklenebilirliği gösterir:
```
Algorithm: inexact
  Threads    Time (sec)   Speedup      Efficiency
  1          0.612        1.00x        100.00%
  2          0.334        1.83x        91.62%
  4          0.189        3.24x        80.95%
  8          0.125        4.90x        61.22%

Algorithm: exact
  Threads    Time (sec)   Speedup      Efficiency
  1          0.589        1.00x        100.00%
  2          0.312        1.89x        94.39%
  4          0.167        3.53x        88.18%
  8          0.098        6.01x        75.13%
```

### [4/5] Program Variant Comparison
Farklı mincut varyantlarını karşılaştırır:
```
Variant              Time (sec)   Cut Value
------------------------------------------------------------------------------------
base                 0.543        50
contract             0.612        50
heavy                0.678        50
recursive            0.589        50
```

### [5/5] CSV Export
Tüm sonuçları CSV formatında export eder (`test_results_YYYYMMDD_HHMMSS.csv`):
```
Algorithm,Variant,Threads,Time,Cut,Nodes,Edges,Speedup,Efficiency
vc,base,1,0.543,50,100000,500000,1.000,100.000
inexact,base,4,0.189,50,100000,500000,2.873,71.825
exact,base,8,0.098,50,100000,500000,5.541,69.255
```

Bu CSV dosyası Excel, Python (pandas), R, veya diğer analiz araçlarında kullanılabilir.

## Sorun Giderme

### "Please select a minimum cut..." hatası
- Algoritma adını doğru yazdığınızdan emin olun
- Sequential programlar için: `ks`, `noi`, `matula`, `vc`, `pr`, `cactus`
- Parallel programlar için: `inexact`, `exact`, `cactus`

### Build hatası
- MPI kurulu olduğundan emin olun: `sudo apt-get install libopenmpi-dev openmpi-bin`
- CMake versiyonu >= 3.9 olmalı
- C++17 desteği gerekli

### Graf bulunamadı
```bash
cd /home/user/VieCut/build
./gnp_torus -n 1000 -b 10 -c 5 -s 42 -o ../graphs
mv ../graphs/graph.metis ../graphs/yuzbinlik.metis
```

## Dosya Yapısı

```
VieCut/
├── build_and_test.sh          # Tam otomatik test (tüm algoritmalar)
├── quick_test.sh              # Hızlı test (5 ana algoritma)
├── TEST_COMMANDS.md           # Detaylı komut listesi
├── ALGORITHM_REFERENCE.md     # Bu dosya
├── build/                     # Build dizini
│   ├── mincut*               # Executable'lar
│   └── test_results_*.log    # Test sonuçları
└── graphs/
    └── yuzbinlik.metis       # Test grafı
```
