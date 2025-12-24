#!/usr/bin/env python3
"""
Visualize benchmark results from CSV file.
Generate parallel speedup plot showing Speedup vs Threads.
"""

import sys
import pandas as pd
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend
import matplotlib.pyplot as plt
import os

def visualize_results(csv_file):
    """
    Read CSV file and generate speedup plot.
    CSV format: Algorithm,Threads,Time,Cut
    """
    print(f"Reading results from {csv_file}...")

    # Read CSV
    df = pd.read_csv(csv_file)

    print(f"Found {len(df)} benchmark results")
    print(df.to_string())

    # Filter for parallel algorithms (those with thread counts)
    parallel_df = df[df['Threads'] > 0].copy()

    # Calculate speedup for each algorithm
    fig, ax = plt.subplots(figsize=(10, 6))

    # Process exact algorithm
    exact_df = parallel_df[parallel_df['Algorithm'] == 'exact'].copy()
    if not exact_df.empty:
        exact_df = exact_df.sort_values('Threads')
        baseline_time = exact_df[exact_df['Threads'] == 1]['Time'].values[0] if 1 in exact_df['Threads'].values else exact_df.iloc[0]['Time']
        exact_df['Speedup'] = baseline_time / exact_df['Time']
        ax.plot(exact_df['Threads'], exact_df['Speedup'], marker='o', linewidth=2,
                markersize=8, label='Exact (Parallel)', color='#2E86AB')

    # Process inexact algorithm
    inexact_df = parallel_df[parallel_df['Algorithm'] == 'inexact'].copy()
    if not inexact_df.empty:
        inexact_df = inexact_df.sort_values('Threads')
        baseline_time = inexact_df[inexact_df['Threads'] == 1]['Time'].values[0] if 1 in inexact_df['Threads'].values else inexact_df.iloc[0]['Time']
        inexact_df['Speedup'] = baseline_time / inexact_df['Time']
        ax.plot(inexact_df['Threads'], inexact_df['Speedup'], marker='s', linewidth=2,
                markersize=8, label='Inexact (Parallel)', color='#A23B72')

    # Add ideal speedup line
    if not parallel_df.empty:
        max_threads = parallel_df['Threads'].max()
        ideal_threads = range(1, int(max_threads) + 1)
        ax.plot(ideal_threads, ideal_threads, '--', linewidth=2,
                label='Ideal Speedup', color='#808080', alpha=0.7)

    # Formatting
    ax.set_xlabel('Number of Threads', fontsize=12, fontweight='bold')
    ax.set_ylabel('Speedup', fontsize=12, fontweight='bold')
    ax.set_title('Parallel Speedup on AS-Skitter Network', fontsize=14, fontweight='bold')
    ax.legend(fontsize=10, loc='upper left')
    ax.grid(True, alpha=0.3, linestyle='--')
    ax.set_xlim(left=0)
    ax.set_ylim(bottom=0)

    # Save plot
    output_dir = os.path.dirname(csv_file)
    output_path = os.path.join(output_dir, 'parallel_speedup.png')
    plt.tight_layout()
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"\nSpeedup plot saved to: {output_path}")

    # Print speedup summary
    print("\n=== Speedup Summary ===")
    if not exact_df.empty:
        print("\nExact Algorithm:")
        for _, row in exact_df.iterrows():
            print(f"  {int(row['Threads'])} threads: {row['Speedup']:.2f}x speedup ({row['Time']:.2f}s)")

    if not inexact_df.empty:
        print("\nInexact Algorithm:")
        for _, row in inexact_df.iterrows():
            print(f"  {int(row['Threads'])} threads: {row['Speedup']:.2f}x speedup ({row['Time']:.2f}s)")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 visualize_results.py <csv_file>")
        sys.exit(1)

    csv_file = sys.argv[1]

    if not os.path.exists(csv_file):
        print(f"Error: CSV file not found: {csv_file}")
        sys.exit(1)

    visualize_results(csv_file)
