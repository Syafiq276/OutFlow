import 'package:cloud_firestore/cloud_firestore.dart';

class Subscription {
  final String? id;
  final String userId;
  final String name;
  final double cost;
  final String period;
  final String category;
  final DateTime nextBillingDate;
  final bool isActive;
  final String? logoPath;

  Subscription({
    this.id,
    required this.userId,
    required this.name,
    required this.cost,
    required this.period,
    required this.category,
    required this.nextBillingDate,
    this.isActive = true,
    this.logoPath,
  });

  factory Subscription.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subscription(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'Unnamed',
      cost: (data['cost'] ?? 0.0).toDouble(),
      period: data['period'] ?? '',
      category: data['category'] ?? '',
      nextBillingDate: (data['nextBillingDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      logoPath: data['logoPath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'cost': cost,
      'period': period,
      'category': category,
      'nextBillingDate': Timestamp.fromDate(nextBillingDate),
      'isActive': isActive,
      'logoPath': logoPath,
    };
  }

  double get monthlyCost {
    if (period == 'year') {
      return cost / 12;
    }
    return cost;
  }
}
