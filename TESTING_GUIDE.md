# 🧪 Corporate RideShare Platform - Testing Guide

This guide covers comprehensive testing of the Corporate RideShare Platform, including backend APIs, mobile app, and integration testing.

## 📋 **Testing Overview**

The platform includes three types of tests:
1. **Backend Tests** - API endpoint testing
2. **Mobile App Tests** - Flutter app functionality testing
3. **Integration Tests** - End-to-end system testing

## 🚀 **Quick Start Testing**

### **Option 1: Run Everything at Once (Recommended)**
```bash
# Start services and run all tests
./run_with_tests.sh
```

### **Option 2: Manual Step-by-Step Testing**
```bash
# 1. Start services
./run.sh

# 2. Wait for services to be ready
sleep 15

# 3. Run backend tests
python3 test_backend_comprehensive.py

# 4. Run integration tests
python3 test_integration.py

# 5. Run mobile app tests
cd mobile
python3 ../test_mobile_app.py
```

## 🔧 **Prerequisites**

### **Required Software**
- Docker and Docker Compose
- Python 3.7+
- Flutter SDK (for mobile app testing)
- curl (for health checks)

### **Install Python Dependencies**
```bash
pip install -r test_requirements.txt
```

## 📱 **Mobile App Testing**

### **Prerequisites**
- Flutter SDK installed
- Android/iOS simulator or device
- Backend services running

### **Test Mobile App**
```bash
cd mobile

# Install dependencies
flutter pub get

# Run analysis
flutter analyze

# Run tests
flutter test

# Test API integration
python3 ../test_mobile_app.py

# Run the app
flutter run
```

### **Mobile App Test Coverage**
- ✅ Flutter dependencies installation
- ✅ Code analysis and linting
- ✅ Build process verification
- ✅ API integration testing
- ✅ Configuration file validation

## 🖥️ **Backend API Testing**

### **Test Backend APIs**
```bash
# Run comprehensive backend tests
python3 test_backend_comprehensive.py

# Test specific endpoints manually
curl http://localhost:8000/health
curl http://localhost:8000/api/v1/auth/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@techcorp.com", "password": "admin123", "company_id": "company-1"}'
```

### **Backend Test Coverage**
- ✅ Health checks and basic endpoints
- ✅ Authentication (login, register, user management)
- ✅ Company management APIs
- ✅ User management APIs
- ✅ Ride lifecycle (create, read, update, delete)
- ✅ Ride matching algorithms
- ✅ WebSocket functionality

## 🔗 **Integration Testing**

### **Test Complete System**
```bash
# Run full integration tests
python3 test_integration.py
```

### **Integration Test Coverage**
- ✅ Service startup and health
- ✅ Complete user authentication flow
- ✅ Company and user management
- ✅ Full ride lifecycle
- ✅ Mobile app integration
- ✅ WebSocket functionality

## 📊 **Test Results Interpretation**

### **Success Indicators**
- ✅ All tests pass
- ✅ No critical errors
- ✅ Services respond within expected time
- ✅ Data consistency maintained

### **Common Issues and Solutions**

#### **Backend Not Responding**
```bash
# Check Docker services
docker-compose ps

# Check logs
docker-compose logs backend

# Restart services
docker-compose restart
```

#### **Database Connection Issues**
```bash
# Check PostgreSQL
docker-compose logs postgres

# Check database health
docker exec rideshare_postgres pg_isready -U rideshare_user -d rideshare_db
```

#### **Mobile App API Errors**
- Verify backend is running on correct port
- Check `mobile/lib/config/app_config.dart` for correct API URL
- Ensure authentication token is valid

## 🧪 **Manual Testing Scenarios**

### **1. User Authentication Flow**
1. Open mobile app
2. Select company (use "company-1")
3. Login with `admin@techcorp.com` / `admin123`
4. Verify user profile loads

### **2. Ride Creation and Management**
1. Create a new ride
2. Set pickup and destination
3. Verify ride appears in "My Rides"
4. Check ride details

### **3. Company Management (Admin)**
1. Access web admin: http://localhost:8000/admin
2. Login with admin credentials
3. View company and user lists
4. Verify data consistency

### **4. API Documentation**
1. Access Swagger UI: http://localhost:8000/docs
2. Test endpoints interactively
3. Verify request/response schemas

## 🔍 **Debugging and Troubleshooting**

### **Enable Debug Logging**
```bash
# Backend debug logs
docker-compose logs -f backend

# Database logs
docker-compose logs -f postgres

# Redis logs
docker-compose logs -f redis
```

### **Check Service Health**
```bash
# Health check
curl http://localhost:8000/health

# Service status
docker-compose ps

# Resource usage
docker stats
```

### **Reset Test Environment**
```bash
# Stop all services
docker-compose down

# Remove volumes (WARNING: deletes all data)
docker-compose down -v

# Restart fresh
./run.sh
```

## 📈 **Performance Testing**

### **Load Testing APIs**
```bash
# Install Apache Bench
# macOS: brew install httpd
# Ubuntu: sudo apt-get install apache2-utils

# Test API performance
ab -n 100 -c 10 http://localhost:8000/health
ab -n 100 -c 10 -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8000/api/v1/rides/
```

### **Database Performance**
```bash
# Check PostgreSQL performance
docker exec rideshare_postgres psql -U rideshare_user -d rideshare_db -c "SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;"
```

## 🚨 **Security Testing**

### **Authentication Testing**
- Test with invalid credentials
- Test with expired tokens
- Test with missing tokens
- Verify company isolation

### **Authorization Testing**
- Test admin-only endpoints
- Test user permission boundaries
- Verify data access controls

## 📝 **Test Data Management**

### **Sample Test Data**
The platform includes sample data for testing:
- **Company**: TechCorp Inc. (company-1)
- **Admin User**: admin@techcorp.com / admin123
- **Test Company**: company-1

### **Creating Test Data**
```bash
# Create test user via API
curl -X POST "http://localhost:8000/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "testpass123",
    "company_id": "company-1"
  }'
```

## 🎯 **Testing Best Practices**

### **Before Running Tests**
1. Ensure all services are running
2. Check network connectivity
3. Verify test data is available
4. Clear any previous test artifacts

### **During Testing**
1. Monitor service logs
2. Check resource usage
2. Verify data consistency
3. Document any failures

### **After Testing**
1. Review test results
2. Clean up test data
3. Document issues found
4. Update test scripts if needed

## 📚 **Additional Resources**

### **API Documentation**
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

### **Logs and Monitoring**
- Backend logs: `docker-compose logs backend`
- Database logs: `docker-compose logs postgres`
- Service status: `docker-compose ps`

### **Support and Issues**
- Check service logs for errors
- Verify configuration files
- Test individual components
- Review this testing guide

---

**🎉 Happy Testing! The Corporate RideShare Platform is designed to be thoroughly testable and reliable.**
