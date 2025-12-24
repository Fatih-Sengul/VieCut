#!/usr/bin/env python3
"""
Convert SNAP format graph to METIS format.
SNAP format: edge list (tab or space separated, possibly 0-indexed, may have comments)
METIS format: first line has <num_vertices> <num_edges>, then adjacency lists (1-indexed)
"""

import sys
from collections import defaultdict

def convert_snap_to_metis(input_file, output_file):
    """
    Convert SNAP format to METIS format.
    - Re-index nodes to be 1-based and consecutive
    - Handle undirected edges (avoid duplicates in adjacency lists)
    - Remove comments and headers
    """
    edges = set()
    nodes = set()

    print(f"Reading SNAP graph from {input_file}...")

    # Read all edges
    with open(input_file, 'r') as f:
        for line in f:
            line = line.strip()
            # Skip comments and empty lines
            if not line or line.startswith('#') or line.startswith('%'):
                continue

            parts = line.split()
            if len(parts) < 2:
                continue

            try:
                u, v = int(parts[0]), int(parts[1])
                # Add both nodes
                nodes.add(u)
                nodes.add(v)
                # Add edge (both directions for undirected graph, avoiding duplicates)
                if u != v:  # Skip self-loops
                    edges.add((min(u, v), max(u, v)))
            except ValueError:
                continue

    # Create mapping from original node IDs to consecutive 1-based IDs
    sorted_nodes = sorted(nodes)
    node_mapping = {old_id: new_id for new_id, old_id in enumerate(sorted_nodes, start=1)}

    num_vertices = len(nodes)
    num_edges = len(edges)

    print(f"Graph has {num_vertices} vertices and {num_edges} edges")

    # Build adjacency list
    adj_list = defaultdict(set)
    for u, v in edges:
        new_u = node_mapping[u]
        new_v = node_mapping[v]
        adj_list[new_u].add(new_v)
        adj_list[new_v].add(new_u)

    # Write METIS format
    print(f"Writing METIS graph to {output_file}...")
    with open(output_file, 'w') as f:
        # Header: num_vertices num_edges
        f.write(f"{num_vertices} {num_edges}\n")

        # Adjacency lists (1-indexed)
        for i in range(1, num_vertices + 1):
            neighbors = sorted(adj_list[i])
            f.write(" ".join(map(str, neighbors)) + "\n")

    print("Conversion complete!")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 convert_snap_to_metis.py <input_snap_file> <output_metis_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    convert_snap_to_metis(input_file, output_file)
