import 'package:flutter/material.dart'; 
import 'profile_screen.dart';
import 'session_dets.dart';

void main() {
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

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  int _selectedIndex = 0;

  final List<Patient> _patients = List<Patient>.generate(
    8,
    (int index) => Patient(
      name: 'Dhwani Joshi',
      age: 20,
      id: '402348',
      avatarUrl:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=256&q=80&auto=format&fit=crop&ixlib=rb-4.0.3',
    ),
  );

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
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                itemCount: _patients.length,
                itemBuilder: (BuildContext context, int index) => PatientCard(
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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