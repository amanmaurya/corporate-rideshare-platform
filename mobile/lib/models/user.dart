class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String role;
  final String companyId;
  final bool isDriver;
  final bool isActive;
  final double? latitude;
  final double? longitude;
  final String? profilePicture;
  final double rating;
  final int totalRides;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.role,
    required this.companyId,
    required this.isDriver,
    required this.isActive,
    this.latitude,
    this.longitude,
    this.profilePicture,
    this.rating = 0.0,
    this.totalRides = 0,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      department: json['department'],
      role: json['role'],
      companyId: json['company_id'],
      isDriver: json['is_driver'] ?? false,
      isActive: json['is_active'] ?? true,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      profilePicture: json['profile_picture'],
      rating: json['rating']?.toDouble() ?? 0.0,
      totalRides: json['total_rides'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'department': department,
      'role': role,
      'company_id': companyId,
      'is_driver': isDriver,
      'is_active': isActive,
      'latitude': latitude,
      'longitude': longitude,
      'profile_picture': profilePicture,
      'rating': rating,
      'total_rides': totalRides,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Company {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String contactEmail;
  final String contactPhone;
  final Map<String, dynamic> settings;
  final String? logoUrl;
  final bool isActive;
  final DateTime createdAt;

  Company({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.contactEmail,
    required this.contactPhone,
    this.settings = const {},
    this.logoUrl,
    this.isActive = true,
    required this.createdAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      settings: json['settings'] ?? {},
      logoUrl: json['logo_url'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
