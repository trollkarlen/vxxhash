// xxHash Performance Benchmark Tool
//
// This example demonstrates comprehensive usage of the vxxhash module for performance testing.
// It shows both one-shot hashing (entire data at once) and streaming hashing (data in chunks).
//
// Key vxxhash features demonstrated:
// - Multiple hash algorithms: xxh32, xxh64, xxh3_64, xxh3_128
// - One-shot hash functions for simple use cases
// - Streaming hasher for large files or memory-constrained scenarios
// - Performance optimization through chunk size tuning
//
// Use cases for different approaches:
// - One-shot: Best for small to medium files that fit in memory
// - Streaming: Essential for large files, network streams, or memory-limited environments
// - Chunk optimization: Critical for achieving maximum throughput in streaming scenarios

module main

import os
import cli
import time
import vxxhash

// format_time formats execution time for human readability
// Shows nanoseconds for very fast operations (< 0.1ms) and milliseconds for slower ones
// This helps users understand the performance characteristics at different scales
fn format_time(time_ns f64) string {
	if time_ns < 100000 { // < 0.1ms
		return '${time_ns:0.0} ns'
	} else {
		return '${time_ns / 1000000:.2} ms'
	}
}

// format_bytes converts byte counts to human-readable units
// Essential for displaying file sizes and chunk sizes in an intuitive way
// Helps users understand the scale of data being processed
fn format_bytes(bytes f64) string {
	if bytes < 1024 {
		return '${bytes:0.0} B'
	} else if bytes < 1024 * 1024 {
		return '${bytes / 1024:.1f} KB'
	} else if bytes < 1024 * 1024 * 1024 {
		return '${bytes / (1024 * 1024):.1f} MB'
	} else {
		return '${bytes / (1024 * 1024 * 1024):.1f} GB'
	}
}

// Format bytes for table display (right-aligned with consistent width)
fn format_bytes_table(bytes f64) string {
	if bytes < 1024 {
		return '${bytes:8.0f} B'
	} else if bytes < 1024 * 1024 {
		return '${bytes / 1024:7.1f} KB'
	} else if bytes < 1024 * 1024 * 1024 {
		return '${bytes / (1024 * 1024):7.1f} MB'
	} else {
		return '${bytes / (1024 * 1024 * 1024):7.1f} GB'
	}
}

// Format throughput in appropriate unit (MB/s or GB/s)
fn format_throughput(throughput f64) string {
	if throughput >= 1000 {
		return '${throughput / 1024:.2f} GB/s'
	} else {
		return '${throughput:.2f} MB/s'
	}
}

// ChunkResult stores performance metrics for each chunk size tested
// Used to analyze and compare the performance characteristics of different chunk sizes
// This data helps identify the optimal chunk size for maximum throughput
struct ChunkResult {
	chunk_size int // Size of data chunks processed in each iteration
	avg_time   f64 // Average time taken to hash the entire file with this chunk size
	throughput f64 // Data processing rate in MB/s or GB/s
}

// find_optimal_chunk_size determines the best chunk size for streaming hash operations
//
// Why chunk size matters:
// - Too small: Excessive function call overhead, poor performance
// - Too large: Memory inefficiency, cache misses, potential memory pressure
// - Just right: Balances function call overhead with memory efficiency for maximum throughput
//
// This function tests various chunk sizes and recommends the optimal one based on:
// 1. Raw performance (fastest execution time)
// 2. Memory efficiency (prefers smaller chunks with similar performance)
//
// The vxxhash streaming interface is used here to simulate real-world scenarios where:
// - Files are too large to fit in memory
// - Data arrives from network streams
// - Memory usage must be controlled
fn find_optimal_chunk_size(data []u8, algorithm vxxhash.DigestAlgorithm, iterations int, file_path string, algorithm_name string) !int {
	file_size := f64(data.len)
	println('=== Finding Optimal Chunk Size ===')
	println('File: ${file_path}')
	println('Size: ${file_size} bytes (${file_size / 1024.0 / 1024.0:.2} MB)')
	println('Algorithm: ${algorithm_name}')
	println('Running ${iterations} iterations per chunk size')
	println('')

	// Generate chunk sizes from 4KB to 8MB with logarithmic scaling
	mut chunk_sizes := []int{}

	// Start with 4KB and double until we reach 8MB
	mut current_size := 4096
	for current_size <= 8 * 1024 * 1024 {
		chunk_sizes << current_size
		current_size *= 2
	}

	// Add some intermediate sizes for better granularity
	intermediate_sizes := [6 * 1024, 12 * 1024, 24 * 1024, 48 * 1024, 96 * 1024, 192 * 1024,
		384 * 1024, 768 * 1024, 1536 * 1024, 3072 * 1024, 6144 * 1024]

	for size in intermediate_sizes {
		if size > 4096 && size < 8 * 1024 * 1024 {
			chunk_sizes << size
		}
	}

	// Sort and remove duplicates
	chunk_sizes.sort()
	chunk_sizes = chunk_sizes.filter(it > 0 && it <= data.len)

	if chunk_sizes.len == 0 {
		chunk_sizes << data.len
	}

	if chunk_sizes.len > 0 {
		last_idx := chunk_sizes.len - 1
		println('Testing ${chunk_sizes.len} chunk sizes from ${format_bytes_table(f64(chunk_sizes[0]))} to ${format_bytes_table(f64(chunk_sizes[last_idx]))}')
	} else {
		println('No valid chunk sizes to test')
		return data.len
	}
	println('Chunk Size | Avg Time | Throughput')
	println('-----------|----------|-----------')

	mut results := []ChunkResult{}

	for chunk_size in chunk_sizes {
		mut times := []u64{cap: iterations}

		for i := 0; i < iterations; i++ {
			// Create a new streaming hasher for each iteration
			// vxxhash.new_xxhasher() creates a hasher instance that can process data incrementally
			// The seed (0) ensures reproducible results across runs
			mut hasher := vxxhash.new_xxhasher(algorithm, 0) or {
				eprintln('Error creating hasher: ${err}')
				continue
			}
			defer { hasher.free() } // Clean up resources to prevent memory leaks

			start_time := time.now()

			// Process data in chunks to simulate streaming scenarios
			// This is the core of streaming hashing: breaking large data into manageable pieces
			// Each chunk is processed independently but contributes to the final hash
			for j := 0; j < data.len; j += chunk_size {
				mut end := j + chunk_size
				if end > data.len {
					end = data.len
				}
				// hasher.update() feeds data to the streaming hasher
				// This method can be called multiple times with different data chunks
				// The hasher maintains internal state between calls
				hasher.update(data[j..end]) or {
					eprintln('Error updating hasher: ${err}')
					break
				}
			}

			// hasher.digest() finalizes the hash computation and returns the result
			// After calling digest(), the hasher is reset and can be reused or freed
			hasher.digest() or {
				eprintln('Error getting digest: ${err}')
				continue
			}

			elapsed := time.now() - start_time
			times << u64(elapsed.nanoseconds())
		}

		// Calculate average time and throughput
		mut total_time := u64(0)
		for t in times {
			total_time += t
		}
		avg_time := f64(total_time) / f64(iterations)
		throughput := (file_size / 1024.0 / 1024.0) / (avg_time / 1000000000.0)

		results << ChunkResult{
			chunk_size: chunk_size
			avg_time:   avg_time
			throughput: throughput
		}

		chunk_str := format_bytes_table(f64(chunk_size))
		time_str := format_time(avg_time)
		throughput_str := format_throughput(throughput)

		println('${chunk_str} | ${time_str:8} | ${throughput_str:17}')
	}

	// Sort results by average time (fastest first)
	results.sort(|a, b| a.avg_time < b.avg_time)

	// Find the best result
	best_result := results[0]
	mut recommended_chunk := best_result.chunk_size
	mut recommendation_note := ''

	// Check if there are smaller chunks with nearly the same performance (within 2%)
	for result in results {
		if result.chunk_size < best_result.chunk_size {
			performance_diff := (best_result.avg_time - result.avg_time) / best_result.avg_time
			if performance_diff <= 0.02 { // Within 2% performance difference
				recommended_chunk = result.chunk_size
				recommendation_note = ' (recommended: smaller chunk with similar performance)'
				break
			}
		}
	}

	println('')
	println('🏆 Results ordered by performance (fastest first):')
	for i, result in results {
		chunk_str := format_bytes_table(f64(result.chunk_size))
		time_str := format_time(result.avg_time)
		mut marker := ''
		if result.chunk_size == best_result.chunk_size {
			marker = ' 🏆'
		}
		if result.chunk_size == recommended_chunk && result.chunk_size != best_result.chunk_size {
			marker = ' ⭐'
		}
		throughput_str := format_throughput(result.throughput)
		println('${i + 1:2}. ${chunk_str} | ${time_str:8} | ${throughput_str:17}${marker}')
	}

	println('')
	if recommended_chunk == best_result.chunk_size {
		println('🏆 Optimal chunk size: ${format_bytes(f64(recommended_chunk))} (${format_throughput(best_result.throughput)})')
		println('   * This chunk size performed best in the test above')
	} else {
		println('🏆 Fastest chunk size: ${format_bytes(f64(best_result.chunk_size))} (${format_throughput(best_result.throughput)})')
		println('⭐ Recommended chunk size: ${format_bytes(f64(recommended_chunk))} (${format_throughput(results.filter(it.chunk_size == recommended_chunk)[0].throughput)})${recommendation_note}')
	}
	println('')

	return recommended_chunk
}

fn main() {
	mut app := cli.Command{
		name:        'benchmark'
		description: 'Comprehensive xxHash performance benchmark'
		version:     '1.0.0'
		flags:       [
			cli.Flag{
				name:        'file'
				abbrev:      'f'
				description: 'File to benchmark (required)'
				flag:        .string
				required:    true
			},
			cli.Flag{
				name:          'iter'
				abbrev:        'i'
				description:   'Number of iterations (default: 100)'
				flag:          .int
				default_value: ['100']
			},
			cli.Flag{
				name:          'chunk-size'
				abbrev:        'c'
				description:   'Chunk size for streaming tests (default: 4096)'
				flag:          .int
				default_value: ['4096']
			},
			cli.Flag{
				name:          'algorithms'
				abbrev:        'a'
				description:   'Algorithms to test (comma-separated, default: all)'
				flag:          .string
				default_value: ['xxh32,xxh64,xxh3_64,xxh3_128']
			},
			cli.Flag{
				name:          'warmup'
				abbrev:        'w'
				description:   'Number of warmup iterations (default: 5)'
				flag:          .int
				default_value: ['5']
			},
		]
		commands:    [
			cli.Command{
				name:        'find-best-chunk'
				description: 'Test chunk sizes from 4KB to 8MB to find optimal performance'
				flags:       [
					cli.Flag{
						name:        'file'
						abbrev:      'f'
						description: 'File to benchmark (required)'
						flag:        .string
						required:    true
					},
					cli.Flag{
						name:          'iter'
						abbrev:        'i'
						description:   'Number of iterations (default: 20)'
						flag:          .int
						default_value: ['20']
					},
					cli.Flag{
						name:          'algorithms'
						abbrev:        'a'
						description:   'Algorithm to test (default: xxh32)'
						flag:          .string
						default_value: ['xxh32']
					},
				]
				execute:     fn (cmd cli.Command) ! {
					run_find_best_chunk(cmd)!
				}
			},
		]
	}

	app.parse(os.args)

	// If no subcommand was used, run normal benchmark
	if app.args.len == 0 || app.args[0] != 'find-best-chunk' {
		run_normal_benchmark(app)!
	}
}

// Run normal benchmark mode
fn run_normal_benchmark(app cli.Command) ! {
	file_path := app.flags.get_string('file') or { '' }

	// Validate arguments with proper error messages
	if file_path == '' {
		eprintln('Error: File path is required')
		eprintln('Usage: v run benchmark.v -f <file> [options]')
		eprintln('Use -h or --help for detailed usage information')
		exit(1)
	}

	if !os.exists(file_path) {
		eprintln('Error: File not found: ${file_path}')
		exit(1)
	}

	// Parse and validate iterations
	iterations := app.flags.get_int('iter') or {
		eprintln('Error: Invalid iterations value: ${err}')
		exit(1)
	}
	if iterations <= 0 {
		eprintln('Error: Iterations must be a positive number')
		exit(1)
	}

	// Parse and validate chunk size
	mut chunk_size := app.flags.get_int('chunk-size') or {
		eprintln('Error: Invalid chunk size value: ${err}')
		exit(1)
	}
	if chunk_size <= 0 {
		eprintln('Error: Chunk size must be a positive number')
		exit(1)
	}

	// Parse and validate warmup
	warmup := app.flags.get_int('warmup') or {
		eprintln('Error: Invalid warmup value: ${err}')
		exit(1)
	}
	if warmup < 0 {
		eprintln('Error: Warmup must be a non-negative number')
		exit(1)
	}

	// Parse algorithms
	algorithms_str := app.flags.get_string('algorithms') or {
		eprintln('Error: Invalid algorithms value: ${err}')
		exit(1)
	}

	data := os.read_file(file_path) or {
		eprintln('Error reading file: ${err}')
		exit(1)
	}
	file_size := f64(data.len)

	// Parse algorithms
	struct Algorithm {
		name        string
		algorithm   vxxhash.DigestAlgorithm
		hash_fn     fn ([]u8) u64             = unsafe { nil }
		hash_fn_128 fn ([]u8) vxxhash.Hash128 = unsafe { nil }
	}

	mut algorithms := []Algorithm{}
	algorithms << Algorithm{'xxh32', vxxhash.DigestAlgorithm.xxh32, fn (data []u8) u64 {
		return u64(vxxhash.xxh32_hash(data, 0))
	}, unsafe { nil }}
	algorithms << Algorithm{'xxh64', vxxhash.DigestAlgorithm.xxh64, fn (data []u8) u64 {
		return vxxhash.xxh64_hash(data, 0)
	}, unsafe { nil }}
	algorithms << Algorithm{'xxh3_64', vxxhash.DigestAlgorithm.xxh3_64, fn (data []u8) u64 {
		return vxxhash.xxh3_hash(data, 0)
	}, unsafe { nil }}
	algorithms << Algorithm{'xxh3_128', vxxhash.DigestAlgorithm.xxh3_128, fn (data []u8) u64 {
		return vxxhash.xxh3_hash(data, 0)
	}, unsafe { nil }}

	mut selected_algorithms := []Algorithm{}
	mut invalid_algos := []string{}

	for algo in algorithms_str.split(',') {
		algo_name := algo.trim_space()
		if algo_name.len == 0 {
			continue
		}

		mut found := false
		for alg in algorithms {
			if alg.name == algo_name {
				selected_algorithms << alg
				found = true
				break
			}
		}

		if !found {
			invalid_algos << algo_name
		}
	}

	if invalid_algos.len > 0 {
		eprintln('Error: Invalid algorithm(s): ${invalid_algos.join(', ')}')
		eprintln('Available algorithms: xxh32, xxh64, xxh3_64, xxh3_128')
		exit(1)
	}

	if selected_algorithms.len == 0 {
		eprintln('Error: No valid algorithms specified')
		eprintln('Available algorithms: xxh32, xxh64, xxh3_64, xxh3_128')
		exit(1)
	}

	println('=== xxHash Performance Benchmark ===')
	println('File: ${file_path}')
	println('Size: ${file_size} bytes (${file_size / 1024.0 / 1024.0:.2} MB)')
	println('Iterations: ${iterations}')
	println('Chunk size: ${format_bytes(f64(chunk_size))}')
	println('Warmup: ${warmup} iterations')
	println('Algorithms: ${selected_algorithms.map(|it| it.name).join(', ')}')
	println('')

	// Warmup
	if warmup > 0 {
		println('=== Warmup ===')
		for alg in selected_algorithms {
			for i := 0; i < warmup; i++ {
				_ = alg.hash_fn(data.bytes())
			}
		}
		println('Warmup complete')
		println('')
	}

	// One-shot benchmark
	println('=== One-shot Performance ===')
	println('Algorithm | Min      | Max      | Avg      | Throughput (MB/s) | Hash')
	println('----------|----------|----------|----------|-------------------|------')

	for alg in selected_algorithms {
		name := alg.name
		hash_fn := alg.hash_fn
		mut times := []u64{cap: iterations}

		// Run benchmark
		for i := 0; i < iterations; i++ {
			start_time := time.now()
			_ = hash_fn(data.bytes())
			elapsed := time.now() - start_time
			times << u64(elapsed.nanoseconds())
		}

		// Calculate statistics
		mut min_time := times[0]
		mut max_time := times[0]
		mut total_time := u64(0)

		for t in times {
			if t < min_time {
				min_time = t
			}
			if t > max_time {
				max_time = t
			}
			total_time += t
		}

		avg_time := f64(total_time) / f64(iterations)
		throughput := (file_size / 1024.0 / 1024.0) / (avg_time / 1000000000.0)

		// Get hash for display
		mut hash_display := ''
		if alg.algorithm == .xxh3_128 {
			// Use hasher for 128-bit display
			mut hasher := vxxhash.new_xxhasher(alg.algorithm, 0) or {
				eprintln('Error creating hasher: ${err}')
				continue
			}
			defer { hasher.free() }
			hasher.update(data.bytes()) or {
				eprintln('Error updating hasher: ${err}')
				continue
			}
			result := hasher.digest() or {
				eprintln('Error getting digest: ${err}')
				continue
			}
			// Display full 128-bit hash
			hash_display = result.hex()
		} else {
			hash := hash_fn(data.bytes())
			hash_display = '${hash:x}'
		}

		println('${name:-9} | ${format_time(f64(min_time)):8} | ${format_time(f64(max_time)):8} | ${format_time(avg_time):8} | ${throughput:17.2} | ${hash_display}')
	}

	println('')

	// Streaming benchmark
	println('=== Streaming Performance ===')
	println('Algorithm | Min      | Max      | Avg      | Throughput (MB/s) | Hash')
	println('----------|----------|----------|----------|-------------------|------')

	for alg in selected_algorithms {
		name := alg.name
		algorithm := alg.algorithm
		mut times := []u64{cap: iterations}

		for i := 0; i < iterations; i++ {
			mut hasher := vxxhash.new_xxhasher(algorithm, 0) or {
				eprintln('Error creating hasher: ${err}')
				continue
			}
			defer { hasher.free() }

			start_time := time.now()

			// Process in chunks to simulate real streaming
			for j := 0; j < data.len; j += chunk_size {
				mut end := j + chunk_size
				if end > data.len {
					end = data.len
				}
				hasher.update(data[j..end].bytes()) or {
					eprintln('Error updating hasher: ${err}')
					break
				}
			}

			hasher.digest() or {
				eprintln('Error getting digest: ${err}')
				continue
			}
			elapsed := time.now() - start_time
			times << u64(elapsed.nanoseconds())
		}

		// Calculate statistics
		mut min_time := times[0]
		mut max_time := times[0]
		mut total_time := u64(0)

		for t in times {
			if t < min_time {
				min_time = t
			}
			if t > max_time {
				max_time = t
			}
			total_time += t
		}

		avg_time := f64(total_time) / f64(iterations)
		throughput := (file_size / 1024.0 / 1024.0) / (avg_time / 1000000000.0)

		// Get hash for display
		mut hasher := vxxhash.new_xxhasher(algorithm, 0) or {
			eprintln('Error creating hasher: ${err}')
			continue
		}
		defer { hasher.free() }
		hasher.update(data.bytes()) or {
			eprintln('Error updating hasher: ${err}')
			continue
		}
		result := hasher.digest() or {
			eprintln('Error getting digest: ${err}')
			continue
		}

		// Display appropriate hash based on algorithm
		mut hash_display := ''
		if algorithm == .xxh3_128 {
			// Display full 128-bit hash
			hash_display = result.hex()
		} else if algorithm == .xxh32 {
			hash_display = '${result.get_hash():x}'
		} else {
			hash_display = '${result.get_hash():x}'
		}

		println('${name:-9} | ${format_time(f64(min_time)):8} | ${format_time(f64(max_time)):8} | ${format_time(avg_time):8} | ${throughput:17.2} | ${hash_display}')
	}

	println('')

	println('Benchmark complete!')
}

// Run find-best-chunk subcommand
fn run_find_best_chunk(cmd cli.Command) ! {
	file_path := cmd.flags.get_string('file') or { '' }

	if file_path == '' {
		eprintln('Error: File path is required')
		eprintln('Usage: v run benchmark.v find-best-chunk -f <file> [options]')
		exit(1)
	}

	if !os.exists(file_path) {
		eprintln('Error: File not found: ${file_path}')
		exit(1)
	}

	// Parse and validate iterations
	iterations := cmd.flags.get_int('iter') or {
		eprintln('Error: Invalid iterations value: ${err}')
		exit(1)
	}
	if iterations <= 0 {
		eprintln('Error: Iterations must be a positive number')
		exit(1)
	}

	// Parse algorithm
	algorithms_str := cmd.flags.get_string('algorithms') or {
		eprintln('Error: Invalid algorithms value: ${err}')
		exit(1)
	}

	// Parse algorithms (simplified - just use first one)
	algo_name := algorithms_str.split(',')[0].trim_space()

	mut algorithm := vxxhash.DigestAlgorithm.xxh3_64
	match algo_name {
		'xxh32' {
			algorithm = .xxh32
		}
		'xxh64' {
			algorithm = .xxh64
		}
		'xxh3_64' {
			algorithm = .xxh3_64
		}
		'xxh3_128' {
			algorithm = .xxh3_128
		}
		else {
			eprintln('Error: Unknown algorithm: ${algo_name}')
			eprintln('Available algorithms: xxh32, xxh64, xxh3_64, xxh3_128')
			exit(1)
		}
	}

	// Run find-best-chunk logic
	data := os.read_file(file_path)!
	find_optimal_chunk_size(data.bytes(), algorithm, iterations, file_path, algo_name)!
}
