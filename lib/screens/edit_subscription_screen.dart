import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';
import '../services/settings_service.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class EditSubscriptionScreen extends StatefulWidget {
  final Subscription subscription;

  const EditSubscriptionScreen({super.key, required this.subscription});

  @override
  State<EditSubscriptionScreen> createState() => _EditSubscriptionScreenState();
}

class _EditSubscriptionScreenState extends State<EditSubscriptionScreen> {
  late TextEditingController _nameController;
  late TextEditingController _costController;
  late String _selectedCategory;
  late String _selectedPeriod;
  late DateTime _nextBillingDate;
  bool _isLoading = false;

  final List<String> _categories = [
    "Entertainment",
    "Utilities",
    "Work",
    "Personal",
    "Other",
  ];

  final SubscriptionService _service = SubscriptionService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subscription.name);
    _costController = TextEditingController(
      text: widget.subscription.cost.toString(),
    );
    _selectedCategory = widget.subscription.category;
    _selectedPeriod = widget.subscription.period;
    _nextBillingDate = widget.subscription.nextBillingDate;
  }

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

  Future<void> _updateSubscription() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedSub = Subscription(
        userId: _authService.currentUser!.uid,
        name: _nameController.text.trim(),
        cost: double.parse(_costController.text),
        period: _selectedPeriod,
        category: _selectedCategory,
        nextBillingDate: _nextBillingDate,
        isActive: widget.subscription.isActive,
      );

      await _service.updateSubscription(widget.subscription.id!, updatedSub);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription updated successfully')),
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
      appBar: AppBar(title: const Text('Edit Subscription')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HERO LOGO
              Center(
                child: Hero(
                  tag: 'subscription_logo_${widget.subscription.id}',
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: widget.subscription.logoPath != null ? Colors.transparent : Colors.teal.shade100,
                      shape: BoxShape.circle,
                      image: widget.subscription.logoPath != null
                          ? DecorationImage(
                              image: AssetImage(widget.subscription.logoPath!),
                              fit: BoxFit.contain,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: widget.subscription.logoPath == null
                        ? Text(
                            widget.subscription.name.isNotEmpty ? widget.subscription.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // NAME INPUT
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Service Name',
                  hintText: 'e.g. Netflix',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a service name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // COST INPUT
              TextFormField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Cost (${Provider.of<SettingsService>(context, listen: false).currencySymbol})',
                  prefixText: '${Provider.of<SettingsService>(context, listen: false).currencySymbol} ',
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter a cost';
                  }
                  try {
                    final cost = double.parse(val);
                    if (cost <= 0) {
                      return 'Cost must be greater than 0';
                    }
                  } catch (e) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // PERIOD & CATEGORY
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedPeriod,
                      decoration: const InputDecoration(
                        labelText: 'Billing Cycle',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'month',
                          child: Text('Monthly'),
                        ),
                        DropdownMenuItem(value: 'year', child: Text('Yearly')),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedPeriod = val as String),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
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

              // DATE PICKER
              ListTile(
                title: const Text('Next Billing Date'),
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

              // UPDATE BUTTON
              ElevatedButton(
                onPressed: _isLoading ? null : _updateSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'UPDATE SUBSCRIPTION',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    super.dispose();
  }
}
