// vxxhash - V language bindings for xxHash library
//
// xxHash is an extremely fast non-cryptographic hash algorithm
// working at RAM speed limits. It provides four variants:
// - XXH32: 32-bit hash
// - XXH64: 64-bit hash
// - XXH3_64: XXH3 64-bit (default, fastest)
// - XXH3_128: XXH3 128-bit
//
// This module provides both one-shot and streaming APIs
// with support for all xxHash algorithms.
//
// Author: vxxhash contributors
// License: Same as xxHash (BSD 2-Clause)
// Version: 0.1.0

module vxxhash

// Link flags for xxHash library
// Platform-specific paths for xxHash installation

// Windows (chocolatey installation)
#flag windows -IC:/ProgramData/chocolatey/lib/xxhash/tools/include
#flag windows -LC:/ProgramData/chocolatey/lib/xxhash/tools/lib

// macOS (Homebrew installation)
#flag darwin -I/opt/homebrew/opt/xxhash/include
#flag darwin -L/opt/homebrew/opt/xxhash/lib

// Linux (system package manager)
#flag linux -I/usr/include
#flag linux -L/usr/lib/x86_64-linux-gnu

// Fallback for other Unix-like systems
#flag freebsd -I/usr/local/include
#flag freebsd -L/usr/local/lib

// Default fallback
#flag -lxxhash

#include <xxhash.h>

// Type alias for C size_t
type Size_t = u64

// C function declarations from xxHash library
// These provide direct access to the underlying xxHash C API

// One-shot hash functions
fn C.XXH_versionNumber() u32
fn C.XXH32(voidptr, Size_t, u32) u32
fn C.XXH64(voidptr, Size_t, u64) u64
fn C.XXH3_64bits_withSeed(voidptr, Size_t, u64) u64

// XXH32 streaming functions
fn C.XXH32_createState() voidptr
fn C.XXH32_freeState(voidptr) int
fn C.XXH32_reset(voidptr, u32) int
fn C.XXH32_update(voidptr, voidptr, Size_t) int
fn C.XXH32_digest(voidptr) u32

// XXH64 streaming functions
fn C.XXH64_createState() voidptr
fn C.XXH64_freeState(voidptr) int
fn C.XXH64_reset(voidptr, u64) int
fn C.XXH64_update(voidptr, voidptr, Size_t) int
fn C.XXH64_digest(voidptr) u64

// XXH3 streaming functions
fn C.XXH3_createState() voidptr
fn C.XXH3_freeState(voidptr) int
fn C.XXH3_64bits_reset_withSeed(voidptr, u64) int
fn C.XXH3_64bits_update(voidptr, voidptr, Size_t) int
fn C.XXH3_64bits_digest(voidptr) u64

// XXH3 128-bit streaming functions
fn C.XXH3_128bits_reset_withSeed(voidptr, u64) int
fn C.XXH3_128bits_update(voidptr, voidptr, Size_t) int

// XXH128_hash_t structure for 128-bit hash results
type C.XXH128_hash_t = struct {
	low64  u64
	high64 u64
}

// XXH3 128-bit digest function
fn C.XXH3_128bits_digest(voidptr) C.XXH128_hash_t

// XXH3 128-bit one-shot function
fn C.XXH3_128bits_withSeed(voidptr, Size_t, u64) C.XXH128_hash_t

// DigestAlgorithm represents the available xxHash algorithms
//
// Each algorithm offers different trade-offs between speed, hash size, and collision resistance:
//
// PERFORMANCE CHARACTERISTICS:
// - Speed (fastest to slowest): XXH3-64 > XXH64 > XXH32 > XXH3-128
// - Memory usage: All algorithms use minimal memory (few hundred bytes for state)
// - Collision resistance: 128-bit > 64-bit > 32-bit
//
// USAGE RECOMMENDATIONS:
// - Use XXH3-64 for most applications (best speed/quality balance)
// - Use XXH3-128 when collision resistance is critical
// - Use XXH32 only for 32-bit compatibility requirements
// - Use XXH64 for legacy systems or when XXH3 is unavailable
pub enum DigestAlgorithm {
	// 32-bit hash algorithm (XXH32)
	//
	// CHARACTERISTICS:
	// - Hash size: 32 bits (4 bytes)
	// - Speed: Fastest on 32-bit CPUs, moderate on 64-bit CPUs
	// - Collision probability: 1 in 2^32 (approximately 1 in 4.3 billion)
	// - Memory usage: ~64 bytes for internal state
	//
	// LIMITATIONS:
	// - Higher collision rate than 64-bit variants
	// - Not recommended for new applications unless 32-bit compatibility is required
	// - Not suitable for large datasets or security-sensitive applications
	//
	// USE CASES:
	// - Legacy systems requiring 32-bit hashes
	// - Hash tables where memory is critical
	// - Applications with small datasets
	xxh32

	// 64-bit hash algorithm (XXH64)
	//
	// CHARACTERISTICS:
	// - Hash size: 64 bits (8 bytes)
	// - Speed: Very fast on both 32-bit and 64-bit CPUs
	// - Collision probability: 1 in 2^64 (approximately 1 in 1.8×10^19)
	// - Memory usage: ~128 bytes for internal state
	//
	// LIMITATIONS:
	// - Slightly slower than XXH3-64 on modern CPUs
	// - May have different performance characteristics across architectures
	//
	// USE CASES:
	// - General-purpose hashing when XXH3 is not available
	// - Applications requiring good balance of speed and collision resistance
	// - Database indexing and deduplication
	xxh64

	// XXH3 64-bit hash algorithm
	//
	// CHARACTERISTICS:
	// - Hash size: 64 bits (8 bytes)
	// - Speed: Fastest on modern 64-bit CPUs (vectorized implementation)
	// - Collision probability: 1 in 2^64 (approximately 1 in 1.8×10^19)
	// - Memory usage: ~256 bytes for internal state
	// - Vectorized: Uses SIMD instructions when available (AVX2, SSE2, NEON)
	//
	// LIMITATIONS:
	// - Requires 64-bit CPU for optimal performance
	// - Slightly higher memory usage than XXH64
	// - Performance varies based on CPU SIMD support
	//
	// USE CASES:
	// - **RECOMMENDED DEFAULT** for most applications
	// - High-performance hashing on modern systems
	// - Large-scale data processing
	// - Real-time applications requiring maximum speed
	xxh3_64

	// XXH3 128-bit hash algorithm
	//
	// CHARACTERISTICS:
	// - Hash size: 128 bits (16 bytes)
	// - Speed: Fast, but slightly slower than XXH3-64 variant
	// - Collision probability: 1 in 2^128 (approximately 1 in 3.4×10^38)
	// - Memory usage: ~256 bytes for internal state
	// - Vectorized: Uses SIMD instructions when available
	//
	// LIMITATIONS:
	// - Slower than 64-bit variants (approximately 10-20% performance penalty)
	// - Larger hash size increases storage requirements
	// - Overkill for applications with modest collision requirements
	//
	// USE CASES:
	// - Applications requiring extremely low collision probability
	// - Cryptographic-adjacent applications (NOTE: NOT CRYPTOGRAPHICALLY SECURE)
	// - Content-addressable storage systems
	// - Distributed systems requiring global uniqueness
	xxh3_128
}

// XXHasher provides streaming hash functionality
//
// This struct enables incremental hashing of data in chunks, which is essential for:
// - Large files that don't fit in memory
// - Network streams or real-time data processing
// - Memory-constrained environments
// - When data arrives incrementally over time
//
// MEMORY USAGE:
// - XXH32: ~64 bytes internal state
// - XXH64: ~128 bytes internal state
// - XXH3 variants: ~256 bytes internal state
//
// THREAD SAFETY:
// - Each XXHasher instance is NOT thread-safe
// - Use separate instances per thread for parallel processing
// - The same instance can be reused sequentially after reset()
//
// LIFECYCLE:
// 1. Create with new_xxhasher() or new_xxhasher_default()
// 2. Call update() multiple times with data chunks
// 3. Call digest() to get final hash result
// 4. Optionally call reset() to reuse for new data
// 5. Call free() when done to release memory
pub struct XXHasher {
mut:
	// The hash algorithm being used
	// Determines which underlying xxHash functions are called
	// Cannot be changed after creation
	algorithm DigestAlgorithm

	// Internal state pointer (opaque C structure)
	// Contains algorithm-specific hashing state
	// Size varies by algorithm (64-256 bytes)
	// Managed by xxHash library, do not modify directly
	state voidptr

	// Seed value used for initialization
	// Affects hash output - same data with different seeds produces different hashes
	// Useful for versioning, salting, or avoiding hash collisions
	// Range: 0 to 2^64-1 (full u64 range)
	seed u64
}

// Hash128 represents a 128-bit hash value
//
// This structure provides a convenient way to work with 128-bit hashes
// while maintaining compatibility with 64-bit systems.
//
// REPRESENTATION:
// - The full 128-bit value is: (high << 64) | low
// - high contains the most significant 64 bits
// - low contains the least significant 64 bits
//
// USAGE NOTES:
// - For comparison, use the Hash128 struct directly
// - For display, use the hex_128() method
// - For storage, both fields can be serialized independently
//
// LIMITATIONS:
// - Only used by XXH3-128 algorithm
// - Other algorithms store their result in low field only (high = 0)
pub struct Hash128 {
pub:
	// Lower 64 bits of 128-bit hash
	// Contains the least significant 64 bits
	// Range: 0 to 2^64-1
	// For non-128-bit algorithms, this contains the entire hash
	low u64

	// Higher 64 bits of 128-bit hash
	// Contains the most significant 64 bits
	// Range: 0 to 2^64-1
	// For non-128-bit algorithms, this is always 0
	high u64
}

// HashType represents which algorithm was used to generate the hash
pub enum HashType {
	xxh32    // 32-bit xxHash algorithm
	xxh64    // 64-bit xxHash algorithm
	xxh3_64  // XXH3 64-bit algorithm
	xxh3_128 // XXH3 128-bit algorithm
}

// HashResult contains hash value with type information
//
// This struct provides a unified way to access hash values
// from different xxHash algorithms while being memory efficient.
// The hash_type indicates which algorithm was used and how to interpret hash_128.
pub struct HashResult {
pub:
	hash_type HashType // Which algorithm generated this hash
	hash_128  Hash128  // Hash value storage
	// For xxh32/xxh64/xxh3_64: hash_128.low contains the hash, hash_128.high = 0
	// For xxh3_128: hash_128 contains the full 128-bit hash
}

// HashResult type checking methods

// Get the hash type
pub fn (h HashResult) type() HashType {
	return h.hash_type
}

// Check if hash type is xxh32
pub fn (h HashResult) is_xxh32() bool {
	return h.hash_type == .xxh32
}

// Check if hash type is xxh64
pub fn (h HashResult) is_xxh64() bool {
	return h.hash_type == .xxh64
}

// Check if hash type is xxh3_64
pub fn (h HashResult) is_xxh3_64() bool {
	return h.hash_type == .xxh3_64
}

// Check if hash type is xxh3_128
pub fn (h HashResult) is_xxh3_128() bool {
	return h.hash_type == .xxh3_128
}

// Get raw hash value based on type
pub fn (h HashResult) get_hash() u64 {
	return h.hash_128.low
}

// Get 128-bit hash value (for xxh3_128)
pub fn (h HashResult) get_hash_128() Hash128 {
	return h.hash_128
}

// HashResult comparison methods

// Check if hash results are equal
pub fn (h HashResult) is_equal(other HashResult) bool {
	return h.hash_type == other.hash_type && h.hash_128.low == other.hash_128.low
		&& h.hash_128.high == other.hash_128.high
}

// Check if hash is zero
pub fn (h HashResult) is_zero() bool {
	return h.hash_128.low == 0 && h.hash_128.high == 0
}

// Get hash as hex string based on type
pub fn (h HashResult) hex() string {
	return match h.hash_type {
		.xxh32 { u64_to_hex(h.hash_128.low, 8) }
		.xxh64 { u64_to_hex(h.hash_128.low, 16) }
		.xxh3_64 { u64_to_hex(h.hash_128.low, 16) }
		.xxh3_128 { u64_to_hex(h.hash_128.high, 16) + u64_to_hex(h.hash_128.low, 16) }
	}
}

// String representation of hash values
pub fn (h HashResult) str() string {
	return match h.hash_type {
		.xxh32 { 'HashResult{type:xxh32 hash:0x${u32(h.hash_128.low):x}}' }
		.xxh64 { 'HashResult{type:xxh64 hash:0x${h.hash_128.low:x}}' }
		.xxh3_64 { 'HashResult{type:xxh3_64 hash:0x${h.hash_128.low:x}}' }
		.xxh3_128 { 'HashResult{type:xxh3_128 hash:0x${h.hash_128.high:x}${h.hash_128.low:x}}' }
	}
}

// Support == operator for HashResult
pub fn (h HashResult) == (other HashResult) bool {
	return h.is_equal(other)
}

// new_xxhasher creates a new streaming hasher with specified algorithm and seed
//
// This function allocates memory for the hasher's internal state and initializes
// it with the specified algorithm and seed. The hasher can then be used for
// incremental hashing of data chunks.
//
// PARAMETERS:
//   algorithm: The hash algorithm to use
//     - .xxh32: 32-bit hash, fastest on 32-bit systems
//     - .xxh64: 64-bit hash, good speed/quality balance
//     - .xxh3_64: 64-bit hash, fastest on modern 64-bit systems (RECOMMENDED)
//     - .xxh3_128: 128-bit hash, highest collision resistance
//
//   seed: Seed value for hash initialization
//     - Range: 0 to 2^64-1 (full u64 range)
//     - Use 0 for default/standard seeding
//     - Different seeds produce different hashes for same data
//     - Useful for versioning, salting, or collision avoidance
//
// RETURN VALUE:
//   XXHasher instance ready for streaming updates
//   - Returns error if memory allocation fails
//   - Returns error if algorithm initialization fails
//
// MEMORY USAGE:
//   - XXH32: ~64 bytes allocated
//   - XXH64: ~128 bytes allocated
//   - XXH3 variants: ~256 bytes allocated
//
// ERROR CONDITIONS:
//   - Out of memory: System cannot allocate hasher state
//   - Invalid algorithm: Should never happen with enum values
//
// EXAMPLE:
//   ```
//   mut hasher := new_xxhasher(.xxh3_64, 42)!
//   defer { hasher.free() } // Important: prevent memory leak
//
//   hasher.update("hello".bytes())!
//   hasher.update(" world".bytes())!
//   result := hasher.digest()!
//   println("Hash: ${result.hex()}")
//   ```
//
// THREAD SAFETY:
//   - Each hasher instance is NOT thread-safe
//   - Create separate instances for parallel processing
//   - Same instance can be reused sequentially with reset()
pub fn new_xxhasher(algorithm DigestAlgorithm, seed u64) !XXHasher {
	mut hasher := XXHasher{
		algorithm: algorithm
		seed:      seed
		state:     unsafe { nil }
	}

	match algorithm {
		.xxh32 {
			hasher.state = C.XXH32_createState()
			if hasher.state == unsafe { nil } {
				return error('Failed to create XXH32 state')
			}
			if C.XXH32_reset(hasher.state, u32(seed)) != 0 {
				return error('Failed to reset XXH32 state')
			}
		}
		.xxh64 {
			hasher.state = C.XXH64_createState()
			if hasher.state == unsafe { nil } {
				return error('Failed to create XXH64 state')
			}
			if C.XXH64_reset(hasher.state, seed) != 0 {
				return error('Failed to reset XXH64 state')
			}
		}
		.xxh3_64 {
			hasher.state = C.XXH3_createState()
			if hasher.state == unsafe { nil } {
				return error('Failed to create XXH3 state')
			}
			if C.XXH3_64bits_reset_withSeed(hasher.state, seed) != 0 {
				return error('Failed to reset XXH3 state')
			}
		}
		.xxh3_128 {
			hasher.state = C.XXH3_createState()
			if hasher.state == unsafe { nil } {
				return error('Failed to create XXH3 state')
			}
			// Use the proper 128-bit reset function
			if C.XXH3_128bits_reset_withSeed(hasher.state, seed) != 0 {
				return error('Failed to reset XXH3-128 state')
			}
		}
	}

	return hasher
}

// update adds more data to the streaming hash computation
//
// This method processes the provided data chunk and updates the internal
// hashing state. It can be called multiple times to process data
// incrementally, which is essential for large files or streaming data.
//
// PARAMETERS:
//   data: Byte slice containing data to add to hash
//     - Can be empty (no effect on hash)
//     - Can be any size up to available memory
//     - Empty slices are ignored (no state change)
//     - Large chunks are processed efficiently
//
// PERFORMANCE CONSIDERATIONS:
//   - Chunk size affects performance:
//     * Too small (< 1KB): High function call overhead
//     * Too large (> 1MB): May cause cache misses
//     * Optimal: 4KB to 256KB (use benchmark.v to find optimal)
//   - Total data size is unlimited (streaming nature)
//   - Memory usage remains constant regardless of total data processed
//
// ERROR CONDITIONS:
//   - Hasher not initialized: Returns error if state is nil
//   - Internal xxHash error: Rare, indicates library issue
//
// THREAD SAFETY:
//   - NOT thread-safe for concurrent calls on same instance
//   - Safe for sequential calls from any thread
//   - Use separate hashers for parallel processing
//
// EXAMPLE:
//   ```
//   mut hasher := new_xxhasher_default(.xxh3_64)!
//   defer { hasher.free() }
//
//   // Process file in 8KB chunks
//   chunk_size := 8192
//   for offset := 0; offset < file_data.len; offset += chunk_size {
//       end := offset + chunk_size
//       if end > file_data.len { end = file_data.len }
//
//       hasher.update(file_data[offset..end])!
//   }
//
//   result := hasher.digest()!
//   ```
//
// LIMITATIONS:
//   - Cannot be called after free() has been called
//   - Data must be valid for the duration of the call
//   - Very large chunks (> 2GB) may cause issues on some systems
pub fn (mut h XXHasher) update(data []u8) ! {
    if h.state == unsafe { nil } {
        return error('Hasher not initialized')
    }

	unsafe {
		match h.algorithm {
			.xxh32 {
				if C.XXH32_update(h.state, data.data, u64(data.len)) != 0 {
					return error('Failed to update XXH32')
				}
			}
			.xxh64 {
				if C.XXH64_update(h.state, data.data, u64(data.len)) != 0 {
					return error('Failed to update XXH64')
				}
			}
			.xxh3_64 {
				if C.XXH3_64bits_update(h.state, data.data, u64(data.len)) != 0 {
					return error('Failed to update XXH3')
				}
			}
			.xxh3_128 {
				if C.XXH3_128bits_update(h.state, data.data, u64(data.len)) != 0 {
					return error('Failed to update XXH3-128')
				}
			}
		}
	}
}

// digest computes the final hash value for all streamed data
//
// This method finalizes the hash computation using all data that has been
// fed to the hasher via update() calls. The result contains the hash
// value in a format appropriate for the selected algorithm.
//
// RETURN VALUE:
//   HashResult containing the computed hash:
//   - For XXH32: 32-bit hash in hash_128.low, hash_128.high = 0
//   - For XXH64: 64-bit hash in hash_128.low, hash_128.high = 0
//   - For XXH3-64: 64-bit hash in hash_128.low, hash_128.high = 0
//   - For XXH3-128: Full 128-bit hash in both hash_128.low and hash_128.high
//
// HASH RESULT PROPERTIES:
//   - Deterministic: Same data + seed always produces same hash
//   - Avalanche effect: Small input changes cause large output changes
//   - Uniform distribution: Hash values are evenly distributed
//   - Fixed size: Output size depends only on algorithm, not input size
//
// ERROR CONDITIONS:
//   - Hasher not initialized: Returns error if state is nil
//   - Internal xxHash error: Rare, indicates library corruption
//
// POST-DIGEST BEHAVIOR:
//   - Hasher state remains valid and can be reused
//   - Can call reset() to start fresh computation with same seed
//   - Can continue update() calls to extend current hash (not recommended)
//   - Can call digest() again (returns same result)
//
// THREAD SAFETY:
//   - Safe to call from any thread that has exclusive access
//   - NOT thread-safe for concurrent calls
//   - Result can be safely shared between threads
//
// EXAMPLE:
//   ```
//   mut hasher := new_xxhasher(.xxh3_64, 0)!
//   defer { hasher.free() }
//
//   hasher.update("Hello, ".bytes())!
//   hasher.update("World!".bytes())!
//
//   result := hasher.digest()!
//   println("Hash: ${result.hex()}")  // 64-bit hex string
//   println("Type: ${result.type()}")   // .xxh3_64
//   println("Value: ${result.get_hash():x}") // Raw u64 value
//   ```
//
// PERFORMANCE:
//   - O(1) operation - constant time regardless of data size
//   - Uses finalization step specific to each algorithm
//   - No additional memory allocation
//   - Cache-friendly operation
pub fn (h &XXHasher) digest() !HashResult {
	if h.state == unsafe { nil } {
		return error('Hasher not initialized')
	}

	unsafe {
		match h.algorithm {
			.xxh32 {
				hash32 := C.XXH32_digest(h.state)
				return HashResult{
					hash_type: .xxh32
					hash_128:  Hash128{
						low:  u64(hash32)
						high: 0
					}
				}
			}
			.xxh64 {
				hash64 := C.XXH64_digest(h.state)
				return HashResult{
					hash_type: .xxh64
					hash_128:  Hash128{
						low:  hash64
						high: 0
					}
				}
			}
			.xxh3_64 {
				hash64 := C.XXH3_64bits_digest(h.state)
				return HashResult{
					hash_type: .xxh3_64
					hash_128:  Hash128{
						low:  hash64
						high: 0
					}
				}
			}
			.xxh3_128 {
				// Use the proper XXH3 128-bit digest function
				c_hash128 := C.XXH3_128bits_digest(h.state)
				return HashResult{
					hash_type: .xxh3_128
					hash_128:  Hash128{
						low:  c_hash128.low64
						high: c_hash128.high64
					}
				}
			}
		}
	}
}

// u64_to_hex converts a u64 value to a hexadecimal string with specified width
//
// Parameters:
//   value: The u64 value to convert
//   width: Number of hex digits to output (padded with leading zeros)
//
// Returns:
//   Hexadecimal string representation of the value
fn u64_to_hex(value u64, width int) string {
	hex_chars := '0123456789abcdef'
	mut result := []u8{len: width}
	mut i := width - 1
	mut val := value

	for i >= 0 {
		result[i] = hex_chars[val & 0xF]
		val >>= 4
		i--
	}

	return result.bytestr()
}

// digest_hex computes the final hash and returns it as a hexadecimal string
//
// This is a convenience method that combines digest() and hex formatting.
// The output format depends on the algorithm:
// - XXH32: 8 hex characters
// - XXH64/XXH3_64: 16 hex characters
// - XXH3_128: 32 hex characters (high + low parts)
//
// Returns:
//   Hexadecimal string representation of the hash
pub fn (h &XXHasher) digest_hex() !string {
	result := h.digest()!
	return result.hex()
}

// reset clears the hasher state and reinitializes with the same seed
//
// This allows reusing the same hasher instance for multiple hash computations
// without allocating new memory.
//
// Example:
//   ```
//   mut hasher := new_xxhasher_default(.xxh3_64)!
//   hasher.update("data1".bytes())!
//   result1 := hasher.digest()!
//   hasher.reset()!
//   hasher.update("data2".bytes())!
//   result2 := hasher.digest()!
//   ```
pub fn (mut h XXHasher) reset() ! {
	if h.state == unsafe { nil } {
		return error('Hasher not initialized')
	}

	unsafe {
		match h.algorithm {
			.xxh32 {
				if C.XXH32_reset(h.state, u32(h.seed)) != 0 {
					return error('Failed to reset XXH32')
				}
			}
			.xxh64 {
				if C.XXH64_reset(h.state, h.seed) != 0 {
					return error('Failed to reset XXH64')
				}
			}
			.xxh3_64 {
				if C.XXH3_64bits_reset_withSeed(h.state, h.seed) != 0 {
					return error('Failed to reset XXH3')
				}
			}
			.xxh3_128 {
				if C.XXH3_128bits_reset_withSeed(h.state, h.seed) != 0 {
					return error('Failed to reset XXH3-128')
				}
			}
		}
	}
}

// free releases the memory allocated for the hasher's internal state
//
// This should be called when the hasher is no longer needed to prevent
// memory leaks. After calling free(), the hasher cannot be used again.
//
// Example:
//   ```
//   {
//       mut hasher := new_xxhasher_default(.xxh3_64)!
//       hasher.update("data".bytes())!
//       result := hasher.digest()!
//       hasher.free() // Clean up
//   }
//   ```
pub fn (mut h XXHasher) free() {
	if h.state != unsafe { nil } {
		unsafe {
			match h.algorithm {
				.xxh32 {
					C.XXH32_freeState(h.state)
				}
				.xxh64 {
					C.XXH64_freeState(h.state)
				}
				.xxh3_64, .xxh3_128 {
					C.XXH3_freeState(h.state)
				}
			}
		}
		h.state = unsafe { nil }
	}
}

// ============================================================================
// One-shot Hashing Functions
// ============================================================================
// These functions compute hash values in a single call for the entire data.
// Use these when you have all the data available at once.

// xxh32_hash computes 32-bit xxHash in one shot
//
// This function computes the entire hash in a single call, which is optimal
// for small to medium-sized data that fits comfortably in memory.
//
// PARAMETERS:
//   data: Byte slice containing data to hash
//     - Can be empty (returns hash of empty string)
//     - Size: 0 to 2^64-1 bytes (practically unlimited)
//     - Must be valid memory for duration of call
//     - Large data is processed efficiently in internal chunks
//
//   seed: Seed value for hash initialization
//     - Range: 0 to 2^64-1 (full u64 range, but only lower 32 bits used)
//     - Different seeds produce different hashes for same data
//     - Use 0 for standard/default seeding
//     - Useful for versioning, salting, or collision avoidance
//
// RETURN VALUE:
//   32-bit hash value (u32)
//     - Range: 0 to 2^32-1 (0 to 4,294,967,295)
//     - Uniform distribution across the range
//     - Deterministic: same input always produces same output
//
// PERFORMANCE CHARACTERISTICS:
//   - Speed: Very fast, ~6-10 GB/s on modern CPUs
//   - Memory: O(1) additional memory usage
//   - Cache: Optimized for L1/L2 cache efficiency
//   - Vectorization: Uses SIMD when available
//
// LIMITATIONS:
//   - Higher collision probability than 64-bit variants
//   - Not suitable for very large datasets
//   - 32-bit output may be insufficient for some applications
//
// USE CASES:
//   - Legacy systems requiring 32-bit hashes
//   - Memory-constrained environments
//   - Hash tables where 32-bit keys are sufficient
//   - Applications with small datasets
//
// EXAMPLE:
//   ```
//   data := "hello world".bytes()
//   hash := xxh32_hash(data, 42)
//   println("Hash: 0x${hash:x}")  // 8-digit hex
//   ```
//
// THREAD SAFETY:
//   - Fully thread-safe (no mutable state)
//   - Can be called concurrently from multiple threads
//   - Each call is independent
pub fn xxh32_hash(data []u8, seed u64) u32 {
	unsafe {
		return C.XXH32(data.data, u64(data.len), u32(seed))
	}
}

// xxh64_hash computes 64-bit xxHash in one shot
//
// This function provides an excellent balance of speed and collision resistance
// for general-purpose hashing applications.
//
// PARAMETERS:
//   data: Byte slice containing data to hash
//     - Can be empty (returns hash of empty string)
//     - Size: 0 to 2^64-1 bytes (practically unlimited)
//     - Must be valid memory for duration of call
//     - Optimized for both small and large data
//
//   seed: Seed value for hash initialization
//     - Range: 0 to 2^64-1 (full u64 range)
//     - Different seeds produce different hashes for same data
//     - Use 0 for standard/default seeding
//     - Critical for reproducibility and collision avoidance
//
// RETURN VALUE:
//   64-bit hash value (u64)
//     - Range: 0 to 2^64-1 (0 to 18,446,744,073,709,551,615)
//     - Uniform distribution across the range
//     - Collision probability: 1 in 2^64 (extremely low)
//
// PERFORMANCE CHARACTERISTICS:
//   - Speed: Very fast, ~8-12 GB/s on modern CPUs
//   - Memory: O(1) additional memory usage
//   - Cache: Optimized for modern CPU caches
//   - Architecture: Excellent performance on both 32-bit and 64-bit systems
//
// ADVANTAGES OVER XXH32:
//   - Much lower collision probability (2^64 vs 2^32)
//   - Better distribution properties
//   - More suitable for large datasets
//   - Still very fast with minimal overhead
//
// LIMITATIONS:
//   - Slightly slower than XXH3-64 on modern CPUs
//   - 64-bit output may be insufficient for some security-critical applications
//
// USE CASES:
//   - General-purpose hashing (RECOMMENDED for most applications)
//   - Database indexing and deduplication
//   - File integrity verification
//   - Distributed system data partitioning
//
// EXAMPLE:
//   ```
//   data := "hello world".bytes()
//   hash := xxh64_hash(data, 42)
//   println("Hash: 0x${hash:x}")  // 16-digit hex
//   ```
//
// THREAD SAFETY:
//   - Fully thread-safe (no mutable state)
//   - Can be called concurrently from multiple threads
//   - Each call is independent
pub fn xxh64_hash(data []u8, seed u64) u64 {
	unsafe {
		return C.XXH64(data.data, u64(data.len), seed)
	}
}

// xxh3_hash computes XXH3 64-bit hash in one shot
//
// This function provides the highest performance hashing available in the xxHash
// family, making it the recommended choice for most applications on modern systems.
//
// PARAMETERS:
//   data: Byte slice containing data to hash
//     - Can be empty (returns hash of empty string)
//     - Size: 0 to 2^64-1 bytes (practically unlimited)
//     - Must be valid memory for duration of call
//     - Optimized for both small and large data with adaptive algorithms
//
//   seed: Seed value for hash initialization
//     - Range: 0 to 2^64-1 (full u64 range)
//     - Different seeds produce different hashes for same data
//     - Use 0 for standard/default seeding
//     - Critical for reproducibility and collision avoidance
//
// RETURN VALUE:
//   64-bit hash value (u64)
//     - Range: 0 to 2^64-1 (0 to 18,446,744,073,709,551,615)
//     - Uniform distribution across the range
//     - Collision probability: 1 in 2^64 (extremely low)
//
// PERFORMANCE CHARACTERISTICS:
//   - Speed: Fastest in xxHash family, ~10-15 GB/s on modern CPUs
//   - Memory: O(1) additional memory usage
//   - Vectorization: Uses SIMD instructions (AVX2, SSE2, NEON) when available
//   - Adaptive: Uses different algorithms based on data size
//     * Small data (< 256 bytes): Optimized short data algorithm
//     * Medium data (256B - 16KB): Vectorized processing
//     * Large data (> 16KB): Streaming with large blocks
//
// ADVANTAGES OVER OTHER ALGORITHMS:
//   - Fastest performance on modern 64-bit CPUs
//   - Better cache utilization and prefetching
//   - Optimized for both small and large data
//   - Maintains excellent distribution quality
//
// LIMITATIONS:
//   - Requires 64-bit CPU for optimal performance
//   - Slightly higher memory usage than XXH64 (~256B vs ~128B state)
//   - Performance varies based on CPU SIMD support
//   - Not available on very old systems without SIMD support
//
// USE CASES:
//   - **RECOMMENDED DEFAULT** for most new applications
//   - High-performance data processing pipelines
//   - Real-time systems requiring maximum throughput
//   - Large-scale data analytics and ETL
//   - Network packet processing and content routing
//
// EXAMPLE:
//   ```
//   data := "hello world".bytes()
//   hash := xxh3_hash(data, 42)
//   println("Hash: 0x${hash:x}")  // 16-digit hex
//   ```
//
// THREAD SAFETY:
//   - Fully thread-safe (no mutable state)
//   - Can be called concurrently from multiple threads
//   - Each call is independent
pub fn xxh3_hash(data []u8, seed u64) u64 {
	unsafe {
		return C.XXH3_64bits_withSeed(data.data, u64(data.len), seed)
	}
}

// xxh3_128_hash computes XXH3 128-bit hash in one shot
//
// This function provides the highest collision resistance available in the xxHash
// family by utilizing the full 128-bit hash space. It's designed for applications
// where collision probability must be virtually eliminated.
//
// PARAMETERS:
//   data: Byte slice containing data to hash
//     - Can be empty (returns hash of empty string)
//     - Size: 0 to 2^64-1 bytes (practically unlimited)
//     - Must be valid memory for duration of call
//     - Optimized for both small and large data with adaptive algorithms
//
//   seed: Seed value for hash initialization
//     - Range: 0 to 2^64-1 (full u64 range)
//     - Different seeds produce different hashes for same data
//     - Use 0 for standard/default seeding
//     - Critical for reproducibility and collision avoidance
//
// RETURN VALUE:
//   Hash128 struct containing the 128-bit hash value
//     - Range: 0 to 2^128-1 (approximately 3.4×10^38)
//     - Collision probability: 1 in 2^128 (virtually zero)
//     - Stored as two 64-bit values: high (most significant) and low (least significant)
//
// PERFORMANCE CHARACTERISTICS:
//   - Speed: Very fast, ~8-12 GB/s on modern CPUs (slightly slower than 64-bit variant)
//   - Memory: O(1) additional memory usage
//   - Vectorization: Uses SIMD instructions when available
//   - Adaptive: Uses different algorithms based on data size
//     * Small data (< 256 bytes): Optimized short data algorithm
//     * Medium data (256B - 16KB): Vectorized processing
//     * Large data (> 16KB): Streaming with large blocks
//
// COLLISION RESISTANCE:
//   - Probability: 1 in 2^128 (approximately 1 in 340 undecillion)
//   - For comparison: 64-bit hashes have 1 in 2^64 collision probability
//   - Practically collision-free for all realistic datasets
//   - Suitable for globally unique identifiers
//
// ADVANTAGES OVER 64-BIT HASHES:
//   - Virtually eliminates collision possibility
//   - Future-proof against growing dataset sizes
//   - Suitable for distributed systems with global coordination
//   - Excellent for content-addressable storage
//
// LIMITATIONS:
//   - ~10-20% slower than XXH3-64 variant
//   - Larger storage requirements (16 bytes vs 8 bytes)
//   - Overkill for many applications
//   - Higher memory bandwidth usage
//
// USE CASES:
//   - Content-addressable storage systems (IPFS, Git)
//   - Distributed system global unique identifiers
//   - Cryptographic-adjacent applications (NOTE: NOT CRYPTOGRAPHICALLY SECURE)
//   - Large-scale deduplication systems
//   - Blockchain and distributed ledger applications
//   - Systems requiring provable uniqueness
//
// EXAMPLE:
//   ```
//   data := "hello world".bytes()
//   hash := xxh3_128_hash(data, 42)
//   println("High: 0x${hash.high:x}")  // 16-digit hex (most significant)
//   println("Low: 0x${hash.low:x}")    // 16-digit hex (least significant)
//   println("Full: ${hash.hex_128()}") // 32-digit hex string
//   ```
//
// THREAD SAFETY:
//   - Fully thread-safe (no mutable state)
//   - Can be called concurrently from multiple threads
//   - Each call is independent
pub fn xxh3_128_hash(data []u8, seed u64) Hash128 {
	unsafe {
		// Use the proper XXH3 128-bit function
		c_hash128 := C.XXH3_128bits_withSeed(data.data, u64(data.len), seed)
		return Hash128{
			low:  c_hash128.low64
			high: c_hash128.high64
		}
	}
}

// ============================================================================
// Convenience Functions with Default Seed (0)
// ============================================================================

// xxh32_hash_default computes 32-bit xxHash with seed 0
//
// This is a convenience function that uses the standard seed value of 0,
// which is the most common use case for xxHash computations.
//
// PARAMETERS:
//   data: Byte slice containing data to hash
//     - Can be empty (returns hash of empty string)
//     - Size: 0 to 2^64-1 bytes (practically unlimited)
//     - Must be valid memory for duration of call
//     - Large data is processed efficiently in internal chunks
//
// RETURN VALUE:
//   32-bit hash value (u32)
//     - Range: 0 to 2^32-1 (0 to 4,294,967,295)
//     - Uniform distribution across the range
//     - Deterministic: same input always produces same output
//
// SEED BEHAVIOR:
//   - Uses fixed seed value of 0
//   - Provides consistent, reproducible results across runs
//   - Standard seeding used by most xxHash implementations
//   - Equivalent to calling xxh32_hash(data, 0)
//
// PERFORMANCE CHARACTERISTICS:
//   - Speed: Very fast, ~6-10 GB/s on modern CPUs
//   - Memory: O(1) additional memory usage
//   - Cache: Optimized for L1/L2 cache efficiency
//   - Vectorization: Uses SIMD when available
//
// WHEN TO USE:
//   - When you don't need custom seeding
//   - For standard hash computations
//   - When reproducibility across different systems is important
//   - Legacy applications expecting seed 0 behavior
//
// LIMITATIONS:
//   - Higher collision probability than 64-bit variants
//   - Not suitable for very large datasets
//   - 32-bit output may be insufficient for some applications
//   - Cannot customize seed for versioning or salting
//
// EXAMPLE:
//   ```
//   data := "hello world".bytes()
//   hash := xxh32_hash_default(data)
//   println("Hash: 0x${hash:x}")  // 8-digit hex
//   ```
//
// THREAD SAFETY:
//   - Fully thread-safe (no mutable state)
//   - Can be called concurrently from multiple threads
//   - Each call is independent
pub fn xxh32_hash_default(data []u8) u32 {
	return xxh32_hash(data, 0)
}

// xxh64_hash_default computes 64-bit xxHash with seed 0
//
// This is a convenience function that uses the standard seed value of 0,
// providing the most common use case for 64-bit xxHash computations.
//
// PARAMETERS:
//   data: Byte slice containing data to hash
//     - Can be empty (returns hash of empty string)
//     - Size: 0 to 2^64-1 bytes (practically unlimited)
//     - Must be valid memory for duration of call
//     - Optimized for both small and large data
//
// RETURN VALUE:
//   64-bit hash value (u64)
//     - Range: 0 to 2^64-1 (0 to 18,446,744,073,709,551,615)
//     - Uniform distribution across the range
//     - Collision probability: 1 in 2^64 (extremely low)
//
// SEED BEHAVIOR:
//   - Uses fixed seed value of 0
//   - Provides consistent, reproducible results across runs
//   - Standard seeding used by most xxHash implementations
//   - Equivalent to calling xxh64_hash(data, 0)
//
// PERFORMANCE CHARACTERISTICS:
//   - Speed: Very fast, ~8-12 GB/s on modern CPUs
//   - Memory: O(1) additional memory usage
//   - Cache: Optimized for modern CPU caches
//   - Architecture: Excellent performance on both 32-bit and 64-bit systems
//
// WHEN TO USE:
//   - When you don't need custom seeding
//   - For standard hash computations
//   - When reproducibility across different systems is important
//   - General-purpose hashing applications
//
// LIMITATIONS:
//   - Slightly slower than XXH3-64 on modern CPUs
//   - 64-bit output may be insufficient for some security-critical applications
//   - Cannot customize seed for versioning or salting
//
// USE CASES:
//   - General-purpose hashing (RECOMMENDED for most applications)
//   - Database indexing and deduplication
//   - File integrity verification
//   - Distributed system data partitioning
//   - Standard hash table implementations
//
// EXAMPLE:
//   ```
//   data := "hello world".bytes()
//   hash := xxh64_hash_default(data)
//   println("Hash: 0x${hash:x}")  // 16-digit hex
//   ```
//
// THREAD SAFETY:
//   - Fully thread-safe (no mutable state)
//   - Can be called concurrently from multiple threads
//   - Each call is independent
pub fn xxh64_hash_default(data []u8) u64 {
	return xxh64_hash(data, 0)
}

// xxh3_hash_default computes XXH3 64-bit hash with seed 0
//
// This is a convenience function that uses the standard seed value of 0,
// providing the fastest xxHash algorithm with the most common seeding.
//
// PARAMETERS:
//   data: Byte slice containing data to hash
//     - Can be empty (returns hash of empty string)
//     - Size: 0 to 2^64-1 bytes (practically unlimited)
//     - Must be valid memory for duration of call
//     - Optimized for both small and large data with adaptive algorithms
//
// RETURN VALUE:
//   64-bit hash value (u64)
//     - Range: 0 to 2^64-1 (0 to 18,446,744,073,709,551,615)
//     - Uniform distribution across the range
//     - Collision probability: 1 in 2^64 (extremely low)
//
// SEED BEHAVIOR:
//   - Uses fixed seed value of 0
//   - Provides consistent, reproducible results across runs
//   - Standard seeding used by most xxHash implementations
//   - Equivalent to calling xxh3_hash(data, 0)
//
// PERFORMANCE CHARACTERISTICS:
//   - Speed: Fastest in xxHash family, ~10-15 GB/s on modern CPUs
//   - Memory: O(1) additional memory usage
//   - Vectorization: Uses SIMD instructions (AVX2, SSE2, NEON) when available
//   - Adaptive: Uses different algorithms based on data size
//
// WHEN TO USE:
//   - **RECOMMENDED DEFAULT** for most new applications
//   - When you don't need custom seeding
//   - For standard high-performance hash computations
//   - When reproducibility across different systems is important
//   - High-performance data processing pipelines
//
// LIMITATIONS:
//   - Requires 64-bit CPU for optimal performance
//   - Slightly higher memory usage than XXH64
//   - Performance varies based on CPU SIMD support
//   - Cannot customize seed for versioning or salting
//
// USE CASES:
//   - High-performance data processing
//   - Real-time systems requiring maximum throughput
//   - Large-scale data analytics and ETL
//   - Network packet processing and content routing
//   - Standard hash table implementations requiring maximum speed
//
// EXAMPLE:
//   ```
//   data := "hello world".bytes()
//   hash := xxh3_hash_default(data)
//   println("Hash: 0x${hash:x}")  // 16-digit hex
//   ```
//
// THREAD SAFETY:
//   - Fully thread-safe (no mutable state)
//   - Can be called concurrently from multiple threads
//   - Each call is independent
pub fn xxh3_hash_default(data []u8) u64 {
	return xxh3_hash(data, 0)
}

// xxh3_128_hash_default computes XXH3 128-bit hash with seed 0
//
// This is a convenience function that uses the standard seed value of 0,
// providing the highest collision resistance with the most common seeding.
//
// PARAMETERS:
//   data: Byte slice containing data to hash
//     - Can be empty (returns hash of empty string)
//     - Size: 0 to 2^64-1 bytes (practically unlimited)
//     - Must be valid memory for duration of call
//     - Optimized for both small and large data with adaptive algorithms
//
// RETURN VALUE:
//   Hash128 struct containing the 128-bit hash value
//     - Range: 0 to 2^128-1 (approximately 3.4×10^38)
//     - Collision probability: 1 in 2^128 (virtually zero)
//     - Stored as two 64-bit values: high (most significant) and low (least significant)
//
// SEED BEHAVIOR:
//   - Uses fixed seed value of 0
//   - Provides consistent, reproducible results across runs
//   - Standard seeding used by most xxHash implementations
//   - Equivalent to calling xxh3_128_hash(data, 0)
//
// PERFORMANCE CHARACTERISTICS:
//   - Speed: Very fast, ~8-12 GB/s on modern CPUs (slightly slower than 64-bit variant)
//   - Memory: O(1) additional memory usage
//   - Vectorization: Uses SIMD instructions when available
//   - Adaptive: Uses different algorithms based on data size
//
// COLLISION RESISTANCE:
//   - Probability: 1 in 2^128 (approximately 1 in 340 undecillion)
//   - Practically collision-free for all realistic datasets
//   - Suitable for globally unique identifiers
//
// WHEN TO USE:
//   - When you don't need custom seeding
//   - For applications requiring maximum collision resistance
//   - Content-addressable storage systems
//   - Distributed system global unique identifiers
//   - When reproducibility across different systems is important
//
// LIMITATIONS:
//   - ~10-20% slower than XXH3-64 variant
//   - Larger storage requirements (16 bytes vs 8 bytes)
//   - Overkill for many applications
//   - Cannot customize seed for versioning or salting
//
// USE CASES:
//   - Content-addressable storage systems (IPFS, Git)
//   - Distributed system global unique identifiers
//   - Large-scale deduplication systems
//   - Systems requiring provable uniqueness
//   - Standard 128-bit hash computations
//
// EXAMPLE:
//   ```
//   data := "hello world".bytes()
//   hash := xxh3_128_hash_default(data)
//   println("High: 0x${hash.high:x}")  // 16-digit hex (most significant)
//   println("Low: 0x${hash.low:x}")    // 16-digit hex (least significant)
//   println("Full: ${hash.hex_128()}") // 32-digit hex string
//   ```
//
// THREAD SAFETY:
//   - Fully thread-safe (no mutable state)
//   - Can be called concurrently from multiple threads
//   - Each call is independent
pub fn xxh3_128_hash_default(data []u8) Hash128 {
	return xxh3_128_hash(data, 0)
}

// new_xxhasher_default creates a new streaming hasher with seed 0
//
// This is a convenience function that creates a streaming hasher using the
// standard seed value of 0, which is the most common use case for incremental
// hashing operations.
//
// PARAMETERS:
//   algorithm: The hash algorithm to use
//     - .xxh32: 32-bit hash, fastest on 32-bit systems
//     - .xxh64: 64-bit hash, good speed/quality balance
//     - .xxh3_64: 64-bit hash, fastest on modern 64-bit systems (RECOMMENDED)
//     - .xxh3_128: 128-bit hash, highest collision resistance
//
// RETURN VALUE:
//   XXHasher instance ready for streaming updates
//   - Returns error if memory allocation fails
//   - Returns error if algorithm initialization fails
//
// SEED BEHAVIOR:
//   - Uses fixed seed value of 0
//   - Provides consistent, reproducible results across runs
//   - Standard seeding used by most xxHash implementations
//   - Equivalent to calling new_xxhasher(algorithm, 0)
//
// MEMORY USAGE:
//   - XXH32: ~64 bytes allocated
//   - XXH64: ~128 bytes allocated
//   - XXH3 variants: ~256 bytes allocated
//
// ERROR CONDITIONS:
//   - Out of memory: System cannot allocate hasher state
//   - Invalid algorithm: Should never happen with enum values
//
// WHEN TO USE:
//   - When you don't need custom seeding
//   - For standard streaming hash computations
//   - When reproducibility across different systems is important
//   - Large file processing where data doesn't fit in memory
//   - Network stream processing
//
// EXAMPLE:
//   ```
//   mut hasher := new_xxhasher_default(.xxh3_64)!
//   defer { hasher.free() } // Important: prevent memory leak
//
//   hasher.update("hello".bytes())!
//   hasher.update(" world".bytes())!
//   result := hasher.digest()!
//   println("Hash: ${result.hex()}")
//   ```
//
// THREAD SAFETY:
//   - Each hasher instance is NOT thread-safe
//   - Create separate instances for parallel processing
//   - Same instance can be reused sequentially with reset()
//
// LIFECYCLE:
//   1. Create with new_xxhasher_default()
//   2. Call update() multiple times with data chunks
//   3. Call digest() to get final hash result
//   4. Optionally call reset() to reuse for new data
//   5. Call free() when done to release memory
pub fn new_xxhasher_default(algorithm DigestAlgorithm) !XXHasher {
	return new_xxhasher(algorithm, 0)
}

// ============================================================================
// One-shot Hex Functions
// ============================================================================

// xxh32_hash_hex computes 32-bit xxHash and returns hex string
//
// This function combines the hash computation with hexadecimal formatting,
// providing a convenient way to get human-readable hash strings.
//
// PARAMETERS:
//   data: Byte slice containing data to hash
//     - Can be empty (returns hash of empty string)
//     - Size: 0 to 2^64-1 bytes (practically unlimited)
//     - Must be valid memory for duration of call
//     - Large data is processed efficiently in internal chunks
//
//   seed: Seed value for hash initialization
//     - Range: 0 to 2^64-1 (full u64 range, but only lower 32 bits used)
//     - Different seeds produce different hashes for same data
//     - Use 0 for standard/default seeding
//     - Useful for versioning, salting, or collision avoidance
//
// RETURN VALUE:
//   8-character hexadecimal string
//     - Format: "0123abcd" (lowercase, no prefix)
//     - Contains leading zeros to ensure 8 characters
//     - Represents the 32-bit hash value in base-16
//     - Suitable for display, storage, and comparison
//
// FORMATTING DETAILS:
//   - Uses lowercase hexadecimal digits (0-9, a-f)
//   - Always 8 characters long (padded with leading zeros)
//   - No "0x" prefix (pure hexadecimal string)
//   - Equivalent to: format("0x{:08x}", hash_value)
//
// PERFORMANCE CHARACTERISTICS:
//   - Speed: Very fast, ~6-10 GB/s on modern CPUs
//   - Memory: O(1) additional memory usage
//   - String allocation: 8 bytes for result
//   - Cache: Optimized for L1/L2 cache efficiency
//
// WHEN TO USE:
//   - When you need human-readable hash representation
//   - For display purposes in user interfaces
//   - When storing hashes as text (JSON, XML, etc.)
//   - For debugging and logging
//   - When hex format is required by external systems
//
// LIMITATIONS:
//   - Higher collision probability than 64-bit variants
//   - String allocation overhead vs raw u32 value
//   - Not suitable for very large datasets
//   - 32-bit output may be insufficient for some applications
//
// EXAMPLE:
//   ```
//   data := "hello world".bytes()
//   hex_hash := xxh32_hash_hex(data, 42)
//   println("Hash: ${hex_hash}")  // e.g., "0123abcd"
//   println("Length: ${hex_hash.len}") // Always 8
//   ```
//
// THREAD SAFETY:
//   - Fully thread-safe (no mutable state)
//   - Can be called concurrently from multiple threads
//   - Each call is independent
pub fn xxh32_hash_hex(data []u8, seed u64) string {
	return u64_to_hex(xxh32_hash(data, seed), 8)
}

// xxh64_hash_hex computes 64-bit xxHash and returns hex string
//
// This function combines the hash computation with hexadecimal formatting,
// providing a convenient way to get human-readable hash strings for the
// widely-used 64-bit xxHash algorithm.
//
// PARAMETERS:
//   data: Byte slice containing data to hash
//     - Can be empty (returns hash of empty string)
//     - Size: 0 to 2^64-1 bytes (practically unlimited)
//     - Must be valid memory for duration of call
//     - Optimized for both small and large data
//
//   seed: Seed value for hash initialization
//     - Range: 0 to 2^64-1 (full u64 range)
//     - Different seeds produce different hashes for same data
//     - Use 0 for standard/default seeding
//     - Critical for reproducibility and collision avoidance
//
// RETURN VALUE:
//   16-character hexadecimal string
//     - Format: "0123456789abcdef" (lowercase, no prefix)
//     - Contains leading zeros to ensure 16 characters
//     - Represents the 64-bit hash value in base-16
//     - Suitable for display, storage, and comparison
//
// FORMATTING DETAILS:
//   - Uses lowercase hexadecimal digits (0-9, a-f)
//   - Always 16 characters long (padded with leading zeros)
//   - No "0x" prefix (pure hexadecimal string)
//   - Equivalent to: format("0x{:016x}", hash_value)
//
// PERFORMANCE CHARACTERISTICS:
//   - Speed: Very fast, ~8-12 GB/s on modern CPUs
//   - Memory: O(1) additional memory usage
//   - String allocation: 16 bytes for result
//   - Cache: Optimized for modern CPU caches
//
// WHEN TO USE:
//   - When you need human-readable hash representation
//   - For display purposes in user interfaces
//   - When storing hashes as text (JSON, XML, databases)
//   - For debugging and logging
//   - When hex format is required by external systems
//   - API responses and configuration files
//
// LIMITATIONS:
//   - String allocation overhead vs raw u64 value
//   - Slightly slower than XXH3-64 on modern CPUs
//   - 64-bit output may be insufficient for some security-critical applications
//
// USE CASES:
//   - General-purpose hashing with readable output
//   - Database indexing with string keys
//   - File integrity verification with human-readable results
//   - API endpoints returning hash identifiers
//   - Configuration and metadata files
//
// EXAMPLE:
//   ```
//   data := "hello world".bytes()
//   hex_hash := xxh64_hash_hex(data, 42)
//   println("Hash: ${hex_hash}")  // e.g., "0123456789abcdef"
//   println("Length: ${hex_hash.len}") // Always 16
//   ```
//
// THREAD SAFETY:
//   - Fully thread-safe (no mutable state)
//   - Can be called concurrently from multiple threads
//   - Each call is independent
pub fn xxh64_hash_hex(data []u8, seed u64) string {
	return u64_to_hex(xxh64_hash(data, seed), 16)
}

// xxh3_hash_hex computes XXH3 64-bit hash and returns hex string
//
// This function combines the fastest xxHash algorithm with hexadecimal formatting,
// providing the optimal balance of performance and human-readable output.
//
// PARAMETERS:
//   data: Byte slice containing data to hash
//     - Can be empty (returns hash of empty string)
//     - Size: 0 to 2^64-1 bytes (practically unlimited)
//     - Must be valid memory for duration of call
//     - Optimized for both small and large data with adaptive algorithms
//
//   seed: Seed value for hash initialization
//     - Range: 0 to 2^64-1 (full u64 range)
//     - Different seeds produce different hashes for same data
//     - Use 0 for standard/default seeding
//     - Critical for reproducibility and collision avoidance
//
// RETURN VALUE:
//   16-character hexadecimal string
//     - Format: "0123456789abcdef" (lowercase, no prefix)
//     - Contains leading zeros to ensure 16 characters
//     - Represents the 64-bit hash value in base-16
//     - Suitable for display, storage, and comparison
//
// FORMATTING DETAILS:
//   - Uses lowercase hexadecimal digits (0-9, a-f)
//   - Always 16 characters long (padded with leading zeros)
//   - No "0x" prefix (pure hexadecimal string)
//   - Equivalent to: format("0x{:016x}", hash_value)
//
// PERFORMANCE CHARACTERISTICS:
//   - Speed: Fastest in xxHash family, ~10-15 GB/s on modern CPUs
//   - Memory: O(1) additional memory usage
//   - String allocation: 16 bytes for result
//   - Vectorization: Uses SIMD instructions (AVX2, SSE2, NEON) when available
//   - Adaptive: Uses different algorithms based on data size
//
// WHEN TO USE:
//   - **RECOMMENDED** for most applications needing hex output
//   - When you need the fastest possible hash with readable format
//   - For display purposes in user interfaces
//   - When storing hashes as text (JSON, XML, databases)
//   - High-performance APIs returning hash identifiers
//   - Real-time systems requiring maximum throughput
//
// LIMITATIONS:
//   - String allocation overhead vs raw u64 value
//   - Requires 64-bit CPU for optimal performance
//   - Performance varies based on CPU SIMD support
//
// USE CASES:
//   - High-performance web services
//   - Real-time data processing pipelines
//   - API endpoints returning hash identifiers
//   - Caching systems with string keys
//   - Distributed system data partitioning
//
// EXAMPLE:
//   ```
//   data := "hello world".bytes()
//   hex_hash := xxh3_hash_hex(data, 42)
//   println("Hash: ${hex_hash}")  // e.g., "0123456789abcdef"
//   println("Length: ${hex_hash.len}") // Always 16
//   ```
//
// THREAD SAFETY:
//   - Fully thread-safe (no mutable state)
//   - Can be called concurrently from multiple threads
//   - Each call is independent
pub fn xxh3_hash_hex(data []u8, seed u64) string {
	return u64_to_hex(xxh3_hash(data, seed), 16)
}

// xxh3_128_hash_hex computes XXH3 128-bit hash and returns hex string
//
// This function combines the highest collision resistance xxHash algorithm
// with hexadecimal formatting, providing virtually collision-free hashes
// in a human-readable format.
//
// PARAMETERS:
//   data: Byte slice containing data to hash
//     - Can be empty (returns hash of empty string)
//     - Size: 0 to 2^64-1 bytes (practically unlimited)
//     - Must be valid memory for duration of call
//     - Optimized for both small and large data with adaptive algorithms
//
//   seed: Seed value for hash initialization
//     - Range: 0 to 2^64-1 (full u64 range)
//     - Different seeds produce different hashes for same data
//     - Use 0 for standard/default seeding
//     - Critical for reproducibility and collision avoidance
//
// RETURN VALUE:
//   32-character hexadecimal string
//     - Format: "0123456789abcdef0123456789abcdef" (lowercase, no prefix)
//     - Contains leading zeros to ensure 32 characters
//     - Represents the full 128-bit hash value in base-16
//     - Format: high 64 bits (first 16 chars) + low 64 bits (last 16 chars)
//
// FORMATTING DETAILS:
//   - Uses lowercase hexadecimal digits (0-9, a-f)
//   - Always 32 characters long (padded with leading zeros)
//   - No "0x" prefix (pure hexadecimal string)
//   - High-order 64 bits appear first, low-order 64 bits second
//   - Equivalent to: format("0x{:016x}{:016x}", hash.high, hash.low)
//
// PERFORMANCE CHARACTERISTICS:
//   - Speed: Very fast, ~8-12 GB/s on modern CPUs (slightly slower than 64-bit variant)
//   - Memory: O(1) additional memory usage
//   - String allocation: 32 bytes for result
//   - Vectorization: Uses SIMD instructions when available
//   - Adaptive: Uses different algorithms based on data size
//
// COLLISION RESISTANCE:
//   - Probability: 1 in 2^128 (approximately 1 in 340 undecillion)
//   - Practically collision-free for all realistic datasets
//   - Suitable for globally unique identifiers
//
// WHEN TO USE:
//   - When you need maximum collision resistance with readable format
//   - Content-addressable storage systems
//   - Distributed system global unique identifiers
//   - For display purposes in user interfaces requiring 128-bit precision
//   - When storing 128-bit hashes as text (JSON, XML, databases)
//
// LIMITATIONS:
//   - ~10-20% slower than XXH3-64 variant
//   - Larger storage requirements (32 bytes vs 16 bytes)
//   - String allocation overhead vs raw Hash128 struct
//   - Overkill for many applications
//
// USE CASES:
//   - Content-addressable storage systems (IPFS, Git)
//   - Distributed system global unique identifiers
//   - Large-scale deduplication systems
//   - Systems requiring provable uniqueness
//   - API endpoints returning 128-bit hash identifiers
//
// EXAMPLE:
//   ```
//   data := "hello world".bytes()
//   hex_hash := xxh3_128_hash_hex(data, 42)
//   println("Hash: ${hex_hash}")  // e.g., "0123456789abcdef0123456789abcdef"
//   println("Length: ${hex_hash.len}") // Always 32
//   println("High part: ${hex_hash[..16]}") // First 16 chars (high 64 bits)
//   println("Low part: ${hex_hash[16..]}")  // Last 16 chars (low 64 bits)
//   ```
//
// THREAD SAFETY:
//   - Fully thread-safe (no mutable state)
//   - Can be called concurrently from multiple threads
//   - Each call is independent
pub fn xxh3_128_hash_hex(data []u8, seed u64) string {
	hash := xxh3_128_hash(data, seed)
	return u64_to_hex(hash.high, 16) + u64_to_hex(hash.low, 16)
}

// xxh32_hash_hex_default computes 32-bit xxHash with seed 0 and returns hex string
//
// This is a convenience function that combines standard seeding with hexadecimal
// formatting, providing the most common use case for 32-bit xxHash with
// human-readable output.
//
// PARAMETERS:
//   data: Byte slice containing data to hash
//     - Can be empty (returns hash of empty string)
//     - Size: 0 to 2^64-1 bytes (practically unlimited)
//     - Must be valid memory for duration of call
//     - Large data is processed efficiently in internal chunks
//
// RETURN VALUE:
//   8-character hexadecimal string
//     - Format: "0123abcd" (lowercase, no prefix)
//     - Contains leading zeros to ensure 8 characters
//     - Represents the 32-bit hash value in base-16
//     - Suitable for display, storage, and comparison
//
// SEED BEHAVIOR:
//   - Uses fixed seed value of 0
//   - Provides consistent, reproducible results across runs
//   - Standard seeding used by most xxHash implementations
//   - Equivalent to calling xxh32_hash_hex(data, 0)
//
// FORMATTING DETAILS:
//   - Uses lowercase hexadecimal digits (0-9, a-f)
//   - Always 8 characters long (padded with leading zeros)
//   - No "0x" prefix (pure hexadecimal string)
//   - Equivalent to: format("0x{:08x}", hash_value)
//
// PERFORMANCE CHARACTERISTICS:
//   - Speed: Very fast, ~6-10 GB/s on modern CPUs
//   - Memory: O(1) additional memory usage
//   - String allocation: 8 bytes for result
//   - Cache: Optimized for L1/L2 cache efficiency
//
// WHEN TO USE:
//   - When you need standard 32-bit hashing with readable output
//   - For display purposes in user interfaces
//   - When storing hashes as text (JSON, XML, etc.)
//   - For debugging and logging
//   - Legacy applications expecting seed 0 behavior
//   - When reproducibility across different systems is important
//
// LIMITATIONS:
//   - Higher collision probability than 64-bit variants
//   - String allocation overhead vs raw u32 value
//   - Not suitable for very large datasets
//   - 32-bit output may be insufficient for some applications
//   - Cannot customize seed for versioning or salting
//
// EXAMPLE:
//   ```
//   data := "hello world".bytes()
//   hex_hash := xxh32_hash_hex_default(data)
//   println("Hash: ${hex_hash}")  // e.g., "0123abcd"
//   println("Length: ${hex_hash.len}") // Always 8
//   ```
//
// THREAD SAFETY:
//   - Fully thread-safe (no mutable state)
//   - Can be called concurrently from multiple threads
//   - Each call is independent
pub fn xxh32_hash_hex_default(data []u8) string {
	return u64_to_hex(xxh32_hash(data, 0), 8)
}

// xxh64_hash_hex_default computes 64-bit xxHash with seed 0 and returns hex string
//
// This is a convenience function that combines standard seeding with hexadecimal
// formatting, providing the most common use case for 64-bit xxHash with
// human-readable output.
//
// PARAMETERS:
//   data: Byte slice containing data to hash
//     - Can be empty (returns hash of empty string)
//     - Size: 0 to 2^64-1 bytes (practically unlimited)
//     - Must be valid memory for duration of call
//     - Optimized for both small and large data
//
// RETURN VALUE:
//   16-character hexadecimal string
//     - Format: "0123456789abcdef" (lowercase, no prefix)
//     - Contains leading zeros to ensure 16 characters
//     - Represents the 64-bit hash value in base-16
//     - Suitable for display, storage, and comparison
//
// SEED BEHAVIOR:
//   - Uses fixed seed value of 0
//   - Provides consistent, reproducible results across runs
//   - Standard seeding used by most xxHash implementations
//   - Equivalent to calling xxh64_hash_hex(data, 0)
//
// FORMATTING DETAILS:
//   - Uses lowercase hexadecimal digits (0-9, a-f)
//   - Always 16 characters long (padded with leading zeros)
//   - No "0x" prefix (pure hexadecimal string)
//   - Equivalent to: format("0x{:016x}", hash_value)
//
// PERFORMANCE CHARACTERISTICS:
//   - Speed: Very fast, ~8-12 GB/s on modern CPUs
//   - Memory: O(1) additional memory usage
//   - String allocation: 16 bytes for result
//   - Cache: Optimized for modern CPU caches
//
// WHEN TO USE:
//   - **RECOMMENDED** for most applications needing 64-bit hex output
//   - When you need standard 64-bit hashing with readable format
//   - For display purposes in user interfaces
//   - When storing hashes as text (JSON, XML, databases)
//   - API responses and configuration files
//   - When reproducibility across different systems is important
//
// LIMITATIONS:
//   - String allocation overhead vs raw u64 value
//   - Slightly slower than XXH3-64 on modern CPUs
//   - 64-bit output may be insufficient for some security-critical applications
//   - Cannot customize seed for versioning or salting
//
// USE CASES:
//   - General-purpose hashing with readable output
//   - Database indexing with string keys
//   - File integrity verification with human-readable results
//   - API endpoints returning hash identifiers
//   - Configuration and metadata files
//   - Standard hash table implementations
//
// EXAMPLE:
//   ```
//   data := "hello world".bytes()
//   hex_hash := xxh64_hash_hex_default(data)
//   println("Hash: ${hex_hash}")  // e.g., "0123456789abcdef"
//   println("Length: ${hex_hash.len}") // Always 16
//   ```
//
// THREAD SAFETY:
//   - Fully thread-safe (no mutable state)
//   - Can be called concurrently from multiple threads
//   - Each call is independent
pub fn xxh64_hash_hex_default(data []u8) string {
	return u64_to_hex(xxh64_hash(data, 0), 16)
}

// xxh3_hash_hex_default computes XXH3 64-bit hash with seed 0 and returns hex string
//
// This is a convenience function that combines the fastest xxHash algorithm with
// standard seeding and hexadecimal formatting, providing the optimal balance of
// performance and human-readable output for the most common use case.
//
// PARAMETERS:
//   data: Byte slice containing data to hash
//     - Can be empty (returns hash of empty string)
//     - Size: 0 to 2^64-1 bytes (practically unlimited)
//     - Must be valid memory for duration of call
//     - Optimized for both small and large data with adaptive algorithms
//
// RETURN VALUE:
//   16-character hexadecimal string
//     - Format: "0123456789abcdef" (lowercase, no prefix)
//     - Contains leading zeros to ensure 16 characters
//     - Represents the 64-bit hash value in base-16
//     - Suitable for display, storage, and comparison
//
// SEED BEHAVIOR:
//   - Uses fixed seed value of 0
//   - Provides consistent, reproducible results across runs
//   - Standard seeding used by most xxHash implementations
//   - Equivalent to calling xxh3_hash_hex(data, 0)
//
// FORMATTING DETAILS:
//   - Uses lowercase hexadecimal digits (0-9, a-f)
//   - Always 16 characters long (padded with leading zeros)
//   - No "0x" prefix (pure hexadecimal string)
//   - Equivalent to: format("0x{:016x}", hash_value)
//
// PERFORMANCE CHARACTERISTICS:
//   - Speed: Fastest in xxHash family, ~10-15 GB/s on modern CPUs
//   - Memory: O(1) additional memory usage
//   - String allocation: 16 bytes for result
//   - Vectorization: Uses SIMD instructions (AVX2, SSE2, NEON) when available
//   - Adaptive: Uses different algorithms based on data size
//
// WHEN TO USE:
//   - **RECOMMENDED DEFAULT** for most applications needing hex output
//   - When you need the fastest possible hash with readable format
//   - For display purposes in user interfaces
//   - When storing hashes as text (JSON, XML, databases)
//   - High-performance APIs returning hash identifiers
//   - Real-time systems requiring maximum throughput
//   - When reproducibility across different systems is important
//
// LIMITATIONS:
//   - String allocation overhead vs raw u64 value
//   - Requires 64-bit CPU for optimal performance
//   - Performance varies based on CPU SIMD support
//   - Cannot customize seed for versioning or salting
//
// USE CASES:
//   - High-performance web services
//   - Real-time data processing pipelines
//   - API endpoints returning hash identifiers
//   - Caching systems with string keys
//   - Distributed system data partitioning
//   - Standard hash table implementations requiring maximum speed
//
// EXAMPLE:
//   ```
//   data := "hello world".bytes()
//   hex_hash := xxh3_hash_hex_default(data)
//   println("Hash: ${hex_hash}")  // e.g., "0123456789abcdef"
//   println("Length: ${hex_hash.len}") // Always 16
//   ```
//
// THREAD SAFETY:
//   - Fully thread-safe (no mutable state)
//   - Can be called concurrently from multiple threads
//   - Each call is independent
pub fn xxh3_hash_hex_default(data []u8) string {
	return u64_to_hex(xxh3_hash(data, 0), 16)
}

// xxh3_128_hash_hex_default computes XXH3 128-bit hash with seed 0 and returns hex string
//
// This is a convenience function that combines the highest collision resistance
// xxHash algorithm with standard seeding and hexadecimal formatting, providing
// virtually collision-free hashes in a human-readable format for the most common use case.
//
// PARAMETERS:
//   data: Byte slice containing data to hash
//     - Can be empty (returns hash of empty string)
//     - Size: 0 to 2^64-1 bytes (practically unlimited)
//     - Must be valid memory for duration of call
//     - Optimized for both small and large data with adaptive algorithms
//
// RETURN VALUE:
//   32-character hexadecimal string
//     - Format: "0123456789abcdef0123456789abcdef" (lowercase, no prefix)
//     - Contains leading zeros to ensure 32 characters
//     - Represents the full 128-bit hash value in base-16
//     - Format: high 64 bits (first 16 chars) + low 64 bits (last 16 chars)
//
// SEED BEHAVIOR:
//   - Uses fixed seed value of 0
//   - Provides consistent, reproducible results across runs
//   - Standard seeding used by most xxHash implementations
//   - Equivalent to calling xxh3_128_hash_hex(data, 0)
//
// FORMATTING DETAILS:
//   - Uses lowercase hexadecimal digits (0-9, a-f)
//   - Always 32 characters long (padded with leading zeros)
//   - No "0x" prefix (pure hexadecimal string)
//   - High-order 64 bits appear first, low-order 64 bits second
//   - Equivalent to: format("0x{:016x}{:016x}", hash.high, hash.low)
//
// PERFORMANCE CHARACTERISTICS:
//   - Speed: Very fast, ~8-12 GB/s on modern CPUs (slightly slower than 64-bit variant)
//   - Memory: O(1) additional memory usage
//   - String allocation: 32 bytes for result
//   - Vectorization: Uses SIMD instructions when available
//   - Adaptive: Uses different algorithms based on data size
//
// COLLISION RESISTANCE:
//   - Probability: 1 in 2^128 (approximately 1 in 340 undecillion)
//   - Practically collision-free for all realistic datasets
//   - Suitable for globally unique identifiers
//
// WHEN TO USE:
//   - When you need maximum collision resistance with readable format
//   - Content-addressable storage systems
//   - Distributed system global unique identifiers
//   - For display purposes in user interfaces requiring 128-bit precision
//   - When storing 128-bit hashes as text (JSON, XML, databases)
//   - When reproducibility across different systems is important
//
// LIMITATIONS:
//   - ~10-20% slower than XXH3-64 variant
//   - Larger storage requirements (32 bytes vs 16 bytes)
//   - String allocation overhead vs raw Hash128 struct
//   - Overkill for many applications
//   - Cannot customize seed for versioning or salting
//
// USE CASES:
//   - Content-addressable storage systems (IPFS, Git)
//   - Distributed system global unique identifiers
//   - Large-scale deduplication systems
//   - Systems requiring provable uniqueness
//   - API endpoints returning 128-bit hash identifiers
//   - Standard 128-bit hash computations
//
// EXAMPLE:
//   ```
//   data := "hello world".bytes()
//   hex_hash := xxh3_128_hash_hex_default(data)
//   println("Hash: ${hex_hash}")  // e.g., "0123456789abcdef0123456789abcdef"
//   println("Length: ${hex_hash.len}") // Always 32
//   println("High part: ${hex_hash[..16]}") // First 16 chars (high 64 bits)
//   println("Low part: ${hex_hash[16..]}")  // Last 16 chars (low 64 bits)
//   ```
//
// THREAD SAFETY:
//   - Fully thread-safe (no mutable state)
//   - Can be called concurrently from multiple threads
//   - Each call is independent
pub fn xxh3_128_hash_hex_default(data []u8) string {
	return xxh3_128_hash_hex(data, 0)
}

// ============================================================================
// Library Information
// ============================================================================

// xxh_version_number returns the xxHash library version
//
// Returns:
//   Version number in format: MAJOR * 100 * 100 + MINOR * 100 + PATCH
//   For example, version 0.8.2 returns 802
//
// Example:
//   ```
//   version := xxh_version_number()
//   println('xxHash version: ${version}')
//   ```
pub fn xxh_version_number() u32 {
	return C.XXH_versionNumber()
}
