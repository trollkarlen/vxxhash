# Contributing to vxxhash

Thank you for your interest in contributing to vxxhash! This document provides guidelines and information for contributors.

## Getting Started

### Prerequisites

- V language (latest version recommended)
- xxHash development library
- Git for version control
- Basic knowledge of V language and C interop

### Development Setup

1. **Fork and clone**:
   ```bash
   git clone https://github.com/yourusername/vxxhash.git
   cd vxxhash
   ```

2. **Install dependencies**:
   ```bash
   # macOS
   brew install v xxhash
   
   # Ubuntu/Debian
   sudo apt-get install v libxxhash-dev
   
   # Or build V from source
   git clone https://github.com/vlang/v.git
   cd v && make && sudo ./v symlink
   ```

3. **Run tests to verify setup**:
   ```bash
   ./scripts/test.sh
   ```

## Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 2. Make Changes

- Follow existing code style and conventions
- Add comprehensive tests for new features
- Update documentation as needed
- Ensure all tests pass

### 3. Test Your Changes

```bash
# Run full test suite
./scripts/test.sh

# Run with performance tests
./scripts/test.sh --performance

# Test in Docker (if applicable)
./scripts/docker-test.sh --all
```

### 4. Commit Changes

Use clear, descriptive commit messages:

```
type(scope): description

[optional body]

[optional footer]
```

Examples:
```
feat(api): add XXH3-128 streaming support

- Implement proper 128-bit digest function
- Add Hash128 comparison methods
- Update documentation

Fixes #123
```

```
fix(examples): correct CLI flag parsing in benchmark

- Use correct flag names for V CLI module
- Update test script accordingly
- Add error handling for missing flags
```

### 5. Submit Pull Request

- Push to your fork
- Create a pull request with clear description
- Link any relevant issues
- Ensure CI passes

## Code Style Guidelines

### V Language Conventions

- Follow V language official style guide
- Use meaningful variable and function names
- Keep functions focused and small
- Use `snake_case` for variables and functions
- Use `PascalCase` for types and structs

### Documentation

- Add comprehensive comments for public APIs
- Include parameter descriptions and return values
- Provide usage examples in comments
- Update README.md for user-facing changes

### Error Handling

- Use V's result type (`!`) for functions that can fail
- Provide clear error messages
- Handle errors appropriately in examples
- Test error paths

## Testing Guidelines

### Unit Tests

- Write tests for all new functions
- Test edge cases and error conditions
- Use descriptive test names
- Follow existing test patterns

### Integration Tests

- Test new features through examples
- Verify CLI tools work correctly
- Test cross-platform compatibility
- Include performance tests for speed-critical code

### Test Organization

- Unit tests go in `test/` directory
- Example programs in `examples/` directory
- Performance tests in examples or dedicated scripts
- Use consistent test data and assertions

## Areas for Contribution

### High Priority

1. **Enhanced 128-bit Support**
   - Proper XXH3-128 integration
   - Complete 128-bit streaming API
   - 128-bit comparison utilities

2. **Performance Optimizations**
   - SIMD optimizations where supported
   - Memory alignment improvements
   - Zero-copy operations

3. **Additional Examples**
   - Real-world usage scenarios
   - Integration with common V patterns
   - Performance tuning examples

### Medium Priority

1. **CLI Tool Enhancements**
   - More hash tool features
   - Better error handling
   - Progress indicators for large files

2. **Documentation Improvements**
   - Performance benchmarks
   - Best practices guide
   - Integration tutorials

3. **Testing Infrastructure**
   - More comprehensive test coverage
   - Automated performance regression tests
   - Fuzzing for robustness

### Low Priority

1. **Additional Utilities**
   - Hash combination functions
   - Checksum verification tools
   - Batch processing utilities

2. **Platform-specific Optimizations**
   - Windows-specific optimizations
   - ARM platform support
   - Embedded system considerations

## Submitting Issues

### Bug Reports

Include the following information:
- V and xxHash versions
- Operating system and architecture
- Minimal reproduction code
- Expected vs actual behavior
- Any error messages

### Feature Requests

Include:
- Clear description of the feature
- Use case and motivation
- Proposed API (if applicable)
- Alternative approaches considered

## Review Process

### What We Look For

1. **Correctness**: Code works as intended
2. **Style**: Follows project conventions
3. **Testing**: Adequate test coverage
4. **Documentation**: Clear and complete
5. **Performance**: No significant regressions
6. **Compatibility**: Works across supported platforms

### Review Timeline

- Initial review within 2-3 days
- Additional feedback as needed
- Merge once all concerns addressed

## Community Guidelines

### Code of Conduct

- Be respectful and constructive
- Welcome contributors of all experience levels
- Focus on what is best for the project
- Show empathy toward other community members

### Communication

- Use GitHub issues for bug reports and feature requests
- Use GitHub discussions for general questions
- Be patient with maintainers and contributors
- Provide helpful feedback on pull requests

## Release Process

### Version Management

- Follow semantic versioning (SemVer)
- Update CHANGELOG.md for all releases
- Tag releases in Git
- Update version numbers in documentation

### Release Checklist

- [ ] All tests pass on all platforms
- [ ] Documentation is updated
- [ ] CHANGELOG.md is updated
- [ ] Version numbers are updated
- [ ] Release notes are prepared
- [ ] Git tag is created and pushed

## Getting Help

### Resources

- [V Language Documentation](https://github.com/vlang/v/blob/master/doc/docs.md)
- [xxHash Documentation](https://github.com/Cyan4973/xxHash/wiki)
- [Project Issues](https://github.com/yourusername/vxxhash/issues)
- [GitHub Discussions](https://github.com/yourusername/vxxhash/discussions)

### Contact

- Create an issue for bugs or feature requests
- Start a discussion for questions
- Mention maintainers for urgent issues

## Recognition

Contributors are recognized in:
- README.md contributors section
- Release notes for significant contributions
- Git commit history (attribution preserved)

Thank you for contributing to vxxhash! Your contributions help make this project better for everyone.