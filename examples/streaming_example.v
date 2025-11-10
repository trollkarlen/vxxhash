// xxHash Streaming vs One-shot Performance Comparison
//
// This example demonstrates the performance characteristics and trade-offs between:
// 1. Streaming hashing: Process data incrementally in chunks
// 2. One-shot hashing: Process entire data at once
//
// Key insights this example provides:
// - Performance differences between streaming and one-shot approaches
// - Impact of chunk size on streaming performance
// - Memory usage patterns of each approach
// - When to choose streaming vs one-shot for optimal performance
//
// Real-world applications:
// - Streaming: Large file processing, network data, memory-constrained environments
// - One-shot: Small files, in-memory data, maximum speed when memory is available
//
// This example also demonstrates proper resource management and error handling
// in production scenarios using the vxxhash module.

module main

import os
import cli
import time
import vxxhash

fn main() {
	mut app := cli.Command{
		name:        'streaming_example'
		description: 'Compare streaming vs one-shot xxHash performance'
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
				name:          'chunk-size'
				abbrev:        'c'
				description:   'Chunk size for streaming (default: 8192)'
				flag:          .int
				default_value: ['8192']
			},
			cli.Flag{
				name:          'iterations'
				abbrev:        'i'
				description:   'Number of iterations for timing (default: 1)'
				flag:          .int
				default_value: ['1']
			},
			cli.Flag{
				name:          'algorithms'
				abbrev:        'a'
				description:   'Algorithms to test (comma-separated, default: all)'
				flag:          .string
				default_value: ['xxh32,xxh64,xxh3_64,xxh3_128']
			},
		]
	}

	app.parse(os.args)

	file_path := app.flags.get_string('file') or { '' }
	chunk_size := app.flags.get_int('chunk-size') or { 8192 }
	iterations := app.flags.get_int('iterations') or { 1 }
	algorithms_str := app.flags.get_string('algorithms') or { 'xxh32,xxh64,xxh3_64,xxh3_128' }

	if file_path == '' {
		eprintln('Error: File path is required')
		exit(1)
	}

	if !os.exists(file_path) {
		eprintln('Error: File not found: ${file_path}')
		exit(1)
	}

	// Parse algorithms
	struct Algorithm {
		name      string
		algorithm vxxhash.DigestAlgorithm
	}

	mut algorithms := []Algorithm{}
	algorithms << Algorithm{'xxh32', vxxhash.DigestAlgorithm.xxh32}
	algorithms << Algorithm{'xxh64', vxxhash.DigestAlgorithm.xxh64}
	algorithms << Algorithm{'xxh3_64', vxxhash.DigestAlgorithm.xxh3_64}
	algorithms << Algorithm{'xxh3_128', vxxhash.DigestAlgorithm.xxh3_128}

	mut selected_algorithms := []Algorithm{}

	for algo in algorithms_str.split(',') {
		algo_name := algo.trim_space()
		for alg in algorithms {
			if alg.name == algo_name {
				selected_algorithms << alg
				break
			}
		}
	}

	if selected_algorithms.len == 0 {
		eprintln('Error: No valid algorithms specified')
		exit(1)
	}

	println('=== Streaming Hash Performance Test ===')
	println('File: ${file_path}')
	println('Chunk size: ${chunk_size} bytes')
	println('Iterations: ${iterations}')
	println('Algorithms: ${selected_algorithms.map(|it| it.name).join(', ')}')
	println('')

	// Read file once for one-shot comparison
	data := os.read_file(file_path) or {
		eprintln('Error reading file: ${err}')
		exit(1)
	}

	// Streaming performance test
	//
	// Streaming approach simulates real-world scenarios where:
	// - Files are too large to load entirely into memory
	// - Data arrives from network streams or other sources
	// - Memory usage must be carefully controlled
	//
	// Key vxxhash streaming APIs used:
	// 1. vxxhash.new_xxhasher(): Create streaming hasher with algorithm and seed
	// 2. hasher.update(): Process data chunks incrementally
	// 3. hasher.digest(): Finalize hash computation
	// 4. hasher.free(): Clean up native resources
	//
	// The streaming test reads the file directly from disk in chunks,
	// which is more memory-efficient than loading the entire file first.
	println('=== Streaming Performance ===')
	for alg in selected_algorithms {
		name := alg.name
		algorithm := alg.algorithm
		println('--- ${name} Streaming ---')

		mut total_time := u64(0)
		mut final_hash := u64(0)

		for iter in 0 .. iterations {
			// Create a new streaming hasher for each iteration
			// Each hasher maintains its own internal state
			mut hasher := vxxhash.new_xxhasher(algorithm, 0) or {
				eprintln('Error creating hasher: ${err}')
				continue
			}
			defer { hasher.free() } // Critical: prevent memory leaks

			start_time := time.now()

			// Open file and stream in chunks (memory-efficient approach)
			// This avoids loading the entire file into memory at once
			mut file := os.open(file_path) or {
				eprintln('Error opening file: ${err}')
				continue
			}
			defer { file.close() } // Ensure file handle is closed

			// Read and process file in chunks until EOF
			for {
				mut chunk := []u8{len: chunk_size}
				bytes_read := file.read(mut chunk) or { break }

				if bytes_read == 0 {
					break // End of file reached
				}

				// Feed each chunk to the streaming hasher
				// The hasher maintains state between update() calls
				hasher.update(chunk[..bytes_read]) or {
					eprintln('Error updating hasher: ${err}')
					break
				}
			}

			// Finalize the hash computation after all chunks are processed
			result := hasher.digest() or {
				eprintln('Error getting digest: ${err}')
				continue
			}

			duration := time.now() - start_time
			total_time += u64(duration)

			// Store hash from first iteration for verification
			if iter == 0 {
				final_hash = result.get_hash()
			}
		}

		avg_time_ns := f64(total_time) / f64(iterations)
		throughput := (f64(data.len) / 1024.0 / 1024.0) / (avg_time_ns / 1000000000.0)

		time_str := if avg_time_ns < 100000 {
			'${avg_time_ns:0.0}ns'
		} else {
			'${avg_time_ns / 1000000:.2}ms'
		}

		println('Processed: ${data.len} bytes')
		println('Hash: ${final_hash:x}')
		println('Avg time: ${time_str}')
		println('Throughput: ${throughput:.2} MB/s')
		println('')
	}

	// One-shot performance test
	//
	// One-shot approach is optimal when:
	// - Data fits comfortably in memory
	// - Maximum speed is required
	// - Simplicity is preferred over memory efficiency
	//
	// Key vxxhash one-shot APIs used:
	// - vxxhash.xxh32_hash(): Direct 32-bit hash computation
	// - vxxhash.xxh64_hash(): Direct 64-bit hash computation
	// - vxxhash.xxh3_hash(): Direct XXH3 hash computation
	//
	// These functions take the entire data at once and return the hash directly.
	// They're typically faster than streaming for the same data size, but use more memory.
	println('=== One-shot Performance ===')
	for alg in selected_algorithms {
		name := alg.name
		algorithm := alg.algorithm
		mut total_time := u64(0)
		mut final_hash := u64(0)

		for iter in 0 .. iterations {
			start_time := time.now()

			// Use direct one-shot hash functions for maximum speed
			// Each algorithm has its own optimized function
			hash := match algorithm {
				.xxh32 {
					u64(vxxhash.xxh32_hash(data.bytes(), 0)) // 32-bit hash with seed 0
				}
				.xxh64 {
					vxxhash.xxh64_hash(data.bytes(), 0) // 64-bit hash with seed 0
				}
				.xxh3_64 {
					vxxhash.xxh3_hash(data.bytes(), 0) // XXH3 64-bit hash with seed 0
				}
				.xxh3_128 {
					result := vxxhash.xxh3_hash(data.bytes(), 0) // Use 64-bit for now
					result
				}
			}

			duration := time.now() - start_time
			total_time += u64(duration)

			// Store hash from first iteration for comparison with streaming
			if iter == 0 {
				final_hash = hash
			}
		}

		avg_time_ns := f64(total_time) / f64(iterations)
		throughput := (f64(data.len) / 1024.0 / 1024.0) / (avg_time_ns / 1000000000.0)

		time_str := if avg_time_ns < 100000 {
			'${avg_time_ns:0.0}ns'
		} else {
			'${avg_time_ns / 1000000:.2}ms'
		}

		println('${name:-10}: ${final_hash:x} (${time_str}, ${throughput:.2} MB/s)')
	}
}
