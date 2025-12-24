# VieCut Test Komutları

## 1. Proje Build Etme

```bash
cd /home/user/VieCut
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

## 2. Graf Oluşturma (100,000 node)

```bash
cd /home/user/VieCut/build
mkdir -p ../graphs

# 100,000 node graf oluştur (10x10 blok, her blokta 1000 node)
./gnp_torus -n 1000 -b 10 -c 5 -s 42 -o ../graphs

# Dosyayı yeniden adlandır
mv ../graphs/graph.metis ../graphs/yuzbinlik.metis
```

## 3. Manuel Test Komutları

### Sequential (Tek İşlemcili) Algoritmalar

Temel kullanım: `./mincut <graph_file> <algorithm> [options]`

Geçerli algoritmalar: `ks`, `noi`, `matula`, `vc`, `pr`, `cactus`

```bash
cd /home/user/VieCut/build

# Karger-Stein
./mincut ../graphs/yuzbinlik.metis ks -r 42 -v

# Noi's Algorithm
./mincut ../graphs/yuzbinlik.metis noi -r 42 -v

# Matula Approximation
./mincut ../graphs/yuzbinlik.metis matula -r 42 -v

# VieCut
./mincut ../graphs/yuzbinlik.metis vc -r 42 -v

# Padberg-Rinaldi
./mincut ../graphs/yuzbinlik.metis pr -r 42 -v

# Cactus
./mincut ../graphs/yuzbinlik.metis cactus -r 42 -v
```

### Parallel (Çok İşlemcili) Algoritmalar

Temel kullanım: `./mincut_parallel <graph_file> <algorithm> -p <threads> [options]`

Geçerli algoritmalar: `inexact`, `exact`, `cactus`

```bash
# VieCut Parallel (inexact) - farklı thread sayıları
./mincut_parallel ../graphs/yuzbinlik.metis inexact -p 1 -r 42 -v
./mincut_parallel ../graphs/yuzbinlik.metis inexact -p 2 -r 42 -v
./mincut_parallel ../graphs/yuzbinlik.metis inexact -p 4 -r 42 -v
./mincut_parallel ../graphs/yuzbinlik.metis inexact -p 8 -r 42 -v

# Exact Parallel
./mincut_parallel ../graphs/yuzbinlik.metis exact -p 1 -r 42 -v
./mincut_parallel ../graphs/yuzbinlik.metis exact -p 2 -r 42 -v
./mincut_parallel ../graphs/yuzbinlik.metis exact -p 4 -r 42 -v
./mincut_parallel ../graphs/yuzbinlik.metis exact -p 8 -r 42 -v

# Parallel Cactus
./mincut_parallel ../graphs/yuzbinlik.metis cactus -p 1 -r 42 -v
./mincut_parallel ../graphs/yuzbinlik.metis cactus -p 2 -r 42 -v
./mincut_parallel ../graphs/yuzbinlik.metis cactus -p 4 -r 42 -v
./mincut_parallel ../graphs/yuzbinlik.metis cactus -p 8 -r 42 -v
```

### Contract Versiyonu

```bash
# Sequential
./mincut_contract ../graphs/yuzbinlik.metis ks -r 42 -v
./mincut_contract ../graphs/yuzbinlik.metis noi -r 42 -v
./mincut_contract ../graphs/yuzbinlik.metis matula -r 42 -v
./mincut_contract ../graphs/yuzbinlik.metis vc -r 42 -v
./mincut_contract ../graphs/yuzbinlik.metis pr -r 42 -v
./mincut_contract ../graphs/yuzbinlik.metis cactus -r 42 -v

# Parallel
./mincut_contract_parallel ../graphs/yuzbinlik.metis inexact -p 4 -r 42 -v
./mincut_contract_parallel ../graphs/yuzbinlik.metis exact -p 4 -r 42 -v
./mincut_contract_parallel ../graphs/yuzbinlik.metis cactus -p 4 -r 42 -v
```

### Heavy Versiyonu

```bash
# Sequential
./mincut_heavy ../graphs/yuzbinlik.metis ks -r 42 -v
./mincut_heavy ../graphs/yuzbinlik.metis noi -r 42 -v
./mincut_heavy ../graphs/yuzbinlik.metis matula -r 42 -v
./mincut_heavy ../graphs/yuzbinlik.metis vc -r 42 -v
./mincut_heavy ../graphs/yuzbinlik.metis pr -r 42 -v
./mincut_heavy ../graphs/yuzbinlik.metis cactus -r 42 -v

# Parallel
./mincut_heavy_parallel ../graphs/yuzbinlik.metis inexact -p 4 -r 42 -v
./mincut_heavy_parallel ../graphs/yuzbinlik.metis exact -p 4 -r 42 -v
./mincut_heavy_parallel ../graphs/yuzbinlik.metis cactus -p 4 -r 42 -v
```

### Recursive Versiyonu

```bash
# Sequential
./mincut_recursive ../graphs/yuzbinlik.metis ks -r 42 -v
./mincut_recursive ../graphs/yuzbinlik.metis noi -r 42 -v
./mincut_recursive ../graphs/yuzbinlik.metis matula -r 42 -v
./mincut_recursive ../graphs/yuzbinlik.metis vc -r 42 -v
./mincut_recursive ../graphs/yuzbinlik.metis pr -r 42 -v
./mincut_recursive ../graphs/yuzbinlik.metis cactus -r 42 -v

# Parallel
./mincut_recursive_parallel ../graphs/yuzbinlik.metis inexact -p 4 -r 42 -v
./mincut_recursive_parallel ../graphs/yuzbinlik.metis exact -p 4 -r 42 -v
./mincut_recursive_parallel ../graphs/yuzbinlik.metis cactus -p 4 -r 42 -v
```

## 4. Tüm Testleri Otomatik Çalıştırma

```bash
cd /home/user/VieCut
chmod +x build_and_test.sh
./build_and_test.sh
```

## Önemli Parametreler

- `-r 42` : Random seed (tekrarlanabilir sonuçlar için)
- `-v` : Verbose mode (detaylı log)
- `-p <N>` : Thread sayısı (sadece parallel versiyonlar için)
- `-i <N>` : İterasyon sayısı
- `-s` : Cut'ı kaydet
- `-o <path>` : Sonucu dosyaya yaz (requires -s)

## Notlar

1. **Sequential algoritmalar**: `ks`, `noi`, `matula`, `vc`, `pr`, `cactus`
2. **Parallel algoritmalar**: `inexact`, `exact`, `cactus`
3. **Program varyantları**:
   - `mincut` / `mincut_parallel` (temel)
   - `mincut_contract` / `mincut_contract_parallel`
   - `mincut_heavy` / `mincut_heavy_parallel`
   - `mincut_recursive` / `mincut_recursive_parallel`
4. **Total test sayısı**: 6 seq + 3 par × 4 thread = 18 par, toplamda 24 test × 4 varyant = 96 test

## Hata Mesajı

Eğer şu mesajı alırsanız:
```
Please select a minimum cut global_mincut [vc, noi, pr, matula, ks, cactus]!
```

Bu, algoritma parametresinin yanlış yazıldığı veya eksik olduğu anlamına gelir. Algoritma adını doğru yazdığınızdan emin olun.
