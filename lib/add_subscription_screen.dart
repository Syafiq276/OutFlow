import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/subscription_model.dart';
import 'services/subscription_service.dart';
import 'services/auth_service.dart';

class AddSubscriptionScreen extends StatefulWidget {
  const AddSubscriptionScreen({super.key});

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers & Variables
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();

  String _selectedCategory = "Entertainment";
  String _selectedPeriod = "month";
  DateTime _nextBillingDate = DateTime.now();
  bool _isLoading = false;

  final SubscriptionService _service = SubscriptionService();
  final AuthService _authService = AuthService();

  final List<String> _categories = [
    "Entertainment",
    "Utilities",
    "Work",
    "Personal",
    "Other",
  ];

  // --- DATE PICKER FUNCTION ---
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextBillingDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _nextBillingDate = picked);
    }
  }

  // --- SAVE TO FIREBASE ---
  Future<void> _saveSubscription() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newSub = Subscription(
        userId: _authService.currentUser!.uid,
        name: _nameController.text.trim(),
        cost: double.parse(_costController.text),
        period: _selectedPeriod,
        category: _selectedCategory,
        nextBillingDate: _nextBillingDate,
      );

      await _service.addSubscription(newSub);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Subscription")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. NAME INPUT
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Service Name (e.g. Netflix)",
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Please enter a service name";
                  }
                  if (val.length < 2) {
                    return "Service name must be at least 2 characters";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // 2. COST INPUT
              TextFormField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Cost (RM)",
                  prefixText: "RM ",
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return "Please enter a cost";
                  }
                  try {
                    final cost = double.parse(val);
                    if (cost <= 0) {
                      return "Cost must be greater than 0";
                    }
                  } catch (e) {
                    return "Please enter a valid number";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 3. ROW: PERIOD & CATEGORY
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedPeriod,
                      decoration: const InputDecoration(
                        labelText: "Billing Cycle",
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "month",
                          child: Text("Monthly"),
                        ),
                        DropdownMenuItem(value: "year", child: Text("Yearly")),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedPeriod = val as String),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: "Category"),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val as String),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. DATE PICKER ROW
              ListTile(
                title: const Text("Next Billing Date"),
                subtitle: Text(
                  DateFormat('dd MMM yyyy').format(_nextBillingDate),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.teal),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(5),
                ),
                onTap: _pickDate,
              ),
              const SizedBox(height: 40),

              // 5. SAVE BUTTON
              ElevatedButton(
                onPressed: _isLoading ? null : _saveSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SAVE SUBSCRIPTION",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
