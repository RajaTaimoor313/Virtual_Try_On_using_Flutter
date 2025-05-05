// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:clothify/user_provider.dart';
import 'package:provider/provider.dart';

class SeasonalRecommendationsPage extends StatefulWidget {
  const SeasonalRecommendationsPage({Key? key}) : super(key: key);

  @override
  State<SeasonalRecommendationsPage> createState() =>
      _SeasonalRecommendationsPageState();
}

class _SeasonalRecommendationsPageState
    extends State<SeasonalRecommendationsPage> {
  String _selectedSeason = 'Summer';
  bool _isLoading = false;
  List<Map<String, dynamic>> _recommendations = [];

  final Map<String, Color> _seasonColors = {
    'Spring': Colors.green,
    'Summer': Colors.orange,
    'Fall': Colors.amber.shade800,
    'Winter': Colors.blue,
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
        _recommendations = _getSeasonalRecommendations(_selectedSeason);
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

  void _changeSeason(String season) {
    setState(() {
      _selectedSeason = season;
    });
    _loadRecommendations();
  }

  List<Map<String, dynamic>> _getSeasonalRecommendations(String season) {
    switch (season) {
      case 'Spring':
        return [
          {
            'name': 'Light Layered T-Shirt',
            'description':
                'Perfect for variable spring weather, easy to add or remove layers as needed.',
            'category': 'T-Shirts',
            'features': [
              'Breathable fabric',
              'Light colors',
              'Versatile styling',
            ],
          },
          {
            'name': 'Spring Casual Shirt',
            'description':
                'Lightweight button-up shirt in pastel colors ideal for the season.',
            'category': 'Shirts',
            'features': ['Cotton blend', 'Pastel tones', 'Comfortable fit'],
          },
          {
            'name': 'Light Rain Jacket',
            'description':
                'Water-resistant jacket for spring showers while keeping you comfortable.',
            'category': 'Jackets',
            'features': ['Water-resistant', 'Breathable', 'Lightweight'],
          },
        ];

      case 'Summer':
        return [
          {
            'name': 'Breathable Cotton T-Shirt',
            'description':
                'Stay cool with this lightweight, breathable cotton t-shirt designed for hot days.',
            'category': 'T-Shirts',
            'features': ['100% cotton', 'Moisture-wicking', 'UV protection'],
          },
          {
            'name': 'Short-Sleeve Linen Shirt',
            'description':
                'Natural linen shirt perfect for summer heat while maintaining a polished look.',
            'category': 'Shirts',
            'features': ['Linen fabric', 'Breathable design', 'Quick-drying'],
          },
          {
            'name': 'Ultralight Windbreaker',
            'description':
                'For cool summer evenings or unexpected weather changes, this ultralight jacket packs easily.',
            'category': 'Jackets',
            'features': ['Ultralight', 'Packable', 'Wind-resistant'],
          },
        ];

      case 'Fall':
        return [
          {
            'name': 'Long-Sleeve Thermal T-Shirt',
            'description':
                'Perfect base layer for fall with thermal properties to keep you warm as temperatures drop.',
            'category': 'T-Shirts',
            'features': ['Thermal fabric', 'Layering piece', 'Earth tones'],
          },
          {
            'name': 'Flannel Button-Up Shirt',
            'description':
                'Classic fall staple with warm flannel fabric in seasonal patterns.',
            'category': 'Shirts',
            'features': [
              'Soft flannel',
              'Brushed interior',
              'Versatile styling',
            ],
          },
          {
            'name': 'Quilted Field Jacket',
            'description':
                'Quilted insulation and multiple pockets make this jacket perfect for fall activities.',
            'category': 'Jackets',
            'features': ['Quilted design', 'Medium weight', 'Multiple pockets'],
          },
        ];

      case 'Winter':
        return [
          {
            'name': 'Heavy Thermal Undershirt',
            'description':
                'Essential winter base layer with maximum thermal retention to keep you warm in cold weather.',
            'category': 'T-Shirts',
            'features': ['Heavy thermal', 'Moisture-wicking', 'Heat retention'],
          },
          {
            'name': 'Thick Flannel Shirt',
            'description':
                'Extra thick flannel shirt that can be worn as a light jacket or mid-layer in winter.',
            'category': 'Shirts',
            'features': ['Heavy flannel', 'Insulating', 'Durable construction'],
          },
          {
            'name': 'Insulated Winter Parka',
            'description':
                'Maximum protection against winter weather with synthetic or down insulation.',
            'category': 'Jackets',
            'features': [
              'Heavy insulation',
              'Wind-blocking',
              'Weather-resistant',
            ],
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
        title: const Text('Seasonal Recommendations'),
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
                  _buildSeasonButton('Spring', Icons.eco),
                  _buildSeasonButton('Summer', Icons.wb_sunny),
                  _buildSeasonButton('Fall', Icons.forest),
                  _buildSeasonButton('Winter', Icons.ac_unit),
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
                  _seasonColors[_selectedSeason]!.withOpacity(0.8),
                  _seasonColors[_selectedSeason]!.withOpacity(0.3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_selectedSeason Recommendations',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _getSeasonDescription(_selectedSeason),
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
                          'Add your body measurements for personalized recommendations',
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
                        'No recommendations available for $_selectedSeason',
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

  Widget _buildSeasonButton(String season, IconData icon) {
    final isSelected = _selectedSeason == season;
    final seasonColor = _seasonColors[season] ?? Colors.blue;

    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: ElevatedButton.icon(
        onPressed: () => _changeSeason(season),
        icon: Icon(icon, size: 18),
        label: Text(season),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? seasonColor : Colors.white.withOpacity(0.1),
          foregroundColor: isSelected ? Colors.white : Colors.white70,
          elevation: isSelected ? 2 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? seasonColor : Colors.transparent,
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

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      (item['features'] as List<dynamic>).map((feature) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _seasonColors[_selectedSeason]!.withOpacity(
                              0.2,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: _seasonColors[_selectedSeason]!
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            feature,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
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

  String _getSeasonDescription(String season) {
    switch (season) {
      case 'Spring':
        return 'As temperatures rise and nature renews, these spring designs offer the perfect balance of warmth and breathability with lighter fabrics and brighter colors.';
      case 'Summer':
        return 'Beat the heat with these summer selections featuring lightweight, breathable fabrics designed to keep you cool and comfortable during hot weather.';
      case 'Fall':
        return 'Embrace the changing season with these fall designs that provide warmth and style with richer colors and adaptable layering options.';
      case 'Winter':
        return 'Stay warm and protected from the elements with these winter designs featuring insulating materials and practical features for cold weather.';
      default:
        return '';
    }
  }
}
