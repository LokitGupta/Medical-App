class PaymentModel {
  final String? id;
  final String userId;
  final String paymentType; // 'appointment', 'medication', 'insurance'
  final String referenceId; // appointmentId, medicationId, insuranceId
  final double amount;
  final String currency;
  final String status; // 'pending', 'completed', 'failed', 'refunded'
  final String paymentMethod; // 'card', 'upi', 'netbanking', 'wallet'
  final String? transactionId;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PaymentModel({
    this.id,
    required this.userId,
    required this.paymentType,
    required this.referenceId,
    required this.amount,
    this.currency = 'INR',
    required this.status,
    required this.paymentMethod,
    this.transactionId,
    required this.timestamp,
    this.metadata,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      userId: json['userId'],
      paymentType: json['paymentType'],
      referenceId: json['referenceId'],
      amount: json['amount'].toDouble(),
      currency: json['currency'] ?? 'INR',
      status: json['status'],
      paymentMethod: json['paymentMethod'],
      transactionId: json['transactionId'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'paymentType': paymentType,
      'referenceId': referenceId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? userId,
    String? paymentType,
    String? referenceId,
    double? amount,
    String? currency,
    String? status,
    String? paymentMethod,
    String? transactionId,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      paymentType: paymentType ?? this.paymentType,
      referenceId: referenceId ?? this.referenceId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }
}

class InsuranceModel {
  final String? id;
  final String userId;
  final String provider;
  final String policyNumber;
  final DateTime startDate;
  final DateTime endDate;
  final String coverageType; // 'basic', 'premium', 'comprehensive'
  final double coverageAmount;
  final bool isVerified;
  final Map<String, dynamic>? details;

  InsuranceModel({
    this.id,
    required this.userId,
    required this.provider,
    required this.policyNumber,
    required this.startDate,
    required this.endDate,
    required this.coverageType,
    required this.coverageAmount,
    this.isVerified = false,
    this.details,
  });

  factory InsuranceModel.fromJson(Map<String, dynamic> json) {
    return InsuranceModel(
      id: json['id'],
      userId: json['userId'],
      provider: json['provider'],
      policyNumber: json['policyNumber'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      coverageType: json['coverageType'],
      coverageAmount: json['coverageAmount'].toDouble(),
      isVerified: json['isVerified'] ?? false,
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'provider': provider,
      'policyNumber': policyNumber,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'coverageType': coverageType,
      'coverageAmount': coverageAmount,
      'isVerified': isVerified,
      'details': details,
    };
  }
}

class PaymentMethodModel {
  final String? id;
  final String userId;
  final String type; // 'card', 'upi', 'netbanking', 'wallet'
  final String name; // Card name, UPI ID, Bank name
  final String? last4; // Last 4 digits for card
  final String? expiryMonth;
  final String? expiryYear;
  final bool isDefault;
  final Map<String, dynamic>? details;

  PaymentMethodModel({
    this.id,
    required this.userId,
    required this.type,
    required this.name,
    this.last4,
    this.expiryMonth,
    this.expiryYear,
    this.isDefault = false,
    this.details,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'],
      userId: json['userId'],
      type: json['type'],
      name: json['name'],
      last4: json['last4'],
      expiryMonth: json['expiryMonth'],
      expiryYear: json['expiryYear'],
      isDefault: json['isDefault'] ?? false,
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'name': name,
      'last4': last4,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'isDefault': isDefault,
      'details': details,
    };
  }
}
