import 'package:flutter/material.dart';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:path/path.dart' as path;
import 'package:google_fonts/google_fonts.dart';

/// Simple data holder for gait phase percentages
class GaitPhaseData {
  final double stancePercentage;
  final double swingPercentage;
  final double cadence;

  GaitPhaseData({
    required this.stancePercentage,
    required this.swingPercentage,
    required this.cadence,
  });
}

class ChartView extends StatelessWidget {
  final File file;
  final GaitPhaseData data;

  const ChartView({super.key, required this.file, required this.data});

  @override
  Widget build(BuildContext context) {
    final String baseName = path.basename(file.path);
    final RegExp re = RegExp(r'Session\s*([0-9]+)', caseSensitive: false);
    String titleText;
    final match = re.firstMatch(baseName);
    if (match != null && match.groupCount >= 1) {
      titleText = 'Session ${match.group(1)}';
    } else {
      // Fallback: try to get number before underscore e.g., Session5_2024-01-01.txt
      final RegExp reAlt = RegExp(r'Session[_\- ]?(\d+)', caseSensitive: false);
      final alt = reAlt.firstMatch(baseName);
      titleText = alt != null ? 'Session ${alt.group(1)}' : 'Session';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          titleText,
          style: GoogleFonts.secularOne(
            color: Colors.black,
            fontWeight: FontWeight.w400,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color.fromRGBO(115, 209, 246, 0.53),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Place the pie chart in the same visual position as gait_details.dart
              Center(
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: PhasePieChart(data: data),
                ),
              ),
              const SizedBox(height: 24),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Swing Phase', const Color(0xFF73D1F6)),
                  const SizedBox(width: 24),
                  _buildLegendItem('Stance Phase', const Color(0xFF1E3A8A)),
                ],
              ),
              const SizedBox(height: 64),
              // Cadence Section
              const Text(
                'Cadence',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${data.cadence.toStringAsFixed(2)} steps/min',
                style: const TextStyle(fontSize: 18, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class PhasePieChart extends StatelessWidget {
  final GaitPhaseData data;

  const PhasePieChart({super.key, required this.data});

  List<PieChartSectionData> showingSections() {
    return [
      PieChartSectionData(
        color: const Color(0xFF1E3A8A), // stance - dark blue
        value: data.stancePercentage,
        title: '${data.stancePercentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: const Color(0xFF73D1F6), // swing - light blue
        value: data.swingPercentage,
        title: '${data.swingPercentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        startDegreeOffset: -90,
        sections: showingSections(),
      ),
    );
  }
}
