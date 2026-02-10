import 'package:flutter_test/flutter_test.dart';
import 'package:outflow/models/subscription_model.dart';

void main() {
  group('Subscription Model', () {
    test('monthlyCost returns correct cost for monthly period', () {
      final sub = Subscription(
        userId: 'test_user',
        name: 'Netflix',
        cost: 15.0,
        period: 'month',
        category: 'Entertainment',
        nextBillingDate: DateTime.now(),
      );
      expect(sub.monthlyCost, 15.0);
    });

    test('monthlyCost returns correct cost for yearly period', () {
      final sub = Subscription(
        userId: 'test_user',
        name: 'Gym',
        cost: 120.0,
        period: 'year',
        category: 'Health',
        nextBillingDate: DateTime.now(),
      );
      expect(sub.monthlyCost, 10.0);
    });
  });
}
