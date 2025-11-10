module main

import vxxhash

fn test_xxh32_one_shot() {
    data := "Hello, World!"
    hash := vxxhash.xxh32_hash(data.bytes(), 0)
    assert hash == 0x4007de50
    
    // Test with seed
    hash_with_seed := vxxhash.xxh32_hash(data.bytes(), 42)
    assert hash_with_seed != hash
    
    // Test default function
    hash_default := vxxhash.xxh32_hash_default(data.bytes())
    assert hash_default == hash
}

fn test_xxh64_one_shot() {
    data := "Hello, World!"
    hash := vxxhash.xxh64_hash(data.bytes(), 0)
    assert hash == 0xc49aacf8080fe47f
    
    // Test with seed
    hash_with_seed := vxxhash.xxh64_hash(data.bytes(), 42)
    assert hash_with_seed != hash
    
    // Test default function
    hash_default := vxxhash.xxh64_hash_default(data.bytes())
    assert hash_default == hash
}

fn test_xxh3_one_shot() {
    data := "Hello, World!"
    hash := vxxhash.xxh3_hash(data.bytes(), 0)
    assert hash == 0x60415d5f616602aa
    
    // Test with seed
    hash_with_seed := vxxhash.xxh3_hash(data.bytes(), 42)
    assert hash_with_seed != hash
    
    // Test default function
    hash_default := vxxhash.xxh3_hash_default(data.bytes())
    assert hash_default == hash
}

fn test_xxhasher_xxh32_streaming() {
    mut hasher := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh32, 0) or { panic(err) }
    defer { hasher.free() }
    
    data1 := "Hello, "
    data2 := "World!"
    
    hasher.update(data1.bytes()) or { panic(err) }
    hasher.update(data2.bytes()) or { panic(err) }
    
    result := hasher.digest() or { panic(err) }
    assert result.hash_32 == 0x4007de50
    
    // Test reset
    hasher.reset() or { panic(err) }
    hasher.update("Hello, World!".bytes()) or { panic(err) }
    result2 := hasher.digest() or { panic(err) }
    assert result2.hash_32 == result.hash_32
}

fn test_xxhasher_xxh64_streaming() {
    mut hasher := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh64, 0) or { panic(err) }
    defer { hasher.free() }
    
    data1 := "Hello, "
    data2 := "World!"
    
    hasher.update(data1.bytes()) or { panic(err) }
    hasher.update(data2.bytes()) or { panic(err) }
    
    result := hasher.digest() or { panic(err) }
    assert result.hash_64 == 0xc49aacf8080fe47f
    
    // Test reset
    hasher.reset() or { panic(err) }
    hasher.update("Hello, World!".bytes()) or { panic(err) }
    result2 := hasher.digest() or { panic(err) }
    assert result2.hash_64 == result.hash_64
}

fn test_xxhasher_xxh3_64_streaming() {
    mut hasher := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh3_64, 0) or { panic(err) }
    defer { hasher.free() }
    
    data1 := "Hello, "
    data2 := "World!"
    
    hasher.update(data1.bytes()) or { panic(err) }
    hasher.update(data2.bytes()) or { panic(err) }
    
    result := hasher.digest() or { panic(err) }
    assert result.hash_64 == 0x60415d5f616602aa
    
    // Test reset
    hasher.reset() or { panic(err) }
    hasher.update("Hello, World!".bytes()) or { panic(err) }
    result2 := hasher.digest() or { panic(err) }
    assert result2.hash_64 == result.hash_64
}

fn test_hex_functions() {
    data := "Hello, World!"
    
    // Test hex output functions
    hex32 := vxxhash.xxh32_hash_hex_default(data.bytes())
    hex64 := vxxhash.xxh64_hash_hex_default(data.bytes())
    hex3_64 := vxxhash.xxh3_hash_hex_default(data.bytes())
    
    assert hex32.len == 8  // 32-bit = 8 hex chars
    assert hex64.len == 16 // 64-bit = 16 hex chars
    assert hex3_64.len == 16 // 64-bit = 16 hex chars
    
    // Test hex from hasher
    mut hasher := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh64, 0) or { panic(err) }
    defer { hasher.free() }
    hasher.update(data.bytes()) or { panic(err) }
    
    hex_from_hasher := hasher.digest_hex() or { panic(err) }
    assert hex_from_hasher == hex64
}

fn test_empty_data() {
    empty := []u8{}
    
    // Test one-shot functions with empty data
    assert vxxhash.xxh32_hash(empty, 0) == 0x02cc5d05
    assert vxxhash.xxh64_hash(empty, 0) == 0xef46db3751d8e999
    assert vxxhash.xxh3_hash(empty, 0) == 0x2d06800538d394c2
}

fn test_large_data() {
    // Create 1MB of data
    mut large_data := []u8{len: 1024 * 1024, init: 0x42}
    
    // Test streaming with large data
    mut hasher := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh3_64, 0) or { panic(err) }
    defer { hasher.free() }
    
    // Update in chunks
    chunk_size := 4096
    for i := 0; i < large_data.len; i += chunk_size {
        mut end := i + chunk_size
        if end > large_data.len {
            end = large_data.len
        }
        hasher.update(large_data[i..end]) or { panic(err) }
    }
    
    stream_result := hasher.digest() or { panic(err) }
    one_shot_result := vxxhash.xxh3_hash(large_data, 0)
    
    assert stream_result.hash_64 == one_shot_result
}

fn test_algorithm_consistency() {
    data := "test data for consistency"
    seed := u64(12345)
    
    // Compare streaming vs one-shot for all algorithms
    algorithms := [vxxhash.DigestAlgorithm.xxh32, vxxhash.DigestAlgorithm.xxh64, vxxhash.DigestAlgorithm.xxh3_64]
    
    for alg in algorithms {
        mut hasher := vxxhash.new_xxhasher(alg, seed) or { panic(err) }
        defer { hasher.free() }
        
        hasher.update(data.bytes()) or { panic(err) }
        stream_result := hasher.digest() or { panic(err) }
        
        match alg {
            .xxh32 {
                one_shot := vxxhash.xxh32_hash(data.bytes(), seed)
                assert stream_result.hash_32 == one_shot
            }
            .xxh64 {
                one_shot := vxxhash.xxh64_hash(data.bytes(), seed)
                assert stream_result.hash_64 == one_shot
            }
            .xxh3_64 {
                one_shot := vxxhash.xxh3_hash(data.bytes(), seed)
                assert stream_result.hash_64 == one_shot
            }
            .xxh3_128 {
                // Note: XXH3-128 currently returns 64-bit result
                one_shot := vxxhash.xxh3_hash(data.bytes(), seed)
                assert stream_result.hash_64 == one_shot
            }
        }
    }
}

fn test_version_number() {
    version := vxxhash.xxh_version_number()
    
    // Version should be non-zero and reasonable (expecting 803 for 0.8.3)
    assert version > 0
    assert version < 10000  // Reasonable upper bound
    
    // Version should be consistent across calls
    version2 := vxxhash.xxh_version_number()
    assert version == version2
    
    println("✓ Version number test passed: ${version}")
}

fn test_hashresult_equality() {
    // Create identical hash results
    result1 := vxxhash.HashResult{
        hash_32: 0x12345678
        hash_64: 0x123456789abcdef0
        hash_128: vxxhash.Hash128{low: 0x123456789abcdef0, high: 0xfedcba9876543210}
    }
    
    result2 := vxxhash.HashResult{
        hash_32: 0x12345678
        hash_64: 0x123456789abcdef0
        hash_128: vxxhash.Hash128{low: 0x123456789abcdef0, high: 0xfedcba9876543210}
    }
    
    // Create different hash results
    result3 := vxxhash.HashResult{
        hash_32: 0x87654321
        hash_64: 0x87654321fedcba09
        hash_128: vxxhash.Hash128{low: 0x87654321fedcba09, high: 0x0123456789abcdef}
    }
    
    // Test full equality
    assert result1.is_equal(result2) == true
    assert result1.is_equal(result3) == false
    
    // Test operator overloads
    assert result1 == result2
    assert result1 != result3
    
    println("✓ HashResult equality test passed")
}

fn test_hashresult_partial_comparisons() {
    result1 := vxxhash.HashResult{
        hash_32: 0x12345678
        hash_64: 0x123456789abcdef0
        hash_128: vxxhash.Hash128{low: 0x123456789abcdef0, high: 0xfedcba9876543210}
    }
    
    result2 := vxxhash.HashResult{
        hash_32: 0x12345678  // Same 32-bit
        hash_64: 0x87654321fedcba09  // Different 64-bit
        hash_128: vxxhash.Hash128{low: 0x87654321fedcba09, high: 0x0123456789abcdef}  // Different 128-bit
    }
    
    result3 := vxxhash.HashResult{
        hash_32: 0x87654321  // Different 32-bit
        hash_64: 0x123456789abcdef0  // Same 64-bit
        hash_128: vxxhash.Hash128{low: 0x123456789abcdef0, high: 0xfedcba9876543210}  // Same 128-bit
    }
    
    // Test 32-bit comparison
    assert result1.equals_32(result2) == true
    assert result1.equals_32(result3) == false
    
    // Test 64-bit comparison
    assert result1.equals_64(result2) == false
    assert result1.equals_64(result3) == true
    
    // Test 128-bit comparison
    assert result1.equals_128(result2) == false
    assert result1.equals_128(result3) == true
    
    // Test alias function
    assert result1.is_equal_128(result2) == false
    assert result1.is_equal_128(result3) == true
    
    println("✓ HashResult partial comparison test passed")
}

fn test_hashresult_zero_detection() {
    // Test zero hash result
    zero_result := vxxhash.HashResult{}
    assert zero_result.is_zero() == true
    assert zero_result.is_zero_128() == true
    
    // Test non-zero hash result
    non_zero_result := vxxhash.HashResult{
        hash_32: 0x12345678
        hash_64: 0x123456789abcdef0,
        hash_128: vxxhash.Hash128{low: 0x123456789abcdef0, high: 0xfedcba9876543210}
    }
    assert non_zero_result.is_zero() == false
    assert non_zero_result.is_zero_128() == false
    
    // Test partially zero
    partial_zero := vxxhash.HashResult{
        hash_32: 0,
        hash_64: 0x123456789abcdef0,  // Non-zero
        hash_128: vxxhash.Hash128{low: 0, high: 0}  // Zero 128-bit
    }
    assert partial_zero.is_zero() == false  // Not all zero
    assert partial_zero.is_zero_128() == true  // 128-bit is zero
    
    println("✓ HashResult zero detection test passed")
}

fn test_hashresult_string_functions() {
    result := vxxhash.HashResult{
        hash_32: 0x12345678
        hash_64: 0x123456789abcdef0,
        hash_128: vxxhash.Hash128{low: 0x123456789abcdef0, high: 0xfedcba9876543210}
    }
    
    // Test string representation
    str_repr := result.str()
    assert str_repr.contains('32:0x12345678')
    assert str_repr.contains('64:0x123456789abcdef0')
    assert str_repr.contains('128:0xfedcba9876543210123456789abcdef0')
    
    // Test 128-bit hex string
    hex_128 := result.hex_128()
    assert hex_128 == 'fedcba9876543210123456789abcdef0'
    assert hex_128.len == 32  // 128 bits = 32 hex chars
    
    // Test zero result string
    zero_result := vxxhash.HashResult{}
    zero_str := zero_result.str()
    assert zero_str.contains('32:0x0')
    assert zero_str.contains('64:0x0')
    assert zero_str.contains('128:0x00')
    
    zero_hex_128 := zero_result.hex_128()
    assert zero_hex_128 == '00000000000000000000000000000000'
    
    println("✓ HashResult string function test passed")
}

fn test_hashresult_with_real_hashes() {
    data := "Hello, World!"
    
    // Create hash results from real xxHash computations
    hash32 := vxxhash.xxh32_hash(data.bytes(), 0)
    hash64 := vxxhash.xxh64_hash(data.bytes(), 0)
    hash128_low := hash64
    hash128_high := u64(0)
    
    result1 := vxxhash.HashResult{
        hash_32: hash32
        hash_64: hash64
        hash_128: vxxhash.Hash128{low: hash128_low, high: hash128_high}
    }
    
    // Create identical result
    result2 := vxxhash.HashResult{
        hash_32: hash32
        hash_64: hash64
        hash_128: vxxhash.Hash128{low: hash128_low, high: hash128_high}
    }
    
    // Create different result with different data
    different_data := "Different data"
    diff_hash32 := vxxhash.xxh32_hash(different_data.bytes(), 0)
    diff_hash64 := vxxhash.xxh64_hash(different_data.bytes(), 0)
    
    result3 := vxxhash.HashResult{
        hash_32: diff_hash32
        hash_64: diff_hash64
        hash_128: vxxhash.Hash128{low: diff_hash64, high: 0}
    }
    
    // Test equality with real hashes
    assert result1.is_equal(result2) == true
    assert result1 == result2
    assert result1.is_equal(result3) == false
    assert result1 != result3
    
    // Test partial comparisons
    assert result1.equals_32(result2) == true
    assert result1.equals_64(result2) == true
    assert result1.equals_128(result2) == true
    
    assert result1.equals_32(result3) == false
    assert result1.equals_64(result3) == false
    assert result1.equals_128(result3) == false
    
    println("✓ HashResult real hash test passed")
}

fn test_hashresult_edge_cases() {
    // Test maximum values
    max_result := vxxhash.HashResult{
        hash_32: u32(0xffffffff)
        hash_64: u64(0xffffffffffffffff)
        hash_128: vxxhash.Hash128{low: u64(0xffffffffffffffff), high: u64(0xffffffffffffffff)}
    }
    
    assert max_result.is_zero() == false
    assert max_result.is_zero_128() == false
    
    // Test comparison with max values
    max_result2 := vxxhash.HashResult{
        hash_32: u32(0xffffffff)
        hash_64: u64(0xffffffffffffffff)
        hash_128: vxxhash.Hash128{low: u64(0xffffffffffffffff), high: u64(0xffffffffffffffff)}
    }
    
    assert max_result.is_equal(max_result2) == true
    assert max_result == max_result2
    
    // Test single bit differences
    one_bit_diff := vxxhash.HashResult{
        hash_32: u32(0xfffffffe)  // One bit different
        hash_64: u64(0xffffffffffffffff),
        hash_128: vxxhash.Hash128{low: u64(0xffffffffffffffff), high: u64(0xffffffffffffffff)}
    }
    
    assert max_result.is_equal(one_bit_diff) == false
    assert max_result != one_bit_diff
    assert max_result.equals_32(one_bit_diff) == false
    assert max_result.equals_64(one_bit_diff) == true  // 64-bit same
    assert max_result.equals_128(one_bit_diff) == true  // 128-bit same
    
    println("✓ HashResult edge cases test passed")
}

fn main() {
    println("Running vxxhash tests...")
    
    // Original tests
    test_xxh32_one_shot()
    test_xxh64_one_shot()
    test_xxh3_one_shot()
    
    test_xxhasher_xxh32_streaming()
    test_xxhasher_xxh64_streaming()
    test_xxhasher_xxh3_64_streaming()
    
    test_hex_functions()
    test_empty_data()
    test_large_data()
    test_algorithm_consistency()
    
    // New tests for comparison functions and version
    test_version_number()
    test_hashresult_equality()
    test_hashresult_partial_comparisons()
    test_hashresult_zero_detection()
    test_hashresult_string_functions()
    test_hashresult_with_real_hashes()
    test_hashresult_edge_cases()
    
    println("All tests passed! ✅")
}