#!/bin/bash
# Corporate RideShare Platform - Enhanced Run Script with Testing

echo "🚗 Corporate RideShare Platform - Enhanced Run & Test Script"
echo "=========================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed. Please install Python 3 first."
        exit 1
    fi
    
    # Check required Python packages
    if ! python3 -c "import requests" &> /dev/null; then
        print_warning "Python requests package not found. Installing..."
        pip3 install requests
    fi
    
    print_success "All prerequisites are satisfied!"
}

# Start services
start_services() {
    print_status "Starting services with Docker Compose..."
    
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found. Please ensure all required files are present."
        exit 1
    fi
    
    # Start services in background
    docker-compose up -d
    
    if [ $? -eq 0 ]; then
        print_success "Services started successfully!"
    else
        print_error "Failed to start services. Check Docker logs."
        exit 1
    fi
}

# Wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:8000/health > /dev/null 2>&1; then
            print_success "Backend is ready!"
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts - waiting for backend..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "Services failed to start within expected time."
    return 1
}

# Show service status
show_service_status() {
    print_status "Checking service status..."
    docker-compose ps
    
    echo ""
    print_status "Service URLs:"
    echo "   - API: http://localhost:8000"
    echo "   - API Documentation: http://localhost:8000/docs"
    echo "   - Admin Dashboard: http://localhost:8000/admin"
    echo "   - Health Check: http://localhost:8000/health"
}

# Run backend tests
run_backend_tests() {
    print_status "Running comprehensive backend tests..."
    
    if [ -f "test_backend_comprehensive.py" ]; then
        python3 test_backend_comprehensive.py
        local backend_test_result=$?
        
        if [ $backend_test_result -eq 0 ]; then
            print_success "Backend tests passed!"
        else
            print_warning "Some backend tests failed. Check the output above."
        fi
    else
        print_warning "Backend test script not found. Skipping backend tests."
    fi
}

# Run integration tests
run_integration_tests() {
    print_status "Running integration tests..."
    
    if [ -f "test_integration.py" ]; then
        python3 test_integration.py
        local integration_test_result=$?
        
        if [ $integration_test_result -eq 0 ]; then
            print_success "Integration tests passed!"
        else
            print_warning "Some integration tests failed. Check the output above."
        fi
    else
        print_warning "Integration test script not found. Skipping integration tests."
    fi
}

# Run mobile app tests
run_mobile_tests() {
    print_status "Running mobile app tests..."
    
    if [ -d "mobile" ] && [ -f "mobile/pubspec.yaml" ]; then
        cd mobile
        
        if [ -f "../test_mobile_app.py" ]; then
            python3 ../test_mobile_app.py
            local mobile_test_result=$?
            
            if [ $mobile_test_result -eq 0 ]; then
                print_success "Mobile app tests passed!"
            else
                print_warning "Some mobile app tests failed. Check the output above."
            fi
        else
            print_warning "Mobile app test script not found. Skipping mobile tests."
        fi
        
        cd ..
    else
        print_warning "Mobile app directory not found. Skipping mobile tests."
    fi
}

# Show next steps
show_next_steps() {
    echo ""
    print_success "🎉 Platform is ready for use!"
    echo ""
    echo "📱 Next Steps:"
    echo "   1. Test the mobile app:"
    echo "      cd mobile && flutter run"
    echo ""
    echo "   2. Access the web admin:"
    echo "      http://localhost:8000/admin"
    echo "      Login: admin@techcorp.com / admin123"
    echo ""
    echo "   3. View API documentation:"
    echo "      http://localhost:8000/docs"
    echo ""
    echo "   4. Run tests again:"
    echo "      python3 test_integration.py"
    echo ""
    echo "🛑 To stop services: docker-compose down"
}

# Main execution
main() {
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Start services
    start_services
    
    # Wait for services
    if ! wait_for_services; then
        print_error "Failed to start services. Exiting."
        exit 1
    fi
    
    # Show status
    show_service_status
    
    echo ""
    print_status "Running comprehensive tests..."
    echo ""
    
    # Run all tests
    run_backend_tests
    echo ""
    run_integration_tests
    echo ""
    run_mobile_tests
    
    # Show next steps
    show_next_steps
}

# Run main function
main "$@"
