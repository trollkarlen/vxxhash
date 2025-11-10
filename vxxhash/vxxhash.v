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
// Note: These paths may need adjustment for different systems
#flag -I/opt/homebrew/opt/xxhash/include
#flag -L/opt/homebrew/opt/xxhash/lib
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
pub enum DigestAlgorithm {
	// 32-bit hash algorithm (XXH32)
	// Fastest on 32-bit systems, good for small data
	xxh32

	// 64-bit hash algorithm (XXH64)
	// Good balance of speed and hash quality
	xxh64

	// XXH3 64-bit hash algorithm
	// Default choice - fastest on 64-bit systems, excellent quality
	xxh3_64

	// XXH3 128-bit hash algorithm
	// Provides 128-bit hash space, slightly slower than 64-bit variant
	xxh3_128
}

// XXHasher provides streaming hash functionality
//
// Use this struct when you need to hash data in chunks
// rather than all at once. More memory efficient for large data.
pub struct XXHasher {
mut:
	// The hash algorithm being used
	algorithm DigestAlgorithm

	// Internal state pointer (opaque C structure)
	state voidptr

	// Seed value used for initialization
	seed u64
}

// Hash128 represents a 128-bit hash value
//
// The hash is stored as two 64-bit values:
// - low: Lower 64 bits of the hash
// - high: Higher 64 bits of the hash
pub struct Hash128 {
pub:
	low  u64 // Lower 64 bits of the 128-bit hash
	high u64 // Higher 64 bits of the 128-bit hash
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
// Parameters:
//   algorithm: The hash algorithm to use (xxh32, xxh64, xxh3_64, xxh3_128)
//   seed: Seed value for hash initialization (use 0 for default)
//
// Returns:
//   XXHasher instance ready for streaming updates
//
// Example:
//   ```
//   mut hasher := new_xxhasher(.xxh3_64, 42)!
//   hasher.update("hello".bytes())!
//   hasher.update(" world".bytes())!
//   result := hasher.digest()!
//   hasher.free()
//   ```
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
// This method can be called multiple times to hash data in chunks.
// More memory efficient than loading all data at once.
//
// Parameters:
//   data: Byte slice containing data to add to hash
//
// Example:
//   ```
//   mut hasher := new_xxhasher_default(.xxh3_64)!
//   hasher.update(chunk1.bytes())!
//   hasher.update(chunk2.bytes())!
//   result := hasher.digest()!
//   ```
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
// This method finalizes the hash computation and returns a HashResult
// containing hash values for all algorithm variants.
//
// Returns:
//   HashResult with 32-bit, 64-bit, and 128-bit hash values
//
// Note: After calling digest(), the hasher state remains valid and
// can be reused by calling reset() or continue updating.
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
// Parameters:
//   data: Byte slice containing data to hash
//   seed: Seed value for hash initialization
//
// Returns:
//   32-bit hash value
//
// Example:
//   ```
//   hash := xxh32_hash("hello world".bytes(), 42)
//   ```
pub fn xxh32_hash(data []u8, seed u64) u32 {
	unsafe {
		return C.XXH32(data.data, u64(data.len), u32(seed))
	}
}

// xxh64_hash computes 64-bit xxHash in one shot
//
// Parameters:
//   data: Byte slice containing data to hash
//   seed: Seed value for hash initialization
//
// Returns:
//   64-bit hash value
pub fn xxh64_hash(data []u8, seed u64) u64 {
	unsafe {
		return C.XXH64(data.data, u64(data.len), seed)
	}
}

// xxh3_hash computes XXH3 64-bit hash in one shot
//
// XXH3 is the fastest and recommended algorithm for most use cases.
//
// Parameters:
//   data: Byte slice containing data to hash
//   seed: Seed value for hash initialization
//
// Returns:
//   64-bit hash value
pub fn xxh3_hash(data []u8, seed u64) u64 {
	unsafe {
		return C.XXH3_64bits_withSeed(data.data, u64(data.len), seed)
	}
}

// xxh3_128_hash computes XXH3 128-bit hash in one shot
//
// This provides the full 128-bit hash space for applications that need
// extremely low collision probability.
//
// Parameters:
//   data: Byte slice containing data to hash
//   seed: Seed value for hash initialization
//
// Returns:
//   Hash128 struct containing the 128-bit hash value
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
// Parameters:
//   data: Byte slice containing data to hash
//
// Returns:
//   32-bit hash value
pub fn xxh32_hash_default(data []u8) u32 {
	return xxh32_hash(data, 0)
}

// xxh64_hash_default computes 64-bit xxHash with seed 0
//
// Parameters:
//   data: Byte slice containing data to hash
//
// Returns:
//   64-bit hash value
pub fn xxh64_hash_default(data []u8) u64 {
	return xxh64_hash(data, 0)
}

// xxh3_hash_default computes XXH3 64-bit hash with seed 0
//
// Parameters:
//   data: Byte slice containing data to hash
//
// Returns:
//   64-bit hash value
pub fn xxh3_hash_default(data []u8) u64 {
	return xxh3_hash(data, 0)
}

// xxh3_128_hash_default computes XXH3 128-bit hash with seed 0
//
// Parameters:
//   data: Byte slice containing data to hash
//
// Returns:
//   Hash128 struct containing the 128-bit hash value
pub fn xxh3_128_hash_default(data []u8) Hash128 {
	return xxh3_128_hash(data, 0)
}

// new_xxhasher_default creates a new streaming hasher with seed 0
//
// Parameters:
//   algorithm: The hash algorithm to use
//
// Returns:
//   XXHasher instance ready for streaming updates
pub fn new_xxhasher_default(algorithm DigestAlgorithm) !XXHasher {
	return new_xxhasher(algorithm, 0)
}

// ============================================================================
// One-shot Hex Functions
// ============================================================================

// xxh32_hash_hex computes 32-bit xxHash and returns hex string
//
// Parameters:
//   data: Byte slice containing data to hash
//   seed: Seed value for hash initialization
//
// Returns:
//   8-character hexadecimal string
pub fn xxh32_hash_hex(data []u8, seed u64) string {
	return u64_to_hex(xxh32_hash(data, seed), 8)
}

// xxh64_hash_hex computes 64-bit xxHash and returns hex string
//
// Parameters:
//   data: Byte slice containing data to hash
//   seed: Seed value for hash initialization
//
// Returns:
//   16-character hexadecimal string
pub fn xxh64_hash_hex(data []u8, seed u64) string {
	return u64_to_hex(xxh64_hash(data, seed), 16)
}

// xxh3_hash_hex computes XXH3 64-bit hash and returns hex string
//
// Parameters:
//   data: Byte slice containing data to hash
//   seed: Seed value for hash initialization
//
// Returns:
//   16-character hexadecimal string
pub fn xxh3_hash_hex(data []u8, seed u64) string {
	return u64_to_hex(xxh3_hash(data, seed), 16)
}

// xxh3_128_hash_hex computes XXH3 128-bit hash and returns hex string
//
// Parameters:
//   data: Byte slice containing data to hash
//   seed: Seed value for hash initialization
//
// Returns:
//   32-character hexadecimal string (high 16 + low 16)
pub fn xxh3_128_hash_hex(data []u8, seed u64) string {
	hash := xxh3_128_hash(data, seed)
	return u64_to_hex(hash.high, 16) + u64_to_hex(hash.low, 16)
}

// xxh32_hash_hex_default computes 32-bit xxHash with seed 0 and returns hex string
//
// Parameters:
//   data: Byte slice containing data to hash
//
// Returns:
//   8-character hexadecimal string
pub fn xxh32_hash_hex_default(data []u8) string {
	return u64_to_hex(xxh32_hash(data, 0), 8)
}

// xxh64_hash_hex_default computes 64-bit xxHash with seed 0 and returns hex string
//
// Parameters:
//   data: Byte slice containing data to hash
//
// Returns:
//   16-character hexadecimal string
pub fn xxh64_hash_hex_default(data []u8) string {
	return u64_to_hex(xxh64_hash(data, 0), 16)
}

// xxh3_hash_hex_default computes XXH3 64-bit hash with seed 0 and returns hex string
//
// Parameters:
//   data: Byte slice containing data to hash
//
// Returns:
//   16-character hexadecimal string
pub fn xxh3_hash_hex_default(data []u8) string {
	return u64_to_hex(xxh3_hash(data, 0), 16)
}

// xxh3_128_hash_hex_default computes XXH3 128-bit hash with seed 0 and returns hex string
//
// Parameters:
//   data: Byte slice containing data to hash
//
// Returns:
//   32-character hexadecimal string (high 16 + low 16)
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
