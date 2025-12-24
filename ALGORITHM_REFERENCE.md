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
