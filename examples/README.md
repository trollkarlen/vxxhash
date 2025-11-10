# V xxHash Examples

This directory contains comprehensive example programs demonstrating the vxxhash module's capabilities and best practices. Each example is thoroughly commented to explain not just *how* to use the APIs, but *why* you would choose specific approaches for different scenarios.

## Examples Overview

### 1. Basic Hash Example (`hash_example.v`)

**Purpose**: Introduction to fundamental vxxhash usage patterns

**Demonstrates**:
- One-shot hashing (entire data at once) - simplest approach
- Streaming hashing (data in chunks) - memory-efficient approach  
- Multiple hash algorithms and their characteristics
- Result verification between streaming and one-shot methods

**When to use this example**:
- Learning the basics of vxxhash
- Understanding the difference between one-shot and streaming approaches
- Choosing the right algorithm for your use case

```bash
# Hash a file with all algorithms
v run examples/hash_example.v -f path/to/file.txt

# Use test data instead of a file
v run examples/hash_example.v -d "Hello World"
```

**Key vxxhash APIs demonstrated**:
- `vxxhash.xxh32_hash_hex_default()` - Simple 32-bit hashing
- `vxxhash.xxh64_hash_hex_default()` - Simple 64-bit hashing  
- `vxxhash.xxh3_hash_hex_default()` - Modern XXH3 hashing
- `vxxhash.new_xxhasher()` - Create streaming hasher
- `hasher.update()` - Feed data to streaming hasher
- `hasher.digest()` - Get final hash result

### 2. Streaming Example (`streaming_example.v`)

**Purpose**: Performance comparison between streaming and one-shot approaches

**Demonstrates**:
- Memory-efficient streaming for large files
- Performance measurement and analysis
- Real-world file handling patterns
- Throughput calculation and optimization

**When to use this example**:
- Processing large files that don't fit in memory
- Understanding performance trade-offs
- Optimizing chunk sizes for maximum throughput
- Building memory-efficient applications

```bash
# Compare streaming vs one-shot performance
v run examples/streaming_example.v -f path/to/large_file.txt -i 100

# Test different chunk sizes
v run examples/streaming_example.v -f large_file.txt -c 16384 -i 50
```

**Key insights provided**:
- Performance impact of chunk size selection
- Memory usage patterns of different approaches
- When streaming outperforms one-shot (and vice versa)
- Algorithm-specific performance characteristics

### 3. Performance Benchmark (`benchmark.v`)

**Purpose**: Comprehensive performance analysis and optimization

**Demonstrates**:
- Statistical performance analysis (min/max/avg)
- Chunk size optimization for streaming
- Algorithm performance comparison
- Optimal configuration recommendation

**When to use this example**:
- Selecting the best algorithm for your hardware
- Optimizing streaming performance
- Understanding performance characteristics
- Making data-driven configuration decisions

```bash
# Find optimal chunk size for a file
v run examples/benchmark.v find-best-chunk -f path/to/file.txt -i 20 -a xxh3_64

# Run comprehensive benchmark
v run examples/benchmark.v -f file.txt -i 100 -a xxh3_64,xxh64
```

**Advanced features**:
- Automatic chunk size optimization
- Performance ranking and recommendations
- Memory-efficient vs speed trade-off analysis
- Production-ready performance testing methodology

### 4. CLI Tool (`hash_tool.v`)

**Purpose**: Production-ready command-line tool implementation

**Demonstrates**:
- Real-world application design patterns
- CLI interface implementation with V's `cli` module
- Error handling and user experience
- Custom seed support for reproducible hashing

**When to use this example**:
- Building production tools with vxxhash
- Learning CLI application patterns
- Understanding proper error handling
- Implementing custom seeding strategies

```bash
# Hash a file with specific algorithm and seed
v run examples/hash_tool.v hash -f file.txt -a xxh3_64 -s 42

# Benchmark all algorithms
v run examples/hash_tool.v benchmark -f file.txt -i 100
```

**Production features**:
- Robust error handling and validation
- User-friendly command-line interface
- Performance benchmarking capabilities
- Extensible design patterns

## vxxhash Module Guide

### Algorithm Selection Guide

| Algorithm | Hash Size | Speed | Use Case | Recommendation |
|-----------|-----------|-------|----------|----------------|
| **XXH32** | 32-bit | Fastest | Legacy compatibility, hash tables | Use only if 32-bit required |
| **XXH64** | 64-bit | Very Fast | General purpose, good balance | Excellent default choice |
| **XXH3-64** | 64-bit | Fastest | Modern systems, new code | **Recommended for most use cases** |
| **XXH3-128** | 128-bit | Fast | High security, collision resistance | Use when collision resistance critical |

### Performance Optimization

#### When to Use One-shot Hashing:
- Small to medium files (< 10MB)
- Data already in memory
- Maximum speed required
- Simple implementation preferred

```v
// Simple one-shot hashing
hash := vxxhash.xxh3_hash(data.bytes(), 0)
```

#### When to Use Streaming Hashing:
- Large files (> 10MB)
- Memory-constrained environments
- Network streams or real-time data
- When data arrives incrementally

```v
// Memory-efficient streaming hashing
mut hasher := vxxhash.new_xxhasher(.xxh3_64, 0)!
defer { hasher.free() }

for chunk in data_chunks {
    hasher.update(chunk)!
}
result := hasher.digest()!
```

#### Chunk Size Optimization:
- **Too small** (< 4KB): Excessive function call overhead
- **Too large** (> 1MB): Memory inefficiency, cache misses
- **Optimal**: 4KB - 256KB (use `find-best-chunk` to determine)

### Memory Usage Patterns

| Approach | Memory Usage | Speed | Best For |
|----------|---------------|-------|-----------|
| One-shot | O(file size) | Fastest | Small files, ample memory |
| Streaming | O(chunk size) | Fast | Large files, memory constraints |

### Error Handling Best Practices

All examples demonstrate proper error handling:

```v
// Always handle hasher creation errors
mut hasher := vxxhash.new_xxhasher(.xxh3_64, 0) or {
    return error('Failed to create hasher: ${err}')
}
defer { hasher.free() } // Always free resources

// Handle update errors in streaming
hasher.update(chunk) or {
    return error('Hash update failed: ${err}')
}

// Handle digest errors
result := hasher.digest() or {
    return error('Digest computation failed: ${err}')
}
```

## Running Examples

### Prerequisites
Make sure you're in the vxxhash module directory:

```bash
cd /path/to/vxxhash
```

### Quick Start

```bash
# Basic hashing demonstration
v run examples/hash_example.v -f examples/hash_example.v

# Performance comparison
v run examples/streaming_example.v -f examples/streaming_example.v -i 10

# Find optimal chunk size
v run examples/benchmark.v find-best-chunk -f examples/benchmark.v -i 5

# Use as CLI tool
v run examples/hash_tool.v hash -f examples/hash_tool.v -a xxh3_64
```

### Building Executables

For better performance, build the examples:

```bash
# Build individual examples
v build examples/hash_example.v
v build examples/benchmark.v
v build examples/hash_tool.v

# Run built executables
./hash_example -f your_file.txt
./benchmark find-best-chunk -f your_file.txt
./hash_tool hash -f your_file.txt -a xxh3_64
```

### Testing with Sample Data

Create test files for experimentation:

```bash
# Create test files of different sizes
echo "Hello World" > small.txt
dd if=/dev/zero of=medium.bin bs=1M count=10  # 10MB file
dd if=/dev/zero of=large.bin bs=1M count=100   # 100MB file

# Test with different file sizes
v run examples/benchmark.v find-best-chunk -f small.txt -i 20
v run examples/benchmark.v find-best-chunk -f medium.bin -i 10
v run examples/benchmark.v find-best-chunk -f large.bin -i 5
```

## Learning Path

1. **Start with `hash_example.v`** - Learn basic APIs and concepts
2. **Try `streaming_example.v`** - Understand performance trade-offs  
3. **Use `benchmark.v`** - Optimize for your specific use case
4. **Study `hash_tool.v`** - Learn production implementation patterns

Each example builds on concepts from the previous ones, providing a complete understanding of the vxxhash module's capabilities and best practices.

---

## Credits

This documentation and examples were enhanced with comprehensive comments and explanations using **OpenCode** - the AI-powered development assistant that helps write better code, documentation, and examples.

OpenCode assisted in:
- Adding detailed API documentation and usage explanations
- Creating comprehensive learning paths and best practices
- Providing real-world use case scenarios and performance insights
- Structuring examples for optimal learning and reference

**Learn more about OpenCode at: [opencode.ai](https://opencode.ai)**