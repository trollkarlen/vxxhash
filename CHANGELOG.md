# Changelog

All notable changes to vxxhash will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive CI/CD pipeline with GitHub Actions and GitLab CI
- Docker testing support for multiple Linux distributions
- Automated test scripts with cross-platform compatibility
- Complete API documentation with examples
- Performance benchmarking tools
- CLI hash tool with multiple algorithm support

### Changed
- Improved error handling and type safety
- Enhanced streaming API with better memory management
- Updated module structure for better organization

### Fixed
- Fixed CLI flag parsing in all example programs
- Corrected timing calculations in benchmark tools
- Resolved struct initialization issues
- Fixed throughput calculation formulas

## [0.1.0] - 2024-11-05

### Added
- Initial release of vxxhash V language bindings
- Support for all xxHash algorithms (XXH32, XXH64, XXH3-64, XXH3-128)
- One-shot hashing functions
- Streaming hash API with XXHasher struct
- HashResult unified result structure
- Hash128 128-bit hash representation
- Comprehensive comparison methods for HashResult
- Hex string conversion utilities
- Version number detection from xxHash library
- Complete test suite with 25+ assertions
- Example programs demonstrating all features
- Cross-platform support (Linux, macOS, Windows)

### Features
- **One-shot Hashing**: Direct hash computation for complete data
- **Streaming Hashing**: Incremental hashing for large datasets
- **Multiple Algorithms**: Support for all xxHash variants
- **Type Safety**: Full V language type safety and error handling
- **Performance**: Minimal overhead with direct C library calls
- **Documentation**: Comprehensive inline documentation
- **Testing**: Extensive test coverage

### API
- `xxh32_hash()`, `xxh64_hash()`, `xxh3_hash()` - One-shot hashing
- `new_xxhasher()` - Create streaming hasher
- `XXHasher.update()`, `XXHasher.digest()`, `XXHasher.reset()` - Streaming operations
- `HashResult` comparison methods and utilities
- Hex string conversion functions
- Library version detection

### Examples
- `hash_example.v` - Basic usage demonstration
- `streaming_example.v` - Streaming vs one-shot comparison
- `benchmark.v` - Performance testing tool
- `hash_tool.v` - CLI hashing utility

### Documentation
- Complete API documentation with examples
- Usage guides for all major features
- Performance characteristics and recommendations
- Installation instructions for all platforms

### Testing
- Unit tests for all major functions
- Integration tests with example programs
- Cross-platform compatibility testing
- Performance regression tests

## [Future Plans]

### Planned Features
- Enhanced 128-bit hash support with proper XXH3-128 integration
- SIMD optimizations for supported platforms
- Additional utility functions (hash combination, etc.)
- More comprehensive CLI tool features
- Integration with V's built-in hashing interfaces

### Performance Improvements
- Zero-copy optimizations where possible
- Better memory alignment for SIMD operations
- Platform-specific optimizations

### Documentation
- More performance benchmarks and comparisons
- Advanced usage patterns and best practices
- Integration guides for common use cases