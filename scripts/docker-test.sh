#!/bin/bash

# Docker Test Runner for vxxhash
# This script runs tests inside Docker containers for different Linux distributions

set -e

echo "🐳 vxxhash Docker Test Runner"
echo "============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Docker images to test
DOCKER_IMAGES=(
    "ubuntu:22.04"
    "ubuntu:24.04"
    "debian:bullseye"
    "debian:bookworm"
    "alpine:3.18"
    "alpine:3.19"
    "fedora:38"
    "fedora:39"
)

# Function to test in Docker container
test_in_docker() {
    local image=$1
    print_header "Testing in $image"
    
    # Detect current platform to use correct Docker platform
    local platform=""
    case $(uname -m) in
        arm64|aarch64)
            platform="--platform linux/arm64"
            ;;
        x86_64|amd64)
            platform="--platform linux/amd64"
            ;;
        *)
            print_warning "Unknown architecture $(uname -m), using default platform"
            platform=""
            ;;
    esac
    
    # Create Dockerfile content based on image
    local install_cmd=""
    
    case $image in
        ubuntu:*|debian:*)
            install_cmd="apt-get update -qq && apt-get install -y -qq git gcc pkg-config libxxhash-dev ca-certificates make"
            ;;
        alpine:*)
            install_cmd="apk add --no-cache git gcc musl-dev xxhash-dev ca-certificates make linux-headers bash"
            ;;
        fedora:*)
            install_cmd="dnf update -y && dnf install -y git gcc pkg-config xxhash-devel ca-certificates make"
            ;;
        *)
            print_error "Unknown Docker image: $image"
            return 1
            ;;
    esac
    
    # Create temporary Dockerfile with multi-stage build
    cat > Dockerfile.test << EOF
FROM $image AS builder

# Set non-interactive frontend
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN $install_cmd

# Install V language from source
RUN git clone https://github.com/vlang/v.git /tmp/v && \\
    cd /tmp/v && \\
    make

# Set working directory
WORKDIR /app

# Copy source code
COPY . .

# Make test script executable
RUN chmod +x scripts/test.sh

# Run tests with proper V environment
ENV PATH="/tmp/v:\$PATH"
ENV VROOT="/tmp/v"
ENV VLIB="/tmp/v/vlib"
RUN bash scripts/test.sh

EOF
    
    # Build and run Docker container
    local container_name="vxxhash-test-$(echo $image | tr ':' '-')"
    
    print_status "Building Docker image for $image (platform: ${platform:-default})..."
    
    # Capture build output to show on failure
    local build_log="docker-build-$container_name.log"
    if docker build $platform -f Dockerfile.test -t $container_name . > $build_log 2>&1; then
        print_status "✅ Docker image built successfully for $image"
        
        print_status "Running tests in $image..."
        if docker run $platform --rm $container_name 2>/dev/null; then
            print_status "✅ Tests passed in $image"
        else
            print_error "❌ Tests failed in $image"
            # Try to get more details
            docker run $platform --rm $container_name ./scripts/test.sh || true
            return 1
        fi
    else
        print_error "❌ Failed to build Docker image for $image"
        print_error "Build log:"
        if [ -f "$build_log" ]; then
            cat $build_log
            rm -f $build_log
        else
            print_error "Build log file not found"
        fi
        return 1
    fi
    
    # Cleanup
    rm -f $build_log
    docker rmi $container_name > /dev/null 2>&1 || true
    rm -f Dockerfile.test
}

# Function to check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        print_error "Please install Docker from https://docker.com"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        print_error "Please start Docker daemon"
        exit 1
    fi
    
    print_status "Docker is available and running"
}

# Function to test specific image
test_specific_image() {
    local image=$1
    print_header "Testing specific image: $image"
    test_in_docker "$image"
}

# Function to test all images
test_all_images() {
    print_header "Testing all Docker images"
    
    local failed_images=()
    local total_images=${#DOCKER_IMAGES[@]}
    local passed_count=0
    
    for image in "${DOCKER_IMAGES[@]}"; do
        if test_in_docker "$image"; then
            ((passed_count++))
        else
            failed_images+=("$image")
        fi
        echo ""  # Add spacing between tests
    done
    
    # Print summary
    print_header "Test Summary"
    print_status "Passed: $passed_count/$total_images"
    
    if [ ${#failed_images[@]} -gt 0 ]; then
        print_error "Failed images:"
        for image in "${failed_images[@]}"; do
            print_error "  - $image"
        done
        return 1
    else
        print_status "🎉 All tests passed in all Docker images!"
        return 0
    fi
}

# Function to show available images
show_images() {
    print_header "Available Docker images for testing:"
    for i in "${!DOCKER_IMAGES[@]}"; do
        echo "  $((i+1)). ${DOCKER_IMAGES[i]}"
    done
}

# Help message
show_help() {
    echo "vxxhash Docker Test Runner"
    echo ""
    echo "Usage: $0 [OPTIONS] [IMAGE]"
    echo ""
    echo "Options:"
    echo "  --list          List available Docker images"
    echo "  --all           Test all available Docker images"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --all                    # Test all images"
    echo "  $0 ubuntu:22.04            # Test specific image"
    echo "  $0 --list                   # Show available images"
    echo ""
    echo "Available images:"
    show_images
}

# Main execution
main() {
    check_docker
    
    case "$1" in
        --help|-h)
            show_help
            exit 0
            ;;
        --list)
            show_images
            exit 0
            ;;
        --all)
            test_all_images
            exit $?
            ;;
        "")
            print_warning "No arguments provided. Use --all to test all images or specify an image."
            show_help
            exit 1
            ;;
        *)
            test_specific_image "$1"
            exit $?
            ;;
    esac
}

# Run main function with all arguments
main "$@"