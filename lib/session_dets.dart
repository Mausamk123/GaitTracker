import 'package:flutter/material.dart';
import 'package:gait_tracker/chart_view.dart';
import 'profile_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';

class SessionDetailsScreen extends StatefulWidget {
  const SessionDetailsScreen({super.key});

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  // int _selectedSession = 0;

  final List<SessionData> _sessions = [
    SessionData(
      sessionNumber: 1,
      date: '20-09-2003',
      speed: 1.2,
      steps: 100,
      timeTaken: 30,
      fileName: 'Session1_20-09-2003.txt',
    ),
    SessionData(
      sessionNumber: 2,
      date: '20-10-2003',
      speed: 1.5,
      steps: 150,
      timeTaken: 35,
      fileName: 'Session2_20-10-2003.txt',
    ),
    SessionData(
      sessionNumber: 3,
      date: '20-11-2003',
      speed: 1.3,
      steps: 130,
      timeTaken: 32,
      fileName: 'Session3_20-11-2003.txt',
    ),
    SessionData(
      sessionNumber: 4,
      date: '20-12-2003',
      speed: 1.7,
      steps: 180,
      timeTaken: 40,
      fileName: 'Session4_20-12-2003.txt',
    ),
    SessionData(
      sessionNumber: 5,
      date: '21-01-2004',
      speed: 1.4,
      steps: 160,
      timeTaken: 38,
      fileName: 'Session5_21-01-2004.txt',
    ),
    SessionData(
      sessionNumber: 6,
      date: '21-02-2004',
      speed: 1.8,
      steps: 200,
      timeTaken: 45,
      fileName: 'Session6_21-02-2004.txt',
    ),
    SessionData(
      sessionNumber: 7,
      date: '21-03-2004',
      speed: 1.6,
      steps: 220,
      timeTaken: 50,
      fileName: 'Session7_21-03-2004.txt',
    ),
  ];

  // Helper method to create GaitPhaseData from SessionData
  GaitPhaseData _createGaitDataFromSession(SessionData session) {
    // Calculate cadence: steps per minute
    final double cadence = session.steps / (session.timeTaken / 60.0);

    // Calculate stance and swing percentages based on speed
    // Higher speed typically means more swing phase
    // Normal gait: ~60% stance, ~40% swing
    // Adjust based on speed (higher speed = more swing)
    double swingPercentage = 35.0 + (session.speed - 1.0) * 10.0;
    swingPercentage = swingPercentage.clamp(30.0, 50.0);
    double stancePercentage = 100.0 - swingPercentage;

    return GaitPhaseData(
      stancePercentage: stancePercentage,
      swingPercentage: swingPercentage,
      cadence: cadence,
    );
  }

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
            // Steps Chart Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: StepsBarChart(sessions: _sessions),
            ),
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
                        // Create a File object for the session
                        // The file path is used only for display in ChartView
                        final file = File(session.fileName);
                        final gaitData = _createGaitDataFromSession(session);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ChartView(file: file, data: gaitData),
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
    );
  }
}

class SessionData {
  final int sessionNumber;
  final String date;
  final double speed;
  final int steps;
  final int timeTaken; // in minutes
  final String fileName;

  SessionData({
    required this.sessionNumber,
    required this.date,
    required this.speed,
    required this.steps,
    required this.timeTaken,
    required this.fileName,
  });
}

class StepsBarChart extends StatefulWidget {
  final List<SessionData> sessions;

  const StepsBarChart({super.key, required this.sessions});

  @override
  State<StepsBarChart> createState() => _StepsBarChartState();
}

class _StepsBarChartState extends State<StepsBarChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Steps',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    widget.sessions
                        .map((s) => s.steps.toDouble())
                        .reduce((a, b) => a > b ? a : b) *
                    1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final session = widget.sessions[groupIndex];
                      return BarTooltipItem(
                        'Steps: ${session.steps}\nTime Taken: ${session.timeTaken} min',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        touchedIndex = null;
                        return;
                      }
                      touchedIndex =
                          barTouchResponse.spot!.touchedBarGroupIndex;
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < widget.sessions.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Session${index + 1}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 6,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: widget.sessions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final session = entry.value;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: session.steps.toDouble(),
                        color: const Color(0xFF73D1F6),
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY:
                              widget.sessions
                                  .map((s) => s.steps.toDouble())
                                  .reduce((a, b) => a > b ? a : b) *
                              1.2,
                          color: Colors.grey[100],
                        ),
                      ),
                    ],
                  );
                }).toList(),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
