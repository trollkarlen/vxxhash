# vxxhash - V Language xxHash Bindings

[![CI](https://github.com/yourusername/vxxhash/workflows/CI/badge.svg)](https://github.com/yourusername/vxxhash/actions)
[![License](https://img.shields.io/badge/License-BSD%202--Clause-blue.svg)](https://opensource.org/licenses/BSD-2-Clause)

A high-performance V language wrapper for the [xxHash](https://github.com/Cyan4973/xxHash) non-cryptographic hash library.

## Overview

xxHash is an extremely fast hash algorithm working at RAM speed limits. This module provides complete V bindings with support for all xxHash variants:

- **XXH32**: 32-bit hash (fastest on 32-bit systems)
- **XXH64**: 64-bit hash (good balance of speed and quality)
- **XXH3-64**: XXH3 64-bit (default choice - fastest on 64-bit systems)
- **XXH3-128**: XXH3 128-bit (provides 128-bit hash space)

## Features

✅ **Complete API Coverage**: All xxHash algorithms and functions  
✅ **Streaming & One-shot**: Both streaming and single-call hashing  
✅ **Type-safe**: Full V language type safety and error handling  
✅ **Performance Optimized**: Minimal overhead, direct C library calls  
✅ **Cross-platform**: Works on Linux, macOS, and Windows  
✅ **Well Documented**: Comprehensive documentation and examples  
✅ **Tested**: Extensive test suite with CI/CD pipeline  

## Quick Start

### Installation

1. **Install xxHash system library**:
   ```bash
   # macOS with Homebrew
   brew install xxhash
   
   # Ubuntu/Debian
   sudo apt-get install libxxhash-dev
   
   # Fedora/CentOS
   sudo dnf install xxhash-devel
   
   # Alpine
   sudo apk add xxhash-dev
   ```

2. **Add to your V project**:
   ```bash
   # Clone this repository
   git clone https://github.com/yourusername/vxxhash.git
   cd vxxhash
   
   # Or add as submodule
   git submodule add https://github.com/yourusername/vxxhash.git
   ```

### Basic Usage

```v
import vxxhash

fn main() {
    data := "Hello, World!".bytes()
    
    // One-shot hashing (recommended for most cases)
    hash_64 := vxxhash.xxh3_hash_hex_default(data)
    println("XXH3-64: ${hash_64}")
    
    // Streaming hashing (for large data)
    mut hasher := vxxhash.new_xxhasher_default(.xxh3_64) or { panic(err) }
    defer { hasher.free() }
    
    hasher.update("Hello, ".bytes())!
    hasher.update("World!".bytes())!
    
    result := hasher.digest()!
    println("Streaming: ${result.hash_64:x}")
}
```

## Usage Examples

### One-shot Hashing

Perfect for when you have all the data available at once:

```v
import vxxhash

fn main() {
    data := "Hello World".bytes()
    
    // Different algorithms
    hash32 := vxxhash.xxh32_hash_hex_default(data)
    hash64 := vxxhash.xxh64_hash_hex_default(data)
    hash3_64 := vxxhash.xxh3_hash_hex_default(data)
    
    println("XXH32:   ${hash32}")
    println("XXH64:   ${hash64}")
    println("XXH3-64: ${hash3_64}")
    
    // With custom seed
    hash_seeded := vxxhash.xxh3_hash_hex(data, 42)
    println("Seeded:  ${hash_seeded}")
}
```

### Streaming Hashing

Ideal for large files or streaming data:

```v
import vxxhash
import os

fn main() {
    // Create hasher with algorithm and seed
    mut hasher := vxxhash.new_xxhasher(.xxh3_64, 0) or { panic(err) }
    defer { hasher.free() }  // Important: free memory when done
    
    // Process data in chunks
    chunks := [
        "Hello, ",
        "World!",
        " This is ",
        "streaming."
    ]
    
    for chunk in chunks {
        hasher.update(chunk.bytes())!
    }
    
    // Get results
    result := hasher.digest()!
    println("32-bit:  ${result.hash_32:x}")
    println("64-bit:  ${result.hash_64:x}")
    println("128-bit: ${result.hex_128()}")
    
    // Reuse hasher for new data
    hasher.reset()!
    hasher.update("New data".bytes())!
    new_result := hasher.digest()!
    println("New hash: ${new_result.hash_64:x}")
}
```

### File Hashing

```v
import vxxhash
import os

fn hash_file(file_path string) !string {
    mut hasher := vxxhash.new_xxhasher_default(.xxh3_64)!
    defer { hasher.free() }
    
    // Read file in chunks
    mut file := os.open(file_path) or { return err }
    defer { file.close() }
    
    mut buf := []u8{len: 8192}
    for {
        bytes_read := file.read(mut buf) or { break }
        if bytes_read == 0 { break }
        hasher.update(buf[..bytes_read])!
    }
    
    return hasher.digest_hex()!
}

fn main() {
    hash := hash_file("example.txt") or { panic(err) }
    println("File hash: ${hash}")
}
```

### Hash Comparison

```v
import vxxhash

fn main() {
    data := "test data".bytes()
    
    // Get structured result for comparison
    result1 := vxxhash.new_xxhasher_default(.xxh3_64) or { panic(err) }
    defer { result1.free() }
    result1.update(data)!
    hash1 := result1.digest()!
    
    result2 := vxxhash.new_xxhasher_default(.xxh3_64) or { panic(err) }
    defer { result2.free() }
    result2.update(data)!
    hash2 := result2.digest()!
    
    // Compare results
    if hash1 == hash2 {
        println("Hashes match!")
    }
    
    // Check specific parts
    if hash1.equals_64(hash2) {
        println("64-bit hashes match")
    }
    
    // String representation
    println("Full result: ${hash1}")
}
```

## API Reference

### Enums

#### `DigestAlgorithm`
Available hash algorithms:
- `.xxh32`: 32-bit hash (fastest on 32-bit systems)
- `.xxh64`: 64-bit hash (good balance of speed and quality)
- `.xxh3_64`: XXH3 64-bit (default choice - fastest on 64-bit systems)
- `.xxh3_128`: XXH3 128-bit (provides 128-bit hash space)

### Structs

#### `XXHasher`
Streaming hasher state machine:
```v
pub struct XXHasher {
mut:
    algorithm DigestAlgorithm
    state     voidptr  // Internal C state
    seed      u64
}
```

#### `HashResult`
Unified digest result containing all hash formats:
```v
pub struct HashResult {
pub:
    hash_32  u32     // 32-bit hash value
    hash_64  u64     // 64-bit hash value
    hash_128 Hash128 // 128-bit hash value
}
```

#### `Hash128`
128-bit hash representation:
```v
pub struct Hash128 {
pub:
    low  u64  // Lower 64 bits
    high u64  // Higher 64 bits
}
```

### One-shot Functions

#### Basic Hashing
```v
fn xxh32_hash(data []u8, seed u64) u32
fn xxh64_hash(data []u8, seed u64) u64
fn xxh3_hash(data []u8, seed u64) u64
```

#### Default Seed (0)
```v
fn xxh32_hash_default(data []u8) u32
fn xxh64_hash_default(data []u8) u64
fn xxh3_hash_default(data []u8) u64
```

#### Hex String Output
```v
fn xxh32_hash_hex(data []u8, seed u64) string
fn xxh64_hash_hex(data []u8, seed u64) string
fn xxh3_hash_hex(data []u8, seed u64) string

fn xxh32_hash_hex_default(data []u8) string
fn xxh64_hash_hex_default(data []u8) string
fn xxh3_hash_hex_default(data []u8) string
```

### Streaming Functions

#### Hasher Creation
```v
fn new_xxhasher(algorithm DigestAlgorithm, seed u64) !XXHasher
fn new_xxhasher_default(algorithm DigestAlgorithm) !XXHasher
```

#### Hasher Operations
```v
fn (mut h XXHasher) update(data []u8) !
fn (h &XXHasher) digest() !HashResult
fn (h &XXHasher) digest_hex() !string
fn (mut h XXHasher) reset() !
fn (mut h XXHasher) free()
```

### HashResult Methods

#### Comparison
```v
fn (h HashResult) is_equal(other HashResult) bool
fn (h HashResult) equals_32(other HashResult) bool
fn (h HashHash) equals_64(other HashResult) bool
fn (h HashResult) equals_128(other HashResult) bool
fn (h HashResult) == (other HashResult) bool  // Operator overload
```

#### Utilities
```v
fn (h HashResult) is_zero() bool
fn (h HashResult) is_zero_128() bool
fn (h HashResult) hex_128() string
fn (h HashResult) str() string
```

### Library Information
```v
fn xxh_version_number() u32  // Get xxHash library version
```

## Examples

The `examples/` directory contains comprehensive examples:

- **`hash_example.v`**: Basic usage demonstration
- **`streaming_example.v`**: Streaming vs one-shot performance comparison
- **`benchmark.v`**: Comprehensive performance benchmarking
- **`hash_tool.v`**: Full-featured CLI hashing tool

Run examples:
```bash
# Basic usage
v run examples/hash_example.v -d "Hello World"

# Performance comparison
v run examples/streaming_example.v -f large_file.txt

# Benchmarking
v run examples/benchmark.v -f test_file.txt -i 1000

# CLI tool
v run examples/hash_tool.v hash -f file.txt -a xxh3_64
```

## Testing

Run the complete test suite:

```bash
# Run all tests
./scripts/test.sh

# Run with performance benchmarks
./scripts/test.sh --performance

# Test in Docker containers
./scripts/docker-test.sh --all

# Test specific Docker image
./scripts/docker-test.sh ubuntu:22.04
```

## Performance

xxHash is designed for maximum speed:

- **XXH3-64**: ~10-15 GB/s on modern CPUs (recommended)
- **XXH64**: ~8-12 GB/s (good compatibility)
- **XXH32**: ~6-10 GB/s (32-bit optimized)

Performance varies by CPU architecture and data size. XXH3-64 is typically the fastest choice on 64-bit systems.

## CI/CD

This project includes comprehensive CI/CD pipelines:

- **GitHub Actions**: Tests on Ubuntu, macOS, and Windows
- **GitLab CI**: Additional Linux distribution testing
- **Docker Testing**: Multi-distribution container testing

The pipelines automatically test:
- Module compilation
- Unit tests (25+ assertions)
- Example functionality
- Cross-platform compatibility

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes and add tests
4. Run the test suite: `./scripts/test.sh`
5. Submit a pull request

## License

This project follows the same BSD 2-Clause license as xxHash:

```
Copyright (c) 2024 vxxhash contributors

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

## Acknowledgments

- [xxHash](https://github.com/Cyan4973/xxHash) by Yann Collet - The foundation of this module
- [V Language](https://github.com/vlang/v) community - For the excellent language and ecosystem
- **OpenCode** - AI-powered development assistant that helped enhance the documentation and examples with comprehensive comments, usage explanations, and best practices. OpenCode assisted in creating detailed API documentation, learning paths, and real-world use case scenarios to make the vxxhash module more accessible and well-documented.
- All contributors and testers for their valuable feedback and improvements