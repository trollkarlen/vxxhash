module main

import os
import cli
import vxxhash

fn main() {
    mut app := cli.Command{
        name: 'hash_example'
        description: 'Demonstrate xxHash algorithms on a file'
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
                name: 'data'
                abbrev: 'd'
                description: 'Use test data instead of file'
                flag: .string
                default_value: ['Hello World']
            },
            cli.Flag{
                name: 'chunk-size'
                abbrev: 'c'
                description: 'Chunk size for streaming (default: 4096)'
                flag: .int
                default_value: ['4096']
            }
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
    
    // Test all algorithms with hex output
    println('=== One-shot Hashing ===')
    hash32_hex := vxxhash.xxh32_hash_hex_default(data.bytes())
    hash64_hex := vxxhash.xxh64_hash_hex_default(data.bytes())
    hash3_64_hex := vxxhash.xxh3_hash_hex_default(data.bytes())
    
    println('XXH32:     ${hash32_hex}')
    println('XXH64:     ${hash64_hex}')
    println('XXH3-64:   ${hash3_64_hex}')
    println('')
    
    // Demonstrate streaming with unified digest
    println('=== Streaming Hashing (XXH3-64) ===')
    mut hasher := vxxhash.new_xxhasher(vxxhash.DigestAlgorithm.xxh3_64, 0) or { panic(err) }
    defer { hasher.free() }
    
    // Process in chunks
    for i := 0; i < data.len; i += chunk_size {
        mut end := i + chunk_size
        if end > data.len {
            end = data.len
        }
        
        hasher.update(data[i..end].bytes()) or { panic(err) }
    }
    
    stream_result := hasher.digest() or { panic(err) }
    stream_hex := hasher.digest_hex() or { panic(err) }
    one_shot_hex := vxxhash.xxh3_hash_hex_default(data.bytes())
    
    println('Streaming:  ${stream_hex}')
    println('One-shot:   ${one_shot_hex}')
    println('Match:       ${stream_hex == one_shot_hex}')
    println('Hash result:  ${stream_result.hash_64:x}')
}