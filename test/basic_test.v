module main

import vxxhash

fn test_xxh32_one_shot() {
	data := 'Hello, World!'
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
	data := 'Hello, World!'
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
	data := 'Hello, World!'
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

	data1 := 'Hello, '
	data2 := 'World!'

	hasher.update(data1.bytes()) or { panic(err) }
	hasher.update(data2.bytes()) or { panic(err) }

	result := hasher.digest() or { panic(err) }
	assert result.hash_type == vxxhash.HashType.xxh32
	assert result.hash_128.low == 0x4007de50

	// Test reset
	hasher.reset() or { panic(err) }
	hasher.update('Hello, World!'.bytes()) or { panic(err) }
	result2 := hasher.digest() or { panic(err) }
	assert result2.hash_type == result.hash_type
	assert result2.hash_128.low == result.hash_128.low
}

fn test_xxhasher_xxh64_streaming() {
	mut hasher := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh64, 0) or { panic(err) }
	defer { hasher.free() }

	data1 := 'Hello, '
	data2 := 'World!'

	hasher.update(data1.bytes()) or { panic(err) }
	hasher.update(data2.bytes()) or { panic(err) }

	result := hasher.digest() or { panic(err) }
	assert result.hash_type == vxxhash.HashType.xxh64
	assert result.hash_128.low == 0xc49aacf8080fe47f

	// Test reset
	hasher.reset() or { panic(err) }
	hasher.update('Hello, World!'.bytes()) or { panic(err) }
	result2 := hasher.digest() or { panic(err) }
	assert result2.hash_type == result.hash_type
	assert result2.hash_128.low == result.hash_128.low
}

fn test_xxhasher_xxh3_64_streaming() {
	mut hasher := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh3_64, 0) or { panic(err) }
	defer { hasher.free() }

	data1 := 'Hello, '
	data2 := 'World!'

	hasher.update(data1.bytes()) or { panic(err) }
	hasher.update(data2.bytes()) or { panic(err) }

	result := hasher.digest() or { panic(err) }
	assert result.hash_type == vxxhash.HashType.xxh3_64
	assert result.hash_128.low == 0x60415d5f616602aa

	// Test reset
	hasher.reset() or { panic(err) }
	hasher.update('Hello, World!'.bytes()) or { panic(err) }
	result2 := hasher.digest() or { panic(err) }
	assert result2.hash_type == result.hash_type
	assert result2.hash_128.low == result.hash_128.low
}

fn test_xxh3_128_one_shot() {
	data := 'Hello, World!'
	hash := vxxhash.xxh3_128_hash(data.bytes(), 0)
	
	// Verify it's a proper 128-bit hash (both parts should be non-zero for non-empty data)
	assert hash.low != 0 || hash.high != 0
	
	// Test with seed
	hash_with_seed := vxxhash.xxh3_128_hash(data.bytes(), 42)
	assert hash_with_seed.low != hash.low || hash_with_seed.high != hash.high
	
	// Test default function
	hash_default := vxxhash.xxh3_128_hash_default(data.bytes())
	assert hash_default.low == hash.low && hash_default.high == hash.high
	
	// Test empty data
	empty_hash := vxxhash.xxh3_128_hash([], 0)
	// Empty data should produce a specific non-zero hash
	assert empty_hash.low != 0 || empty_hash.high != 0
	
	println('✓ XXH3-128 one-shot test passed')
}

fn test_xxhasher_xxh3_128_streaming() {
	mut hasher := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh3_128, 0) or { panic(err) }
	defer { hasher.free() }

	data1 := 'Hello, '
	data2 := 'World!'

	hasher.update(data1.bytes()) or { panic(err) }
	hasher.update(data2.bytes()) or { panic(err) }

	result := hasher.digest() or { panic(err) }
	
	// Verify hash type and 128-bit result
	assert result.hash_type == vxxhash.HashType.xxh3_128
	assert result.hash_128.low != 0 || result.hash_128.high != 0
	
	// Compare with one-shot result
	one_shot := vxxhash.xxh3_128_hash('Hello, World!'.bytes(), 0)
	assert result.hash_128.low == one_shot.low && result.hash_128.high == one_shot.high

	// Test reset
	hasher.reset() or { panic(err) }
	hasher.update('Hello, World!'.bytes()) or { panic(err) }
	result2 := hasher.digest() or { panic(err) }
	assert result2.hash_type == result.hash_type
	assert result2.hash_128.low == result.hash_128.low && result2.hash_128.high == result.hash_128.high
	
	println('✓ XXH3-128 streaming test passed')
}

fn test_xxh3_128_hex_functions() {
	data := 'Hello, World!'
	
	// Test hex output function
	hex128 := vxxhash.xxh3_128_hash_hex(data.bytes(), 0)
	assert hex128.len == 32 // 128-bit = 32 hex chars
	
	// Verify hex format (should be valid hex)
	for ch in hex128 {
		assert (ch >= `0` && ch <= `9`) || (ch >= `a` && ch <= `f`)
	}
	
	// Test with seed
	hex128_seed := vxxhash.xxh3_128_hash_hex(data.bytes(), 42)
	assert hex128_seed != hex128
	
	// Test default function
	hex128_default := vxxhash.xxh3_128_hash_hex_default(data.bytes())
	assert hex128_default == hex128
	
	// Test hex from hasher
	mut hasher := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh3_128, 0) or { panic(err) }
	defer { hasher.free() }
	hasher.update(data.bytes()) or { panic(err) }
	
	hex_from_hasher := hasher.digest_hex() or { panic(err) }
	assert hex_from_hasher == hex128
	
	println('✓ XXH3-128 hex function test passed')
}

fn test_xxh3_128_consistency() {
	data := 'test data for consistency'
	seed := u64(12345)
	
	// Compare streaming vs one-shot for XXH3-128
	mut hasher := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh3_128, seed) or { panic(err) }
	defer { hasher.free() }
	
	hasher.update(data.bytes()) or { panic(err) }
	stream_result := hasher.digest() or { panic(err) }
	
	one_shot := vxxhash.xxh3_128_hash(data.bytes(), seed)
	
	assert stream_result.hash_type == vxxhash.HashType.xxh3_128
	assert stream_result.hash_128.low == one_shot.low
	assert stream_result.hash_128.high == one_shot.high
	
	// Test with different data sizes
	small_data := 'hi'
	large_data := 'a'.repeat(10000)
	
	for test_data in [small_data, data, large_data] {
		mut h := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh3_128, 0) or { panic(err) }
		defer { h.free() }
		
		h.update(test_data.bytes()) or { panic(err) }
		stream_res := h.digest() or { panic(err) }
		
		one_shot_res := vxxhash.xxh3_128_hash(test_data.bytes(), 0)
		
		assert stream_res.hash_type == vxxhash.HashType.xxh3_128
		assert stream_res.hash_128.low == one_shot_res.low
		assert stream_res.hash_128.high == one_shot_res.high
	}
	
	println('✓ XXH3-128 consistency test passed')
}

fn test_xxh3_128_different_from_64bit() {
	data := 'Hello, World!'
	
	// Get 64-bit and 128-bit hashes
	hash64 := vxxhash.xxh3_hash(data.bytes(), 0)
	hash128 := vxxhash.xxh3_128_hash(data.bytes(), 0)
	
	// The low 64 bits of XXH3-128 should be different from XXH3-64
	// (they use different algorithms, so this should almost always be true)
	// Note: This might occasionally be false for specific data, but should be true for "Hello, World!"
	assert hash64 != hash128.low || hash128.high != 0
	
	// Test that 128-bit hash provides additional entropy
	assert hash128.high != 0 || hash128.low != hash64
	
	println('✓ XXH3-128 different from 64-bit test passed')
}

fn test_hex_functions() {
	data := 'Hello, World!'

	// Test hex output functions
	hex32 := vxxhash.xxh32_hash_hex_default(data.bytes())
	hex64 := vxxhash.xxh64_hash_hex_default(data.bytes())
	hex3_64 := vxxhash.xxh3_hash_hex_default(data.bytes())
	hex3_128 := vxxhash.xxh3_128_hash_hex_default(data.bytes())

	assert hex32.len == 8 // 32-bit = 8 hex chars
	assert hex64.len == 16 // 64-bit = 16 hex chars
	assert hex3_64.len == 16 // 64-bit = 16 hex chars
	assert hex3_128.len == 32 // 128-bit = 32 hex chars

	// Test hex from hasher for different algorithms
	algorithms := [
		vxxhash.DigestAlgorithm.xxh32,
		vxxhash.DigestAlgorithm.xxh64,
		vxxhash.DigestAlgorithm.xxh3_64,
		vxxhash.DigestAlgorithm.xxh3_128,
	]
	
	expected_lengths := [8, 16, 16, 32]
	
	for i, alg in algorithms {
		mut hasher := vxxhash.new_xxhasher(alg, 0) or { panic(err) }
		defer { hasher.free() }
		hasher.update(data.bytes()) or { panic(err) }

		hex_from_hasher := hasher.digest_hex() or { panic(err) }
		assert hex_from_hasher.len == expected_lengths[i]
		
		match alg {
			.xxh32 { assert hex_from_hasher == hex32 }
			.xxh64 { assert hex_from_hasher == hex64 }
			.xxh3_64 { assert hex_from_hasher == hex3_64 }
			.xxh3_128 { assert hex_from_hasher == hex3_128 }
		}
	}
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

	assert stream_result.is_xxh3_64()
	assert stream_result.get_hash() == one_shot_result
}

fn test_algorithm_consistency() {
	data := 'test data for consistency'
	seed := u64(12345)

	// Compare streaming vs one-shot for all algorithms
	algorithms := [vxxhash.DigestAlgorithm.xxh32, vxxhash.DigestAlgorithm.xxh64,
		vxxhash.DigestAlgorithm.xxh3_64, vxxhash.DigestAlgorithm.xxh3_128]

	for alg in algorithms {
		mut hasher := vxxhash.new_xxhasher(alg, seed) or { panic(err) }
		defer { hasher.free() }

		hasher.update(data.bytes()) or { panic(err) }
		stream_result := hasher.digest() or { panic(err) }

		match alg {
			.xxh32 {
				one_shot := vxxhash.xxh32_hash(data.bytes(), seed)
				assert stream_result.is_xxh32()
				assert stream_result.get_hash() == u64(one_shot)
			}
			.xxh64 {
				one_shot := vxxhash.xxh64_hash(data.bytes(), seed)
				assert stream_result.is_xxh64()
				assert stream_result.get_hash() == one_shot
			}
			.xxh3_64 {
				one_shot := vxxhash.xxh3_hash(data.bytes(), seed)
				assert stream_result.is_xxh3_64()
				assert stream_result.get_hash() == one_shot
			}
			.xxh3_128 {
				one_shot := vxxhash.xxh3_128_hash(data.bytes(), seed)
				assert stream_result.is_xxh3_128()
				assert stream_result.get_hash_128().low == one_shot.low
				assert stream_result.get_hash_128().high == one_shot.high
			}
		}
	}
}

fn test_version_number() {
	version := vxxhash.xxh_version_number()

	// Version should be non-zero and reasonable (expecting 803 for 0.8.3)
	assert version > 0
	assert version < 10000 // Reasonable upper bound

	// Version should be consistent across calls
	version2 := vxxhash.xxh_version_number()
	assert version == version2

	println('✓ Version number test passed: ${version}')
}

fn test_hashresult_equality() {
	// Create identical hash results
	result1 := vxxhash.HashResult{
		hash_type: vxxhash.HashType.xxh3_128
		hash_128: vxxhash.Hash128{
			low:  0x123456789abcdef0
			high: 0xfedcba9876543210
		}
	}

	result2 := vxxhash.HashResult{
		hash_type: vxxhash.HashType.xxh3_128
		hash_128: vxxhash.Hash128{
			low:  0x123456789abcdef0
			high: 0xfedcba9876543210
		}
	}

	// Create different hash results
	result3 := vxxhash.HashResult{
		hash_type: vxxhash.HashType.xxh3_128
		hash_128: vxxhash.Hash128{
			low:  0x87654321fedcba09
			high: 0x0123456789abcdef
		}
	}

	// Test full equality
	assert result1.is_equal(result2) == true
	assert result1.is_equal(result3) == false

	// Test operator overloads
	assert result1 == result2
	assert result1 != result3

	println('✓ HashResult equality test passed')
}

fn test_hashresult_partial_comparisons() {
	result1 := vxxhash.HashResult{
		hash_type: vxxhash.HashType.xxh3_128
		hash_128: vxxhash.Hash128{
			low:  0x123456789abcdef0
			high: 0xfedcba9876543210
		}
	}

	result2 := vxxhash.HashResult{
		hash_type: vxxhash.HashType.xxh3_128
		hash_128: vxxhash.Hash128{
			low:  0x87654321fedcba09
			high: 0x0123456789abcdef
		}
	}

	result3 := vxxhash.HashResult{
		hash_type: vxxhash.HashType.xxh3_128
		hash_128: vxxhash.Hash128{
			low:  0x123456789abcdef0
			high: 0xfedcba9876543210
		}
	}

	// Test type-based comparisons
	assert result1.is_equal(result2) == false
	assert result1.is_equal(result3) == true

	// Test operator overloads
	assert result1 != result2
	assert result1 == result3

	println('✓ HashResult partial comparison test passed')
}

fn test_hashresult_zero_detection() {
	// Test zero hash result
	zero_result := vxxhash.HashResult{
		hash_type: vxxhash.HashType.xxh3_128
		hash_128: vxxhash.Hash128{
			low:  0
			high: 0
		}
	}
	assert zero_result.is_zero() == true

	// Test non-zero hash result
	non_zero_result := vxxhash.HashResult{
		hash_type: vxxhash.HashType.xxh3_128
		hash_128: vxxhash.Hash128{
			low:  0x123456789abcdef0
			high: 0xfedcba9876543210
		}
	}
	assert non_zero_result.is_zero() == false

	println('✓ HashResult zero detection test passed')
}

fn test_hashresult_string_functions() {
	result := vxxhash.HashResult{
		hash_type: vxxhash.HashType.xxh3_128
		hash_128: vxxhash.Hash128{
			low:  0x123456789abcdef0
			high: 0xfedcba9876543210
		}
	}

	// Test string representation
	str_repr := result.str()
	assert str_repr.contains('type:xxh3_128')
	assert str_repr.contains('hash:0xfedcba9876543210123456789abcdef0')

	// Test hex string
	hex_str := result.hex()
	assert hex_str == 'fedcba9876543210123456789abcdef0'
	assert hex_str.len == 32 // 128 bits = 32 hex chars

	// Test zero result string
	zero_result := vxxhash.HashResult{
		hash_type: vxxhash.HashType.xxh3_128
		hash_128: vxxhash.Hash128{
			low:  0
			high: 0
		}
	}
	zero_str := zero_result.str()
	assert zero_str.contains('type:xxh3_128')
	assert zero_str.contains('hash:0x00')

	zero_hex_str := zero_result.hex()
	assert zero_hex_str == '00000000000000000000000000000000'
	assert zero_hex_str.len == 32

	println('✓ HashResult string function test passed')
}

fn test_hashresult_with_real_hashes() {
	data := 'Hello, World!'

	// Create hash results from real xxHash computations using hashers
	mut hasher32 := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh32, 0) or { panic(err) }
	defer { hasher32.free() }
	hasher32.update(data.bytes()) or { panic(err) }
	result1 := hasher32.digest() or { panic(err) }

	// Create identical result
	mut hasher32_2 := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh32, 0) or { panic(err) }
	defer { hasher32_2.free() }
	hasher32_2.update(data.bytes()) or { panic(err) }
	result2 := hasher32_2.digest() or { panic(err) }

	// Create different result with different data
	different_data := 'Different data'
	mut hasher32_3 := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh32, 0) or { panic(err) }
	defer { hasher32_3.free() }
	hasher32_3.update(different_data.bytes()) or { panic(err) }
	result3 := hasher32_3.digest() or { panic(err) }

	// Test equality with real hashes
	assert result1.is_equal(result2) == true
	assert result1 == result2
	assert result1.is_equal(result3) == false
	assert result1 != result3

	println('✓ HashResult real hash test passed')
}

fn test_hashresult_edge_cases() {
	// Test maximum values
	max_result := vxxhash.HashResult{
		hash_type: vxxhash.HashType.xxh3_128
		hash_128: vxxhash.Hash128{
			low:  u64(0xffffffffffffffff)
			high: u64(0xffffffffffffffff)
		}
	}

	assert max_result.is_zero() == false

	// Test comparison with max values
	max_result2 := vxxhash.HashResult{
		hash_type: vxxhash.HashType.xxh3_128
		hash_128: vxxhash.Hash128{
			low:  u64(0xffffffffffffffff)
			high: u64(0xffffffffffffffff)
		}
	}

	assert max_result.is_equal(max_result2) == true
	assert max_result == max_result2

	// Test single bit differences
	one_bit_diff := vxxhash.HashResult{
		hash_type: vxxhash.HashType.xxh3_128
		hash_128: vxxhash.Hash128{
			low:  u64(0xfffffffffffffffe) // One bit different
			high: u64(0xffffffffffffffff)
		}
	}

	assert max_result.is_equal(one_bit_diff) == false
	assert max_result != one_bit_diff

	println('✓ HashResult edge cases test passed')
}

fn test_hashresult_type_checking() {
	data := 'Hello, World!'
	
	// Test XXH32
	mut hasher32 := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh32, 0) or { panic(err) }
	defer { hasher32.free() }
	hasher32.update(data.bytes()) or { panic(err) }
	result32 := hasher32.digest() or { panic(err) }
	
	assert result32.is_xxh32() == true
	assert result32.is_xxh64() == false
	assert result32.is_xxh3_64() == false
	assert result32.is_xxh3_128() == false
	assert result32.type() == vxxhash.HashType.xxh32
	assert result32.get_hash() == u64(vxxhash.xxh32_hash(data.bytes(), 0))
	
	// Test XXH64
	mut hasher64 := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh64, 0) or { panic(err) }
	defer { hasher64.free() }
	hasher64.update(data.bytes()) or { panic(err) }
	result64 := hasher64.digest() or { panic(err) }
	
	assert result64.is_xxh32() == false
	assert result64.is_xxh64() == true
	assert result64.is_xxh3_64() == false
	assert result64.is_xxh3_128() == false
	assert result64.type() == vxxhash.HashType.xxh64
	assert result64.get_hash() == vxxhash.xxh64_hash(data.bytes(), 0)
	
	// Test XXH3_64
	mut hasher3_64 := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh3_64, 0) or { panic(err) }
	defer { hasher3_64.free() }
	hasher3_64.update(data.bytes()) or { panic(err) }
	result3_64 := hasher3_64.digest() or { panic(err) }
	
	assert result3_64.is_xxh32() == false
	assert result3_64.is_xxh64() == false
	assert result3_64.is_xxh3_64() == true
	assert result3_64.is_xxh3_128() == false
	assert result3_64.type() == vxxhash.HashType.xxh3_64
	assert result3_64.get_hash() == vxxhash.xxh3_hash(data.bytes(), 0)
	
	// Test XXH3_128
	mut hasher3_128 := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh3_128, 0) or { panic(err) }
	defer { hasher3_128.free() }
	hasher3_128.update(data.bytes()) or { panic(err) }
	result3_128 := hasher3_128.digest() or { panic(err) }
	
	assert result3_128.is_xxh32() == false
	assert result3_128.is_xxh64() == false
	assert result3_128.is_xxh3_64() == false
	assert result3_128.is_xxh3_128() == true
	assert result3_128.type() == vxxhash.HashType.xxh3_128
	
	// Test 128-bit hash retrieval
	hash128 := vxxhash.xxh3_128_hash(data.bytes(), 0)
	retrieved_hash128 := result3_128.get_hash_128()
	assert retrieved_hash128.low == hash128.low
	assert retrieved_hash128.high == hash128.high
	
	println('✓ HashResult type checking test passed')
}

fn test_hashresult_operator_overloading() {
	data := 'Hello, World!'
	
	// Test XXH32 operator overloading
	mut hasher32_1 := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh32, 0) or { panic(err) }
	defer { hasher32_1.free() }
	hasher32_1.update(data.bytes()) or { panic(err) }
	result32_1 := hasher32_1.digest() or { panic(err) }
	
	mut hasher32_2 := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh32, 0) or { panic(err) }
	defer { hasher32_2.free() }
	hasher32_2.update(data.bytes()) or { panic(err) }
	result32_2 := hasher32_2.digest() or { panic(err) }
	
	mut hasher32_3 := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh32, 42) or { panic(err) }
	defer { hasher32_3.free() }
	hasher32_3.update(data.bytes()) or { panic(err) }
	result32_3 := hasher32_3.digest() or { panic(err) }
	
	// Test equality operators for XXH32
	assert result32_1 == result32_2  // Same data, same seed
	assert result32_1 != result32_3  // Same data, different seed
	
	// Test XXH64 operator overloading
	mut hasher64_1 := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh64, 0) or { panic(err) }
	defer { hasher64_1.free() }
	hasher64_1.update(data.bytes()) or { panic(err) }
	result64_1 := hasher64_1.digest() or { panic(err) }
	
	mut hasher64_2 := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh64, 0) or { panic(err) }
	defer { hasher64_2.free() }
	hasher64_2.update(data.bytes()) or { panic(err) }
	result64_2 := hasher64_2.digest() or { panic(err) }
	
	// Test equality operators for XXH64
	assert result64_1 == result64_2
	assert result32_1 != result64_1  // Different types should not be equal
	
	// Test XXH3_64 operator overloading
	mut hasher3_64_1 := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh3_64, 0) or { panic(err) }
	defer { hasher3_64_1.free() }
	hasher3_64_1.update(data.bytes()) or { panic(err) }
	result3_64_1 := hasher3_64_1.digest() or { panic(err) }
	
	mut hasher3_64_2 := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh3_64, 0) or { panic(err) }
	defer { hasher3_64_2.free() }
	hasher3_64_2.update(data.bytes()) or { panic(err) }
	result3_64_2 := hasher3_64_2.digest() or { panic(err) }
	
	// Test equality operators for XXH3_64
	assert result3_64_1 == result3_64_2
	assert result32_1 != result3_64_1  // Different types should not be equal
	
	// Test XXH3_128 operator overloading
	mut hasher3_128_1 := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh3_128, 0) or { panic(err) }
	defer { hasher3_128_1.free() }
	hasher3_128_1.update(data.bytes()) or { panic(err) }
	result3_128_1 := hasher3_128_1.digest() or { panic(err) }
	
	mut hasher3_128_2 := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh3_128, 0) or { panic(err) }
	defer { hasher3_128_2.free() }
	hasher3_128_2.update(data.bytes()) or { panic(err) }
	result3_128_2 := hasher3_128_2.digest() or { panic(err) }
	
	mut hasher3_128_3 := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh3_128, 42) or { panic(err) }
	defer { hasher3_128_3.free() }
	hasher3_128_3.update(data.bytes()) or { panic(err) }
	result3_128_3 := hasher3_128_3.digest() or { panic(err) }
	
	// Test equality operators for XXH3_128
	assert result3_128_1 == result3_128_2  // Same data, same seed
	assert result3_128_1 != result3_128_3  // Same data, different seed
	assert result32_1 != result3_128_1  // Different types should not be equal
	
	// Test manually created HashResult objects
	manual_result1 := vxxhash.HashResult{
		hash_type: vxxhash.HashType.xxh3_128,
		hash_128: vxxhash.Hash128{
			low:  0x123456789abcdef0
			high: 0xfedcba9876543210
		}
	}
	
	manual_result2 := vxxhash.HashResult{
		hash_type: vxxhash.HashType.xxh3_128,
		hash_128: vxxhash.Hash128{
			low:  0x123456789abcdef0
			high: 0xfedcba9876543210
		}
	}
	
	manual_result3 := vxxhash.HashResult{
		hash_type: vxxhash.HashType.xxh3_128,
		hash_128: vxxhash.Hash128{
			low:  0x87654321fedcba09
			high: 0xfedcba9876543210
		}
	}
	
	manual_result4 := vxxhash.HashResult{
		hash_type: vxxhash.HashType.xxh64,  // Different type
		hash_128: vxxhash.Hash128{
			low:  0x123456789abcdef0
			high: 0
		}
	}
	
	// Test equality with manual objects
	assert manual_result1 == manual_result2  // Identical
	assert manual_result1 != manual_result3  // Different low bits
	assert manual_result1 != manual_result4  // Different types
	
	// Test transitivity: if a == b and b == c, then a == c
	assert manual_result1 == manual_result2
	assert manual_result2 == manual_result1  // Symmetric
	// All should be equal to themselves
	assert manual_result1 == manual_result1
	assert manual_result2 == manual_result2
	assert manual_result3 == manual_result3
	assert manual_result4 == manual_result4
	
	println('✓ HashResult operator overloading test passed')
}

fn main() {
	println('Running vxxhash tests...')

	// Original tests
	test_xxh32_one_shot()
	test_xxh64_one_shot()
	test_xxh3_one_shot()

	test_xxhasher_xxh32_streaming()
	test_xxhasher_xxh64_streaming()
	test_xxhasher_xxh3_64_streaming()

	// New 128-bit tests
	test_xxh3_128_one_shot()
	test_xxhasher_xxh3_128_streaming()
	test_xxh3_128_hex_functions()
	test_xxh3_128_consistency()
	test_xxh3_128_different_from_64bit()

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
	test_hashresult_type_checking()
	test_hashresult_operator_overloading()

	println('All tests passed! ✅')
}
