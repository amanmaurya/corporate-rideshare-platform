import '../models/company.dart';
import 'api_service.dart';

class CompanyService {
  static Future<List<Company>> getCompanies() async {
    try {
      final response = await ApiService.getCompanies();
      return response.map((json) => Company.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get companies: ${e.toString()}');
    }
  }

  static Future<Company> getCompany(String companyId) async {
    try {
      final response = await ApiService.getCompany(companyId);
      return Company.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get company: ${e.toString()}');
    }
  }

  static Future<List<Company>> getDemoCompanies() async {
    // Fallback demo companies if API fails
    final now = DateTime.now();
    return [
      Company(
        id: 'company-1',
        name: 'TechCorp Inc.',
        address: '123 Innovation Drive, Tech City',
        latitude: 37.7749,
        longitude: -122.4194,
        contactEmail: 'admin@techcorp.com',
        contactPhone: '+1-555-0123',
        createdAt: now,
        updatedAt: now,
      ),
      Company(
        id: 'company-2',
        name: 'Innovate Solutions',
        address: '456 Business Ave, Startup City',
        latitude: 37.7849,
        longitude: -122.4094,
        contactEmail: 'info@innovate.com',
        contactPhone: '+1-555-0456',
        createdAt: now,
        updatedAt: now,
      ),
      Company(
        id: 'company-3',
        name: 'Global Enterprises',
        address: '789 Corporate Blvd, Metro City',
        latitude: 37.7949,
        longitude: -122.3994,
        contactEmail: 'contact@global.com',
        contactPhone: '+1-555-0789',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
