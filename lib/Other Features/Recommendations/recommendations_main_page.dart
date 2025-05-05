// ignore_for_file: deprecated_member_use

import 'package:clothify/Other%20Features/Recommendations/color_recommendations_page.dart';
import 'package:clothify/Other%20Features/Recommendations/ocassional_recommendations_page.dart';
import 'package:clothify/Other%20Features/Recommendations/seasonal_recommendations_page.dart';
import 'package:clothify/Other%20Features/Recommendations/style_recommendations_page.dart';
import 'package:flutter/material.dart';

class RecommendationsMainPage extends StatelessWidget {
  const RecommendationsMainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000A3D),
      appBar: AppBar(
        title: const Text('Recommendations'),
        backgroundColor: const Color(0xFFECECEC),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personalized Recommendations',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get clothing recommendations based on your preferences and measurements',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),

            _buildRecommendationCard(
              context,
              'Seasonal',
              'Get clothing recommendations based on the current season',
              Icons.wb_sunny,
              Colors.orange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SeasonalRecommendationsPage(),
                  ),
                );
              },
            ),

            _buildRecommendationCard(
              context,
              'Occasional',
              'Find the perfect outfit for any special occasion',
              Icons.celebration,
              Colors.pink,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OccasionalRecommendationsPage(),
                  ),
                );
              },
            ),

            _buildRecommendationCard(
              context,
              'Style',
              'Discover clothing that matches your personal style',
              Icons.style,
              Colors.teal,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StyleRecommendationsPage(),
                  ),
                );
              },
            ),

            _buildRecommendationCard(
              context,
              'Color',
              'Find colors that complement your skin tone and preference',
              Icons.color_lens,
              Colors.purple,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ColorRecommendationsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
