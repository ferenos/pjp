#!/bin/bash
# Bash script to run Docker build tests for NutAndJamPack

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
TEST_TYPE="all"
CLEAN=false
NO_BUILD=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --client)
            TEST_TYPE="client"
            shift
            ;;
        --server)
            TEST_TYPE="server"
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --no-build)
            NO_BUILD=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--client|--server|--all] [--clean] [--no-build]"
            exit 1
            ;;
    esac
done

# Helper functions
print_step() {
    echo -e "\n${YELLOW}═══ $1 ═══${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Check if Docker is running
check_docker() {
    print_step "Checking Docker availability"
    if ! docker info &> /dev/null; then
        print_error "Docker is not running or not installed"
        print_info "Please start Docker and try again"
        exit 1
    fi
    print_success "Docker is running"
}

# Clean build artifacts
clean_build() {
    print_step "Cleaning build artifacts"
    
    rm -rf build-output
    print_success "Removed build-output directory"
    
    rm -f *.mrpack
    print_success "Removed .mrpack files"
    
    docker-compose down --rmi local &> /dev/null || true
    print_success "Cleaned Docker resources"
}

# Test client build
test_client() {
    print_step "Testing Client Build"
    
    if [ "$NO_BUILD" = true ]; then
        docker-compose run --rm client-test
    else
        docker-compose up --build client-test
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Client build test PASSED"
        return 0
    else
        print_error "Client build test FAILED"
        return 1
    fi
}

# Test server build
test_server() {
    print_step "Testing Server Build and Startup"
    
    print_info "This will take several minutes as the server downloads and starts..."
    
    if [ "$NO_BUILD" = true ]; then
        docker-compose run --rm server-test
    else
        docker-compose up --build server-test
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Server build test PASSED"
        return 0
    else
        print_error "Server build test FAILED"
        return 1
    fi
}

# Main execution
echo -e "\n${YELLOW}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║   NutAndJamPack Docker Build Test Suite          ║${NC}"
echo -e "${YELLOW}╚═══════════════════════════════════════════════════╝${NC}\n"

# Check Docker
check_docker

# Clean if requested
if [ "$CLEAN" = true ]; then
    clean_build
fi

# Create build-output directory
mkdir -p build-output/client
mkdir -p build-output/server

# Run tests
CLIENT_PASSED=false
SERVER_PASSED=false

case $TEST_TYPE in
    client)
        test_client && CLIENT_PASSED=true
        ;;
    server)
        test_server && SERVER_PASSED=true
        ;;
    all)
        test_client && CLIENT_PASSED=true || true
        test_server && SERVER_PASSED=true || true
        ;;
esac

# Summary
print_step "Test Summary"

if [ "$TEST_TYPE" = "all" ]; then
    echo -n -e "\nClient Test: "
    if [ "$CLIENT_PASSED" = true ]; then
        echo -e "${GREEN}PASSED ✓${NC}"
    else
        echo -e "${RED}FAILED ✗${NC}"
    fi
    
    echo -n "Server Test: "
    if [ "$SERVER_PASSED" = true ]; then
        echo -e "${GREEN}PASSED ✓${NC}"
    else
        echo -e "${RED}FAILED ✗${NC}"
    fi
    
    if [ "$CLIENT_PASSED" = true ] && [ "$SERVER_PASSED" = true ]; then
        echo -e "\n${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║   ALL TESTS PASSED! ✓                             ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}\n"
        exit 0
    else
        echo -e "\n${RED}╔═══════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║   SOME TESTS FAILED! ✗                            ║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════════════════╝${NC}\n"
        exit 1
    fi
else
    if [ "$TEST_TYPE" = "client" ] && [ "$CLIENT_PASSED" = true ]; then
        print_success "Client test completed successfully!"
        exit 0
    elif [ "$TEST_TYPE" = "server" ] && [ "$SERVER_PASSED" = true ]; then
        print_success "Server test completed successfully!"
        exit 0
    else
        print_error "Test failed!"
        exit 1
    fi
fi
