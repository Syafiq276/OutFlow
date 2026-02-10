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
  final TextEditingController _notesController = TextEditingController();

  String _selectedCategory = "Entertainment";
  String _selectedPeriod = "month";
  String? _selectedLogoPath;

  // Available logos
  final List<String> _availableLogos = [
    'assets/logos/ASB.png',
    'assets/logos/Atome.png',
    'assets/logos/Bank Islam.png',
    'assets/logos/Coway.png',
    'assets/logos/Cuckoo.png',
    'assets/logos/Indah water.png',
    'assets/logos/Maybank.png',
    'assets/logos/ShopeePay.png',
    'assets/logos/Spotify.png',
    'assets/logos/TM.png',
    'assets/logos/TNB.png',
    'assets/logos/TNG.png',
    'assets/logos/Umobile.png',
    'assets/logos/Unifi.png',
    'assets/logos/celcomdigi.png',
    'assets/logos/grabpay.png',
    'assets/logos/maxis.png',
    'assets/logos/netflix.png',
    'assets/logos/youtube.png',
  ];

  DateTime _nextBillingDate = DateTime.now();
  bool _isLoading = false;

  final SubscriptionService _service = SubscriptionService();
  final AuthService _authService = AuthService();

  final List<String> _categories = [
    "Entertainment",
    "Utilities",
    "Finance",
    "Work",
    "Personal",
    "Other",
  ];

  // Mock popular services
  final List<Map<String, dynamic>> _popularServices = [
    {'name': 'Netflix', 'icon': Icons.movie},
    {'name': 'Spotify', 'icon': Icons.music_note},
    {'name': 'Dropbox', 'icon': Icons.cloud},
    {'name': 'Youtube', 'icon': Icons.play_circle_filled},
  ];

  // --- LOGO PICKER FUNCTION ---
  void _showLogoPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            children: [
              const Text(
                "Select a Logo",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _availableLogos.length,
                  itemBuilder: (context, index) {
                    final logoPath = _availableLogos[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedLogoPath = logoPath);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: AssetImage(logoPath),
                            fit: BoxFit.contain, // Changed to contain to avoid cropping
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- DATE PICKER FUNCTION ---
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextBillingDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00796B),
            ),
          ),
          child: child!,
        );
      },
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
        logoPath: _selectedLogoPath,
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

  void _fillPopularService(String name) {
    _nameController.text = name;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add Subscription",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
               // Clear form
               _nameController.clear();
               _costController.clear();
               _notesController.clear();
               setState(() {
                 _selectedCategory = "Entertainment";
                 _selectedPeriod = "month";
                 _nextBillingDate = DateTime.now();
                 _selectedLogoPath = null;
               });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Logo Placeholder
              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: _showLogoPicker,
                  child: Stack(
                    children: [
                       Container(
                         width: 100,
                         height: 100,
                         decoration: BoxDecoration(
                           color: Colors.grey[200],
                           borderRadius: BorderRadius.circular(30),
                           image: _selectedLogoPath != null
                               ? DecorationImage(
                                   image: AssetImage(_selectedLogoPath!),
                                   fit: BoxFit.contain, // contain to match picker
                                 )
                               : null,
                         ),
                         child: _selectedLogoPath == null
                             ? const Icon(Icons.camera_alt, color: Colors.grey, size: 40)
                             : null,
                       ),
                       Positioned(
                         bottom: 0,
                         right: 0,
                         child: Container(
                           padding: const EdgeInsets.all(4),
                           decoration: const BoxDecoration(
                             color: Color(0xFF00796B),
                             shape: BoxShape.circle,
                             boxShadow: [
                               BoxShadow(color: Colors.white, spreadRadius: 2),
                             ],
                           ),
                           child: const Icon(Icons.edit, color: Colors.white, size: 20), // Changed from add to edit
                         ),
                       ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedLogoPath != null ? 'Tap to change logo' : 'Tap to select logo',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 32),

              // 2. Name Input
              const Text("Subscription Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: "e.g. Netflix, Spotify, Gym",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Please enter a service name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              const Text('Enter the name of the service provider', style: TextStyle(color: Colors.grey, fontSize: 10)),
              const SizedBox(height: 24),

              // 3. Amount & Cycle
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _costController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            prefixText: "RM ",
                            hintText: "0.00",
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return "Required";
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Cycle", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedPeriod = 'month'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedPeriod == 'month' ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: _selectedPeriod == 'month'
                                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "Monthly",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: _selectedPeriod == 'month' ? const Color(0xFF00796B) : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedPeriod = 'year'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedPeriod == 'year' ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: _selectedPeriod == 'year'
                                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "Yearly",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: _selectedPeriod == 'year' ? const Color(0xFF00796B) : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Category
              const Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00796B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.category, size: 16, color: Color(0xFF00796B)),
                        ),
                        const SizedBox(width: 8),
                        Text(c),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                icon: const Icon(Icons.keyboard_arrow_down),
                decoration: const InputDecoration(
                   contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 24),

              // 5. Next Billing Date
              const Text("Next Billing Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today, color: Colors.grey),
                  ),
                  child: Text(
                    DateFormat('MMMM dd, yyyy').format(_nextBillingDate),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 6. Notes
              const Text("Notes (Optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Plan details, sharing with family, etc.",
                  hintStyle: TextStyle(color: Colors.grey),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              // 7. Popular Services
              const Text("Popular Services", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _popularServices.map((service) {
                    return GestureDetector(
                      onTap: () => _fillPopularService(service['name']),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(service['icon'], size: 20), // Placeholder icons
                            const SizedBox(width: 8),
                            Text(service['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 40),

              // 8. Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Save Subscription",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
