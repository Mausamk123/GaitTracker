import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'database_helper.dart';
import 'edit_profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  final int? patientId;
  final String? fileName;
  final String? filePath;

  const ProfileScreen({
    super.key,
    this.patientId,
    this.fileName,
    this.filePath,
  });

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

          'date_of_injury': '',

          'fileName': widget.fileName,
        };
        _isLoading = false;
      });
      return;
    }

    if (widget.patientId != null) {
      // Load existing patient data
      final patient = await DatabaseHelper.instance.getPatientById(
        widget.patientId!,
      );
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
            'date_of_injury': '',
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

          'date_of_injury': '',
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    }
  }

  void _showEditProfileDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          patientData: _patientData,
          patientId: widget.patientId,
          fileName: widget.fileName,
          filePath: widget.filePath,
          onSave: (updatedData) async {
            await _updatePatientData(updatedData);
            if (mounted) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    ).then((_) {
      // Reload data when returning from edit screen
      _loadPatientData();
    });
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
    final dateOfInjury = patient['date_of_injury'] ?? '';

    // Show edit screen immediately if no data is present
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
          'Profile',
          style: GoogleFonts.secularOne(
            color: Colors.black,
            fontWeight: FontWeight.w400,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color.fromRGBO(115, 209, 246, 0.53),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: _showEditProfileDialog,
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _confirmAndDeletePatient,
            tooltip: 'Delete Patient',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile icon (image removed)
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color.fromRGBO(115, 209, 246, 0.53),
                child: const Icon(
                  Icons.person,
                  size: 48,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),
              // Name
              Text(
                name.isEmpty ? 'No Name' : name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 32),
              // Profile Information
              _buildInfoRow('Age', age != null ? age.toString() : 'Not set'),
              const SizedBox(height: 20),
              _buildInfoRow('Phone Number', phone.isEmpty ? 'Not set' : phone),
              const SizedBox(height: 20),
              _buildInfoRow('Gender', gender.isEmpty ? 'Not set' : gender),
              const SizedBox(height: 20),
              _buildInfoRow(
                'Date of Injury',
                dateOfInjury.isEmpty ? 'Not set' : dateOfInjury,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }

  Future<void> _confirmAndDeletePatient() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete patient'),
        content: const Text(
          'This will permanently delete the patient and all related sessions and data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete is not supported on web.')),
        );
      }
      return;
    }

    try {
      final db = DatabaseHelper.instance;
      if (widget.patientId != null) {
        await db.deletePatientById(widget.patientId!);
      } else if (widget.filePath != null) {
        await db.deletePatientByFilePath(widget.filePath!);
      } else if (widget.fileName != null) {
        await db.deletePatientByFileName(widget.fileName!);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Patient deleted')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete patient: $e')));
      }
    }
  }
}
