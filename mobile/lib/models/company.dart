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
  final DateTime updatedAt;

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
    required this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      settings: json['settings'] ?? {},
      logoUrl: json['logo_url'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'settings': settings,
      'logo_url': logoUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Company copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? contactEmail,
    String? contactPhone,
    Map<String, dynamic>? settings,
    String? logoUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      settings: settings ?? this.settings,
      logoUrl: logoUrl ?? this.logoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Company(id: $id, name: $name, address: $address, latitude: $latitude, longitude: $longitude, contactEmail: $contactEmail, contactPhone: $contactPhone, settings: $settings, logoUrl: $logoUrl, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Company &&
        other.id == id &&
        other.name == name &&
        other.address == address &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.contactEmail == contactEmail &&
        other.contactPhone == contactPhone &&
        other.settings == settings &&
        other.logoUrl == logoUrl &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        address.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        contactEmail.hashCode ^
        contactPhone.hashCode ^
        settings.hashCode ^
        logoUrl.hashCode ^
        isActive.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
