# Corporate RideShare Platform

A comprehensive multi-tenant corporate ride-sharing platform built with Flutter (mobile), Python FastAPI (backend), and PostgreSQL (database).

## Features

### Core Features
- **Multi-tenant Architecture**: Support for multiple companies
- **Employee Authentication**: Secure login with company-specific access
- **Ride Booking**: Book rides with real-time matching
- **Real-time GPS Tracking**: Live location updates
- **Corporate Integration**: HR system integration capabilities
- **Admin Dashboard**: Web-based management interface
- **Analytics & Reporting**: Usage statistics and cost analysis

### Mobile App (Flutter)
- Cross-platform mobile application
- Real-time ride matching
- GPS location services
- Push notifications
- Profile management
- Ride history

### Backend API (Python FastAPI)
- RESTful API with automatic documentation
- JWT-based authentication
- Multi-tenant data isolation
- Real-time WebSocket support
- PostgreSQL with PostGIS for geospatial queries
- Redis for caching and real-time data

### Admin Dashboard (Web)
- Company management
- Employee administration
- Ride monitoring
- Analytics and reporting
- Settings configuration

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Flutter SDK (for mobile development)
- Python 3.11+ (for local development)
- PostgreSQL 15+ with PostGIS

### Using Docker (Recommended)

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd corporate-rideshare-platform
   ```

2. **Start services**
   ```bash
   docker-compose up -d
   ```

3. **Access the application**
   - API: http://localhost:8000
   - Admin Dashboard: http://localhost:8000/admin
   - API Documentation: http://localhost:8000/docs

### Local Development

#### Backend Setup

1. **Database Setup**
   ```bash
   # Start PostgreSQL with PostGIS
   docker run -d --name rideshare_postgres \
     -e POSTGRES_DB=rideshare_db \
     -e POSTGRES_USER=rideshare_user \
     -e POSTGRES_PASSWORD=rideshare_password \
     -p 5432:5432 \
     postgis/postgis:15-3.3
   ```

2. **Backend Development**
   ```bash
   cd backend

   # Create virtual environment
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate

   # Install dependencies
   pip install -r requirements.txt

   # Set environment variables
   export DATABASE_URL="postgresql://rideshare_user:rideshare_password@localhost:5432/rideshare_db"
   export SECRET_KEY="your-secret-key-here"

   # Run the application
   uvicorn main:app --reload
   ```

#### Mobile App Setup

1. **Flutter Setup**
   ```bash
   cd mobile

   # Install dependencies
   flutter pub get

   # Run on Android/iOS
   flutter run
   ```

## Project Structure

```
corporate-rideshare-platform/
├── backend/                    # Python FastAPI backend
│   ├── app/
│   │   ├── models/            # SQLAlchemy models
│   │   ├── schemas/           # Pydantic schemas
│   │   ├── services/          # Business logic
│   │   └── api/               # API endpoints
│   ├── main.py                # FastAPI application
│   ├── requirements.txt       # Python dependencies
│   └── Dockerfile            # Docker configuration
├── mobile/                    # Flutter mobile app
│   ├── lib/
│   │   ├── models/           # Data models
│   │   ├── screens/          # UI screens
│   │   ├── services/         # API services
│   │   └── utils/            # Utilities
│   └── pubspec.yaml          # Flutter dependencies
├── web-admin/                 # Web admin dashboard
│   ├── static/               # Static assets
│   └── templates/            # HTML templates
├── docker/                   # Docker configurations
├── docs/                     # Documentation
└── docker-compose.yml        # Docker Compose configuration
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - User login
- `GET /api/v1/auth/me` - Get current user

### Rides
- `POST /api/v1/rides/` - Create ride
- `GET /api/v1/rides/` - Get rides
- `GET /api/v1/rides/my-rides` - Get user's rides
- `GET /api/v1/rides/{id}` - Get specific ride
- `PUT /api/v1/rides/{id}` - Update ride
- `DELETE /api/v1/rides/{id}` - Delete ride
- `GET /api/v1/rides/{id}/matches` - Find ride matches
- `POST /api/v1/rides/{id}/request` - Request to join ride

## Configuration

### Environment Variables

Create a `.env` file in the backend directory:

```env
DATABASE_URL=postgresql://rideshare_user:rideshare_password@localhost:5432/rideshare_db
SECRET_KEY=your-secret-key-here-change-in-production
ACCESS_TOKEN_EXPIRE_MINUTES=30
REDIS_URL=redis://localhost:6379
```

### Mobile App Configuration

Edit `mobile/lib/utils/constants.dart`:

```dart
static const String baseUrl = 'http://localhost:8000'; // Your API URL
```

## Testing

### Backend Tests
```bash
cd backend
python -m pytest tests/
```

### Mobile Tests
```bash
cd mobile
flutter test
```

## Deployment

### Production Deployment

1. **Update environment variables**
   ```bash
   # Update docker-compose.yml with production values
   vim docker-compose.yml
   ```

2. **Deploy with Docker Compose**
   ```bash
   docker-compose -f docker-compose.yml up -d
   ```

3. **Setup SSL (recommended)**
   ```bash
   # Add SSL certificates to nginx configuration
   # Update nginx.conf for HTTPS
   ```

### Mobile App Deployment

1. **Android**
   ```bash
   cd mobile
   flutter build apk --release
   ```

2. **iOS**
   ```bash
   cd mobile
   flutter build ios --release
   ```

## Security

- JWT-based authentication
- Password hashing with bcrypt
- HTTPS enforcement in production
- Input validation and sanitization
- Rate limiting
- SQL injection prevention

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please contact [support@example.com](mailto:support@example.com) or create an issue in the repository.
