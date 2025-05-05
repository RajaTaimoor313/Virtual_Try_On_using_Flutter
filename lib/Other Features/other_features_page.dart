// ignore_for_file: deprecated_member_use

import 'package:clothify/Other%20Features/Recommendations/recommendations_main_page.dart';
import 'package:clothify/Other%20Features/Virtual_TryOn/virtual_tryon_features_page.dart';
import 'package:clothify/Other%20Features/ai_chat_stylist_page.dart';
import 'package:clothify/Other%20Features/compare_style_page.dart';
import 'package:clothify/Other%20Features/style_quiz_page.dart';
import 'package:clothify/persistent_bottom_nav.dart';
import 'package:flutter/material.dart';

class OtherFeaturesPage extends StatelessWidget {
  const OtherFeaturesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PersistentBottomNav(
      currentIndex: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF000A3D),
        appBar: AppBar(
          title: const Text('Other Features'),
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
                'Explore More Features',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Discover additional features to enhance your fashion experience',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 30),

              _buildFeatureCard(
                context,
                'Virtual Try On',
                'Try clothes virtually before buying',
                Icons.checkroom,
                const Color.fromARGB(255, 7, 150, 151),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VirtualTryOnFeaturesPage(),
                    ),
                  );
                },
              ),

              _buildFeatureCard(
                context,
                'Recommendations',
                'Get personalized clothing recommendations',
                Icons.recommend,
                const Color(0xFFE91E63),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecommendationsMainPage(),
                    ),
                  );
                },
              ),

              _buildFeatureCard(
                context,
                'Style Quiz',
                'Discover your fashion style',
                Icons.quiz,
                Colors.amber,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StyleQuizPage(),
                    ),
                  );
                },
              ),

              _buildFeatureCard(
                context,
                'AI Assistant',
                'Chat with your personal fashion stylist',
                Icons.chat,
                Colors.purple,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIChatStylistPage(),
                    ),
                  );
                },
              ),

              _buildFeatureCard(
                context,
                'Compare Style',
                'Compare different styles on you',
                Icons.compare,
                Colors.blue,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompareStylePage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color.withOpacity(0.2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 20),
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
                    const SizedBox(height: 5),
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
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
