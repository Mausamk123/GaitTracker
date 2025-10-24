import 'package:flutter/material.dart';

class GaitDetails extends StatelessWidget {
  const GaitDetails({super.key});

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
      ),
      body: Column(
        children: [
        
          // Patient Information Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Patient 1',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Age: 38 / Female',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    children: [
                      TextSpan(
                        text: 'Condition: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'ACL Tear (Right Knee)',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      
          // Session Details Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Session 1',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '1st September, 2025',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Gait Phase Donut Chart
                Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Donut Chart
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: Stack(
                            children: [
                              // Stance Phase (45%)
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: CircularProgressIndicator(
                                  value: 0.45,
                                  strokeWidth: 20,
                                  backgroundColor: Colors.transparent,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF1E3A8A), // Dark blue
                                  ),
                                ),
                              ),
                              // Swing Phase (55%)
                              Positioned.fill(
                                child: CircularProgressIndicator(
                                  value: 0.55,
                                  strokeWidth: 20,
                                  backgroundColor: Colors.transparent,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF73D1F6), // Light blue
                                  ),
                                ),
                              ),
                              // Center content
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      '45%',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Stance Phase',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF1E3A8A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 40),
                        
                        // Legend
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegendItem(
                              'Stance Phase',
                              const Color(0xFF1E3A8A),
                            ),
                            const SizedBox(height: 12),
                            _buildLegendItem(
                              'Swing Phase',
                              const Color(0xFF73D1F6),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Cadence Section
                const Text(
                  'Cadence',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '103.27 steps/min',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                
              ],
            ),
          ),
        ],
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
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: '',
            ),
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}


