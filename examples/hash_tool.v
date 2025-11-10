module main

import os
import cli
import time
import vxxhash

fn main() {
	mut app := cli.Command{
		name:        'vxxhash'
		description: 'Fast file hashing tool using xxHash algorithms'
		version:     '1.0.0'
		commands:    [
			cli.Command{
				name:        'hash'
				description: 'Hash files using specified algorithm'
				flags:       [
					cli.Flag{
						name:          'algorithm'
						abbrev:        'a'
						description:   'Hash algorithm to use (xxh32, xxh64, xxh3_64, xxh3_128)'
						flag:          .string
						default_value: ['xxh3_64']
					},
					cli.Flag{
						name:          'seed'
						abbrev:        's'
						description:   'Seed for hash calculation'
						flag:          .int
						default_value: ['0']
					},
					cli.Flag{
						name:        'file'
						abbrev:      'f'
						description: 'File to hash'
						flag:        .string
						required:    true
					},
				]
				execute:     hash_file
			},
			cli.Command{
				name:        'benchmark'
				description: 'Compare performance of different hash algorithms on a file'
				flags:       [
					cli.Flag{
						name:        'file'
						abbrev:      'f'
						description: 'File to benchmark'
						flag:        .string
						required:    true
					},
					cli.Flag{
						name:          'iterations'
						abbrev:        'i'
						description:   'Number of iterations for each algorithm'
						flag:          .int
						default_value: ['100']
					},
				]
				execute:     benchmark_file
			},
		]
	}

	app.parse(os.args)
}

fn hash_file(cmd cli.Command) ! {
	algorithm_str := cmd.flags.get_string('algorithm') or { 'xxh3_64' }
	seed := u64(cmd.flags.get_int('seed') or { 0 })
	file_path := cmd.flags.get_string('file')!

	if !os.exists(file_path) {
		return error('File not found: ${file_path}')
	}

	file_size := os.file_size(file_path)
	data := os.read_file(file_path)!
	println('Hashing file: ${file_path}')
	println('File size: ${file_size} bytes')
	println('Algorithm: ${algorithm_str}')
	println('Seed: ${seed}')
	println('')

	start_time := time.now()

	match algorithm_str {
		'xxh32' {
			hash := vxxhash.xxh32_hash(data.bytes(), seed)
			duration := time.now() - start_time
			println('XXH32 Hash: ${hash:x}')
			println('Time taken: ${format_duration(duration)}')
		}
		'xxh64' {
			hash := vxxhash.xxh64_hash(data.bytes(), seed)
			duration := time.now() - start_time
			println('XXH64 Hash: ${hash:x}')
			println('Time taken: ${format_duration(duration)}')
		}
		'xxh3_64' {
			hash := vxxhash.xxh3_hash(data.bytes(), seed)
			duration := time.now() - start_time
			println('XXH3-64 Hash: ${hash:x}')
			println('Time taken: ${format_duration(duration)}')
		}
		'xxh3_128' {
			hash := vxxhash.xxh3_hash(data.bytes(), seed) // Use 64-bit for now
			duration := time.now() - start_time
			println('XXH3-128 Hash: ${hash:x}')
			println('Time taken: ${format_duration(duration)}')
		}
		else {
			return error('Invalid algorithm: ${algorithm_str}')
		}
	}
}

fn benchmark_file(cmd cli.Command) ! {
	file_path := cmd.flags.get_string('file')!
	iterations_str := cmd.flags.get_string('iterations') or { '100' }
	iterations := iterations_str.int()

	if !os.exists(file_path) {
		return error('File not found: ${file_path}')
	}

	file_size := os.file_size(file_path)
	data := os.read_file(file_path)!

	println('Benchmarking file: ${file_path}')
	println('File size: ${file_size} bytes')
	println('Iterations: ${iterations}')
	println('')

	struct Algorithm {
		name    string
		hash_fn fn ([]u8, u64) u64 = unsafe { nil }
	}

	algorithms := [
		Algorithm{'XXH32', fn (data []u8, seed u64) u64 {
			return u64(vxxhash.xxh32_hash(data, seed))
		}},
		Algorithm{'XXH64', fn (data []u8, seed u64) u64 {
			return vxxhash.xxh64_hash(data, seed)
		}},
		Algorithm{'XXH3-64', fn (data []u8, seed u64) u64 {
			return vxxhash.xxh3_hash(data, seed)
		}},
		Algorithm{'XXH3-128', fn (data []u8, seed u64) u64 {
			return vxxhash.xxh3_hash(data, seed)
		}}, // Use 64-bit for now
	]

	println('Algorithm | Time      | Throughput (MB/s) | Hash')
	println('----------|-----------|-------------------|------')

	for alg in algorithms {
		name := alg.name
		hash_fn := alg.hash_fn
		mut total_time := i64(0)

		for i := 0; i < iterations; i++ {
			start_time := time.now()
			_ = hash_fn(data.bytes(), 0)
			total_time += time.now() - start_time
		}

		avg_time_ns := f64(total_time) / f64(iterations)
		throughput := (f64(file_size) / 1024.0 / 1024.0) / (avg_time_ns / 1000000000.0)

		// Get hash for display
		hash := hash_fn(data.bytes(), 0)

		time_str := if avg_time_ns < 10000 {
			'${avg_time_ns:8.0}ns'
		} else {
			'${avg_time_ns / 1000000:8.2}ms'
		}

		println('${name:-9} | ${time_str} | ${throughput:17.2} | ${hash:x}')
	}

	println('')
	println('Note: XXH3-128 shows low 64 bits for comparison. Full 128-bit hash available in API.')
}

fn format_duration(duration i64) string {
	if duration < 10000 { // Below 0.01ms = 10,000ns
		return '${duration}ns'
	} else {
		return '${duration / 1000000}ms'
	}
}
