import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:math';
import 'profile_screen.dart';
import 'session_dets.dart';
import 'database_helper.dart';
import 'file_manager.dart';
import 'chart_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database only on mobile platforms
  if (!kIsWeb) {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;

    // Add sample patient data if database is empty
    final patients = await dbHelper.getAllPatients();
    if (patients.isEmpty) {
      await dbHelper.upsertPatientWithFile({
        'fileName': 'sample_patient_1',
        'name': 'Dhwani Joshi',
        'age': 38,
        'gender': 'Female',
        'disease': 'ACL Tear',
        'phone': '(+91) 9876542310',
        'email': 'dhwanijoshi193@gmail.com',
        'address': '1234 Main St, Springfield, IL',
        'diagnosis': 'ACL Tear (Right Knee)',
        'date_of_injury': '12/07/2024',
        'medical_history': 'Hypertension (under control)',
        'medications': 'Ibuprofen 400mg',
      });
    }
  }

  runApp(const GaitTrackerApp());
}

class GaitTrackerApp extends StatelessWidget {
  const GaitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gait Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF73D1F6)),
        useMaterial3: true,
      ),
      home: const PatientListScreen(),
    );
  }
}

// Alias for compatibility with existing tests
class MyApp extends GaitTrackerApp {
  const MyApp({super.key});
}

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  int _selectedIndex = 0;
  List<File> _importedFiles = [];
  bool _isLoadingFiles = false;

  final List<Patient> _patients = List<Patient>.generate(
    1,
    (int index) => Patient(
      name: 'Dhwani Joshi',
      age: 20,
      id: '402348',
      avatarUrl:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=256&q=80&auto=format&fit=crop&ixlib=rb-4.0.3',
    ),
  );

  @override
  void initState() {
    super.initState();
    _loadImportedFiles();
  }

  Future<void> _loadImportedFiles() async {
    if (!kIsWeb) {
      setState(() => _isLoadingFiles = true);
      final files = await FileManager().getImportedFiles();
      setState(() {
        _importedFiles = files;
        _isLoadingFiles = false;
      });
    }
  }

  Future<void> _importFiles() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File import not supported on web')),
      );
      return;
    }

    setState(() => _isLoadingFiles = true);

    try {
      final selectedFiles = await FileManager().pickTextFiles();

      if (selectedFiles != null && selectedFiles.isNotEmpty) {
        int successCount = 0;

        for (final file in selectedFiles) {
          final copiedPath = await FileManager().copyFileToLocal(file);
          if (copiedPath != null) {
            successCount++;
          }
        }

        await _loadImportedFiles();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported $successCount file(s)'),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No files selected')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error importing files: $e')));
    } finally {
      setState(() => _isLoadingFiles = false);
    }
  }

  Future<void> _editFile(File file) async {
    final content = await FileManager().readFileContent(file.path);
    if (content != null) {
      _showEditDialog(file, content);
    }
  }

  Future<void> _viewChart(File file) async {
    try {
      final content = await FileManager().readFileContent(file.path);
      if (content == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file content')),
        );
        return;
      }

      // Analysis logic: compute swing vs stance based on gyro magnitude
      const double GYRO_MAGNITUDE_THRESHOLD = 50.0; // adjust if needed

      final lines = content.split(RegExp(r'[\r\n]+')).where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File is empty')),
        );
        return;
      }

      // Remove header if present (simple heuristic)
      if (lines.length > 1) lines.removeAt(0);

      int totalPoints = 0;
      int swingPoints = 0;

      for (final line in lines) {
        final parts = line.split(',').map((p) => p.trim()).toList();
        // Expect at least SerialNo, Time, AccX, AccY, AccZ, GyroX, GyroY, GyroZ -> 8 parts
        if (parts.length < 8) continue;

        try {
          final String gxRaw = parts[5].replaceAll(RegExp(r'[^0-9.\-+]'), '');
          final String gyRaw = parts[6].replaceAll(RegExp(r'[^0-9.\-+]'), '');
          final String gzRaw = parts[7].replaceAll(RegExp(r'[^0-9.\-+]'), '');

          final double gx = double.parse(gxRaw);
          final double gy = double.parse(gyRaw);
          final double gz = double.parse(gzRaw);

          final double gyroMagnitude = sqrt(pow(gx, 2) + pow(gy, 2) + pow(gz, 2));

          if (gyroMagnitude > GYRO_MAGNITUDE_THRESHOLD) {
            swingPoints++;
          }
          totalPoints++;
        } catch (e) {
          // ignore parse errors on this line
          debugPrint('Line parse error: $e');
        }
      }

      if (totalPoints == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid data points found in file')),
        );
        return;
      }

      final double swingPct = (swingPoints / totalPoints) * 100.0;
      final double stancePct = 100.0 - swingPct;

      final gaitData = GaitPhaseData(stancePercentage: stancePct, swingPercentage: swingPct);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChartView(file: file, data: gaitData)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reading file: $e')));
    }
  }

  Future<void> _deleteFile(File file) async {
    final success = await FileManager().deleteFile(file.path);
    if (success) {
      await _loadImportedFiles();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${file.path.split('/').last}')),
      );
    }
  }

  void _showEditDialog(File file, String content) {
    final controller = TextEditingController(text: content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${file.path.split('/').last}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'File content...',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await FileManager().writeFileContent(
                file.path,
                controller.text,
              );
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File saved successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.asset('assets/images/Logo.png', width: 20, height: 20),
        leadingWidth: 50,
        title: Text(
          'GaitTracker',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color.fromRGBO(115, 209, 246, 0.53),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                'Patient List',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Import Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoadingFiles ? null : _importFiles,
                  icon: _isLoadingFiles
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(
                    _isLoadingFiles ? 'Importing...' : 'Import Text Files',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF73D1F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            // Imported Files Section
            if (_importedFiles.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(
                  'Imported Files',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                flex: 2,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _importedFiles.length,
                  itemBuilder: (context, index) => ImportedFileCard(
                    file: _importedFiles[index],
                    onEdit: () => _editFile(_importedFiles[index]),
                    onChart: () => _viewChart(_importedFiles[index]),
                    onDelete: () => _deleteFile(_importedFiles[index]),
                  ),
                ),
              ),
            ],
            // Patients Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Text(
                      'Patients',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      itemCount: _patients.length,
                      itemBuilder: (BuildContext context, int index) =>
                          PatientCard(
                            patient: _patients[index],
                            onViewDetails: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SessionDetailsScreen(),
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
      bottomNavigationBar: _RoundedTopNavBar(
        selectedIndex: _selectedIndex,
        onTap: (int i) {
          setState(() => _selectedIndex = i);
          if (i == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            );
          }
        },
      ),
    );
  }
}

class PatientCard extends StatelessWidget {
  const PatientCard({
    super.key,
    required this.patient,
    required this.onViewDetails,
  });

  final Patient patient;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 236, 234, 234),
          borderRadius: BorderRadius.circular(16),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color.fromARGB(119, 0, 0, 0),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                patient.avatarUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    patient.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    children: [
                      _InfoChip(label: 'Age: ${patient.age}'),
                      _InfoChip(label: 'ID:${patient.id}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 1),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEDEDED),
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                foregroundColor: Colors.black87,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: onViewDetails,
              child: const Text('View Details'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Colors.black54,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _RoundedTopNavBar extends StatelessWidget {
  const _RoundedTopNavBar({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
        ],
        backgroundColor: const Color(0xFF73D1F6),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class Patient {
  const Patient({
    required this.name,
    required this.age,
    required this.id,
    required this.avatarUrl,
  });

  final String name;
  final int age;
  final String id;
  final String avatarUrl;
}

class ImportedFileCard extends StatelessWidget {
  const ImportedFileCard({
    super.key,
    required this.file,
    required this.onEdit,
    required this.onChart,
    required this.onDelete,
  });

  final File file;
  final VoidCallback onEdit;
  final VoidCallback onChart;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final fileName = file.path.split('/').last;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF73D1F6), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.description, color: Color(0xFF73D1F6), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Text File',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, color: Color(0xFF73D1F6)),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: onChart,
                icon: const Icon(Icons.bar_chart, color: Color(0xFF73D1F6)),
                tooltip: 'View Chart',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
