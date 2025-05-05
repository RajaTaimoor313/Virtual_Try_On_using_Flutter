// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:clothify/persistent_bottom_nav.dart';
import 'package:clothify/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AIChatStylistPage extends StatefulWidget {
  const AIChatStylistPage({Key? key}) : super(key: key);

  @override
  _AIChatStylistPageState createState() => _AIChatStylistPageState();
}

class _AIChatStylistPageState extends State<AIChatStylistPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _conversationId;

  String _backendUrl = 'http://192.168.1.75:3000';
  bool _isConnected = false;
  bool _connectionTested = false;

  @override
  void initState() {
    super.initState();
    _loadBackendUrl();

    Future.delayed(Duration.zero, () {
      _addBotMessage(
        "Hello! I'm your AI Style Assistant. Ask me anything about fashion, style recommendations, or clothing advice. How can I help you today?",
      );
    });
  }

  Future<void> _loadBackendUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('backend_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        setState(() {
          _backendUrl = savedUrl;
        });
      }
      await _testBackendConnection();
    } catch (e) {
      print('Error loading backend URL: $e');
    }
  }

  Future<void> _saveBackendUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backend_url', url);
    } catch (e) {
      print('Error saving backend URL: $e');
    }
  }

  Future<void> _testBackendConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_backendUrl/api/style-ai/health'))
          .timeout(const Duration(seconds: 5));

      bool isConnected = response.statusCode == 200;

      setState(() {
        _isConnected = isConnected;
        _connectionTested = true;
      });

      print('Backend connection test: ${isConnected ? 'SUCCESS' : 'FAILED'}');

      return;
    } catch (e) {
      print('Backend connection test failed: $e');
      setState(() {
        _isConnected = false;
        _connectionTested = true;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _isLoading = true;
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;
      final styleProfile = userProvider.styleProfile;

      if (currentUser == null) {
        _addBotMessage("Please log in to use the AI Stylist feature.");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (_isConnected) {
        try {
          print('Sending request to $_backendUrl/api/style-ai/chat');
          print('Conversation ID: $_conversationId');

          final response = await http
              .post(
                Uri.parse('$_backendUrl/api/style-ai/chat'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'message': userMessage,
                  'userId': currentUser.id,
                  'conversationId': _conversationId,
                }),
              )
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            print('Response data: $data');

            if (data['success'] == true && data['data'] != null) {
              final responseMessage = data['data']['message'];
              _addBotMessage(responseMessage);

              if (data['data']['conversationId'] != null) {
                setState(() {
                  _conversationId = data['data']['conversationId'].toString();
                });
                print('Updated conversation ID: $_conversationId');
              }
            } else {
              print('Invalid API response: $data');
              _addFallbackResponse(userMessage, styleProfile);
            }
          } else {
            print('API error: ${response.statusCode}');
            print('Response body: ${response.body}');

            _addFallbackResponse(userMessage, styleProfile);
          }
        } catch (e) {
          print('Error sending message to API: $e');

          _addFallbackResponse(userMessage, styleProfile);
        }
      } else {
        print('Backend not available, using fallback response');
        _addFallbackResponse(userMessage, styleProfile);
      }
    } catch (e) {
      print('Error in send message: $e');
      _addBotMessage("Sorry, I encountered an error. Please try again later.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addBotMessage(String message) {
    setState(() {
      _messages.add(ChatMessage(text: message, isUser: false));
    });
    _scrollToBottom();
  }

  void _addFallbackResponse(
    String userMessage,
    Map<String, dynamic>? styleProfile,
  ) {
    final lowerMessage = userMessage.toLowerCase();
    String styleType = 'casual';

    if (styleProfile != null && styleProfile['style'] != null) {
      styleType = styleProfile['style'].toLowerCase();
    }

    String response;

    if (lowerMessage.contains('wedding') ||
        lowerMessage.contains('formal event') ||
        lowerMessage.contains('ceremony') ||
        lowerMessage.contains('shaadi')) {
      if (styleType == 'formal') {
        response =
            "For a wedding, with your formal style preference, I recommend a well-tailored suit in navy blue or charcoal gray with a crisp white shirt. Consider a tasteful tie and pocket square that complement the wedding colors. Complete the look with polished oxford shoes and minimal accessories for a refined appearance.";
      } else if (styleType == 'casual') {
        response =
            "For a wedding, even with your casual style, you'll want to elevate your look appropriately. Consider a navy or gray suit with a light-colored dress shirt. For less formal weddings, you might opt for dress trousers with a blazer instead. Focus on proper fit and clean, polished shoes to show respect for the occasion.";
      } else if (styleType == 'trendy') {
        response =
            "For a wedding, your trendy style can work well with a modern cut suit in a contemporary color or subtle pattern. Consider details like a slightly slimmer fit, textured fabric, or interesting accessories while still respecting the formality of the occasion. Balance making a style statement with appropriate wedding guest etiquette.";
      } else {
        response =
            "For a wedding, I recommend a well-tailored suit in navy blue or charcoal gray. These colors are versatile and appropriate for most wedding settings. Pair it with a light-colored dress shirt and a tie that complements the wedding theme or season. For footwear, polished oxford or derby shoes in brown or black would complete the look elegantly.";
      }
    } else if (lowerMessage.contains('party') ||
        lowerMessage.contains('date') ||
        lowerMessage.contains('dinner') ||
        lowerMessage.contains('evening')) {
      if (styleType == 'formal') {
        response =
            "For evening events, your formal style works well with a dark suit or separates with luxurious fabrics and subtle details. Consider a deep color palette and refined accessories that convey sophistication.";
      } else if (styleType == 'casual') {
        response =
            "For evenings out, elevate your casual style with dark jeans or chinos, a textured button-up or knit shirt, and a leather jacket or unstructured blazer. Quality leather footwear and thoughtful accessories add sophistication.";
      } else if (styleType == 'trendy') {
        response =
            "For evening events, your trendy style can shine with contemporary silhouettes, interesting textures, and statement pieces that reflect current fashion moves while maintaining a cohesive look.";
      } else {
        response =
            "For evening events, focus on creating a balanced outfit with one focal point - whether that's a statement jacket, interesting shirt, or distinctive footwear - while keeping the rest of the look relatively simple.";
      }
    } else if (lowerMessage.contains('recommend') ||
        lowerMessage.contains('suggest')) {
      if (styleType == 'formal') {
        response =
            "Based on your formal style preference, I recommend investing in quality tailored pieces with clean lines and classic colors like navy, charcoal, and black.";
      } else if (styleType == 'casual') {
        response =
            "For your casual style, consider quality basics like well-fitted t-shirts, premium denim, and versatile sneakers that can be mixed and matched effortlessly.";
      } else if (styleType == 'trendy') {
        response =
            "With your trendy style profile, look for contemporary silhouettes, statement pieces, and bold accessories that showcase current fashion movements without going overboard.";
      } else {
        response =
            "Consider building a versatile wardrobe with quality basics that can be mixed and matched for different occasions while reflecting your personal style.";
      }
    } else if (lowerMessage.contains('color') ||
        lowerMessage.contains('colour')) {
      if (styleType == 'formal') {
        response =
            "For your formal style, stick with classic colors like navy, charcoal, and black for main pieces, with subtle accents in burgundy, forest green, or deep blue.";
      } else if (styleType == 'casual') {
        response =
            "Your casual style works well with versatile neutrals (navy, gray, white) as a base, with pops of color in accessories or accent pieces.";
      } else if (styleType == 'trendy') {
        response =
            "For your trendy style, experiment with this season's color palette while keeping some pieces in timeless neutrals to balance your look.";
      } else {
        response =
            "A good approach to color is building around neutral bases (navy, gray, white, black) and adding accent colors that complement your skin tone and personal preference.";
      }
    } else if (lowerMessage.contains('interview') ||
        lowerMessage.contains('professional') ||
        lowerMessage.contains('work') ||
        lowerMessage.contains('office')) {
      if (styleType == 'formal') {
        response =
            "For professional settings, your formal style aligns well with traditional business attire. Choose a well-tailored suit in navy or charcoal with minimal pattern, a crisp dress shirt, and quality leather shoes. Add subtle personality with your tie or pocket square.";
      } else if (styleType == 'casual') {
        response =
            "For professional settings with your casual style preference, elevate your look with chinos or wool trousers instead of jeans, pair with a button-down shirt or quality polo, and add a blazer for more formal environments. Clean, minimal sneakers or loafers complete the look.";
      } else {
        response =
            "For professional settings, adapt your style by focusing on fit and quality. Choose conservative colors and silhouettes for interviews and traditional workplaces. Save bolder choices for creative industries or casual Fridays.";
      }
    } else {
      if (styleType == 'formal') {
        response =
            "As someone with a formal style preference, focus on quality tailoring, classic silhouettes, and timeless pieces that project professionalism and sophistication.";
      } else if (styleType == 'casual') {
        response =
            "With your casual style, emphasize comfort and versatility while maintaining a put-together appearance through quality fabrics and proper fit.";
      } else if (styleType == 'trendy') {
        response =
            "For your trendy style, balance contemporary pieces with classics, and remember that fit and quality matter more than following every trend.";
      } else {
        response =
            "Focus on understanding what makes you feel confident and comfortable. Pay attention to fit above all else - well-fitting clothes in simple styles look better than poorly fitting 'fashionable' items.";
      }
    }

    _addBotMessage(response);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showBackendSettingsDialog() {
    final TextEditingController urlController = TextEditingController(
      text: _backendUrl,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Backend Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'Backend URL',
                    hintText: 'http://example.com:3000',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final newUrl = urlController.text.trim();
                    if (newUrl.isNotEmpty) {
                      setState(() {
                        _backendUrl = newUrl;
                      });
                      await _saveBackendUrl(newUrl);
                      Navigator.of(context).pop();

                      await _testBackendConnection();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isConnected
                                ? 'Successfully connected to backend!'
                                : 'Failed to connect to backend',
                          ),
                          backgroundColor:
                              _isConnected ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Save and Test Connection'),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PersistentBottomNav(
      currentIndex: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF000A3D),
        appBar: AppBar(
          title: const Text('AI Style Assistant'),
          backgroundColor: const Color(0xFFECECEC),
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showBackendSettingsDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            if (_connectionTested)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 16,
                ),
                color: Colors.black.withOpacity(0.3),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isConnected
                          ? 'Connected to AI backend'
                          : 'Offline mode - Using basic responses',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            if (_messages.length <= 1)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Example questions:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildExampleQuestion(
                        'What should I wear to a job interview?',
                        const Color.fromARGB(255, 7, 150, 151),
                      ),
                      _buildExampleQuestion(
                        'How can I build a casual wardrobe?',
                        Colors.purple,
                      ),
                      _buildExampleQuestion(
                        'What colors work best for my style?',
                        Colors.amber,
                      ),
                      _buildExampleQuestion(
                        'What should I wear for a wedding?',
                        Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(15),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),

            if (_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.black.withOpacity(0.2),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color.fromARGB(255, 7, 150, 151),
                    ),
                  ),
                ),
              ),

            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black.withOpacity(0.3),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Ask about fashion and style...',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.white),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    backgroundColor: const Color.fromARGB(255, 7, 150, 151),
                    mini: true,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleQuestion(String text, Color color) {
    return InkWell(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color:
              message.isUser
                  ? const Color.fromARGB(255, 7, 150, 151).withOpacity(0.7)
                  : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          message.text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
