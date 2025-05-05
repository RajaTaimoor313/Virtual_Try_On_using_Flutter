// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:clothify/user_provider.dart';
import 'package:provider/provider.dart';

class StyleRecommendationsPage extends StatefulWidget {
  const StyleRecommendationsPage({Key? key}) : super(key: key);

  @override
  State<StyleRecommendationsPage> createState() =>
      _StyleRecommendationsPageState();
}

class _StyleRecommendationsPageState extends State<StyleRecommendationsPage> {
  String _selectedStyle = 'Casual';
  bool _isLoading = false;
  List<Map<String, dynamic>> _recommendations = [];

  final Map<String, Color> _styleColors = {
    'Casual': Colors.teal,
    'Formal': Colors.blue,
    'Athletic': Colors.orange,
    'Minimalist': Colors.grey,
    'Vintage': Colors.amber.shade800,
    'Bohemian': Colors.purple,
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
        _recommendations = _getStyleRecommendations(_selectedStyle);
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

  void _changeStyle(String style) {
    setState(() {
      _selectedStyle = style;
    });
    _loadRecommendations();
  }

  List<Map<String, dynamic>> _getStyleRecommendations(String style) {
    switch (style) {
      case 'Casual':
        return [
          {
            'name': 'Relaxed Fit T-Shirt',
            'description':
                'Comfortable, easy-going t-shirt perfect for everyday wear.',
            'category': 'T-Shirts',
          },
          {
            'name': 'Classic Casual Shirt',
            'description':
                'Timeless casual button-up that pairs well with jeans or chinos.',
            'category': 'Shirts',
          },
          {
            'name': 'Everyday Denim Jacket',
            'description':
                'Versatile denim jacket that complements most casual outfits.',
            'category': 'Jackets',
          },
        ];

      case 'Formal':
        return [
          {
            'name': 'Premium Undershirt',
            'description':
                'High-quality undershirt designed to pair seamlessly with formal attire.',
            'category': 'T-Shirts',
          },
          {
            'name': 'Classic Dress Shirt',
            'description':
                'Refined dress shirt with elegant details suitable for formal occasions.',
            'category': 'Shirts',
          },
          {
            'name': 'Tailored Suit Jacket',
            'description':
                'Sophisticated jacket with structured silhouette and premium details.',
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
        title: const Text('Style Recommendations'),
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
                  _buildStyleButton('Casual'),
                  _buildStyleButton('Formal'),
                  _buildStyleButton('Athletic'),
                  _buildStyleButton('Minimalist'),
                  _buildStyleButton('Vintage'),
                  _buildStyleButton('Bohemian'),
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
                  _styleColors[_selectedStyle]!.withOpacity(0.8),
                  _styleColors[_selectedStyle]!.withOpacity(0.3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_selectedStyle Style',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _getStyleDescription(_selectedStyle),
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
                        'No recommendations available for $_selectedStyle style',
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

  Widget _buildStyleButton(String style) {
    final isSelected = _selectedStyle == style;
    final styleColor = _styleColors[style] ?? Colors.blue;

    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: ElevatedButton(
        onPressed: () => _changeStyle(style),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? styleColor : Colors.white.withOpacity(0.1),
          foregroundColor: isSelected ? Colors.white : Colors.white70,
          elevation: isSelected ? 2 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? styleColor : Colors.transparent,
            ),
          ),
        ),
        child: Text(style),
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
                  color: Colors.white.withOpacity(0.1),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(item['category']),
                      size: 60,
                      color: Colors.white.withOpacity(0.3),
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
                          color: _styleColors[_selectedStyle]!.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _styleColors[_selectedStyle]!.withOpacity(
                              0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: _styleColors[_selectedStyle]!,
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'This design complements your body shape and personal style',
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

  String _getStyleDescription(String style) {
    switch (style) {
      case 'Casual':
        return 'Relaxed, comfortable everyday clothing that prioritizes ease of wear and versatility for various informal settings.';
      case 'Formal':
        return 'Elegant and refined clothing with structured silhouettes and premium details suitable for professional or special occasions.';
      case 'Athletic':
        return 'Performance-oriented clothing with technical fabrics and functional features designed for active lifestyles.';
      case 'Minimalist':
        return 'Clean, simple designs with neutral colors and uncluttered aesthetics that focus on quality and versatility.';
      case 'Vintage':
        return 'Clothing inspired by past eras featuring nostalgic designs, patterns, and silhouettes reinterpreted for modern wear.';
      case 'Bohemian':
        return 'Free-spirited, artistic clothing with mixed patterns, textures, and flowing silhouettes that embrace individuality.';
      default:
        return '';
    }
  }
}
