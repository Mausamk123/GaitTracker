import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? patientData;
  final int? patientId;
  final String? fileName;
  final String? filePath;
  final Function(Map<String, dynamic>) onSave;

  const EditProfileScreen({
    super.key,
    this.patientData,
    this.patientId,
    this.fileName,
    this.filePath,
    required this.onSave,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _genderController;
  late TextEditingController _phoneController;
  late TextEditingController _dateOfInjuryController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.patientData?['name'] ?? '',
    );
    _ageController = TextEditingController(
      text: widget.patientData?['age'] != null
          ? widget.patientData!['age'].toString()
          : '',
    );
    _genderController = TextEditingController(
      text: widget.patientData?['gender'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.patientData?['phone'] ?? '',
    );
    _dateOfInjuryController = TextEditingController(
      text: widget.patientData?['date_of_injury'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _phoneController.dispose();
    _dateOfInjuryController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
    });

    final updatedData = {
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'gender': _genderController.text.trim(),
      'phone': _phoneController.text.trim(),
      'date_of_injury': _dateOfInjuryController.text.trim(),
    };

    await widget.onSave(updatedData);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.secularOne(
            color: Colors.black,
            fontWeight: FontWeight.w400,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color.fromRGBO(115, 209, 246, 0.53),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Name Field
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(115, 209, 246, 0.53),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              // Age Field
              TextField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'Age',
                  labelStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(115, 209, 246, 0.53),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              // Phone Number Field
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(115, 209, 246, 0.53),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              // Gender Field
              TextField(
                controller: _genderController,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  labelStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(115, 209, 246, 0.53),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              // Date of Injury Field
              TextField(
                controller: _dateOfInjuryController,
                decoration: InputDecoration(
                  labelText: 'Date of Injury',
                  labelStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(115, 209, 246, 0.53),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  hintText: 'YYYY-MM-DD',
                ),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 31, 130, 163),
                    foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
