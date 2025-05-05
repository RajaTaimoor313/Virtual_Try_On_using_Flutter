// ignore_for_file: deprecated_member_use

import 'package:clothify/AR%20Try-On/ar_view_page.dart';
import 'package:clothify/database_helper.dart';
import 'package:clothify/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ItemDetailPage extends StatefulWidget {
  final String imagePath;
  final String itemName;
  final int? itemId;

  const ItemDetailPage({
    super.key,
    required this.imagePath,
    required this.itemName,
    this.itemId,
  });

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  String? _modelPath;
  bool _isLoading = true;
  int? _itemId;
  bool _isFavorite = false;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _checkingFavorite = true;

  @override
  void initState() {
    super.initState();
    _modelPath = _getModelPathFromImage(widget.imagePath);
    _itemId = widget.itemId;

    if (_itemId == null) {
      _fetchItemId();
    } else {
      _recordItemClick();
      _checkFavoriteStatus();
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _fetchItemId() async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'clothing_items',
        columns: ['id'],
        where: 'image_path = ?',
        whereArgs: [widget.imagePath],
      );

      if (results.isNotEmpty) {
        setState(() {
          _itemId = results.first['id'] as int;
        });
        _recordItemClick();
        _checkFavoriteStatus();
      }
    } catch (e) {
      debugPrint('Error fetching item ID: $e');
    }
  }

  Future<void> _recordItemClick() async {
    try {
      if (_itemId == null) return;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;

      if (currentUser != null && currentUser.id != null) {
        await _dbHelper.recordItemClick(currentUser.id!, _itemId!);
      }
    } catch (e) {
      debugPrint('Error recording item click: $e');
    }
  }

  Future<void> _checkFavoriteStatus() async {
    if (_itemId == null) {
      setState(() {
        _checkingFavorite = false;
      });
      return;
    }

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;

      if (currentUser != null && currentUser.id != null) {
        final isFavorite = await _dbHelper.isFavorite(
          currentUser.id!,
          _itemId!,
        );
        if (mounted) {
          setState(() {
            _isFavorite = isFavorite;
            _checkingFavorite = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _checkingFavorite = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
      if (mounted) {
        setState(() {
          _checkingFavorite = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_itemId == null) {
      _showSnackBar('Cannot find item details', Colors.red);
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser == null || currentUser.id == null) {
      _showSnackBar('Please log in to use favorites', Colors.red);
      return;
    }

    setState(() {
      _checkingFavorite = true;
    });

    try {
      bool success =
          _isFavorite
              ? await _dbHelper.removeFromFavorites(currentUser.id!, _itemId!)
              : await _dbHelper.addToFavorites(currentUser.id!, _itemId!);

      if (mounted) {
        setState(() {
          if (success) {
            _isFavorite = !_isFavorite;
          }
          _checkingFavorite = false;
        });

        _showSnackBar(
          success
              ? (_isFavorite ? 'Added to favorites!' : 'Removed from favorites')
              : 'Failed to update favorites',
          success ? Colors.green : Colors.red,
        );
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      if (mounted) {
        setState(() {
          _checkingFavorite = false;
        });
        _showSnackBar('Error: ${e.toString()}', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  String _getModelPathFromImage(String imagePath) {
    final category = _getCategoryFromImagePath(imagePath);
    final fileNameStart = imagePath.lastIndexOf('/') + 1;
    final fileNameEnd = imagePath.lastIndexOf('.');
    final fileName = imagePath.substring(fileNameStart, fileNameEnd);
    return 'assets/$category/$fileName.glb';
  }

  String _getCategoryFromImagePath(String imagePath) {
    if (imagePath.contains('Jackets/')) return 'Jackets';
    if (imagePath.contains('T-Shirts/')) return 'T-Shirts';
    if (imagePath.contains('Shirts/')) return 'Shirts';
    return 'Jackets';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000A3D),
      appBar: AppBar(
        title: Text(widget.itemName),
        backgroundColor: const Color(0xFFECECEC),
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          _checkingFavorite
              ? const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                ),
              )
              : IconButton(
                icon: Icon(
                  _isFavorite ? Icons.star : Icons.star_border,
                  color: _isFavorite ? Colors.amber : Colors.black,
                ),
                onPressed: _toggleFavorite,
                tooltip:
                    _isFavorite ? 'Remove from favorites' : 'Add to favorites',
              ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              width: double.infinity,
              child: Stack(
                children: [
                  ModelViewer(
                    src: _modelPath!,
                    alt: widget.itemName,
                    ar: false,
                    autoRotate: true,
                    cameraControls: true,
                    backgroundColor: Colors.black,
                    rotationPerSecond: "30%",
                  ),
                  if (_isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 20),
                            Text(
                              'Loading 3D Model...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFECECEC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.itemName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Consumer<UserProvider>(
                          builder: (context, userProvider, child) {
                            return ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            ARViewPage(modelPath: _modelPath!),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.view_in_ar),
                              label: const Text('AR Try-On'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  7,
                                  150,
                                  151,
                                ),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
