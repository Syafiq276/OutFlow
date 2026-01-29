import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // CREATE - Add a new subscription
  Future<void> addSubscription(Subscription subscription) async {
    try {
      await _firestore.collection('subscriptions').add(subscription.toMap());
    } catch (e) {
      throw Exception('Failed to add subscription: $e');
    }
  }

  // READ - Get all subscriptions for a specific user as a stream
  Stream<List<Subscription>> getSubscriptionsStream(String userId) {
    try {
      return _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .orderBy('nextBillingDate', descending: false)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => Subscription.fromDocument(doc))
                .toList();
          });
    } catch (e) {
      throw Exception('Failed to fetch subscriptions: $e');
    }
  }

  // READ - Get single subscription by ID
  Future<Subscription?> getSubscriptionById(String id) async {
    try {
      final doc = await _firestore.collection('subscriptions').doc(id).get();
      if (doc.exists) {
        return Subscription.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch subscription: $e');
    }
  }

  // UPDATE - Update an existing subscription
  Future<void> updateSubscription(String id, Subscription subscription) async {
    try {
      await _firestore
          .collection('subscriptions')
          .doc(id)
          .update(subscription.toMap());
    } catch (e) {
      throw Exception('Failed to update subscription: $e');
    }
  }

  // DELETE - Delete a subscription
  Future<void> deleteSubscription(String id) async {
    try {
      await _firestore.collection('subscriptions').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete subscription: $e');
    }
  }

  // ANALYTICS - Get total monthly spending
  Future<double> getTotalMonthlyCost(List<Subscription> subscriptions) async {
    double total = 0;
    for (var sub in subscriptions) {
      total += sub.monthlyCost;
    }
    return total;
  }

  // ANALYTICS - Get spending by category
  Future<Map<String, double>> getSpendingByCategory(
    List<Subscription> subscriptions,
  ) async {
    Map<String, double> categorySpending = {};
    for (var sub in subscriptions) {
      final category = sub.category;
      categorySpending[category] =
          (categorySpending[category] ?? 0) + sub.monthlyCost;
    }
    return categorySpending;
  }

  // ANALYTICS - Get subscriptions due in next N days
  Future<List<Subscription>> getUpcomingBillings(
    List<Subscription> subscriptions,
    int daysAhead,
  ) async {
    final now = DateTime.now();
    final deadline = now.add(Duration(days: daysAhead));
    return subscriptions
        .where(
          (sub) =>
              sub.nextBillingDate.isBefore(deadline) &&
              sub.nextBillingDate.isAfter(now) &&
              sub.isActive,
        )
        .toList();
  }
}
