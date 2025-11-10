# V xxHash Module

A fast V language wrapper for the xxHash non-cryptographic hash library.

## Features

- Support for XXH32, XXH64, and XXH3-64 algorithms
- Streaming and one-shot hashing
- Unified digest function that returns appropriate size based on algorithm
- Built-in hex string conversion
- Easy-to-use API

## Installation

1. Install xxHash system library:
   ```bash
   # macOS with Homebrew
   brew install xxhash
   
   # Linux with apt
   sudo apt-get install libxxhash-dev
   ```

2. Copy the `vxxhash` module to your project or add it to your V module path.

## Usage

### One-shot Hashing

```v
import vxxhash

data := "Hello World".bytes()

// 32-bit hash
hash32 := vxxhash.xxh32_hash_hex_default(data)
println("XXH32: ${hash32}")

// 64-bit hash  
hash64 := vxxhash.xxh64_hash_hex_default(data)
println("XXH64: ${hash64}")

// XXH3 64-bit hash
hash3_64 := vxxhash.xxh3_hash_hex_default(data)
println("XXH3-64: ${hash3_64}")
```

### Streaming Hashing

```v
import vxxhash

// Create hasher
mut hasher := vxxhash.new_xxhasher_default(.xxh3_64) or { panic(err) }
defer { hasher.free() }

// Update with data
hasher.update("Hello ".bytes())!
hasher.update("World".bytes())!

// Get digest as hex string
hash_hex := hasher.digest_hex()!
println("Hash: ${hash_hex}")

// Or get structured result
result := hasher.digest()!
println("64-bit: ${result.hash_64:x}")
```

### Algorithm Selection

```v
import vxxhash

algorithms := [
    vxxhash.DigestAlgorithm.xxh32,
    vxxhash.DigestAlgorithm.xxh64, 
    vxxhash.DigestAlgorithm.xxh3_64,
]

for algorithm in algorithms {
    mut hasher := vxxhash.new_xxhasher(algorithm, 0)!
    defer { hasher.free() }
    
    hasher.update("test data".bytes())!
    hash_hex := hasher.digest_hex()!
    println("${algorithm}: ${hash_hex}")
}
```

## API Reference

### Enums

- `DigestAlgorithm`: Available hash algorithms
  - `.xxh32`: 32-bit hash
  - `.xxh64`: 64-bit hash  
  - `.xxh3_64`: XXH3 64-bit (recommended)
  - `.xxh3_128`: XXH3 128-bit (future)

### Structs

- `XXHasher`: Streaming hasher state
- `HashResult`: Unified digest result containing all formats
- `Hash128`: 128-bit hash structure

### Functions

#### One-shot Functions
- `xxh32_hash(data []u8, seed u64) u32`
- `xxh64_hash(data []u8, seed u64) u64`
- `xxh3_hash(data []u8, seed u64) u64`
- `xxh32_hash_hex_default(data []u8) string`
- `xxh64_hash_hex_default(data []u8) string`
- `xxh3_hash_hex_default(data []u8) string`

#### Streaming Functions
- `new_xxhasher(algorithm DigestAlgorithm, seed u64) !XXHasher`
- `new_xxhasher_default(algorithm DigestAlgorithm) !XXHasher`
- `(mut hasher) update(data []u8) !`
- `(hasher) digest() !HashResult`
- `(hasher) digest_hex() !string`
- `(mut hasher) reset() !`
- `(mut hasher) free()`

## Examples

See the `examples/` directory for complete working examples:
- `hash_example.v`: Basic usage
- `streaming_example.v`: Streaming vs one-shot comparison
- `benchmark.v`: Performance testing
- `hash_tool.v`: CLI tool

## Performance

xxHash is extremely fast, capable of hashing at RAM speed limits. XXH3-64 is the recommended algorithm for best performance on modern systems.

## License

This wrapper follows the same BSD 2-Clause license as xxHash.