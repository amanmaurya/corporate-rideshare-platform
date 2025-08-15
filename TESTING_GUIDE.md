# 🧪 Corporate RideShare Platform - Testing Guide

This guide will help you get the Corporate RideShare platform up and running for testing.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Python 3.7+ (for testing)
- Flutter SDK (for mobile app testing)

### 1. Start the Services
```bash
# Make the run script executable
chmod +x run.sh

# Start all services
./run.sh
```

This will start:
- PostgreSQL database with PostGIS
- Redis cache
- FastAPI backend
- NGINX reverse proxy

### 2. Test the Backend
```bash
# Install test dependencies
pip install -r test_requirements.txt

# Run the test script
python test_app.py
```

### 3. Access the Application
- **API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **Admin Dashboard**: http://localhost:8000/admin
- **Health Check**: http://localhost:8000/health

## 🔐 Test Credentials

The system comes with pre-configured test users:

### Admin User
- **Email**: admin@techcorp.com
- **Password**: admin123
- **Company ID**: company-1
- **Role**: admin

### Regular User
- **Email**: john.doe@techcorp.com
- **Password**: user123
- **Company ID**: company-1
- **Role**: employee

### Driver
- **Email**: mike.driver@techcorp.com
- **Password**: driver123
- **Company ID**: company-1
- **Role**: driver

## 📱 Testing the Mobile App

### 1. Update API Endpoint
Edit `mobile/lib/utils/constants.dart` and update the base URL:
```dart
static const String baseUrl = 'http://YOUR_IP_ADDRESS:8000';
```

### 2. Run the Mobile App
```bash
cd mobile
flutter pub get
flutter run
```

## 🧪 API Testing

### Using the Test Script
The `test_app.py` script tests:
- Health endpoint
- Root endpoint
- Admin dashboard
- API documentation
- User authentication
- Rides API endpoints

### Manual API Testing
You can also test manually using the interactive API docs at http://localhost:8000/docs

#### Example: Login
```bash
curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@techcorp.com",
    "password": "admin123",
    "company_id": "company-1"
  }'
```

#### Example: Get Rides (with token)
```bash
curl -X GET "http://localhost:8000/api/v1/rides/" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Services Won't Start
```bash
# Check Docker status
docker ps

# Check logs
docker-compose logs

# Restart services
docker-compose down
docker-compose up -d
```

#### 2. Database Connection Issues
```bash
# Check PostgreSQL logs
docker-compose logs postgres

# Check if database is accessible
docker exec -it rideshare_postgres psql -U rideshare_user -d rideshare_db
```

#### 3. Backend Errors
```bash
# Check backend logs
docker-compose logs backend

# Check if all dependencies are installed
docker exec -it rideshare_backend pip list
```

#### 4. Port Conflicts
If ports 8000, 5432, or 6379 are already in use:
```bash
# Stop conflicting services or
# Modify docker-compose.yml to use different ports
```

### Reset Everything
```bash
# Stop and remove all containers
docker-compose down -v

# Remove all images
docker-compose down --rmi all

# Start fresh
./run.sh
```

## 📊 Monitoring

### Check Service Status
```bash
docker-compose ps
```

### View Logs
```bash
# All services
docker-compose logs

# Specific service
docker-compose logs backend
docker-compose logs postgres
docker-compose logs redis
```

### Database Access
```bash
# Connect to PostgreSQL
docker exec -it rideshare_postgres psql -U rideshare_user -d rideshare_db

# List tables
\dt

# View sample data
SELECT * FROM companies;
SELECT * FROM users;
SELECT * FROM rides;
```

## 🔧 Development Mode

### Backend Development
```bash
# Run backend locally (without Docker)
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

### Database Development
```bash
# Connect to local database
psql -h localhost -U rideshare_user -d rideshare_db
```

## 📝 Next Steps

After successful testing:

1. **Customize Configuration**: Update environment variables in `docker-compose.yml`
2. **Add Real Data**: Replace sample data with actual company information
3. **Security**: Change default passwords and secret keys
4. **Deployment**: Prepare for production deployment
5. **Mobile App**: Configure for production API endpoints

## 🆘 Getting Help

If you encounter issues:

1. Check the logs: `docker-compose logs`
2. Verify all services are running: `docker-compose ps`
3. Check the troubleshooting section above
4. Review the main README.md for additional information

---

**Happy Testing! 🚗✨**
