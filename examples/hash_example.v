// xxHash Basic Usage Example
//
// This example demonstrates the fundamental usage patterns of the vxxhash module:
// 1. One-shot hashing: Process entire data at once (simplest approach)
// 2. Streaming hashing: Process data in chunks (memory-efficient for large data)
// 3. Multiple hash algorithms: Compare different xxHash variants
//
// When to use each approach:
// - One-shot: Small to medium files, simple use cases, maximum convenience
// - Streaming: Large files, memory constraints, network streams, real-time processing
//
// vxxhash algorithms demonstrated:
// - XXH32: 32-bit hash, fast, good for hash tables (legacy)
// - XXH64: 64-bit hash, very fast, excellent for general purpose
// - XXH3-64: 64-bit hash, fastest on modern CPUs, recommended for new code

module main

import os
import cli
import vxxhash

fn main() {
	mut app := cli.Command{
		name:        'hash_example'
		description: 'Demonstrate xxHash algorithms on a file'
		version:     '1.0.0'
		flags:       [
			cli.Flag{
				name:        'file'
				abbrev:      'f'
				description: 'File to hash (required)'
				flag:        .string
				required:    true
			},
			cli.Flag{
				name:          'data'
				abbrev:        'd'
				description:   'Use test data instead of file'
				flag:          .string
				default_value: ['Hello World']
			},
			cli.Flag{
				name:          'chunk-size'
				abbrev:        'c'
				description:   'Chunk size for streaming (default: 4096)'
				flag:          .int
				default_value: ['4096']
			},
		]
	}

	app.parse(os.args)

	file_path := app.flags.get_string('file') or { '' }
	test_data := app.flags.get_string('data') or { 'Hello World' }
	chunk_size := app.flags.get_int('chunk-size') or { 4096 }

	data := if file_path != '' {
		if !os.exists(file_path) {
			eprintln('Error: File not found: ${file_path}')
			exit(1)
		}
		os.read_file(file_path) or {
			eprintln('Error reading file: ${err}')
			exit(1)
		}
	} else {
		test_data
	}

	file_size := data.len

	println('=== xxHash Demonstration ===')
	if file_path != '' {
		println('File: ${file_path}')
	} else {
		println('Using test data: "${test_data}"')
	}
	println('Size: ${file_size} bytes')
	println('Chunk size: ${chunk_size} bytes')
	println('')

	// One-shot hashing demonstration
	//
	// One-shot functions are the simplest way to use xxHash:
	// - vxxhash.xxh32_hash_hex_default(): Compute 32-bit hash and return as hex string
	// - vxxhash.xxh64_hash_hex_default(): Compute 64-bit hash and return as hex string
	// - vxxhash.xxh3_hash_hex_default(): Compute XXH3 64-bit hash and return as hex string
	//
	// These functions use a default seed (0) and handle the entire data at once.
	// They're ideal for small to medium datasets that fit comfortably in memory.
	// The hex output is convenient for display, storage, or comparison purposes.
	println('=== One-shot Hashing ===')
	hash32_hex := vxxhash.xxh32_hash_hex_default(data.bytes())
	hash64_hex := vxxhash.xxh64_hash_hex_default(data.bytes())
	hash3_64_hex := vxxhash.xxh3_hash_hex_default(data.bytes())

	println('XXH32:     ${hash32_hex}')
	println('XXH64:     ${hash64_hex}')
	println('XXH3-64:   ${hash3_64_hex}')
	println('')

	// Streaming hashing demonstration
	//
	// Streaming hashing is essential for:
	// - Large files that don't fit in memory
	// - Network streams or real-time data processing
	// - Memory-constrained environments
	// - When data arrives incrementally
	//
	// Key vxxhash streaming APIs demonstrated:
	// 1. vxxhash.new_xxhasher(): Create a new streaming hasher instance
	// 2. hasher.update(): Feed data chunks to the hasher (can be called multiple times)
	// 3. hasher.digest(): Get the final hash result as a Hash object
	// 4. hasher.digest_hex(): Get the final hash as a hex string
	// 5. hasher.free(): Clean up resources (important for memory management)
	//
	// The streaming approach produces identical results to one-shot hashing,
	// but allows processing data in manageable chunks.
	println('=== Streaming Hashing (XXH3-64) ===')
	mut hasher := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh3_64, 0) or { panic(err) }
	defer { hasher.free() } // Always free the hasher to prevent memory leaks

	// Process data in chunks to simulate real-world streaming scenarios
	for i := 0; i < data.len; i += chunk_size {
		mut end := i + chunk_size
		if end > data.len {
			end = data.len
		}

		// hasher.update() processes each chunk and maintains internal state
		// This is the core of streaming: incremental data processing
		hasher.update(data[i..end].bytes()) or { panic(err) }
	}

	// Get the final hash result in multiple formats
	stream_result := hasher.digest() or { panic(err) } // HashResult object
	stream_hex := hasher.digest_hex() or { panic(err) } // Hex string
	one_shot_hex := vxxhash.xxh3_hash_hex_default(data.bytes()) // For comparison

	println('Streaming:  ${stream_hex}')
	println('One-shot:   ${one_shot_hex}')
	println('Match:       ${stream_hex == one_shot_hex}') // Should always be true
	println('Hash result:  ${stream_result.get_hash():x}') // Raw hash value
	println('Hash type:    ${stream_result.type()}') // Algorithm information
	println('Hash hex:     ${stream_result.hex()}') // Formatted hex string
}
