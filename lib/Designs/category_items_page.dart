import 'package:clothify/database_helper.dart';
import 'package:clothify/user_model.dart';
import 'package:clothify/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'item_detail_page.dart';

class CategoryItemsPage extends StatelessWidget {
  final String categoryName;
  final List<Map<String, dynamic>> items;

  const CategoryItemsPage({
    super.key,
    required this.categoryName,
    required this.items,
  });

  Future<void> _recordItemClick(BuildContext context, int itemId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final User? currentUser = userProvider.currentUser;
      if (currentUser != null && currentUser.id != null) {
        final dbHelper = DatabaseHelper.instance;
        await dbHelper.recordItemClick(currentUser.id!, itemId);
      }
    } catch (e) {
      print('Error recording click: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000A3D),
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: const Color(0xFFECECEC),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () async {
              if (item['id'] != null) {
                await _recordItemClick(context, item['id']);
              }
              if (!context.mounted) return;
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
              );
            },
            child: Card(
              color: Colors.white,
              elevation: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.asset(
                      item['image_path'],
                      height: 110,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 7, 150, 151),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '\$${(item['price'] ?? 29.99).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
