#!/bin/bash
# Corporate RideShare Platform - Quick Start Script

echo "🚗 Corporate RideShare Platform"
echo "================================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    echo "   You can install it with: pip install docker-compose"
    exit 1
fi

# Check if required files exist
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found. Please ensure all required files are present."
    exit 1
fi

if [ ! -f "backend/Dockerfile" ]; then
    echo "❌ Backend Dockerfile not found. Please ensure all required files are present."
    exit 1
fi

echo "🔧 Starting services..."
docker-compose up -d

echo "⏳ Waiting for services to start..."
sleep 15

echo "🔍 Checking service status..."
docker-compose ps

echo ""
echo "✅ Services started successfully!"
echo ""
echo "🌐 Access the application:"
echo "   - API: http://localhost:8000"
echo "   - API Documentation: http://localhost:8000/docs"
echo "   - Admin Dashboard: http://localhost:8000/admin"
echo ""
echo "🧪 Test the application:"
echo "   - Run: python test_app.py"
echo ""
echo "📱 Mobile App:"
echo "   - Update mobile/lib/utils/constants.dart with your IP address"
echo "   - Run: cd mobile && flutter run"
echo ""
echo "🛑 To stop services: docker-compose down"
