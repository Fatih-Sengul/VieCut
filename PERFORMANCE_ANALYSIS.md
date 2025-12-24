# VieCut Performance Analysis Guide

Bu belge, `build_and_test.sh` scriptinin otomatik performans analizi özelliklerini ve görselleştirme araçlarını açıklar.

## Otomatik Analiz Özellikleri

Test scripti çalıştırıldığında, tüm testler tamamlandıktan sonra otomatik olarak **5 aşamalı analiz** yapar:

### 1️⃣ Sequential Algorithms Comparison

Tüm sequential algoritmaları karşılaştırır ve en hızlısını belirler.

**Çıktı Örneği:**
```
Algorithm       Time (sec)   Cut Value    Nodes        Edges
------------------------------------------------------------------------------------
ks              2.345        50          100000       500000
noi             1.234        50          100000       500000
matula          0.987        50          100000       500000
vc              0.543        50          100000       500000  ← En hızlı!
pr              3.456        50          100000       500000
cactus          4.567        50          100000       500000
------------------------------------------------------------------------------------
Best Sequential: vc (0.543s)
Reference Cut Value: 50
```

**Ne Gösterir:**
- Her algoritmanın çalışma süresi
- Minimum cut değeri (doğruluk kontrolü için)
- Graf boyutu (node ve edge sayısı)
- Hangi algoritmanın en hızlı olduğu

### 2️⃣ Parallel Speedup Analysis

Parallel algoritmalar için hızlanma (speedup) ve verimlilik (efficiency) hesaplar.

**Çıktı Örneği:**
```
Algorithm       Threads    Time (sec)   Speedup      Efficiency   Status
------------------------------------------------------------------------------------
inexact         1          0.612        0.89x        88.72%       ✓ OK
inexact         2          0.334        1.63x        81.44%       ✓ OK
inexact         4          0.189        2.87x        71.83%       ✓ OK
inexact         8          0.125        4.34x        54.29%       ✓ OK  ← En iyi speedup!
exact           1          0.589        0.92x        92.19%       ✓ OK
exact           2          0.312        1.74x        87.02%       ✓ OK
exact           4          0.167        3.25x        81.29%       ✓ OK
exact           8          0.098        5.54x        69.23%       ✓ OK
------------------------------------------------------------------------------------
Best Speedup: exact (8 threads) (5.54x)
```

**Metrikler:**
- **Speedup**: `T_sequential_best / T_parallel`
  - Ne kadar hızlandı? (ideal: thread sayısı kadar)
  - Örnek: 8 thread ile 5.54x = sequential'den 5.54 kat daha hızlı

- **Efficiency**: `(Speedup / Thread_sayısı) × 100%`
  - Kaynaklar ne kadar verimli kullanıldı?
  - 100% = mükemmel, her thread tam verimli
  - Örnek: 8 thread ile 69.23% = her thread %69 verimli kullanıldı

- **Status**: Cut değeri doğru mu?
  - ✓ OK = Doğru sonuç
  - ✗ WRONG = Yanlış sonuç (algoritma hatası)

### 3️⃣ Scalability Analysis (Strong Scaling)

Her parallel algoritma için 1-thread baseline'a göre ölçeklenebilirliği gösterir.

**Çıktı Örneği:**
```
Algorithm: inexact
  Threads    Time (sec)   Speedup      Efficiency
  1          0.612        1.00x        100.00%   ← Baseline
  2          0.334        1.83x        91.62%    ← 2x thread, 1.83x hızlanma
  4          0.189        3.24x        80.95%    ← 4x thread, 3.24x hızlanma
  8          0.125        4.90x        61.22%    ← 8x thread, 4.90x hızlanma

Algorithm: exact
  Threads    Time (sec)   Speedup      Efficiency
  1          0.589        1.00x        100.00%
  2          0.312        1.89x        94.39%
  4          0.167        3.53x        88.18%
  8          0.098        6.01x        75.13%    ← Daha iyi ölçeklenme!
```

**Ne Gösterir:**
- Her algoritmanın kendi içindeki ölçeklenebilirliği
- Thread sayısı arttıkça performans nasıl değişiyor?
- Efficiency düşüyorsa → parallelization overhead artıyor

**İdeal Durum:**
- 2 thread → 2.00x speedup, 100% efficiency
- 4 thread → 4.00x speedup, 100% efficiency
- 8 thread → 8.00x speedup, 100% efficiency

**Gerçek Durum:**
- Overhead, synchronization, memory bandwidth gibi faktörler ideal durumu engeller
- %80+ efficiency = çok iyi
- %60-80 efficiency = kabul edilebilir
- %60'ın altı = parallelization sorunları olabilir

### 4️⃣ Program Variant Comparison

Farklı mincut varyantlarını karşılaştırır.

**Çıktı Örneği:**
```
Variant              Time (sec)   Cut Value
------------------------------------------------------------------------------------
base                 0.543        50   ← Standart
contract             0.612        50   ← Contraction kullanır
heavy                0.678        50   ← Heavy edge odaklı
recursive            0.589        50   ← Recursive yaklaşım
```

**Ne Gösterir:**
- Her varyantın performans farkı
- Hangi varyant ne zaman kullanılmalı?

### 5️⃣ CSV Export

Tüm sonuçları CSV formatında export eder.

**Dosya Adı:** `test_results_YYYYMMDD_HHMMSS.csv`

**İçerik:**
```csv
Algorithm,Variant,Threads,Time,Cut,Nodes,Edges,Speedup,Efficiency
vc,base,1,0.543,50,100000,500000,1.000,100.000
ks,base,1,2.345,50,100000,500000,0.232,23.154
inexact,base,4,0.189,50,100000,500000,2.873,71.825
exact,base,8,0.098,50,100000,500000,5.541,69.255
```

**Kullanım Alanları:**
- Excel'de analiz
- Python/Pandas ile ileri analiz
- R ile istatistiksel testler
- Makale/rapor için tablo oluşturma

## Görselleştirme

Test sonuçlarını otomatik olarak görselleştirmek için Python scripti kullanın:

### Kurulum

```bash
# Python ve gerekli paketleri yükle
pip3 install pandas matplotlib numpy
```

### Kullanım

```bash
cd /home/user/VieCut/build
python3 ../visualize_results.py test_results_20241224_123456.csv
```

### Oluşturulan Grafikler

Script `visualizations/` klasörüne şu grafikleri oluşturur:

#### 1. Sequential Comparison (`sequential_comparison.png`)
- **Sol Panel**: Her algoritmanın çalışma süresi (bar chart)
- **Sağ Panel**: Relative speedup (en yavaşa göre)
- **Kullanım**: Hangi sequential algoritma en hızlı?

#### 2. Parallel Speedup (`parallel_speedup.png`)
- **Sol Panel**: Thread sayısı vs Speedup
  - Her parallel algoritma için çizgi grafik
  - İdeal (linear) speedup çizgisi ile karşılaştırma
- **Sağ Panel**: Thread sayısı vs Efficiency
  - %100 efficiency referans çizgisi
- **Kullanım**: Parallel algoritmaların ölçeklenebilirliği

#### 3. Strong Scaling (`strong_scaling.png`)
- Thread sayısı vs Speedup (1-thread baseline'a göre)
- Her algoritmanın kendi içindeki ölçeklenebilirliği
- İdeal speedup çizgisi
- **Kullanım**: Amdahl's Law analizi, parallel overhead tespiti

#### 4. Variant Comparison (`variant_comparison.png`)
- Program varyantları arasında performans karşılaştırması
- VC algoritması üzerinden
- **Kullanım**: Hangi varyant ne zaman kullanılmalı?

### Summary Report

Script ayrıca `summary_report.txt` dosyası oluşturur:

```
================================================================================
VieCut Performance Analysis Summary Report
================================================================================

1. SEQUENTIAL ALGORITHMS
--------------------------------------------------------------------------------
   Fastest: vc (0.543s)
   Slowest: cactus (4.567s)
   Speedup: 8.41x
   Average: 1.834s

2. PARALLEL PERFORMANCE
--------------------------------------------------------------------------------
   Best Speedup: exact with 8 threads
                 5.54x speedup, 69.25% efficiency

   Average Efficiency by Thread Count:
      1 threads: 90.45%
      2 threads: 86.48%
      4 threads: 77.76%
      8 threads: 66.21%

3. CORRECTNESS VALIDATION
--------------------------------------------------------------------------------
   ✓ All algorithms found the same minimum cut: 50

================================================================================
```

## Analiz İpuçları

### Performans Optimizasyonu

1. **En hızlı sequential seç**: Research/development için
2. **Best speedup/efficiency balance bul**: Production için
3. **Thread sayısını optimize et**: Efficiency %70'in üstünde olmalı

### Doğruluk Kontrolü

- Tüm algoritmalar aynı cut değerini bulmalı
- Farklı sonuçlar → hata var demektir
- Status sütununda ✗ WRONG görürseniz → algoritma/implementation hatası

### Scalability Analizi

**İyi Ölçeklenme:**
```
2 thread → 1.8x+ speedup
4 thread → 3.2x+ speedup
8 thread → 5.0x+ speedup
```

**Kötü Ölçeklenme:**
```
2 thread → 1.2x speedup  ← Çok fazla overhead
4 thread → 1.8x speedup
8 thread → 2.1x speedup
```

**Sorunlar:**
- Synchronization overhead
- Memory bandwidth bottleneck
- False sharing
- Load imbalance

### CSV ile İleri Analiz

**Python/Pandas Örneği:**
```python
import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv('test_results_20241224_123456.csv')

# Best algorithm per thread count
best_by_threads = df.loc[df.groupby('Threads')['Time'].idxmin()]
print(best_by_threads[['Algorithm', 'Threads', 'Time', 'Speedup']])

# Average efficiency by algorithm
avg_efficiency = df.groupby('Algorithm')['Efficiency'].mean()
print(avg_efficiency.sort_values(ascending=False))

# Plot speedup curve
for algo in df['Algorithm'].unique():
    data = df[df['Algorithm'] == algo].sort_values('Threads')
    plt.plot(data['Threads'], data['Speedup'], marker='o', label=algo)

plt.xlabel('Threads')
plt.ylabel('Speedup')
plt.legend()
plt.grid(True)
plt.savefig('custom_speedup.png')
```

## Tam İş Akışı

```bash
# 1. Testleri çalıştır (otomatik analiz dahil)
cd /home/user/VieCut
./build_and_test.sh

# Output:
# - build/test_results_YYYYMMDD_HHMMSS.log
# - build/test_results_YYYYMMDD_HHMMSS.csv

# 2. Görselleştirme oluştur
cd build
python3 ../visualize_results.py test_results_20241224_123456.csv

# Output:
# - visualizations/sequential_comparison.png
# - visualizations/parallel_speedup.png
# - visualizations/strong_scaling.png
# - visualizations/variant_comparison.png
# - visualizations/summary_report.txt

# 3. Sonuçları incele
cat visualizations/summary_report.txt
eog visualizations/*.png  # veya favori image viewer'ınız
```

## Örnek Çıktı Yorumlama

### Senaryo 1: İyi Parallel Performans

```
Algorithm: exact
  Threads    Speedup      Efficiency
  1          1.00x        100.00%
  2          1.92x        96.00%     ← Mükemmel!
  4          3.68x        92.00%     ← Çok iyi!
  8          6.88x        86.00%     ← İyi!
```

**Yorum:** Algorithm neredeyse linear ölçekleniyor. 8 thread kullanmak mantıklı.

### Senaryo 2: Overhead Problemi

```
Algorithm: inexact
  Threads    Speedup      Efficiency
  1          1.00x        100.00%
  2          1.45x        72.50%     ← Overhead başladı
  4          2.12x        53.00%     ← Çok fazla overhead
  8          2.45x        30.63%     ← Waste of resources!
```

**Yorum:** 2 thread'den sonra overhead çok fazla. Maximum 2 thread kullan.

### Senaryo 3: Memory Bandwidth Problemi

```
Algorithm: cactus
  Threads    Time         Speedup
  1          2.000s       1.00x
  2          1.100s       1.82x      ← İyi
  4          0.750s       2.67x      ← Yavaşlama başladı
  8          0.680s       2.94x      ← Neredeyse aynı!
```

**Yorum:** 4-8 thread arası neredeyse fark yok. Muhtemelen memory bandwidth sınırına dayanıldı.

## Sonuç

Bu otomatik analiz sistemi size şunları sağlar:

✅ **Hızlı Karşılaştırma**: Tüm algoritmaları tek bakışta görün
✅ **Doğruluk Kontrolü**: Cut değerleri otomatik doğrulanır
✅ **Performans Metrikleri**: Speedup ve efficiency otomatik hesaplanır
✅ **Görselleştirme**: Publication-ready grafikler
✅ **CSV Export**: İleri analiz için hazır data
✅ **Summary Report**: Hızlı overview

**Makale/Rapor İçin Hazır:**
- Tablolar: Log dosyasından kopyala
- Grafikler: PNG dosyaları yüksek çözünürlükte (300 DPI)
- İstatistikler: Summary report ve CSV
