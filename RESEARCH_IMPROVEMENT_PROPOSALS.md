# VieCut Research Improvement Proposals
## Theoretically-Grounded Performance Enhancements

**For PhD Thesis Development**

---

## Executive Summary

This document identifies **12 concrete research opportunities** in the VieCut codebase, each with:
- Theoretical justification
- Expected complexity improvement
- Implementation complexity
- Publication potential

---

## Part I: Sequential Processing Improvements

### 1. Priority Queue Selection: Adaptive Switching

**Current Implementation** (`noi_minimum_cut.h:85-121`):
```cpp
if (mincut > 10000 && mincut > G->number_of_nodes()) {
    pq = new vecMaxNodeHeap(G->number_of_nodes());  // Binary heap O(log n)
} else {
    pq = new fifo_node_bucket_pq(G->number_of_nodes(), mincut);  // Bucket O(1)
}
```

**Problem**: Static threshold (10000) is arbitrary, not adaptive to graph structure.

**Proposed Improvement**: **Adaptive Priority Queue Selection**

```
Theory: For bucket PQ, space = O(λ·n), operations = O(1)
        For binary heap, space = O(n), operations = O(log n)

Crossover point: When λ·n operations occur, bucket wins if:
    O(λ·n · 1) < O(λ·n · log n)  → Always true

But memory constraint: bucket uses O(λ) buckets
    If λ > cache_size / sizeof(deque), cache misses dominate
```

**Proposed Algorithm**:
```cpp
// Adaptive selection based on L3 cache size and working set
size_t cache_line_buckets = L3_CACHE_SIZE / (sizeof(std::deque<NodeID>) + 64);
if (mincut < cache_line_buckets && mincut * n < MEMORY_THRESHOLD) {
    pq = new fifo_node_bucket_pq(...);
} else if (mincut < sqrt(n)) {
    pq = new radix_heap(...);  // NEW: O(log C) where C = max key
} else {
    pq = new vecMaxNodeHeap(...);
}
```

**Theoretical Contribution**: Prove crossover point analytically for cache-oblivious model.

**Expected Improvement**: 10-30% on medium-density graphs.

---

### 2. Connectivity Certificate: Sparsification Enhancement

**Current Implementation** (`noi_minimum_cut.h:123-198`):
Builds λ edge-disjoint spanning forests to certify connectivity.

**Gap Identified**: After first contraction round, graph becomes denser (relative to n). Certificate rebuilding doesn't exploit this.

**Proposed Improvement**: **Incremental Connectivity Certificate**

```
Theory (Eppstein et al., 1997):
    Sparse certificate of size O(λn) suffices for λ-connectivity.

Current: Rebuild from scratch after each contraction = O(m + n log n) per round

Proposed: Maintain certificate incrementally during contraction
    - When edge (u,v) contracted, u's certificate edges transfer to contracted vertex
    - Only recompute for affected component

Amortized cost: O(m + n log n) total across ALL rounds (not per round)
```

**Implementation Insight** (`contract_graph.h:133-158`):
```cpp
// Current: Full rebuild after fromUnionFind()
// Proposed: Track which forests each edge belongs to
struct CertifiedEdge {
    EdgeID edge;
    uint8_t forest_membership;  // Bitmask for λ forests
};
```

**Theoretical Contribution**: First incremental connectivity certificate for minimum cut.

**Expected Improvement**: O(k) speedup where k = number of contraction rounds (typically 5-20).

---

### 3. Label Propagation: Weighted Second-Order Expansion

**Current Implementation** (`label_propagation.h:59-87`):
```cpp
// First-order: Only direct neighbor weights
for (EdgeID e : G->edges_of(n)) {
    hash_vec[cluster_id[target]].first += G->getEdgeWeight(n, e);
}
```

**Problem**: Ignores graph structure beyond immediate neighbors. Dense clusters with weak internal connections still merge.

**Proposed Improvement**: **Second-Order Label Propagation**

```
Theory: Connection strength to cluster C from vertex v:
    Current:  w1(v,C) = Σ_{u∈C} w(v,u)
    Proposed: w2(v,C) = w1(v,C) + α·Σ_{u∈N(v)} w(v,u)·|N(u)∩C|/|N(u)|

This captures: "Am I connected to vertices that are themselves well-connected to C?"
```

**Implementation**:
```cpp
// Precompute: For each vertex, cluster distribution of neighbors
std::vector<std::unordered_map<PartitionID, EdgeWeight>> neighbor_cluster_weight(n);

for (NodeID v : G->nodes()) {
    for (EdgeID e : G->edges_of(v)) {
        NodeID u = G->getEdgeTarget(v, e);
        for (EdgeID e2 : G->edges_of(u)) {
            NodeID w = G->getEdgeTarget(u, e2);
            neighbor_cluster_weight[v][cluster_id[w]] += G->getEdgeWeight(u, e2);
        }
    }
}
// Use weighted combination in label selection
```

**Theoretical Contribution**: Prove convergence and cut-preservation properties.

**Expected Improvement**: Better clustering on social networks (15-40% fewer contraction rounds).

---

### 4. Degree-2 Vertex Chains: Path Compression

**Current Implementation** (`heavy_edges.h:96-147`):
Handles degree-2 vertices one at a time.

**Gap Identified**: Chains of degree-2 vertices (paths) processed sequentially.

**Proposed Improvement**: **Path Detection and Bulk Contraction**

```
Observation: In many graphs (road networks, meshes), long paths of degree-2 vertices exist.

Current: Each degree-2 vertex → 1 contraction → O(k) operations for k-path
Proposed: Detect path → contract to single edge → O(1) operation

Theory: Path from u to v with intermediate vertices {w1,...,wk}
    If all wi have degree 2 and total weight = λ:
        - Entire path represents ONE minimum cut choice
        - Can represent as single cycle edge in cactus
```

**Algorithm**:
```cpp
std::vector<bool> visited(n, false);
for (NodeID v : G->nodes()) {
    if (G->degree(v) == 2 && !visited[v]) {
        // BFS to find entire path
        std::vector<NodeID> path = extractDegree2Path(G, v);
        if (path.size() > THRESHOLD) {
            contractPathToSingleEdge(G, path);
        }
    }
}
```

**Expected Improvement**: Orders of magnitude on road networks, mesh graphs.

---

### 5. Maximum Flow: Incremental Push-Relabel

**Current Implementation** (`push_relabel.h`):
Each s-t flow computation starts fresh.

**Gap Identified**: Consecutive flow computations in cactus construction have related structure.

**Proposed Improvement**: **Warm-Started Push-Relabel**

```
Theory (Goldberg, 1997):
    If previous flow f* is feasible for new problem, can warm-start.

Observation in recursive_cactus.h:
    - Flow from s to t computed
    - Then flows within SCCs computed
    - SCC flows are SUBGRAPHS of original

Proposed: Preserve flow values on shared edges
    - When recurring on SCC, restrict previous flow to subgraph
    - This flow is valid preflow, skip initialization

Complexity: Current O(n²√m) per flow
            Warm-start: O(n²√m) AMORTIZED over all recursive calls
```

**Implementation in `recursive_cactus.h`**:
```cpp
// Store flow on graph edges
mutableGraphPtr internalRecursiveCactus(mutableGraphPtr G, size_t depth,
                                         FlowState* parent_flow) {
    // ... find s-t flow ...
    FlowState current_flow = computeFlowWithWarmStart(G, s, t, parent_flow);

    // Pass restricted flow to recursive calls
    for (int c = 0; c < num_comp; ++c) {
        FlowState restricted = restrictFlowToComponent(current_flow, component[c]);
        recursiveCactus(subgraph[c], depth+1, &restricted);
    }
}
```

**Theoretical Contribution**: Prove amortized bound for recursive warm-start.

**Publication Potential**: Strong - combines algorithm engineering with theory.

---

## Part II: Multi-Processing Improvements

### 6. Parallel Capforest: Work Stealing with Affinity

**Current Implementation** (`exact_parallel_minimum_cut.h:182-238`):
```cpp
#pragma omp parallel for
for (int i = 0; i < omp_get_num_threads(); ++i) {
    // Independent capforest from random start
    while (!pq.empty()) {
        // Process vertices
    }
}
```

**Problem**:
1. Random starts may cause massive work duplication
2. No load balancing - some threads finish early
3. `visited[]` array causes cache invalidation across threads

**Proposed Improvement**: **Affinity-Aware Work Stealing**

```
Theory: Graph partitioned into k regions with minimal boundary
    - Each thread "owns" a region
    - Steals work only from boundary vertices

Cache model: If vertex v processed by thread T_owner(v),
    cache miss probability = β (low)
    If processed by stealer, probability = γ >> β

Optimal: Minimize boundary crossings while balancing load
```

**Implementation**:
```cpp
// Phase 1: Partition graph using METIS or label propagation
std::vector<int> partition = partitionGraph(G, omp_get_num_threads());

// Phase 2: Each thread processes owned partition with local PQ
#pragma omp parallel
{
    int tid = omp_get_thread_num();
    LocalPQ local_pq;
    SharedPQ boundary_pq;  // Lock-free for boundary vertices

    // Process owned vertices first
    for (NodeID v : owned_vertices[tid]) {
        processVertex(v, local_pq);
    }

    // Work stealing: only take boundary vertices
    while (!all_done()) {
        if (auto v = boundary_pq.try_steal()) {
            processVertex(*v, local_pq);
        }
    }
}
```

**Theoretical Contribution**: Prove load balance bounds with affinity constraints.

**Expected Improvement**: 2-4x better scaling beyond 16 threads.

---

### 7. Speculative Parallel Cactus Construction

**Current Issue** (`recursive_cactus.h:206-221`):
```cpp
// Sequential: Process small blocks first, then large
for (int c = 0; c < num_comp; ++c) {
    if (blocksizes[c] <= g_n / 2.0) {
        STCactus = mergeCactusWithComponent(...);  // SEQUENTIAL
    }
}
```

**Problem**: Cactus construction is the sequential bottleneck after parallel kernelization.

**Proposed Improvement**: **Speculative Parallel Recursion**

```
Observation: After SCC decomposition, components are INDEPENDENT until merge.

Theory: If we have k components of sizes n1, n2, ..., nk:
    Sequential: T = Σ T(ni)
    Parallel:   T = max(T(ni)) + O(merge overhead)

Speedup potential: k-fold for balanced components
```

**Implementation**:
```cpp
// Launch parallel tasks for independent components
std::vector<std::future<mutableGraphPtr>> futures;
for (int c = 0; c < num_comp; ++c) {
    futures.push_back(std::async(std::launch::async, [&, c]() {
        return recursiveCactus(subgraph[c], depth + 1);
    }));
}

// Collect and merge (must be sequential, but O(n*) time)
for (int c = 0; c < num_comp; ++c) {
    auto sub_cactus = futures[c].get();
    STCactus = graph_modification::mergeGraphs(STCactus, ..., sub_cactus, ...);
}
```

**Challenge**: Need thread-safe mutable_graph or graph copying.

**Expected Improvement**: 3-10x on graphs with many SCCs per level.

---

### 8. SIMD-Accelerated Contraction Tests

**Current Implementation** (`contraction_tests.h:56-96`):
```cpp
for (NodeID n : G->nodes()) {
    for (EdgeID e : G->edges_of(n)) {
        // Scalar comparison
        if (wgt >= limit || 2 * wgt > degrees[source] || ...) {
            uf.Union(source, target);
        }
    }
}
```

**Problem**: Edge-by-edge processing doesn't utilize SIMD.

**Proposed Improvement**: **Vectorized Batch Testing**

```
Theory: Modern CPUs have 256-bit (AVX2) or 512-bit (AVX-512) SIMD.
    Can test 4-8 edges simultaneously.

Condition: 2*wgt > degree[src]
    → Pack 8 edges: wgt[0..7], degree[0..7]
    → SIMD compare: mask = (2*wgt > degree)
    → Scatter results to union-find
```

**Implementation**:
```cpp
#include <immintrin.h>

void vectorizedPRTest12(GraphPtr G, union_find& uf, EdgeWeight limit) {
    alignas(64) EdgeWeight weights[8];
    alignas(64) EdgeWeight degrees_src[8];
    alignas(64) EdgeWeight degrees_tgt[8];

    for (NodeID n : G->nodes()) {
        size_t batch_idx = 0;
        for (EdgeID e : G->edges_of(n)) {
            weights[batch_idx] = G->getEdgeWeight(n, e);
            degrees_src[batch_idx] = G->getWeightedNodeDegree(n);
            degrees_tgt[batch_idx] = G->getWeightedNodeDegree(G->getEdgeTarget(n, e));

            if (++batch_idx == 8) {
                // SIMD test
                __m512i w = _mm512_load_epi64(weights);
                __m512i ds = _mm512_load_epi64(degrees_src);
                __m512i dt = _mm512_load_epi64(degrees_tgt);
                __m512i two_w = _mm512_slli_epi64(w, 1);  // 2*w

                __mmask8 mask1 = _mm512_cmpgt_epi64_mask(w, limit_vec);
                __mmask8 mask2 = _mm512_cmpgt_epi64_mask(two_w, ds);
                __mmask8 mask3 = _mm512_cmpgt_epi64_mask(two_w, dt);
                __mmask8 contract_mask = mask1 | mask2 | mask3;

                // Process contracted edges
                processMask(contract_mask, batch_edges, uf);
                batch_idx = 0;
            }
        }
        // Handle remainder
    }
}
```

**Expected Improvement**: 4-8x for contraction test phase (typically 20-40% of total time).

---

### 9. GPU-Accelerated Label Propagation

**Current Issue**: Label propagation is embarrassingly parallel but runs on CPU.

**Proposed Improvement**: **CUDA/OpenCL Label Propagation**

```
Theory: Each vertex independently computes strongest cluster connection.
    Perfect for GPU: thousands of vertices processed simultaneously.

Memory model:
    - Graph in CSR on GPU global memory
    - Cluster IDs in shared memory (fast)
    - Atomic updates for tie-breaking
```

**Kernel Design**:
```cuda
__global__ void labelPropagationKernel(
    int* row_ptr, int* col_idx, float* weights,
    int* cluster_id, int n)
{
    int v = blockIdx.x * blockDim.x + threadIdx.x;
    if (v >= n) return;

    // Shared memory for cluster weights
    __shared__ float cluster_weight[MAX_CLUSTERS];

    // Compute connection to each cluster
    for (int e = row_ptr[v]; e < row_ptr[v+1]; e++) {
        int u = col_idx[e];
        atomicAdd(&cluster_weight[cluster_id[u]], weights[e]);
    }
    __syncthreads();

    // Find maximum
    int best_cluster = findMaxCluster(cluster_weight);
    cluster_id[v] = best_cluster;
}
```

**Expected Improvement**: 10-100x for graphs with >1M vertices.

**Publication Venue**: PPoPP, SC, Euro-Par

---

## Part III: Theoretical Extensions

### 10. New Kernelization Rule: Bounded-Depth Certificate

**Observation**: Current connectivity certificate (`noi_minimum_cut.h`) provides global bound.

**Gap**: Local structure often provides tighter bounds.

**Proposed Rule**: **k-Hop Connectivity Certificate**

```
Definition: k-hop connectivity λ_k(u,v) = min-cut between u,v using paths of length ≤ k

Theorem (Proposed): If λ_k(e) > λ_hat for k = O(log n), then e not in any minimum cut.

Proof sketch:
    1. BFS from u to depth k, computing min-weight path capacities
    2. If all k-hop paths have capacity > λ_hat, edge can be contracted
    3. Correctness: Any min-cut path must use some k-hop segment

Complexity: O(m · degree^k) but k is small constant (2-4)
```

**Implementation**:
```cpp
union_find kHopCertificate(GraphPtr G, EdgeWeight limit, int k = 3) {
    union_find uf(G->n());

    for (NodeID n : G->nodes()) {
        for (EdgeID e : G->edges_of(n)) {
            NodeID t = G->getEdgeTarget(n, e);
            EdgeWeight k_hop_connectivity = computeKHopConnectivity(G, n, t, k);
            if (k_hop_connectivity > limit) {
                uf.Union(n, t);
            }
        }
    }
    return uf;
}

EdgeWeight computeKHopConnectivity(GraphPtr G, NodeID s, NodeID t, int k) {
    // Modified BFS tracking min bottleneck on each path
    std::vector<EdgeWeight> best_capacity(G->n(), 0);
    std::queue<std::pair<NodeID, int>> bfs;
    bfs.push({s, 0});
    best_capacity[s] = INFINITY;

    while (!bfs.empty()) {
        auto [v, depth] = bfs.front(); bfs.pop();
        if (depth >= k) continue;

        for (EdgeID e : G->edges_of(v)) {
            NodeID u = G->getEdgeTarget(v, e);
            EdgeWeight new_cap = min(best_capacity[v], G->getEdgeWeight(v, e));
            if (new_cap > best_capacity[u]) {
                best_capacity[u] = new_cap;
                bfs.push({u, depth + 1});
            }
        }
    }
    return best_capacity[t];
}
```

**Theoretical Contribution**: New kernelization rule with provable effectiveness.

---

### 11. Dynamic Minimum Cut: Deletion Support

**Current Issue**: Dynamic algorithm (`dynamic_mincut.h`) only supports insertions efficiently.

**Gap**: Edge deletions require full recomputation.

**Proposed Extension**: **Fully Dynamic Cactus Maintenance**

```
Theory (Proposed):
    Insertion: Current O(λ²) amortized
    Deletion:  New O(λ² · log n) amortized using link-cut trees

Key insight: Deletion can only DECREASE min-cut
    Case 1: Deleted edge not in any min-cut → cactus unchanged
    Case 2: Deleted edge in some min-cut → recompute affected cactus region

For Case 2:
    - Identify cactus path containing deleted edge
    - Remove path, obtain two sub-cacti
    - Compute new minimum cut between sub-cacti
    - Merge with flow-based bridge finding
```

**Complexity Analysis**:
```
Let T_cactus = current cactus, e = deleted edge

If e is tree edge in T_cactus:
    Two components formed, size n1 and n2
    Need flow between components: O(min(n1,n2) · m/n)

If e is cycle edge:
    Cycle broken, may split into tree edges
    Local recomputation: O(cycle_size · λ)

Amortized: Each edge deleted once → O(m · λ²) total
```

**Publication Potential**: VERY HIGH - fully dynamic min-cut is open problem.

---

### 12. Approximation-Exact Trade-off

**Observation**: Exact all-cuts unnecessary for many applications (partitioning, clustering).

**Proposed Algorithm**: **ε-Approximate All Minimum Cuts**

```
Definition: ε-approximate min-cut cactus contains all cuts of value ≤ (1+ε)λ

Algorithm:
1. Run VieCut to get λ_hat
2. In kernelization, use threshold (1+ε)λ_hat instead of λ_hat
3. More edges contracted → smaller kernel
4. Cactus construction on smaller graph

Theorem (Proposed):
    Kernel size: O(n/ε) instead of O(n*)
    Contains all (1+ε)-approximate minimum cuts

Trade-off: ε = 0.1 → 10x smaller kernel, 10x faster
```

**Use Case**: Graph partitioning only needs "good enough" cuts.

---

## Part IV: Implementation Quality Improvements

### 13. Memory Layout Optimization

**Current Issue** (`mutable_graph.h:962`):
```cpp
std::vector<std::vector<RevEdge>> vertices;  // Vector of vectors → poor cache
```

**Proposed**: **Flat Edge Storage with Index Array**
```cpp
struct FlatMutableGraph {
    std::vector<RevEdge> all_edges;       // Contiguous memory
    std::vector<size_t> vertex_offset;     // CSR-style indexing
    std::vector<size_t> vertex_capacity;   // For growth
};
```

**Expected Improvement**: 20-50% cache miss reduction.

---

### 14. Lock-Free Union-Find

**Current Issue** (`parallel/data_structure/union_find.h`): Uses locks or has race conditions.

**Proposed**: **Wait-Free Union-Find (Anderson & Woll, 1991)**
```cpp
NodeID Find(NodeID x) {
    while (parent[x] != x) {
        NodeID p = parent[x];
        NodeID gp = parent[p];
        // CAS for path compression
        __sync_bool_compare_and_swap(&parent[x], p, gp);
        x = gp;
    }
    return x;
}

bool Union(NodeID x, NodeID y) {
    while (true) {
        x = Find(x); y = Find(y);
        if (x == y) return false;
        if (x > y) std::swap(x, y);
        if (__sync_bool_compare_and_swap(&parent[y], y, x)) {
            return true;
        }
    }
}
```

---

## Summary: Prioritized Research Agenda

| Priority | Improvement | Effort | Impact | Publication |
|----------|------------|--------|--------|-------------|
| 🔴 HIGH | #5: Warm-Start Flow | Medium | 2-5x | Top venue |
| 🔴 HIGH | #7: Parallel Cactus | High | 3-10x | Top venue |
| 🔴 HIGH | #11: Dynamic Deletion | High | NEW | Very high |
| 🟡 MED | #2: Incremental Certificate | Medium | O(k)x | Good venue |
| 🟡 MED | #6: Affinity Work Stealing | Medium | 2-4x | Good venue |
| 🟡 MED | #10: k-Hop Certificate | Low | 10-30% | Workshop |
| 🟢 LOW | #8: SIMD Tests | Low | 4-8x on tests | Engineering |
| 🟢 LOW | #3: 2nd-Order LP | Medium | 15-40% | Workshop |

---

**Recommended PhD Contribution**:
Combine #5 (Warm-Start Flow) + #7 (Parallel Cactus) + #11 (Dynamic Deletion) for a strong thesis on "Practical Fully Dynamic Minimum Cut Algorithms"

This addresses the open problem of efficient deletions while providing practical speedups for the static case.
