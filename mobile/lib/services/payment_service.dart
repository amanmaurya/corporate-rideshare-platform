import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/payment.dart';

class PaymentService {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);

    final headers = Map<String, String>.from(_headers);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Payment processing failed');
    }
  }

  /// Process payment for a completed ride
  static Future<Payment> processRidePayment({
    required String rideId,
    double? amount,
  }) async {
    final headers = await _getAuthHeaders();
    
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/v1/payments/ride/$rideId'),
      headers: headers,
      body: json.encode({
        'amount': amount,
        'currency': 'USD',
        'description': 'Ride payment',
      }),
    );

    final data = await _handleResponse(response);
    return Payment.fromJson(data);
  }

  /// Process corporate payment
  static Future<Payment> processCorporatePayment({
    required double amount,
    String? description,
  }) async {
    final headers = await _getAuthHeaders();
    
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/v1/payments/corporate'),
      headers: headers,
      body: json.encode({
        'amount': amount,
        'currency': 'USD',
        'description': description ?? 'Corporate service payment',
      }),
    );

    final data = await _handleResponse(response);
    return Payment.fromJson(data);
  }

  /// Request a refund
  static Future<Refund> requestRefund({
    required String paymentId,
    required double amount,
    required String reason,
  }) async {
    final headers = await _getAuthHeaders();
    
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/v1/payments/refund'),
      headers: headers,
      body: json.encode({
        'payment_id': paymentId,
        'amount': amount,
        'reason': reason,
      }),
    );

    final data = await _handleResponse(response);
    return Refund.fromJson(data);
  }

  /// Get payment history for current user
  static Future<List<Payment>> getPaymentHistory() async {
    final headers = await _getAuthHeaders();
    
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/v1/payments/history'),
      headers: headers,
    );

    final data = await _handleResponse(response);
    return (data as List).map((json) => Payment.fromJson(json)).toList();
  }

  /// Get payment status
  static Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    final headers = await _getAuthHeaders();
    
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/v1/payments/status/$paymentId'),
      headers: headers,
    );

    return await _handleResponse(response);
  }

  /// Calculate estimated fare for a ride
  static Future<FareCalculation> calculateFare({
    required double distanceKm,
    required int durationMinutes,
  }) async {
    final headers = await _getAuthHeaders();
    
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/v1/payments/fare/calculate?distance_km=$distanceKm&duration_minutes=$durationMinutes'),
      headers: headers,
    );

    final data = await _handleResponse(response);
    return FareCalculation.fromJson(data);
  }

  /// Get available payment methods
  static List<PaymentMethod> getAvailablePaymentMethods() {
    return [
      PaymentMethod.corporateAccount,
      PaymentMethod.creditCard,
      PaymentMethod.debitCard,
      PaymentMethod.digitalWallet,
    ];
  }

  /// Validate payment amount
  static bool isValidAmount(double amount) {
    return amount > 0 && amount <= 1000; // Max $1000 per payment
  }

  /// Format payment amount for display
  static String formatAmount(double amount, String currency) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  /// Get payment status color
  static String getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return '#4CAF50'; // Green
      case 'pending':
        return '#FF9800'; // Orange
      case 'failed':
        return '#F44336'; // Red
      case 'refunded':
        return '#2196F3'; // Blue
      default:
        return '#9E9E9E'; // Grey
    }
  }

  /// Get payment status text
  static String getPaymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Payment Successful';
      case 'pending':
        return 'Processing Payment';
      case 'failed':
        return 'Payment Failed';
      case 'refunded':
        return 'Payment Refunded';
      default:
        return 'Unknown Status';
    }
  }
}
