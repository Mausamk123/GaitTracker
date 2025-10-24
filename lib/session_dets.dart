import 'package:flutter/material.dart';
import 'package:gait_tracker/gait_details.dart';
import 'profile_screen.dart';

class SessionDetailsScreen extends StatefulWidget {
  const SessionDetailsScreen({super.key});

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  // int _selectedSession = 0;

  final List<SessionData> _sessions = [
    SessionData(sessionNumber: 1, date: '20-09-2003', speed: 1.2),
    SessionData(sessionNumber: 2, date: '20-10-2003', speed: 1.5),
    SessionData(sessionNumber: 3, date: '20-11-2003', speed: 1.3),
    SessionData(sessionNumber: 4, date: '20-12-2003', speed: 1.7),
    SessionData(sessionNumber: 5, date: '21-01-2004', speed: 1.4),
    SessionData(sessionNumber: 6, date: '21-02-2004', speed: 1.8),
    SessionData(sessionNumber: 7, date: '21-03-2004', speed: 1.6),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Dhwani Joshi',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color.fromRGBO(115, 209, 246, 0.53),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=256&q=80&auto=format&fit=crop&ixlib=rb-4.0.3',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Session List Section
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _sessions.length,
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(
                        'Session ${session.sessionNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        'Date: ${session.date}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF73D1F6),
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GaitDetails(),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomNavigationBar(
          currentIndex: 0, // Home is selected
          onTap: (index) {
            if (index == 0) {
              Navigator.pushNamed(context, '/');
            } else if (index == 1) {
              Navigator.pushNamed(context, '/profile');
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: ''),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: '',
            ),
          ],
          backgroundColor: const Color(0xFF73D1F6),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}

class SessionData {
  final int sessionNumber;
  final String date;
  final double speed;

  SessionData({
    required this.sessionNumber,
    required this.date,
    required this.speed,
  });
}
