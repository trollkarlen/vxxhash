module vxxhash

#flag -I/opt/homebrew/Cellar/xxhash/0.8.3/include
#flag -L/opt/homebrew/Cellar/xxhash/0.8.3/lib
#flag -lxxhash

#include <xxhash.h>

type Size_t = u64

// C function declarations
fn C.XXH_versionNumber() u32
fn C.XXH32(voidptr, Size_t, u32) u32
fn C.XXH64(voidptr, Size_t, u64) u64
fn C.XXH3_64bits_withSeed(voidptr, Size_t, u64) u64

fn C.XXH32_createState() voidptr
fn C.XXH32_freeState(voidptr) int
fn C.XXH32_reset(voidptr, u32) int
fn C.XXH32_update(voidptr, voidptr, Size_t) int
fn C.XXH32_digest(voidptr) u32

fn C.XXH64_createState() voidptr
fn C.XXH64_freeState(voidptr) int
fn C.XXH64_reset(voidptr, u64) int
fn C.XXH64_update(voidptr, voidptr, Size_t) int
fn C.XXH64_digest(voidptr) u64

fn C.XXH3_createState() voidptr
fn C.XXH3_freeState(voidptr) int
fn C.XXH3_64bits_reset_withSeed(voidptr, u64) int
fn C.XXH3_64bits_update(voidptr, voidptr, Size_t) int
fn C.XXH3_64bits_digest(voidptr) u64

pub enum DigestAlgorithm {
    xxh32    // 32-bit hash
    xxh64    // 64-bit hash  
    xxh3_64  // XXH3 64-bit (default, fastest)
    xxh3_128 // XXH3 128-bit
}

pub struct XXHasher {
mut:
    algorithm DigestAlgorithm
    state     voidptr
    seed      u64
}

pub struct Hash128 {
pub:
    low  u64
    high u64
}

pub struct HashResult {
pub:
    hash_32  u32
    hash_64  u64
    hash_128 Hash128
}

// HashResult comparison methods

// Check if all hash values are equal
pub fn (h HashResult) is_equal(other HashResult) bool {
    return h.hash_32 == other.hash_32 && 
           h.hash_64 == other.hash_64 && 
           h.hash_128.low == other.hash_128.low && 
           h.hash_128.high == other.hash_128.high
}

// Compare only 32-bit hash
pub fn (h HashResult) equals_32(other HashResult) bool {
    return h.hash_32 == other.hash_32
}

// Compare only 64-bit hash
pub fn (h HashResult) equals_64(other HashResult) bool {
    return h.hash_64 == other.hash_64
}

// Compare only 128-bit hash
pub fn (h HashResult) equals_128(other HashResult) bool {
    return h.hash_128.low == other.hash_128.low && 
           h.hash_128.high == other.hash_128.high
}

// Alias for equals_128 for consistency with xxHash API
pub fn (h HashResult) is_equal_128(other HashResult) bool {
    return h.equals_128(other)
}

// Check if 128-bit hash is zero
pub fn (h HashResult) is_zero_128() bool {
    return h.hash_128.low == 0 && h.hash_128.high == 0
}

// Check if all hashes are zero
pub fn (h HashResult) is_zero() bool {
    return h.hash_32 == 0 && h.hash_64 == 0 && h.is_zero_128()
}

// Get 128-bit hash as combined hex string
pub fn (h HashResult) hex_128() string {
    return u64_to_hex(h.hash_128.high, 16) + u64_to_hex(h.hash_128.low, 16)
}

// String representation of all hash values
pub fn (h HashResult) str() string {
    return 'HashResult{32:0x${h.hash_32:x} 64:0x${h.hash_64:x} 128:0x${h.hash_128.high:x}${h.hash_128.low:x}}'
}

// Support == operator for HashResult
pub fn (h HashResult) == (other HashResult) bool {
    return h.is_equal(other)
}

// Create new XXHasher with specified algorithm and seed
pub fn new_xxhasher(algorithm DigestAlgorithm, seed u64) !XXHasher {
    mut hasher := XXHasher{
        algorithm: algorithm
        seed: seed
        state: voidptr(0)
    }
    
    match algorithm {
        .xxh32 {
            hasher.state = C.XXH32_createState()
            if hasher.state == voidptr(0) {
                return error("Failed to create XXH32 state")
            }
            if C.XXH32_reset(hasher.state, u32(seed)) != 0 {
                return error("Failed to reset XXH32 state")
            }
        }
        .xxh64 {
            hasher.state = C.XXH64_createState()
            if hasher.state == voidptr(0) {
                return error("Failed to create XXH64 state")
            }
            if C.XXH64_reset(hasher.state, seed) != 0 {
                return error("Failed to reset XXH64 state")
            }
        }
        .xxh3_64 {
            hasher.state = C.XXH3_createState()
            if hasher.state == voidptr(0) {
                return error("Failed to create XXH3 state")
            }
            if C.XXH3_64bits_reset_withSeed(hasher.state, seed) != 0 {
                return error("Failed to reset XXH3 state")
            }
        }
        .xxh3_128 {
            hasher.state = C.XXH3_createState()
            if hasher.state == voidptr(0) {
                return error("Failed to create XXH3 state")
            }
            // XXH3-128 uses same state as XXH3-64, just different digest
            if C.XXH3_64bits_reset_withSeed(hasher.state, seed) != 0 {
                return error("Failed to reset XXH3 state")
            }
        }
    }
    
    return hasher
}

// Update hash with new data
pub fn (mut h XXHasher) update(data []u8) ! {
    if h.state == voidptr(0) {
        return error("Hasher not initialized")
    }
    
    unsafe {
        match h.algorithm {
            .xxh32 {
                if C.XXH32_update(h.state, data.data, u64(data.len)) != 0 {
                    return error("Failed to update XXH32")
                }
            }
            .xxh64 {
                if C.XXH64_update(h.state, data.data, u64(data.len)) != 0 {
                    return error("Failed to update XXH64")
                }
            }
            .xxh3_64 {
                if C.XXH3_64bits_update(h.state, data.data, u64(data.len)) != 0 {
                    return error("Failed to update XXH3")
                }
            }
            .xxh3_128 {
                if C.XXH3_64bits_update(h.state, data.data, u64(data.len)) != 0 {
                    return error("Failed to update XXH3")
                }
            }
        }
    }
}

// Get final hash digest - returns u64 for 32/64-bit algorithms, Hash128 for 128-bit
pub fn (h &XXHasher) digest() !HashResult {
    if h.state == voidptr(0) {
        return error("Hasher not initialized")
    }
    
    unsafe {
        match h.algorithm {
            .xxh32 {
                hash32 := C.XXH32_digest(h.state)
                return HashResult{hash_32: hash32, hash_64: u64(hash32), hash_128: Hash128{low: u64(hash32), high: 0}}
            }
            .xxh64 {
                hash64 := C.XXH64_digest(h.state)
                return HashResult{hash_32: u32(hash64), hash_64: hash64, hash_128: Hash128{low: hash64, high: 0}}
            }
            .xxh3_64 {
                hash64 := C.XXH3_64bits_digest(h.state)
                return HashResult{hash_32: u32(hash64), hash_64: hash64, hash_128: Hash128{low: hash64, high: 0}}
            }
            .xxh3_128 {
                // For XXH3-128, we need to call the 128-bit digest function
                // Since we can't easily access the C struct, we'll return 64-bit for now
                // TODO: Implement proper 128-bit support
                hash64 := C.XXH3_64bits_digest(h.state)
                return HashResult{hash_32: u32(hash64), hash_64: hash64, hash_128: Hash128{low: hash64, high: 0}}
            }
        }
    }
}

// Helper function to convert u64 to hex string
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

// Get digest as hex string
pub fn (h &XXHasher) digest_hex() !string {
    result := h.digest()!
    match h.algorithm {
        .xxh32 {
            return u64_to_hex(result.hash_32, 8)
        }
        .xxh64, .xxh3_64 {
            return u64_to_hex(result.hash_64, 16)
        }
        .xxh3_128 {
            return u64_to_hex(result.hash_128.low, 16) + u64_to_hex(result.hash_128.high, 16)
        }
    }
}

// Reset hasher to initial state with same seed
pub fn (mut h XXHasher) reset() ! {
    if h.state == voidptr(0) {
        return error("Hasher not initialized")
    }
    
    unsafe {
        match h.algorithm {
            .xxh32 {
                if C.XXH32_reset(h.state, u32(h.seed)) != 0 {
                    return error("Failed to reset XXH32")
                }
            }
            .xxh64 {
                if C.XXH64_reset(h.state, h.seed) != 0 {
                    return error("Failed to reset XXH64")
                }
            }
            .xxh3_64 {
                if C.XXH3_64bits_reset_withSeed(h.state, h.seed) != 0 {
                    return error("Failed to reset XXH3")
                }
            }
            .xxh3_128 {
                if C.XXH3_64bits_reset_withSeed(h.state, h.seed) != 0 {
                    return error("Failed to reset XXH3")
                }
            }
        }
    }
}

// Free internal state
pub fn (mut h XXHasher) free() {
    if h.state != voidptr(0) {
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
        h.state = voidptr(0)
    }
}

// One-shot hashing functions

// XXH32 one-shot hash
pub fn xxh32_hash(data []u8, seed u64) u32 {
    unsafe {
        return C.XXH32(data.data, u64(data.len), u32(seed))
    }
}

// XXH64 one-shot hash
pub fn xxh64_hash(data []u8, seed u64) u64 {
    unsafe {
        return C.XXH64(data.data, u64(data.len), seed)
    }
}

// XXH3 64-bit one-shot hash
pub fn xxh3_hash(data []u8, seed u64) u64 {
    unsafe {
        return C.XXH3_64bits_withSeed(data.data, u64(data.len), seed)
    }
}

// Convenience functions with default seed (0)

pub fn xxh32_hash_default(data []u8) u32 {
    return xxh32_hash(data, 0)
}

pub fn xxh64_hash_default(data []u8) u64 {
    return xxh64_hash(data, 0)
}

pub fn xxh3_hash_default(data []u8) u64 {
    return xxh3_hash(data, 0)
}

// Create hasher with default seed (0)
pub fn new_xxhasher_default(algorithm DigestAlgorithm) !XXHasher {
    return new_xxhasher(algorithm, 0)
}

// One-shot hex functions
pub fn xxh32_hash_hex(data []u8, seed u64) string {
    return u64_to_hex(xxh32_hash(data, seed), 8)
}

pub fn xxh64_hash_hex(data []u8, seed u64) string {
    return u64_to_hex(xxh64_hash(data, seed), 16)
}

pub fn xxh3_hash_hex(data []u8, seed u64) string {
    return u64_to_hex(xxh3_hash(data, seed), 16)
}

pub fn xxh32_hash_hex_default(data []u8) string {
    return u64_to_hex(xxh32_hash(data, 0), 8)
}

pub fn xxh64_hash_hex_default(data []u8) string {
    return u64_to_hex(xxh64_hash(data, 0), 16)
}

pub fn xxh3_hash_hex_default(data []u8) string {
    return u64_to_hex(xxh3_hash(data, 0), 16)
}

// Get xxHash library version number
pub fn xxh_version_number() u32 {
    return C.XXH_versionNumber()
}