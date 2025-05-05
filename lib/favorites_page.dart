import 'package:clothify/Designs/item_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'user_model.dart';
import 'database_helper.dart';
import 'persistent_bottom_nav.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _favoriteItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final User? currentUser = userProvider.currentUser;

      if (currentUser != null && currentUser.id != null) {
        await _dbHelper.areForeignKeysEnabled();
        final favorites = await _dbHelper.getUserFavorites(currentUser.id!);

        if (mounted) {
          setState(() {
            _favoriteItems = favorites;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _favoriteItems = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading favorites: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFromFavorites(int itemId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final User? currentUser = userProvider.currentUser;

      if (currentUser != null && currentUser.id != null) {
        await _dbHelper.areForeignKeysEnabled();

        final success = await _dbHelper.removeFromFavorites(
          currentUser.id!,
          itemId,
        );

        if (success && mounted) {
          setState(() {
            _favoriteItems.removeWhere((item) => item['id'] == itemId);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites'),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('Error removing from favorites: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PersistentBottomNav(
      currentIndex: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF000A3D),
        appBar: AppBar(
          title: const Text('My Favorites'),
          backgroundColor: const Color(0xFFECECEC),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child:
                      _favoriteItems.isEmpty
                          ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star_border,
                                  color: Colors.white,
                                  size: 64,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No favorites yet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap the star icon on any item to add it to favorites',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _favoriteItems.length,
                            itemBuilder: (context, index) {
                              final item = _favoriteItems[index];
                              return Dismissible(
                                key: Key('favorite_${item['id']}'),
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) {
                                  _removeFromFavorites(item['id']);
                                },
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: Image.asset(
                                        item['image_path'],
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    title: Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Text(
                                      item['category'],
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      ),
                                      onPressed: () {
                                        _removeFromFavorites(item['id']);
                                      },
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ItemDetailPage(
                                                imagePath: item['image_path'],
                                                itemName: item['name'],
                                                itemId: item['id'],
                                              ),
                                        ),
                                      ).then((_) {
                                        _loadFavorites();
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                ),
      ),
    );
  }
}
