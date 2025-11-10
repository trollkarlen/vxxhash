# V xxHash Examples

This directory contains example programs demonstrating the vxxhash module.

## Examples

### 1. Basic Hash Example (`hash_example.v`)

A simple example showing how to hash files using all available algorithms.

```bash
v run hash_example.v path/to/file.txt
```

Features:
- Demonstrates all four hash algorithms (XXH32, XXH64, XXH3-64, XXH3-128)
- Shows both one-shot and streaming approaches
- Compares results to verify correctness

### 2. Streaming Example (`streaming_example.v`)

Demonstrates streaming hash calculation for large files.

```bash
v run streaming_example.v path/to/large_file.txt
```

Features:
- Processes files in 8KB chunks
- Shows performance metrics (throughput)
- Compares streaming vs one-shot performance
- Works with all hash algorithms

### 3. Performance Benchmark (`benchmark.v`)

Comprehensive performance comparison between algorithms.

```bash
v run benchmark.v path/to/file.txt 100
```

Features:
- Runs multiple iterations for statistical accuracy
- Shows min/max/average times
- Calculates throughput in MB/s
- Compares one-shot vs streaming performance
- Displays hash results for verification

### 4. CLI Tool (`hash_tool.v`)

Command-line tool for file hashing and benchmarking.

```bash
# Hash a file with specific algorithm
v run hash_tool.v hash -f file.txt -a xxh3_64 -s 42

# Benchmark all algorithms on a file
v run hash_tool.v benchmark -f file.txt -i 10
```

Features:
- CLI interface using V's `cli` module
- Support for all algorithms
- Custom seed support
- Built-in benchmarking mode

## Usage Notes

1. **Algorithm Selection**:
   - `xxh32`: 32-bit hash, good for legacy systems
   - `xxh64`: 64-bit hash, good balance of speed and size
   - `xxh3_64`: Modern 64-bit hash, fastest for most cases
   - `xxh3_128`: 128-bit hash, highest collision resistance

2. **Performance Tips**:
   - Use `xxh3_64` for best performance on modern systems
   - Streaming is useful for large files (>1MB)
   - One-shot is faster for small files (<1MB)

3. **Memory Usage**:
   - Streaming uses constant memory regardless of file size
   - One-shot loads entire file into memory

## Running Examples

Make sure you're in the vxxhash module directory:

```bash
cd /path/to/vxxhash
v run examples/hash_example.v your_file.txt
```

Or build and run:

```bash
v build examples/hash_example.v
./hash_example your_file.txt
```