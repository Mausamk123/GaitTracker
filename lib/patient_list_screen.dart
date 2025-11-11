import 'package:flutter/material.dart';
import 'session_dets.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final List<Patient> _patients = List<Patient>.generate(
    4,
    (index) => const Patient(name: 'Dhwani Joshi', age: 20, id: '402348'),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Patient List',
          style: GoogleFonts.secularOne(
            color: Colors.black,
            fontWeight: FontWeight.w400,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color.fromRGBO(115, 209, 246, 0.53),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),
              Expanded(
                child: ListView.separated(
                  itemCount: _patients.length,
                  itemBuilder: (context, index) => PatientCard(
                    patient: _patients[index],
                    onViewDetails: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SessionDetailsScreen(),
                      ),
                    ),
                  ),
                  separatorBuilder: (_, __) => const SizedBox(height: 18),
                ),
              ),
            ],
          ),
        ),
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
    return Container(
      // height: 100,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 247, 252, 254),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image removed per requirement
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // const SizedBox(height: 9),
                  Text(
                    'Age: ${patient.age}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ID: ${patient.id}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 130,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(17, 75, 95, 1),
                  foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: onViewDetails,
                child: const Text(
                  'View Details',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Patient {
  const Patient({required this.name, required this.age, required this.id});

  final String name;
  final int age;
  final String id;
}
