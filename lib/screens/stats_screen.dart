import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import 'package:provider/provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final SubscriptionService _service = SubscriptionService();
  final AuthService _authService = AuthService();
  String _selectedPeriod = 'This Month';

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid ?? '';
    final settings = context.watch<SettingsService>();
    final currency = settings.currencySymbol;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Statistics',
          style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Subscription>>(
        stream: _service.getSubscriptionsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final subscriptions = snapshot.data ?? [];
          final totalMonthly = _calculateTotalMonthly(subscriptions);
          final categorySpending = _calculateCategorySpending(subscriptions);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 1. Total Spending Card
                _buildTotalSpendingCard(totalMonthly, currency),
                const SizedBox(height: 20),

                // 2. Chart Card
                _buildChartCard(totalMonthly, categorySpending),
                const SizedBox(height: 20),

                // 3. Category Breakdown
                _buildCategoryBreakdown(categorySpending, totalMonthly, currency),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalSpendingCard(double total, String currency) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF00796B),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00796B).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Total Monthly Spending',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Text(
            '$currency ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
             decoration: BoxDecoration(
               color: Colors.white.withValues(alpha: 0.2),
               borderRadius: BorderRadius.circular(20),
             ),
             child: const Text(
               'On Track', 
               style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
             ),
          )
        ],
      ),
    );
  }

  Widget _buildChartCard(double totalMonthly, Map<String, double> categorySpending) {
     return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                 'Spending Trend',
                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  onChanged: (String? newValue) => setState(() => _selectedPeriod = newValue!),
                  items: ['This Month', 'Last Month'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: totalMonthly * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                     getTooltipColor: (_) => Colors.blueGrey,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const titles = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            titles[value.toInt() % titles.length],
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (totalMonthly / 7) + (index % 2 == 0 ? 20 : -10), 
                        color: index == 3 ? const Color(0xFF00796B) : Theme.of(context).dividerColor,
                        width: 16,
                        borderRadius: BorderRadius.circular(8),
                      )
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(Map<String, double> categorySpending, double totalMonthly, String currency) {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         const Padding(
           padding: EdgeInsets.symmetric(horizontal: 4.0),
           child: Text(
             'Breakdown by Category',
             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
           ),
         ),
         const SizedBox(height: 16),
         ...categorySpending.entries.map((entry) {
            final category = entry.key;
            final amount = entry.value;
            final percentage = totalMonthly > 0 ? amount / totalMonthly : 0.0;
            final color = _getCategoryColor(category);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getCategoryIcon(category), size: 24, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                             Text(category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                             Text(
                                '$currency ${amount.toStringAsFixed(2)}', 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)
                             ),
                           ],
                         ),
                         const SizedBox(height: 8),
                         ClipRRect(
                           borderRadius: BorderRadius.circular(4),
                           child: LinearProgressIndicator(
                             value: percentage,
                             backgroundColor: Colors.grey[100],
                             color: color,
                             minHeight: 6,
                           ),
                         ),
                      ],
                    ),
                  ),
                ],
              ),
            );
         }),
       ],
     );
  }

  double _calculateTotalMonthly(List<Subscription> subscriptions) {
    return subscriptions.where((s) => s.isActive).fold(0.0, (sum, s) => sum + s.monthlyCost);
  }

  Map<String, double> _calculateCategorySpending(List<Subscription> subscriptions) {
    final map = <String, double>{};
    for (var sub in subscriptions.where((s) => s.isActive)) {
      map[sub.category] = (map[sub.category] ?? 0) + sub.monthlyCost;
    }
    return Map.fromEntries(map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  Color _getCategoryColor(String category) {
     switch (category) {
       case 'Entertainment': return const Color(0xFF009688);
       case 'Utilities': return const Color(0xFFFFA726); // Orange
       case 'Work': return const Color(0xFF5C6BC0); // Indigo
       case 'Personal': return const Color(0xFFEF5350); // Red
       default: return Colors.blueGrey;
     }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
       case 'Entertainment': return Icons.movie_creation_outlined;
       case 'Utilities': return Icons.bolt;
       case 'Work': return Icons.work_outline;
       case 'Personal': return Icons.person_outline;
       default: return Icons.category_outlined;
     }
  }
}
