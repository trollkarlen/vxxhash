module main

import os
import cli
import time
import vxxhash

// Format time in ns if < 100000ns (0.1ms), otherwise in ms with 2 decimals
fn format_time(time_ns f64) string {
    if time_ns < 100000 {  // < 0.1ms
        return '${time_ns:0.0}ns'
    } else {
        return '${time_ns / 1000000:.2}ms'
    }
}

fn main() {
    mut app := cli.Command{
        name: 'benchmark'
        description: 'Comprehensive xxHash performance benchmark'
        version: '1.0.0'
        flags: [
            cli.Flag{
                name: 'file'
                abbrev: 'f'
                description: 'File to benchmark (required)'
                flag: .string
                required: true
            },
            cli.Flag{
                name: 'iter'
                abbrev: 'i'
                description: 'Number of iterations (default: 10000)'
                flag: .int
                default_value: ['10000']
            },
            cli.Flag{
                name: 'chunk-size'
                abbrev: 'c'
                description: 'Chunk size for streaming tests (default: 4096)'
                flag: .int
                default_value: ['4096']
            },
            cli.Flag{
                name: 'algorithms'
                abbrev: 'a'
                description: 'Algorithms to test (comma-separated, default: all)'
                flag: .string
                default_value: ['xxh32,xxh64,xxh3_64,xxh3_128']
            },
            cli.Flag{
                name: 'warmup'
                abbrev: 'w'
                description: 'Number of warmup iterations (default: 5)'
                flag: .int
                default_value: ['5']
            }
        ]
    }
    
    app.parse(os.args)
    
    file_path := app.flags.get_string('file') or { '' }
    iterations := app.flags.get_int('iter')!
    chunk_size := app.flags.get_int('chunk-size')!
    algorithms_str := app.flags.get_string('algorithms')!
    warmup := app.flags.get_int('warmup')!
    
    if file_path == '' {
        eprintln('Error: File path is required')
        exit(1)
    }
    
    if !os.exists(file_path) {
        eprintln('Error: File not found: ${file_path}')
        exit(1)
    }
    
    data := os.read_file(file_path) or { 
        eprintln('Error reading file: ${err}')
        exit(1)
    }
    file_size := f64(data.len)
    
    // Parse algorithms
    struct Algorithm {
        name string
        algorithm vxxhash.DigestAlgorithm
        hash_fn fn([]u8) u64 = unsafe { nil }
    }
    
    mut algorithms := []Algorithm{}
    algorithms << Algorithm{'xxh32', vxxhash.DigestAlgorithm.xxh32, fn(data []u8) u64 { return u64(vxxhash.xxh32_hash(data, 0)) }}
    algorithms << Algorithm{'xxh64', vxxhash.DigestAlgorithm.xxh64, fn(data []u8) u64 { return vxxhash.xxh64_hash(data, 0) }}
    algorithms << Algorithm{'xxh3_64', vxxhash.DigestAlgorithm.xxh3_64, fn(data []u8) u64 { return vxxhash.xxh3_hash(data, 0) }}
    algorithms << Algorithm{'xxh3_128', vxxhash.DigestAlgorithm.xxh3_128, fn(data []u8) u64 { return vxxhash.xxh3_hash(data, 0) }}
    
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
    
    println('=== xxHash Performance Benchmark ===')
    println('File: ${file_path}')
    println('Size: ${file_size} bytes (${file_size / 1024.0 / 1024.0:.2} MB)')
    println('Iterations: ${iterations}')
    println('Chunk size: ${chunk_size} bytes')
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
            if t < min_time { min_time = t }
            if t > max_time { max_time = t }
            total_time += t
        }
        
        avg_time := f64(total_time) / f64(iterations)
        throughput := (file_size / 1024.0 / 1024.0) / (avg_time / 1000000000.0)
        
        // Get hash for display
        hash := hash_fn(data.bytes())
        
        println('${name:-9} | ${format_time(f64(min_time)):8} | ${format_time(f64(max_time)):8} | ${format_time(avg_time):8} | ${throughput:17.2} | ${hash:x}')
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
            if t < min_time { min_time = t }
            if t > max_time { max_time = t }
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
        
        println('${name:-9} | ${format_time(f64(min_time)):8} | ${format_time(f64(max_time)):8} | ${format_time(avg_time):8} | ${throughput:17.2} | ${result.hash_64:x}')
    }
    
    println('')
    println('Benchmark complete!')
}
