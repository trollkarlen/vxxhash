module main

import os
import cli
import time
import vxxhash

fn main() {
    mut app := cli.Command{
        name: 'streaming_example'
        description: 'Compare streaming vs one-shot xxHash performance'
        version: '1.0.0'
        flags: [
            cli.Flag{
                name: 'file'
                abbrev: 'f'
                description: 'File to hash (required)'
                flag: .string
                required: true
            },
            cli.Flag{
                name: 'chunk-size'
                abbrev: 'c'
                description: 'Chunk size for streaming (default: 8192)'
                flag: .int
                default_value: ['8192']
            },
            cli.Flag{
                name: 'iterations'
                abbrev: 'i'
                description: 'Number of iterations for timing (default: 1)'
                flag: .int
                default_value: ['1']
            },
            cli.Flag{
                name: 'algorithms'
                abbrev: 'a'
                description: 'Algorithms to test (comma-separated, default: all)'
                flag: .string
                default_value: ['xxh32,xxh64,xxh3_64,xxh3_128']
            }
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
        name string
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
    
    // Test streaming performance
    println('=== Streaming Performance ===')
    for alg in selected_algorithms {
        name := alg.name
        algorithm := alg.algorithm
        println('--- ${name} Streaming ---')
        
        mut total_time := u64(0)
        mut final_hash := u64(0)
        
        for iter in 0 .. iterations {
            mut hasher := vxxhash.new_xxhasher(algorithm, 0) or { 
                eprintln('Error creating hasher: ${err}')
                continue
            }
            defer { hasher.free() }
            
            start_time := time.now()
            
            // Open file and stream in chunks
            mut file := os.open(file_path) or { 
                eprintln('Error opening file: ${err}')
                continue
            }
            defer { file.close() }
            
            for {
                mut chunk := []u8{len: chunk_size}
                bytes_read := file.read(mut chunk) or { break }
                
                if bytes_read == 0 {
                    break
                }
                
                hasher.update(chunk[..bytes_read]) or { 
                    eprintln('Error updating hasher: ${err}')
                    break
                }
            }
            
            // Get final hash
            result := hasher.digest() or { 
                eprintln('Error getting digest: ${err}')
                continue
            }
            
            duration := time.now() - start_time
            total_time += u64(duration)
            
            if iter == 0 {
                final_hash = result.hash_64
            }
        }
        
        avg_time_ns := f64(total_time) / f64(iterations)
        throughput := (f64(data.len) / 1024.0 / 1024.0) / (avg_time_ns / 1000000000.0)
        
        time_str := if avg_time_ns < 100000 { '${avg_time_ns:0.0}ns' } else { '${avg_time_ns / 1000000:.2}ms' }
        
        println('Processed: ${data.len} bytes')
        println('Hash: ${final_hash:x}')
        println('Avg time: ${time_str}')
        println('Throughput: ${throughput:.2} MB/s')
        println('')
    }
    
    // Test one-shot performance
    println('=== One-shot Performance ===')
    for alg in selected_algorithms {
        name := alg.name
        algorithm := alg.algorithm
        mut total_time := u64(0)
        mut final_hash := u64(0)
        
        for iter in 0 .. iterations {
            start_time := time.now()
            
            hash := match algorithm {
                .xxh32 { u64(vxxhash.xxh32_hash(data.bytes(), 0)) }
                .xxh64 { vxxhash.xxh64_hash(data.bytes(), 0) }
                .xxh3_64 { vxxhash.xxh3_hash(data.bytes(), 0) }
                .xxh3_128 { 
                    result := vxxhash.xxh3_hash(data.bytes(), 0) // Use 64-bit for now
                    result
                }
            }
            
            duration := time.now() - start_time
            total_time += u64(duration)
            
            if iter == 0 {
                final_hash = hash
            }
        }
        
        avg_time_ns := f64(total_time) / f64(iterations)
        throughput := (f64(data.len) / 1024.0 / 1024.0) / (avg_time_ns / 1000000000.0)
        
        time_str := if avg_time_ns < 100000 { '${avg_time_ns:0.0}ns' } else { '${avg_time_ns / 1000000:.2}ms' }
        
        println('${name:-10}: ${final_hash:x} (${time_str}, ${throughput:.2} MB/s)')
    }
}