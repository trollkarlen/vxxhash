#!/bin/bash

# vxxhash Test Runner
# This script runs all tests and checks for the vxxhash module

set -e  # Exit on any error

echo "🧪 vxxhash Test Runner"
echo "======================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if V is installed
check_v() {
    if ! command -v v &> /dev/null; then
        print_error "V language is not installed or not in PATH"
        print_error "Please install V from https://github.com/vlang/v"
        exit 1
    fi
    print_status "V language found: $(v version)"
}

# Check if xxHash is installed
check_xxhash() {
    print_status "Checking xxHash installation..."
    
    # Try to find xxhash installation
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if brew list xxhash &> /dev/null; then
            print_status "xxHash found via Homebrew"
            XXHASH_PATH=$(brew --prefix xxhash)
            print_status "xxHash path: $XXHASH_PATH"
            print_status "✅ Platform-specific flags will handle paths automatically"
        else
            print_error "xxHash not found. Install with: brew install xxhash"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if pkg-config --exists libxxhash; then
            print_status "xxHash found via pkg-config"
            XXHASH_CFLAGS=$(pkg-config --cflags libxxhash)
            XXHASH_LIBS=$(pkg-config --libs libxxhash)
            print_status "xxHash flags: $XXHASH_CFLAGS $XXHASH_LIBS"
            print_status "✅ Platform-specific flags will handle paths automatically"
        else
            print_error "xxHash not found. Install with: sudo apt-get install libxxhash-dev"
            exit 1
        fi
    else
        print_warning "Unknown OS. Please ensure xxHash is installed and paths are correct in vxxhash/vxxhash.v"
        print_status "✅ Platform-specific flags will handle paths automatically"
    fi
}

# Run unit tests
run_tests() {
    print_status "Running unit tests..."
    cd test
    if v run basic_test.v; then
        print_status "✅ Unit tests passed"
    else
        print_error "❌ Unit tests failed"
        exit 1
    fi
    cd ..
}

# Test examples
test_examples() {
    print_status "Testing examples..."
    cd examples
    
    # Test hash example
    print_status "Testing hash_example.v..."
    if v run hash_example.v; then
        print_status "✅ hash_example.v passed"
    else
        print_error "❌ hash_example.v failed"
        exit 1
    fi
    
    # Test streaming example
    print_status "Testing streaming_example.v..."
    # Create a test file for streaming example
    echo "Test data for streaming example" > test_data.txt
    if v run streaming_example.v -f test_data.txt -i 1 > /dev/null 2>&1; then
        print_status "✅ streaming_example.v passed"
    else
        print_error "❌ streaming_example.v failed"
        rm -f test_data.txt
        exit 1
    fi
    rm -f test_data.txt
    
    # Test hash tool
    print_status "Testing hash_tool.v..."
    if v run hash_tool.v help > /dev/null 2>&1; then
        print_status "✅ hash_tool.v passed"
    else
        print_error "❌ hash_tool.v failed"
        exit 1
    fi
    
    # Test benchmark (with few iterations)
    print_status "Testing benchmark.v..."
    # Create a test file for benchmark
    echo "Test data for benchmark" > benchmark_test.txt
    if v run benchmark.v -f benchmark_test.txt -i 5 > /dev/null 2>&1; then
        print_status "✅ benchmark.v passed"
    else
        print_error "❌ benchmark.v failed"
        rm -f benchmark_test.txt
        exit 1
    fi
    rm -f benchmark_test.txt
    
    cd ..
    print_status "✅ All examples passed"
}

# Check shared library compilation
check_shared_library() {
    print_status "Checking shared library compilation..."
    if v -shared vxxhash > /dev/null 2>&1; then
        print_status "✅ Shared library compilation successful"
        # Check if shared library was created
        if ls *.so *.dylib *.dll 2>/dev/null | grep -q .; then
            print_status "✅ Shared library files created"
        else
            print_warning "⚠️  Shared library compilation succeeded but no library files found"
        fi
    else
        print_error "❌ Shared library compilation failed"
        exit 1
    fi
}

# Check code formatting
check_formatting() {
    print_status "Checking code formatting..."
    if fmt_output=$(v fmt -verify . 2>&1); then
        print_status "✅ Code formatting is correct"
    else
        print_error "❌ Code formatting issues found"
        print_error "Formatting issues detected:"
        echo -e "$fmt_output"
        print_error "Run 'v fmt .' to fix formatting issues"
        exit 1
    fi
}

# Check module compilation
check_module() {
    print_status "Checking module compilation..."
    # Test that the module can be used by creating a simple test
    echo 'import vxxhash
fn main() {
    data := "test".bytes()
    hash := vxxhash.xxh3_hash_default(data)
    println("Hash: ${hash:x}")
}' > test_module.v
    if v run test_module.v > /dev/null 2>&1; then
        print_status "✅ Module compilation successful"
    else
        print_error "❌ Module compilation failed"
        rm -f test_module.v
        exit 1
    fi
    rm -f test_module.v
}

# Check example compilation
check_examples_compilation() {
    print_status "Checking example compilation..."
    cd examples
    
    # Test compilation of all examples (without running them)
    print_status "Testing hash_example.v compilation..."
    if v hash_example.v > /dev/null 2>&1; then
        print_status "✅ hash_example.v compiled successfully"
    else
        print_error "❌ hash_example.v compilation failed"
        cd ..
        exit 1
    fi
    
    print_status "Testing hash_tool.v compilation..."
    if v hash_tool.v > /dev/null 2>&1; then
        print_status "✅ hash_tool.v compiled successfully"
    else
        print_error "❌ hash_tool.v compilation failed"
        cd ..
        exit 1
    fi
    
    print_status "Testing streaming_example.v compilation..."
    if v streaming_example.v > /dev/null 2>&1; then
        print_status "✅ streaming_example.v compiled successfully"
    else
        print_error "❌ streaming_example.v compilation failed"
        cd ..
        exit 1
    fi
    
    print_status "Testing benchmark.v compilation..."
    if v benchmark.v > /dev/null 2>&1; then
        print_status "✅ benchmark.v compiled successfully"
    else
        print_error "❌ benchmark.v compilation failed"
        cd ..
        exit 1
    fi
    
    cd ..
    print_status "✅ All examples compiled successfully"
}

# Run performance test (optional)
run_performance() {
    if [[ "$1" == "--performance" ]]; then
        print_status "Running performance test..."
        cd examples
        # Create a larger test file for meaningful benchmarks
        dd if=/dev/zero of=perf_test.txt bs=1024 count=100 2>/dev/null
        v run benchmark.v -f perf_test.txt -i 1000
        rm -f perf_test.txt
        cd ..
    fi
}

# Main execution
main() {
    print_status "Starting vxxhash test suite..."
    
    check_v
    check_xxhash
    check_formatting
    run_tests
    check_shared_library
    check_examples_compilation
    test_examples
    check_module
    run_performance "$@"
    
    print_status "🎉 All tests passed successfully!"
    print_status "vxxhash module is ready for use!"
}

# Help message
show_help() {
    echo "vxxhash Test Runner"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --performance    Run performance benchmarks"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                 # Run all tests"
    echo "  $0 --performance   # Run tests with benchmarks"
}

# Parse command line arguments
case "$1" in
    --help|-h)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac