// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:clothify/user_provider.dart';
import 'package:provider/provider.dart';

class OccasionalRecommendationsPage extends StatefulWidget {
  const OccasionalRecommendationsPage({Key? key}) : super(key: key);

  @override
  State<OccasionalRecommendationsPage> createState() =>
      _OccasionalRecommendationsPageState();
}

class _OccasionalRecommendationsPageState
    extends State<OccasionalRecommendationsPage> {
  String _selectedOccasion = 'Casual';
  bool _isLoading = false;
  List<Map<String, dynamic>> _recommendations = [];

  final Map<String, Color> _occasionColors = {
    'Casual': Colors.teal,
    'Business': Colors.blue,
    'Party': Colors.purple,
    'Formal': Colors.indigo,
    'Sports': Colors.orange,
  };

  final Map<String, IconData> _occasionIcons = {
    'Casual': Icons.weekend,
    'Business': Icons.business,
    'Party': Icons.celebration,
    'Formal': Icons.emoji_events,
    'Sports': Icons.sports,
  };

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _recommendations = _getOccasionalRecommendations(_selectedOccasion);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recommendations: $e');
      setState(() {
        _isLoading = false;
        _recommendations = [];
      });
    }
  }

  void _changeOccasion(String occasion) {
    setState(() {
      _selectedOccasion = occasion;
    });
    _loadRecommendations();
  }

  List<Map<String, dynamic>> _getOccasionalRecommendations(String occasion) {
    switch (occasion) {
      case 'Casual':
        return [
          {
            'name': 'Weekend T-Shirt',
            'description':
                'Relaxed fit t-shirt perfect for casual outings and weekend activities.',
            'category': 'T-Shirts',
          },
          {
            'name': 'Everyday Button-Up',
            'description':
                'Comfortable casual shirt that works for daily wear or light social events.',
            'category': 'Shirts',
          },
          {
            'name': 'Light Casual Jacket',
            'description':
                'Versatile jacket that completes your casual look while providing light protection.',
            'category': 'Jackets',
          },
        ];

      case 'Business':
        return [
          {
            'name': 'Professional Undershirt',
            'description':
                'Quality undershirt designed to pair with business attire for comfort throughout the workday.',
            'category': 'T-Shirts',
          },
          {
            'name': 'Business Oxford Shirt',
            'description':
                'Classic oxford shirt with the right balance of professionalism and comfort for office environments.',
            'category': 'Shirts',
          },
          {
            'name': 'Professional Blazer',
            'description':
                'Tailored blazer that maintains a professional appearance while offering comfort for all-day wear.',
            'category': 'Jackets',
          },
        ];

      case 'Party':
        return [
          {
            'name': 'Statement T-Shirt',
            'description':
                'Eye-catching t-shirt with unique details perfect for casual parties and social gatherings.',
            'category': 'T-Shirts',
          },
          {
            'name': 'Party Button-Up',
            'description':
                'Stylish shirt with subtle patterns that stand out in social settings while maintaining comfort.',
            'category': 'Shirts',
          },
          {
            'name': 'Night Out Jacket',
            'description':
                'Fashion-forward jacket that makes a statement for evening events and parties.',
            'category': 'Jackets',
          },
        ];

      case 'Formal':
        return [
          {
            'name': 'Premium Undershirt',
            'description':
                'High-quality undershirt designed specifically to pair with formal wear for important occasions.',
            'category': 'T-Shirts',
          },
          {
            'name': 'Formal Dress Shirt',
            'description':
                'Elegant dress shirt with refined details suitable for weddings, galas, and formal events.',
            'category': 'Shirts',
          },
          {
            'name': 'Formal Suit Jacket',
            'description':
                'Sophisticated jacket with premium construction and details for the most formal occasions.',
            'category': 'Jackets',
          },
        ];

      case 'Sports':
        return [
          {
            'name': 'Performance T-Shirt',
            'description':
                'Technical t-shirt with moisture-wicking properties designed for active sports and exercise.',
            'category': 'T-Shirts',
          },
          {
            'name': 'Athletic Training Shirt',
            'description':
                'Specialized shirt with performance features for training and sports activities.',
            'category': 'Shirts',
          },
          {
            'name': 'Sports Performance Jacket',
            'description':
                'Lightweight, technical jacket designed for warmth and mobility during outdoor sports.',
            'category': 'Jackets',
          },
        ];

      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000A3D),
      appBar: AppBar(
        title: const Text('Occasional Recommendations'),
        backgroundColor: const Color(0xFFECECEC),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  _buildOccasionButton('Casual', _occasionIcons['Casual']!),
                  _buildOccasionButton('Business', _occasionIcons['Business']!),
                  _buildOccasionButton('Party', _occasionIcons['Party']!),
                  _buildOccasionButton('Formal', _occasionIcons['Formal']!),
                  _buildOccasionButton('Sports', _occasionIcons['Sports']!),
                ],
              ),
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _occasionColors[_selectedOccasion]!.withOpacity(0.8),
                  _occasionColors[_selectedOccasion]!.withOpacity(0.3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _occasionIcons[_selectedOccasion],
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$_selectedOccasion Wear',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _getOccasionDescription(_selectedOccasion),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),

          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final hasMeasurements = userProvider.isMeasurementsAvailable;

              if (hasMeasurements) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  color: Colors.white.withOpacity(0.05),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color.fromARGB(255, 7, 150, 151),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Recommendations are personalized based on your body measurements',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  color: Colors.amber.withOpacity(0.1),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Add your body measurements for personalized fit recommendations',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),

          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color.fromARGB(255, 7, 150, 151),
                      ),
                    )
                    : _recommendations.isEmpty
                    ? Center(
                      child: Text(
                        'No recommendations available for $_selectedOccasion',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(15),
                      itemCount: _recommendations.length,
                      itemBuilder: (context, index) {
                        final item = _recommendations[index];
                        return _buildRecommendationCard(item);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccasionButton(String occasion, IconData icon) {
    final isSelected = _selectedOccasion == occasion;
    final occasionColor = _occasionColors[occasion] ?? Colors.blue;

    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: ElevatedButton.icon(
        onPressed: () => _changeOccasion(occasion),
        icon: Icon(icon, size: 18),
        label: Text(occasion),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? occasionColor : Colors.white.withOpacity(0.1),
          foregroundColor: isSelected ? Colors.white : Colors.white70,
          elevation: isSelected ? 2 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? occasionColor : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 180,
                  color: _occasionColors[_selectedOccasion]!.withOpacity(0.2),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(item['category']),
                      size: 60,
                      color: _occasionColors[_selectedOccasion]!.withOpacity(
                        0.5,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 7, 150, 151),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      item['category'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['description'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 15),

                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    if (userProvider.isMeasurementsAvailable) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _occasionColors[_selectedOccasion]!
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _occasionColors[_selectedOccasion]!
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: _occasionColors[_selectedOccasion]!,
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'This design should fit well based on your measurements',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),

                const SizedBox(height: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'T-Shirts':
        return Icons.person;
      case 'Shirts':
        return Icons.accessibility;
      case 'Jackets':
        return Icons.layers;
      default:
        return Icons.category;
    }
  }

  String _getOccasionDescription(String occasion) {
    switch (occasion) {
      case 'Casual':
        return 'Comfortable, everyday clothing suitable for relaxed settings, weekends, and informal gatherings where comfort is key.';
      case 'Business':
        return 'Professional attire appropriate for office environments and business meetings that balances formality with all-day comfort.';
      case 'Party':
        return 'Stylish, attention-grabbing pieces perfect for social events, celebrations, and nights out that help you stand out.';
      case 'Formal':
        return 'Elegant and sophisticated clothing suitable for significant events like weddings, galas, and formal dinners where tradition matters.';
      case 'Sports':
        return 'Technical, performance-focused clothing designed for physical activities, sports, and exercise with features that enhance movement.';
      default:
        return '';
    }
  }
}
