import 'package:flutter/foundation.dart';

enum PaymentMethod {
  creditCard,
  debitCard,
  bankTransfer,
  digitalWallet,
  corporateAccount,
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}

@immutable
class Payment {
  final String paymentId;
  final PaymentStatus status;
  final double amount;
  final String currency;
  final String transactionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? errorMessage;
  final String? rideId;
  final String? description;

  const Payment({
    required this.paymentId,
    required this.status,
    required this.amount,
    required this.currency,
    required this.transactionId,
    required this.createdAt,
    required this.updatedAt,
    this.errorMessage,
    this.rideId,
    this.description,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      paymentId: json['payment_id'] ?? '',
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      transactionId: json['transaction_id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      errorMessage: json['error_message'],
      rideId: json['ride_id'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'status': status.name,
      'amount': amount,
      'currency': currency,
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'error_message': errorMessage,
      'ride_id': rideId,
      'description': description,
    };
  }

  Payment copyWith({
    String? paymentId,
    PaymentStatus? status,
    double? amount,
    String? currency,
    String? transactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? errorMessage,
    String? rideId,
    String? description,
  }) {
    return Payment(
      paymentId: paymentId ?? this.paymentId,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      rideId: rideId ?? this.rideId,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Payment && other.paymentId == paymentId;
  }

  @override
  int get hashCode => paymentId.hashCode;

  @override
  String toString() {
    return 'Payment(paymentId: $paymentId, status: $status, amount: $amount, currency: $currency)';
  }
}

@immutable
class Refund {
  final String refundId;
  final String paymentId;
  final double amount;
  final String status;
  final String reason;
  final DateTime createdAt;

  const Refund({
    required this.refundId,
    required this.paymentId,
    required this.amount,
    required this.status,
    required this.reason,
    required this.createdAt,
  });

  factory Refund.fromJson(Map<String, dynamic> json) {
    return Refund(
      refundId: json['refund_id'] ?? '',
      paymentId: json['payment_id'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
      reason: json['reason'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'refund_id': refundId,
      'payment_id': paymentId,
      'amount': amount,
      'status': status,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Refund && other.refundId == refundId;
  }

  @override
  int get hashCode => refundId.hashCode;

  @override
  String toString() {
    return 'Refund(refundId: $refundId, paymentId: $paymentId, amount: $amount, reason: $reason)';
  }
}

@immutable
class FareCalculation {
  final double estimatedFare;
  final String currency;
  final Map<String, dynamic> breakdown;

  const FareCalculation({
    required this.estimatedFare,
    required this.currency,
    required this.breakdown,
  });

  factory FareCalculation.fromJson(Map<String, dynamic> json) {
    return FareCalculation(
      estimatedFare: (json['estimated_fare'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      breakdown: json['breakdown'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimated_fare': estimatedFare,
      'currency': currency,
      'breakdown': breakdown,
    };
  }

  double get baseRate => (breakdown['base_rate'] ?? 0.0).toDouble();
  double get distanceCost => (breakdown['distance_cost'] ?? 0.0).toDouble();
  double get timeCost => (breakdown['time_cost'] ?? 0.0).toDouble();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FareCalculation && other.estimatedFare == estimatedFare;
  }

  @override
  int get hashCode => estimatedFare.hashCode;

  @override
  String toString() {
    return 'FareCalculation(estimatedFare: $estimatedFare, currency: $currency)';
  }
}

@immutable
class PaymentHistory {
  final String paymentId;
  final String? rideId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final PaymentMethod paymentMethod;
  final String? description;
  final DateTime createdAt;
  final String transactionId;

  const PaymentHistory({
    required this.paymentId,
    this.rideId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    this.description,
    required this.createdAt,
    required this.transactionId,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      paymentId: json['payment_id'] ?? '',
      rideId: json['ride_id'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['payment_method'],
        orElse: () => PaymentMethod.corporateAccount,
      ),
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      transactionId: json['transaction_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'ride_id': rideId,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'payment_method': paymentMethod.name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'transaction_id': transactionId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentHistory && other.paymentId == paymentId;
  }

  @override
  int get hashCode => paymentId.hashCode;

  @override
  String toString() {
    return 'PaymentHistory(paymentId: $paymentId, amount: $amount, status: $status)';
  }
}
