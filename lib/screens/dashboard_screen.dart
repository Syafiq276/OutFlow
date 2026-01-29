import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';
import '../services/auth_service.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (ctx) => const LoginScreen()),
          (route) => false,
        );
      }
    }
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

  void _navigateToAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const AddSubscriptionScreen()),
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
  List<Color> _getCategoryColors() {
    return [
      const Color(0xFF008B8B), // Teal
      const Color(0xFF20B2AA), // Light Sea Green
      const Color(0xFF48D1CC), // Medium Turquoise
      const Color(0xFF7FFFD4), // Aquamarine
      const Color(0xFF00CED1), // Dark Turquoise
      const Color(0xFF5F9EA0), // Cadet Blue
    ];
  }

  // Build the expense breakdown pie chart
  Widget _buildExpenseChart(List<Subscription> subscriptions) {
    final spendingMap = _getSpendingByCategory(subscriptions);

    if (spendingMap.isEmpty) {
      return const Center(child: Text('No active subscriptions'));
    }

    final colors = _getCategoryColors();
    final pieSections = <PieChartSectionData>[];
    final entries = spendingMap.entries.toList();

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      pieSections.add(
        PieChartSectionData(
          value: entry.value,
          color: colors[i % colors.length],
          title: '${entry.value.toStringAsFixed(0)}',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(sections: pieSections),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.asMap().entries.map((e) {
            final index = e.key;
            final entry = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(entry.key),
                  ),
                  Text(
                    'RM ${entry.value.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outflow Dashboard'),
        elevation: 0,
        actions: [
          PopupMenuButton(
            itemBuilder: (ctx) => [
              PopupMenuItem(child: const Text('Logout'), onTap: _logout),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Subscription>>(
        stream: _service.getSubscriptionsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final subscriptions = snapshot.data ?? [];

          // Filter by search and category
          final filteredSubscriptions = subscriptions.where((sub) {
            final matchesSearch = sub.name.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );
            final matchesCategory =
                _selectedCategory == 'All' || sub.category == _selectedCategory;
            return matchesSearch && matchesCategory && sub.isActive;
          }).toList();

          if (subscriptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/outflow_logo.png',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Subscriptions Yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _navigateToAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Bill'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Statistics Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withAlpha(102),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FutureBuilder<double>(
                  future: _service.getTotalMonthlyCost(subscriptions),
                  builder: (context, snapshot) {
                    final totalCost =
                        snapshot.data?.toStringAsFixed(2) ?? '0.00';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monthly Spending',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'RM $totalCost',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${subscriptions.length} active subscription${subscriptions.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Expense Breakdown Pie Chart
              if (subscriptions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(51),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Spending by Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildExpenseChart(subscriptions),
                    ],
                  ),
                ),

              // Search & Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search subscriptions...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = category == _selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => _selectedCategory = category);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Subscriptions List
              Expanded(
                child: filteredSubscriptions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 60,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text('No subscriptions found'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredSubscriptions.length,
                        itemBuilder: (context, index) {
                          final sub = filteredSubscriptions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.withAlpha(25),
                                child: Text(
                                  sub.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                sub.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '${sub.category} • ${sub.period == 'month' ? 'Monthly' : 'Yearly'}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Next: ${DateFormat('dd MMM yyyy').format(sub.nextBillingDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'RM ${sub.monthlyCost.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    sub.period == 'month' ? '/month' : '/year',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              onTap: () => _navigateToEdit(sub),
                              onLongPress: () => _deleteSubscription(sub.id!),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
