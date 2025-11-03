import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'database_helper.dart';

class ProfileScreen extends StatefulWidget {
  final int? patientId;
  final String? fileName;
  final String? filePath;

  const ProfileScreen({super.key, this.patientId, this.fileName, this.filePath});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _patientData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    if (kIsWeb) {
      // Use empty data for web
      setState(() {
        _patientData = {
          'name': '',
          'age': null,
          'gender': '',
          'phone': '',
          'email': '',
          'address': '',
          'diagnosis': '',
          'date_of_injury': '',
          'medical_history': '',
          'medications': '',
          'fileName': widget.fileName,
        };
        _isLoading = false;
      });
      return;
    }

    if (widget.patientId != null) {
      // Load existing patient data
      final patient = await DatabaseHelper.instance.getPatientById(widget.patientId!);
      setState(() {
        _patientData = patient;
        _isLoading = false;
      });
    } else if (widget.filePath != null || widget.fileName != null) {
      // Prefer matching by filePath if available, otherwise fall back to fileName
      final db = await DatabaseHelper.instance.database;
      List<Map<String, Object?>> results = [];

      if (widget.filePath != null) {
        results = await db.query(
          'patients',
          where: 'filePath = ?',
          whereArgs: [widget.filePath],
        );
      }

      if (results.isEmpty && widget.fileName != null) {
        results = await db.query(
          'patients',
          where: 'fileName = ?',
          whereArgs: [widget.fileName],
        );
      }

      setState(() {
        if (results.isNotEmpty) {
          _patientData = results.first;
        } else {
          // New patient with empty data
          _patientData = {
            'name': '',
            'age': null,
            'gender': '',
            'phone': '',
            'email': '',
            'address': '',
            'diagnosis': '',
            'date_of_injury': '',
            'medical_history': '',
            'medications': '',
            'fileName': widget.fileName,
            'filePath': widget.filePath,
          };
        }
        _isLoading = false;
      });
    } else {
      // No patientId or fileName provided - show empty form
      setState(() {
        _patientData = {
          'name': '',
          'age': null,
          'gender': '',
          'phone': '',
          'email': '',
          'address': '',
          'diagnosis': '',
          'date_of_injury': '',
          'medical_history': '',
          'medications': '',
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePatientData(Map<String, dynamic> updatedData) async {
    if (kIsWeb) {
      // On web, just update local state
      setState(() {
        _patientData = updatedData;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile updated (web - changes not saved to database)',
            ),
          ),
        );
      }
      return;
    }

    final dbHelper = DatabaseHelper.instance;
    
    try {
      if (widget.fileName != null) {
        // Add fileName to data for new patients
        updatedData['fileName'] = widget.fileName;
      }
      if (widget.filePath != null) {
        // Also include filePath for unique matching
        updatedData['filePath'] = widget.filePath;
      }

      if (widget.patientId != null) {
        // Update existing patient
        await dbHelper.updatePatient(widget.patientId!, updatedData);
      } else {
        // Insert new patient
        await dbHelper.upsertPatientWithFile(updatedData);
      }

      await _loadPatientData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        // Return to previous screen after saving
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(
      text: _patientData?['name'] ?? '',
    );
    final ageController = TextEditingController(
      text: (_patientData?['age'] ?? '').toString(),
    );
    final genderController = TextEditingController(
      text: _patientData?['gender'] ?? '',
    );
    final phoneController = TextEditingController(
      text: _patientData?['phone'] ?? '',
    );
    final emailController = TextEditingController(
      text: _patientData?['email'] ?? '',
    );
    final addressController = TextEditingController(
      text: _patientData?['address'] ?? '',
    );
    final diagnosisController = TextEditingController(
      text: _patientData?['diagnosis'] ?? '',
    );
    final dateOfInjuryController = TextEditingController(
      text: _patientData?['date_of_injury'] ?? '',
    );
    final medicalHistoryController = TextEditingController(
      text: _patientData?['medical_history'] ?? '',
    );
    final medicationsController = TextEditingController(
      text: _patientData?['medications'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: genderController,
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: diagnosisController,
                decoration: const InputDecoration(labelText: 'Diagnosis'),
              ),
              TextField(
                controller: dateOfInjuryController,
                decoration: const InputDecoration(labelText: 'Date of Injury'),
              ),
              TextField(
                controller: medicalHistoryController,
                decoration: const InputDecoration(labelText: 'Medical History'),
              ),
              TextField(
                controller: medicationsController,
                decoration: const InputDecoration(labelText: 'Medications'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updatePatientData({
                'name': nameController.text,
                'age': int.tryParse(ageController.text) ?? 0,
                'gender': genderController.text,
                'phone': phoneController.text,
                'email': emailController.text,
                'address': addressController.text,
                'diagnosis': diagnosisController.text,
                'date_of_injury': dateOfInjuryController.text,
                'medical_history': medicalHistoryController.text,
                'medications': medicationsController.text,
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final patient = _patientData ?? {};
    final name = patient['name'] ?? '';
    final age = patient['age'];
    final gender = patient['gender'] ?? '';
    final phone = patient['phone'] ?? '';
    final email = patient['email'] ?? '';
    final address = patient['address'] ?? '';
    final diagnosis = patient['diagnosis'] ?? '';
    final dateOfInjury = patient['date_of_injury'] ?? '';
    final medicalHistory = patient['medical_history'] ?? '';
    final medications = patient['medications'] ?? '';
    
    // Show edit dialog immediately if no data is present
    if (widget.patientId == null && 
        widget.fileName != null && 
        name.isEmpty && 
        !_isLoading) {
      // Use Future.delayed to avoid calling setState during build
      Future.delayed(Duration.zero, _showEditProfileDialog);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: const Color.fromRGBO(115, 209, 246, 0.53),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Summary Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=256&q=80&auto=format&fit=crop&ixlib=rb-4.0.3',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Age: $age',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gender: $gender',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contact Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildContactItem('Phone:', phone),
                        const SizedBox(height: 8),
                        _buildContactItem('Email:', email),
                        const SizedBox(height: 8),
                        _buildContactItem('Address:', address),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Medical Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Medical Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildContactItem('Diagnosis:', diagnosis),
                        const SizedBox(height: 8),
                        _buildContactItem('Date of Injury:', dateOfInjury),
                        const SizedBox(height: 8),
                        _buildContactItem('Medical History:', medicalHistory),
                        const SizedBox(height: 8),
                        _buildContactItem('Medications:', medications),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Edit Profile Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 37, 143, 185),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _showEditProfileDialog,
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    
  }

  Widget _buildContactItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
