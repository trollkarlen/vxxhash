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

fn main() {
    println("Running vxxhash tests...")
    
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
    
    println("All tests passed! ✅")
}