import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:gait_tracker/edit_profile_screen.dart';
import 'package:gait_tracker/patient_list_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:math';
import 'profile_screen.dart';
import 'database_helper.dart';
import 'file_manager.dart';
import 'chart_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database only on mobile platforms
  if (!kIsWeb) {
    try {
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
    } catch (e, st) {
      // Don't block app startup if DB initialization fails.
      // Log the error and allow the UI to load so user can still interact.
      debugPrint('Database init failed: $e');
      debugPrint('$st');
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
      home: const DashboardScreen(),
    );
  }
}

// Alias for compatibility with existing tests
class MyApp extends GaitTrackerApp {
  const MyApp({super.key});
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<File> _importedFiles = [];
  // map from imported filename -> display name (patient name) to show on UI
  Map<String, String> _fileDisplayNames = {};
  bool _isLoadingFiles = false;

  @override
  void initState() {
    super.initState();
    _loadImportedFiles();
  }

  Future<void> _loadImportedFiles() async {
    if (!kIsWeb) {
      setState(() => _isLoadingFiles = true);
      List<File> files = [];
      try {
        files = await FileManager().getImportedFiles();
      } catch (e, st) {
        debugPrint('Failed to list imported files: $e');
        debugPrint('$st');
        files = [];
      }

      // Load patients and build a map fileName -> patient name for display
      _fileDisplayNames = {};
      try {
        final db = await DatabaseHelper.instance.database;
        final patients = await db.query('patients');
        for (final p in patients) {
          final String? fName = (p['fileName'] as String?);
          final String? fPath = (p['filePath'] as String?);
          final String? n = (p['name'] as String?);
          if (n != null) {
            if (fPath != null && fPath.isNotEmpty) {
              _fileDisplayNames[fPath] = n;
            }
            if (fName != null && fName.isNotEmpty) {
              // also map basename (for older rows or backups)
              _fileDisplayNames[fName] = n;
            }
          }
        }
      } catch (e) {
        // ignore DB errors and proceed with file names
        debugPrint('Error loading patient names: $e');
      }

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
    final fileName = file.path.split('/').last;
    // Get patient data by fileName
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    final results = await db.query(
      'patients',
      where: 'fileName = ?',
      whereArgs: [fileName],
    );

    int? patientId;
    if (results.isNotEmpty) {
      patientId = results.first['id'] as int;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          patientId: patientId,
          fileName: fileName,
          filePath: file.path,
        ),
      ),
    );

    // After returning from profile screen, reload imported files to update UI names
    await _loadImportedFiles();
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

      final lines = content
          .split(RegExp(r'[\r\n]+'))
          .where((l) => l.trim().isNotEmpty)
          .toList();
      if (lines.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('File is empty')));
        return;
      }

      // Remove header if present (simple heuristic)
      if (lines.length > 1) lines.removeAt(0);

      int totalPoints = 0;
      int swingPoints = 0;
      int stepCount = 0;
      double? firstTime;
      double? lastTime;
      bool inSwing = false;

      for (final line in lines) {
        final parts = line.split(',').map((p) => p.trim()).toList();
        // Expect at least SerialNo, Time, AccX, AccY, AccZ, GyroX, GyroY, GyroZ -> 8 parts
        if (parts.length < 8) continue;

        try {
          // Parse time (assuming it's in seconds)
          final double time = double.parse(parts[1]);
          if (firstTime == null) firstTime = time;
          lastTime = time;

          final String gxRaw = parts[5].replaceAll(RegExp(r'[^0-9.\-+]'), '');
          final String gyRaw = parts[6].replaceAll(RegExp(r'[^0-9.\-+]'), '');
          final String gzRaw = parts[7].replaceAll(RegExp(r'[^0-9.\-+]'), '');

          final double gx = double.parse(gxRaw);
          final double gy = double.parse(gyRaw);
          final double gz = double.parse(gzRaw);

          final double gyroMagnitude = sqrt(
            pow(gx, 2) + pow(gy, 2) + pow(gz, 2),
          );

          if (gyroMagnitude > GYRO_MAGNITUDE_THRESHOLD) {
            if (!inSwing) {
              stepCount++; // Count new step only when transitioning from stance to swing
              inSwing = true;
            }
            swingPoints++;
          } else {
            inSwing = false;
          }
          totalPoints++;
        } catch (e) {
          // ignore parse errors on this line
          debugPrint('Line parse error: $e');
        }
      }

      if (totalPoints == 0 || firstTime == null || lastTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid data points found in file')),
        );
        return;
      }

      final double swingPct = (swingPoints / totalPoints) * 100.0;
      final double stancePct = 100.0 - swingPct;

      // Calculate cadence (steps per minute)
      final double timeInSeconds = lastTime - firstTime;
      final double timeInMinutes = timeInSeconds / 60.0;
      final double cadence = stepCount / timeInMinutes;

      final gaitData = GaitPhaseData(
        stancePercentage: stancePct,
        swingPercentage: swingPct,
        cadence: cadence,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChartView(file: file, data: gaitData),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error reading file: $e')));
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

  Future<void> _reinitializeData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reinitialize data'),
        content: const Text(
          'This will delete all imported files from local storage. This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoadingFiles = true);
    try {
      final files = await FileManager().getImportedFiles();
      int deleted = 0;
      final List<String> deletedPaths = [];
      for (final f in files) {
        final ok = await FileManager().deleteFile(f.path);
        if (ok) {
          deleted++;
          deletedPaths.add(f.path);
        }
      }

      // Also remove patient records corresponding to deleted file paths
      try {
        final db = await DatabaseHelper.instance.database;
        int patientsDeleted = 0;
        for (final p in deletedPaths) {
          patientsDeleted += await db.delete(
            'patients',
            where: 'filePath = ?',
            whereArgs: [p],
          );
        }

        await _loadImportedFiles();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reinitialized: deleted $deleted file(s) and $patientsDeleted patient record(s)',
            ),
          ),
        );
      } catch (e) {
        // If DB delete fails, still reload files and inform user
        await _loadImportedFiles();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reinitialized: deleted $deleted file(s). Failed to remove patient records: $e',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reinitialize data: $e')),
      );
    } finally {
      setState(() => _isLoadingFiles = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Image.asset('assets/images/Logo.png', fit: BoxFit.contain),
          ),
        ),
        leadingWidth: 90,
        title: Text(
          'GaitTracker',
          style: GoogleFonts.secularOne(
            color: Colors.black,
            fontWeight: FontWeight.w400,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color.fromRGBO(115, 209, 246, 0.53),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              if (_importedFiles.isNotEmpty) ...[
                Text(
                  'Imported Files',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    itemCount: _importedFiles.length,
                    itemBuilder: (context, index) {
                      final file = _importedFiles[index];
                      final basename = file.path.split('/').last;
                      final displayName =
                          _fileDisplayNames[file.path] ??
                          _fileDisplayNames[basename];
                      return ImportedFileCard(
                        file: file,
                        displayName: displayName,
                        onEdit: () => _editFile(file),
                        onChart: () => _viewChart(file),
                        onDelete: () => _deleteFile(file),
                      );
                    },
                  ),
                ),
              ],

              // Small debug marker to verify UI is rendering on device
              // Import Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoadingFiles ? null : () {},

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF73D1F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Connect My Device'),
                ),
              ),
              // Imported Files Section
              // Patients Section
              const SizedBox(height: 20),
              SizedBox(
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoadingFiles
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return PatientListScreen();
                            },
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF73D1F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Show all patients'),
                ),
              ),
              const SizedBox(height: 20),
              // Reinitialize data button - deletes all imported files from local storage
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoadingFiles ? null : _reinitializeData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Reinitialize data'),
                ),
              ),
            ],
          ),
        ),
      ),
      // Removed bottomNavigationBar since only one item remains
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

// Bottom navigation removed — single-screen app now

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
    this.displayName,
    required this.onEdit,
    required this.onChart,
    required this.onDelete,
  });

  final File file;
  final String? displayName;
  final VoidCallback onEdit;
  final VoidCallback onChart;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final fileName = file.path.split('/').last;
    final shownName = displayName ?? fileName;

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
                  shownName,
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(onSave: (p0) {}),
                    ),
                  );
                },
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
