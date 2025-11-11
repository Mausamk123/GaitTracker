import 'package:flutter/material.dart';
import 'package:gait_tracker/chart_view.dart';
import 'profile_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

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
          style: GoogleFonts.secularOne(
            color: Colors.black,
            fontWeight: FontWeight.w400,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color.fromRGBO(115, 209, 246, 0.53),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
        actionsPadding: EdgeInsets.only(right: 10),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SwipeableCharts(sessions: _sessions),
              // Action Buttons
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Starting data collection...'),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(17, 75, 95, 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 5),
                            const Flexible(
                              child: Text(
                                'Start data collection',
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Add New Session...')),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color.fromRGBO(17, 75, 95, 1),
                          ),
                        ),
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add,
                              color: Color.fromRGBO(17, 75, 95, 1),
                              size: 20,
                            ),
                            const SizedBox(width: 5),
                            const Flexible(
                              child: Text(
                                'Add New Session',
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromRGBO(17, 75, 95, 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Importing Data...')),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF73D1F6)),
                        ),
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.download,
                              color: Color(0xFF73D1F6),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                'Import Data',
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF73D1F6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Session List Section
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
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
                            color: const Color.fromARGB(27, 0, 0, 0),
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
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
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

class SwipeableCharts extends StatefulWidget {
  final List<SessionData> sessions;

  const SwipeableCharts({super.key, required this.sessions});

  @override
  State<SwipeableCharts> createState() => _SwipeableChartsState();
}

class _SwipeableChartsState extends State<SwipeableCharts> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
          // Title and Page Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getChartTitle(_currentPage),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Row(
                children: List.generate(2, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? const Color(0xFF73D1F6)
                          : Colors.grey[300],
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 200,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                SwingPhaseHistogram(sessions: widget.sessions),
                StancePhaseHistogram(sessions: widget.sessions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getChartTitle(int page) {
    switch (page) {
      case 0:
        return 'Swing Phase';
      case 1:
        return 'Stance Percentage';
      default:
        return 'Chart';
    }
  }
}

class SwingPhaseHistogram extends StatelessWidget {
  final List<SessionData> sessions;

  const SwingPhaseHistogram({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final swingData = sessions.map((s) {
      final gaitData = _createGaitDataFromSession(s);
      return gaitData.swingPercentage;
    }).toList();

    final barGroups = swingData.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: const Color(0xFF73D1F6),
            width: 18,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: 105,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20, // ✅ aligns grid with Y-axis labels
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                if (value % 10 == 0) {
                  return Text(
                    '${value.toInt()}%',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sessions.length) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'S${index + 1}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (group) => const Color.fromRGBO(17, 75, 95, 1),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final session = sessions[group.x.toInt()];
              return BarTooltipItem(
                'Session ${session.sessionNumber}\nSwing: ${rod.toY.toStringAsFixed(1)}%',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  GaitPhaseData _createGaitDataFromSession(SessionData session) {
    final double cadence = session.steps / (session.timeTaken / 60.0);
    double swingPercentage = 35.0 + (session.speed - 1.0) * 10.0;
    swingPercentage = swingPercentage.clamp(30.0, 50.0);
    double stancePercentage = 100.0 - swingPercentage;

    return GaitPhaseData(
      stancePercentage: stancePercentage,
      swingPercentage: swingPercentage,
      cadence: cadence,
    );
  }
}

class StancePhaseHistogram extends StatelessWidget {
  final List<SessionData> sessions;

  const StancePhaseHistogram({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final stanceData = sessions.map((s) {
      final gaitData = _createGaitDataFromSession(s);
      return gaitData.stancePercentage;
    }).toList();

    final barGroups = stanceData.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: const Color.fromRGBO(17, 75, 95, 1), // darker teal
            width: 18,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: 105,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                if (value % 10 == 0) {
                  return Text(
                    '${value.toInt()}%',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sessions.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'S${index + 1}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            fitInsideVertically: true,
            fitInsideHorizontally: true,
            getTooltipColor: (group) => const Color(0xFF73D1F6),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final session = sessions[group.x.toInt()];
              return BarTooltipItem(
                'Session ${session.sessionNumber}\nStance: ${rod.toY.toStringAsFixed(1)}%',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  GaitPhaseData _createGaitDataFromSession(SessionData session) {
    final double cadence = session.steps / (session.timeTaken / 60.0);
    double swingPercentage = 35.0 + (session.speed - 1.0) * 10.0;
    swingPercentage = swingPercentage.clamp(30.0, 50.0);
    double stancePercentage = 100.0 - swingPercentage;

    return GaitPhaseData(
      stancePercentage: stancePercentage,
      swingPercentage: swingPercentage,
      cadence: cadence,
    );
  }
}
