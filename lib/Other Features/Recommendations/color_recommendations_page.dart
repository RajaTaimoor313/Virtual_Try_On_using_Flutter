// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:clothify/user_provider.dart';
import 'package:provider/provider.dart';

class ColorRecommendationsPage extends StatefulWidget {
  const ColorRecommendationsPage({Key? key}) : super(key: key);

  @override
  State<ColorRecommendationsPage> createState() =>
      _ColorRecommendationsPageState();
}

class _ColorRecommendationsPageState extends State<ColorRecommendationsPage> {
  String _selectedColorScheme = 'Neutral';
  bool _isLoading = false;
  List<Map<String, dynamic>> _recommendations = [];

  final Map<String, List<Color>> _colorPalettes = {
    'Neutral': [Colors.black, Colors.white, Colors.grey, Colors.brown.shade200],
    'Earth Tones': [
      Colors.brown,
      Colors.green.shade800,
      Colors.amber.shade700,
      Colors.orange.shade800,
    ],
    'Cool Colors': [Colors.blue, Colors.teal, Colors.purple, Colors.indigo],
    'Warm Colors': [Colors.red, Colors.orange, Colors.yellow, Colors.amber],
    'Pastels': [
      Colors.pink.shade200,
      Colors.blue.shade200,
      Colors.green.shade200,
      Colors.purple.shade200,
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _showSkinToneDialog();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _recommendations = _getColorRecommendations(_selectedColorScheme);
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

  void _showSkinToneDialog() {
    bool hasSelectedSkinTone = false;

    if (!hasSelectedSkinTone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: const Text('Select Your Skin Tone'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'To provide the most accurate color recommendations, please select your skin tone:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSkinToneOption(
                          context,
                          'Light',
                          Colors.brown.shade100,
                        ),
                        _buildSkinToneOption(
                          context,
                          'Medium',
                          Colors.brown.shade300,
                        ),
                        _buildSkinToneOption(
                          context,
                          'Dark',
                          Colors.brown.shade600,
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _changeColorScheme('Neutral');
                    },
                    child: const Text('Skip'),
                  ),
                ],
              ),
        );
      });
    }
  }

  Widget _buildSkinToneOption(BuildContext context, String label, Color color) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        String recommendedScheme = 'Neutral';
        if (label == 'Light') {
          recommendedScheme = 'Cool Colors';
        } else if (label == 'Medium') {
          recommendedScheme = 'Earth Tones';
        } else if (label == 'Dark') {
          recommendedScheme = 'Warm Colors';
        }
        _changeColorScheme(recommendedScheme);
      },
      child: Column(
        children: [
          CircleAvatar(radius: 25, backgroundColor: color),
          const SizedBox(height: 5),
          Text(label),
        ],
      ),
    );
  }

  void _changeColorScheme(String colorScheme) {
    setState(() {
      _selectedColorScheme = colorScheme;
    });
    _loadRecommendations();
  }

  List<Map<String, dynamic>> _getColorRecommendations(String colorScheme) {
    switch (colorScheme) {
      case 'Neutral':
        return [
          {
            'name': 'Classic Black T-Shirt',
            'description':
                'Essential black t-shirt that works with almost any outfit combination.',
            'category': 'T-Shirts',
            'colors': ['Black'],
          },
          {
            'name': 'White Button-Up Shirt',
            'description':
                'Timeless white shirt that offers maximum versatility for any occasion.',
            'category': 'Shirts',
            'colors': ['White'],
          },
          {
            'name': 'Navy Blue Jacket',
            'description':
                'Classic navy jacket that coordinates easily with various colors and styles.',
            'category': 'Jackets',
            'colors': ['Navy'],
          },
        ];

      case 'Earth Tones':
        return [
          {
            'name': 'Olive Green T-Shirt',
            'description':
                'Rich olive t-shirt that complements earth-toned wardrobes and most skin tones.',
            'category': 'T-Shirts',
            'colors': ['Olive Green'],
          },
          {
            'name': 'Rust Orange Casual Shirt',
            'description':
                'Warm rust-colored shirt that adds dimension to earth-toned outfits.',
            'category': 'Shirts',
            'colors': ['Rust Orange'],
          },
          {
            'name': 'Brown Leather Jacket',
            'description':
                'Classic brown leather jacket that pairs well with other earth tones.',
            'category': 'Jackets',
            'colors': ['Brown'],
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
        title: const Text('Color Recommendations'),
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
                  _buildColorSchemeButton('Neutral'),
                  _buildColorSchemeButton('Earth Tones'),
                  _buildColorSchemeButton('Cool Colors'),
                  _buildColorSchemeButton('Warm Colors'),
                  _buildColorSchemeButton('Pastels'),
                ],
              ),
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            color: Colors.black.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_selectedColorScheme Palette',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      _colorPalettes[_selectedColorScheme]!.map((color) {
                        return Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Color Recommendations',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _getColorSchemeDescription(_selectedColorScheme),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
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
                        'No recommendations available for $_selectedColorScheme',
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

  Widget _buildColorSchemeButton(String colorScheme) {
    final isSelected = _selectedColorScheme == colorScheme;
    final colors = _colorPalettes[colorScheme] ?? [Colors.grey];

    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: ElevatedButton(
        onPressed: () => _changeColorScheme(colorScheme),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
          foregroundColor: Colors.white,
          elevation: isSelected ? 2 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side:
                isSelected
                    ? const BorderSide(color: Colors.white, width: 1)
                    : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children:
                    colors.take(3).map((color) {
                      return Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              colorScheme,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
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
                  color: _getColorFromName(item['colors'][0]),
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

                if (item.containsKey('colors') && item['colors'] is List)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        (item['colors'] as List).map((color) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getColorFromName(color),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  color,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),

                const SizedBox(height: 15),

                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Color.fromARGB(255, 7, 150, 151),
                            size: 16,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This color complements your skin tone and preferred palette',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 15),
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

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'navy':
        return Colors.indigo.shade900;
      case 'olive green':
        return Colors.lime;
      case 'rust orange':
        return Colors.deepOrange.shade800;
      case 'brown':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _getColorSchemeDescription(String colorScheme) {
    switch (colorScheme) {
      case 'Neutral':
        return 'Neutral colors like black, white, gray, and navy create a versatile foundation for any wardrobe. These colors are easy to coordinate and complement most skin tones.';
      case 'Earth Tones':
        return 'Earth tones such as browns, olives, rusts, and deep oranges create a warm, grounded aesthetic. These colors complement warm skin tones particularly well.';
      case 'Cool Colors':
        return 'Cool colors like blues, greens, purples, and cool grays create a calm, refreshing palette. These colors particularly complement cool skin undertones.';
      case 'Warm Colors':
        return 'Warm colors including reds, oranges, yellows, and corals create an energetic, vibrant look. These colors work especially well with warm skin undertones.';
      case 'Pastels':
        return 'Soft pastel colors create a light, gentle aesthetic. These colors can brighten your appearance and work well for seasonal or themed outfits.';
      default:
        return '';
    }
  }
}
