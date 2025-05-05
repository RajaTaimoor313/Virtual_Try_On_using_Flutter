// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:clothify/database_helper.dart';
import 'package:clothify/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'style_quiz_result_page.dart';

class StyleQuizPage extends StatefulWidget {
  const StyleQuizPage({Key? key}) : super(key: key);

  @override
  State<StyleQuizPage> createState() => _StyleQuizPageState();
}

class _StyleQuizPageState extends State<StyleQuizPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;
  final Map<String, dynamic> _answers = {};
  bool _isCompleting = false;

  final String _backendUrl = 'http://192.168.1.75:3000';

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What type of clothing makes you feel most comfortable?',
      'options': [
        {'text': 'Casual and relaxed (t-shirts, jeans)', 'value': 'casual'},
        {'text': 'Formal and structured (suits, dresses)', 'value': 'formal'},
        {'text': 'Trendy and fashionable', 'value': 'trendy'},
        {'text': 'Athletic and functional', 'value': 'athletic'},
      ],
    },
    {
      'question': 'Which colors do you prefer to wear most often?',
      'options': [
        {'text': 'Neutral (black, white, gray)', 'value': 'neutral'},
        {'text': 'Bright and vibrant', 'value': 'bright'},
        {'text': 'Earth tones (brown, green, beige)', 'value': 'earth'},
        {'text': 'Pastels and soft colors', 'value': 'pastel'},
      ],
    },
    {
      'question': 'How would you describe your ideal fit for clothing?',
      'options': [
        {'text': 'Loose and comfortable', 'value': 'loose'},
        {'text': 'Fitted but not tight', 'value': 'fitted'},
        {'text': 'Form-fitting and structured', 'value': 'form-fitting'},
        {'text': 'Oversized and relaxed', 'value': 'oversized'},
      ],
    },
    {
      'question': 'What is your main priority when choosing clothes?',
      'options': [
        {'text': 'Comfort and practicality', 'value': 'comfort'},
        {'text': 'Style and appearance', 'value': 'style'},
        {'text': 'Brand and quality', 'value': 'quality'},
        {'text': 'Affordability and value', 'value': 'value'},
      ],
    },
    {
      'question': 'How do you feel about patterns and prints?',
      'options': [
        {
          'text': 'Love them, more patterns the better',
          'value': 'pattern_lover',
        },
        {'text': 'Subtle patterns are nice', 'value': 'subtle_patterns'},
        {'text': 'Prefer solid colors mostly', 'value': 'solids'},
        {
          'text': 'Only wear patterns on special occasions',
          'value': 'occasional_patterns',
        },
      ],
    },
    {
      'question': 'Which best describes your lifestyle?',
      'options': [
        {'text': 'Active and on-the-go', 'value': 'active'},
        {'text': 'Professional work environment', 'value': 'professional'},
        {'text': 'Social and outgoing', 'value': 'social'},
        {'text': 'Relaxed and laid-back', 'value': 'relaxed'},
      ],
    },
    {
      'question': 'Which celebrity\'s style do you most admire?',
      'options': [
        {
          'text': 'Classic and timeless (e.g., George Clooney)',
          'value': 'classic',
        },
        {'text': 'Edgy and avant-garde (e.g., Billie Eilish)', 'value': 'edgy'},
        {
          'text': 'Minimalist and elegant (e.g., Zendaya)',
          'value': 'minimalist',
        },
        {
          'text': 'Bohemian and artistic (e.g., Harry Styles)',
          'value': 'bohemian',
        },
      ],
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _selectOption(String questionKey, String value) {
    setState(() {
      _answers[questionKey] = value;
    });

    if (_currentPage == _questions.length - 1) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _completeQuiz();
      });
    } else {
      _nextPage();
    }
  }

  Future<void> _completeQuiz() async {
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;

      if (currentUser != null && currentUser.id != null) {
        final styleResult = _determineStyle();

        bool apiSuccess = false;
        try {
          final response = await http
              .post(
                Uri.parse('$_backendUrl/api/style-ai/analyze-style'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'userId': currentUser.id,
                  'answers': _answers,
                }),
              )
              .timeout(const Duration(seconds: 5));

          print('API response status: ${response.statusCode}');
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['success'] == true && data['data'] != null) {
              final apiStyleResult = data['data'];

              apiStyleResult['answers'] = _answers;

              await _saveQuizResults(apiStyleResult);

              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            StyleQuizResultPage(styleResult: apiStyleResult),
                  ),
                );
              }

              apiSuccess = true;
            } else {
              print('API returned invalid data format: $data');
            }
          } else {
            print('API returned non-200 status: ${response.statusCode}');
            print('Response body: ${response.body}');
          }
        } catch (apiError) {
          print('Error with backend API: $apiError');
        }

        if (!apiSuccess) {
          print('Using locally determined style results');

          await _saveQuizResults(styleResult);

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => StyleQuizResultPage(styleResult: styleResult),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error completing quiz: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('There was an error processing your style quiz.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  Map<String, dynamic> _determineStyle() {
    final styleCount = <String, int>{};

    _answers.forEach((key, value) {
      styleCount[value] = (styleCount[value] ?? 0) + 1;
    });

    String dominantStyle = 'casual';
    int maxCount = 0;

    styleCount.forEach((style, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantStyle = style;
      }
    });

    List<String> styleInfluences = [];
    styleCount.forEach((style, count) {
      if (count >= maxCount - 1 && style != dominantStyle) {
        styleInfluences.add(style);
      }
    });

    final result = _getStyleDescription(dominantStyle);

    if (styleInfluences.isNotEmpty) {
      result['influences'] = styleInfluences;
      _enhanceRecommendationsWithInfluences(result, styleInfluences);
    }

    result['personalizedAnalysis'] = _generatePersonalizedAnalysis(
      dominantStyle,
      styleInfluences,
    );

    result['answers'] = _answers;

    return result;
  }

  void _enhanceRecommendationsWithInfluences(
    Map<String, dynamic> result,
    List<String> influences,
  ) {
    if (influences.isEmpty) return;

    List<String> currentRecommendations =
        result['recommendations'] as List<String>;
    List<String> enhancedRecommendations = [...currentRecommendations];

    for (var influence in influences) {
      var influenceDesc = _getStyleDescription(influence);
      if (influenceDesc.containsKey('recommendations') &&
          (influenceDesc['recommendations'] as List).isNotEmpty) {
        enhancedRecommendations.add(
          "${influenceDesc['recommendations'][0]} (${influenceDesc['style']} influence)",
        );
      }
    }

    result['recommendations'] = enhancedRecommendations;
  }

  String _generatePersonalizedAnalysis(
    String dominantStyle,
    List<String> influences,
  ) {
    String analysis = "";

    analysis +=
        "Your responses show a clear preference for $dominantStyle style. ";

    if (influences.isNotEmpty) {
      analysis +=
          "You also have elements of ${influences.join(' and ')} in your choices. ";
    }

    analysis +=
        "This combination creates a unique style profile that reflects your personality and lifestyle needs. ";

    analysis +=
        "The recommendations provided are tailored to enhance your personal style while ensuring comfort and confidence.";

    return analysis;
  }

  Map<String, dynamic> _getStyleDescription(String style) {
    switch (style) {
      case 'casual':
        return {
          'style': 'Casual',
          'description':
              'You prefer comfort and relaxed fits. Your style is easy-going and adaptable, perfect for daily activities and informal gatherings.',
          'recommendations': [
            'Well-fitted t-shirts in neutral colors with quality fabric',
            'Premium denim jeans with a comfortable fit',
            'Versatile casual sneakers or loafers for everyday wear',
            'Simple, high-quality accessories like leather watches',
            'Lightweight casual jackets or cardigans for layering',
          ],
        };
      case 'formal':
        return {
          'style': 'Formal',
          'description':
              'You appreciate structure and elegance. Your style is polished and professional, with attention to detail and quality tailoring.',
          'recommendations': [
            'Well-tailored shirts with proper fit around shoulders and chest',
            'Quality suits in classic colors like navy, charcoal, and black',
            'Formal leather shoes like oxfords or derbies with matching belts',
            'Elegant accessories like subtle ties and cufflinks',
            'Tailored overcoats or blazers for layering',
          ],
        };
      case 'trendy':
        return {
          'style': 'Trendy',
          'description':
              'You stay current with fashion trends. Your style is dynamic and expressive, showing your awareness of contemporary fashion movements.',
          'recommendations': [
            'Statement pieces that showcase current trends without going overboard',
            'Unique accessories that add personality to your outfits',
            'Contemporary silhouettes and cuts that flatter your body type',
            'Strategic use of bold colors and patterns',
            'Trendy footwear that balances style and comfort',
          ],
        };
      case 'athletic':
        return {
          'style': 'Athletic',
          'description':
              'You value function and performance. Your style is sporty and practical, with emphasis on comfort and movement.',
          'recommendations': [
            'High-quality athletic wear with technical fabrics',
            'Performance-oriented materials that wick moisture',
            'Comfortable athletic sneakers for versatile use',
            'Practical accessories like sports watches and caps',
            'Athleisure pieces that transition from workout to casual settings',
          ],
        };
      case 'minimalist':
        return {
          'style': 'Minimalist',
          'description':
              'You appreciate simplicity and clean lines. Your style is understated and elegant, focusing on quality over quantity.',
          'recommendations': [
            'Classic pieces in neutral colors with excellent construction',
            'Simple, high-quality basics that form the foundation of a capsule wardrobe',
            'Clean silhouettes and minimal patterns that stand the test of time',
            'Subtle, elegant accessories that complement rather than dominate',
            'Quality fabrics that age well and maintain their appearance',
          ],
        };
      case 'bohemian':
        return {
          'style': 'Bohemian',
          'description':
              'You embrace an artistic and free-spirited approach. Your style is creative and unconventional, with rich textures and patterns.',
          'recommendations': [
            'Loose, flowing garments with natural drape and movement',
            'Natural fabrics and textures like linen, cotton, and suede',
            'Layered accessories and statement pieces that tell a story',
            'Mixed patterns and earthy colors that create a cohesive look',
            'Handcrafted or artisanal items that add uniqueness',
          ],
        };
      case 'edgy':
        return {
          'style': 'Edgy',
          'description':
              'You push boundaries with bold choices. Your style is distinctive and confident, often challenging conventional fashion rules.',
          'recommendations': [
            'Statement pieces with unconventional cuts or materials',
            'Strategic contrast between fitted and oversized elements',
            'Dark color palette with strategic accent colors',
            'Leather or alternative materials that add texture and edge',
            'Distinctive footwear that grounds your distinctive look',
          ],
        };
      case 'classic':
        return {
          'style': 'Classic',
          'description':
              'You appreciate timeless elegance. Your style is refined and sophisticated, focusing on pieces with enduring appeal.',
          'recommendations': [
            'Investment pieces in traditional cuts that never go out of style',
            'Quality fabrics and construction that stand the test of time',
            'Balanced proportions that flatter your body type consistently',
            'Traditional patterns like pinstripes, houndstooth, or subtle checks',
            'Heritage accessories that complement your refined aesthetic',
          ],
        };
      default:
        return {
          'style': 'Smart Casual',
          'description':
              'You have a versatile and balanced approach to style. Your wardrobe works across various contexts while maintaining a polished appearance.',
          'recommendations': [
            'Invest in quality basics that create a foundation for versatile outfits',
            'Focus on fit and comfort while maintaining a put-together appearance',
            'Choose versatile colors that mix and match well for maximum outfit combinations',
            'Select simple, elegant accessories that elevate casual pieces',
            'Balance structure and comfort for an effortlessly stylish look',
          ],
        };
    }
  }

  Future<void> _saveQuizResults(Map<String, dynamic> styleResult) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;

      if (currentUser != null && currentUser.id != null) {
        await userProvider.saveStyleProfile(styleResult);

        try {
          final dbHelper = DatabaseHelper.instance;
          final db = await dbHelper.database;

          final data = {
            'user_id': currentUser.id,
            'style_type': styleResult['style'],
            'style_data': json.encode(styleResult),
            'taken_at': DateTime.now().toIso8601String(),
          };

          final existing = await db.query(
            'user_style_preferences',
            where: 'user_id = ?',
            whereArgs: [currentUser.id],
          );

          if (existing.isNotEmpty) {
            await db.update(
              'user_style_preferences',
              data,
              where: 'user_id = ?',
              whereArgs: [currentUser.id],
            );
          } else {
            final tableCheck = await db.rawQuery(
              "SELECT name FROM sqlite_master WHERE type='table' AND name='user_style_preferences'",
            );

            if (tableCheck.isEmpty) {
              await db.execute('''
                CREATE TABLE user_style_preferences (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  user_id INTEGER NOT NULL,
                  style_type TEXT NOT NULL,
                  style_data TEXT,
                  taken_at TEXT NOT NULL
                )
              ''');
            }

            await db.insert('user_style_preferences', data);
          }
        } catch (dbError) {
          print('Error saving to local database: $dbError');
        }
      }
    } catch (e) {
      print('Error saving quiz results: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000A3D),
      appBar: AppBar(
        title: const Text('Style Quiz'),
        backgroundColor: const Color(0xFFECECEC),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentPage + 1) / _questions.length,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color.fromARGB(255, 7, 150, 151),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentPage + 1}/${_questions.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                if (_currentPage > 0)
                  TextButton.icon(
                    onPressed: _previousPage,
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 16,
                      color: Colors.white70,
                    ),
                    label: const Text(
                      'Previous',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                  _isLastPage = page == _questions.length - 1;
                });
              },
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                final questionKey = 'q${index + 1}';
                final selectedValue = _answers[questionKey];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          question['question'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      ...List.generate(question['options'].length, (
                        optionIndex,
                      ) {
                        final option = question['options'][optionIndex];
                        final isSelected = selectedValue == option['value'];

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 15),
                          child: InkWell(
                            onTap:
                                () =>
                                    _selectOption(questionKey, option['value']),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? const Color.fromARGB(
                                          255,
                                          7,
                                          150,
                                          151,
                                        ).withOpacity(0.2)
                                        : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? const Color.fromARGB(
                                            255,
                                            7,
                                            150,
                                            151,
                                          )
                                          : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? const Color.fromARGB(
                                                  255,
                                                  7,
                                                  150,
                                                  151,
                                                )
                                                : Colors.white54,
                                        width: 2,
                                      ),
                                    ),
                                    child:
                                        isSelected
                                            ? const Icon(
                                              Icons.check_circle,
                                              color: Color.fromARGB(
                                                255,
                                                7,
                                                150,
                                                151,
                                              ),
                                              size: 16,
                                            )
                                            : const SizedBox(
                                              width: 16,
                                              height: 16,
                                            ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Text(
                                      option['text'],
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.white70,
                                        fontSize: 16,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isLastPage
                            ? (_isCompleting ? null : _completeQuiz)
                            : () {
                              if (_answers['q${_currentPage + 1}'] == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select an option to continue',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              _nextPage();
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 7, 150, 151),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child:
                        _isCompleting
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              _isLastPage ? 'Get My Style' : 'Next',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
