import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import 'package:provider/provider.dart';
import '../add_subscription_screen.dart';
import 'edit_subscription_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SubscriptionService _service = SubscriptionService();
  final AuthService _authService = AuthService();
  
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    _categories = [
      'All',
      'Entertainment',
      'Utilities',
      'Work',
      'Personal',
      'Other',
    ];
    setState(() {});
  }

  Future<void> _deleteSubscription(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subscription'),
        content: const Text(
          'Are you sure you want to delete this subscription?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      try {
        await _service.deleteSubscription(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _navigateToEdit(Subscription subscription) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => EditSubscriptionScreen(subscription: subscription),
      ),
    );
  }

  // Calculate spending by category
  Map<String, double> _getSpendingByCategory(List<Subscription> subscriptions) {
    final spendingMap = <String, double>{};
    for (final sub in subscriptions.where((s) => s.isActive)) {
      final key = sub.category;
      spendingMap[key] = (spendingMap[key] ?? 0) + sub.monthlyCost;
    }
    return spendingMap;
  }

  // Get colors for pie chart
  Color _getCategoryColor(String category) {
     switch (category) {
       case 'Entertainment': return const Color(0xFF009688); // Teal
       case 'Utilities': return const Color(0xFF4DB6AC); // Lighter Teal
       case 'Work': return const Color(0xFF80CBC4);
       case 'Personal': return const Color(0xFFB2DFDB);
       default: return const Color(0xFFE0F2F1);
     }
  }

  // Build the expense breakdown pie chart
  Widget _buildExpenseChart(List<Subscription> subscriptions) {
    final spendingMap = _getSpendingByCategory(subscriptions);

    if (spendingMap.isEmpty) {
      return const Center(child: Text('No active subscriptions'));
    }

    final pieSections = <PieChartSectionData>[];
    final entries = spendingMap.entries.toList();
    
    // Sort by value desc
    entries.sort((a, b) => b.value.compareTo(a.value));
    
    // Determine Top Category
    String topCategory = entries.isNotEmpty ? entries.first.key : '-';

    double total = entries.fold(0, (sum, item) => sum + item.value);

    for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final isTop = i == 0;
        final percentage = (entry.value / total * 100).toStringAsFixed(0);
        
        pieSections.add(
          PieChartSectionData(
            value: entry.value,
            color: _getCategoryColor(entry.key),
            title: '$percentage%',
            radius: isTop ? 25 : 20, // Thin ring
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.transparent, // Hide on chart
            ),
            showTitle: false,
          ),
        );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sections: pieSections,
              centerSpaceRadius: 60,
              sectionsSpace: 2,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             const Text('Top', style: TextStyle(color: Colors.grey, fontSize: 12)),
             Text(
               topCategory,
               style: TextStyle(
                 fontWeight: FontWeight.bold,
                 fontSize: 16,
                 color: Theme.of(context).textTheme.bodyLarge?.color,
               ),
             ),
          ],
        )
      ],
    );
  }

  Widget _buildBreakdownList(Map<String, double> spendingMap) {
     final entries = spendingMap.entries.toList();
     entries.sort((a, b) => b.value.compareTo(a.value)); // Descending
     
     final total = entries.fold(0.0, (sum, item) => sum + item.value);

     return Column(
       children: entries.take(4).map((e) {
         final percent = (e.value / total * 100).round();
         return Padding(
           padding: const EdgeInsets.symmetric(vertical: 4),
           child: Row(
             children: [
               Container(
                 width: 10, height: 10,
                 decoration: BoxDecoration(
                   color: _getCategoryColor(e.key),
                   shape: BoxShape.circle,
                 ),
               ),
               const SizedBox(width: 8),
                Expanded(
                  child: Text(e.key, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)),
                ),
                Text('$percent%', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
             ],
           ),
         );
       }).toList(),
     );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid ?? '';
    final currency = Provider.of<SettingsService>(context).currencySymbol;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Row(
          children: [
             Container(
               padding: const EdgeInsets.all(4),
               decoration: BoxDecoration(
                 color: const Color(0xFF00796B),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: const Icon(Icons.wallet, color: Colors.white, size: 20),
             ),
             const SizedBox(width: 8),
             Text('Outflow', style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.grey)),
          // Logout removed
        ],
      ),
      body: StreamBuilder<List<Subscription>>(
        stream: _service.getSubscriptionsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final subscriptions = snapshot.data ?? [];

          if (subscriptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.subscriptions_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No subscriptions yet',
                    style: TextStyle(color: Colors.grey[500], fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddSubscriptionScreen()),
                      );
                    },
                    child: const Text('Add your first subscription'),
                  ),
                ],
              ),
            );
          }

          final filteredSubscriptions = subscriptions.where((sub) {
             return (_selectedCategory == 'All' || sub.category == _selectedCategory) && sub.isActive;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Total Monthly Spending Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00796B),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00796B).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: FutureBuilder<double>(
                    future: _service.getTotalMonthlyCost(subscriptions),
                    builder: (context, snapshot) {
                      final totalCost = snapshot.data ?? 0.00;
                      // Split integer and decimal for styling
                      final parts = totalCost.toStringAsFixed(2).split('.');
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Monthly Spending',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                     Icon(Icons.arrow_upward, color: Colors.white, size: 12),
                                     SizedBox(width: 4),
                                     Text('+12.5%', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Text(
                                '$currency ', 
                                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                parts[0],
                                style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '.${parts[1]}',
                                style: const TextStyle(color: Colors.white70, fontSize: 24, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                               Expanded(
                                 child: Container(
                                   padding: const EdgeInsets.all(12),
                                   decoration: BoxDecoration(
                                     color: Colors.white.withValues(alpha: 0.1),
                                     borderRadius: BorderRadius.circular(12),
                                   ),
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       const Text('Active Subs', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                       const SizedBox(height: 4),
                                       Text(
                                         '${subscriptions.length}',
                                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                       ),
                                     ],
                                   ),
                                 ),
                               ),
                               const SizedBox(width: 12),
                               Expanded(
                                 child: Container(
                                   padding: const EdgeInsets.all(12),
                                   decoration: BoxDecoration(
                                     color: Colors.white.withValues(alpha: 0.1),
                                     borderRadius: BorderRadius.circular(12),
                                   ),
                                   child: const Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Text('Upcoming', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                        SizedBox(height: 4),
                                       Text(
                                         '3', // Mock data for now, requires calculation features
                                         style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                       ),
                                     ],
                                   ),
                                 ),
                               ),
                            ],
                          )
                        ],
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 24),

                // 2. Spending Breakdown Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Spending Breakdown',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (subscriptions.isNotEmpty)
                        Row(
                          children: [
                             Expanded(
                               flex: 3,
                               child: _buildExpenseChart(subscriptions)
                             ),
                             Expanded(
                               flex: 4,
                               child: Padding(
                                 padding: const EdgeInsets.only(left: 16),
                                 child: _buildBreakdownList(_getSpendingByCategory(subscriptions)),
                               ),
                             ),
                          ],
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No data available'),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Category Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                       final isSelected = _selectedCategory == cat;
                       return Padding(
                         padding: const EdgeInsets.only(right: 8),
                         child: ActionChip(
                           label: Text(cat),
                           backgroundColor: isSelected ? const Color(0xFF00796B) : Theme.of(context).cardTheme.color,
                           labelStyle: TextStyle(
                             color: isSelected ? Colors.white : Colors.grey[600],
                             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                           ),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(20),
                             side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade200),
                           ),
                           onPressed: () => setState(() => _selectedCategory = cat),
                         ),
                       );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Subscriptions List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text(
                       'Subscriptions',
                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                     ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('See All', style: TextStyle(color: Color(0xFF00796B))),
                    ),
                  ],
                ),
                
                if (filteredSubscriptions.isEmpty)
                   const Padding(
                     padding: EdgeInsets.all(32),
                     child: Center(child: Text('No subscriptions in this category')),
                   )
                else
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: filteredSubscriptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final sub = filteredSubscriptions[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Hero(
                          tag: 'subscription_logo_${sub.id}',
                          child: Container(
                             width: 50, height: 50,
                             decoration: BoxDecoration(
                               color: sub.logoPath != null ? Colors.transparent : Colors.black, // Transparent if logo exists
                               shape: BoxShape.circle,
                               image: sub.logoPath != null
                                   ? DecorationImage(
                                       image: AssetImage(sub.logoPath!),
                                       fit: BoxFit.contain,
                                     )
                                   : null,
                             ),
                             alignment: Alignment.center,
                             child: sub.logoPath == null
                                 ? Text(
                                     sub.name.isNotEmpty ? sub.name[0].toUpperCase() : '?',
                                     style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                   )
                                 : null,
                          ),
                        ),
                        title: Text(
                          sub.name,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        subtitle: Text(
                           '${sub.period} • Next: ${DateFormat('MMM dd').format(sub.nextBillingDate)}',
                           style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$currency ${sub.cost.toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(sub.category).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                sub.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getCategoryColor(sub.category).withValues(alpha: 1.0), // Full opacity for text
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _navigateToEdit(sub),
                        onLongPress: () => _deleteSubscription(sub.id!),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 80), // Space for FAB/BottomNav
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    // _searchController.dispose();
    super.dispose();
  }
}
