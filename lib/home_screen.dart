// ignore_for_file: use_build_context_synchronously

import 'package:clothify/APP%20Info/about_us_page.dart';
import 'package:clothify/APP%20Info/terms_conditions_page.dart';
import 'package:clothify/APP%20Info/user_profile_page.dart';
import 'package:clothify/Designs/category_items_page.dart';
import 'package:clothify/Designs/item_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'home_page.dart';
import 'user_model.dart';
import 'database_helper.dart';
import 'persistent_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _popularItems = [];
  List<Map<String, dynamic>> _recommendedItems = [];
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItemsFromDatabase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() async {
    final searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isEmpty) return;

    String categoryName = "";
    if (searchQuery == "t-shirts" ||
        searchQuery == "tshirts" ||
        searchQuery == "t shirts") {
      categoryName = "T-Shirts";
    } else if (searchQuery == "shirts" || searchQuery == "shirt") {
      categoryName = "Shirts";
    } else if (searchQuery == "jackets" || searchQuery == "jacket") {
      categoryName = "Jackets";
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No matching category found. Try searching for "t-shirts", "shirts", or "jackets".',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final categoryItems = await _dbHelper.getClothingItemsByCategory(
      categoryName,
    );
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CategoryItemsPage(
              categoryName: categoryName,
              items: categoryItems,
            ),
      ),
    ).then((_) {
      _searchController.clear();
      _loadItemsFromDatabase();
    });
  }

  Future<void> _loadItemsFromDatabase() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final User? currentUser = userProvider.currentUser;
      List<Map<String, dynamic>> popularItems = await _dbHelper
          .getMostPopularItems(3);
      if (popularItems.isEmpty) {
        popularItems = await _dbHelper.getPopularClothingItems(3);
      }

      List<Map<String, dynamic>> recommendedItems = [];
      if (currentUser != null && currentUser.id != null) {
        recommendedItems = await _dbHelper.getUserRecommendedItems(
          currentUser.id!,
          3,
        );
      }

      if (recommendedItems.isEmpty) {
        final allItems = await _dbHelper.getAllClothingItems();
        final popularIds = popularItems.map((item) => item['id']).toSet();
        recommendedItems =
            allItems
                .where((item) => !popularIds.contains(item['id']))
                .take(3)
                .toList();
      }

      if (mounted) {
        setState(() {
          _popularItems = popularItems;
          _recommendedItems = recommendedItems;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recordItemClick(int itemId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final User? currentUser = userProvider.currentUser;
      if (currentUser != null && currentUser.id != null) {
        await _dbHelper.recordItemClick(currentUser.id!, itemId);
      }
    } catch (_) {}
  }

  Widget _buildCategoryItem(String title, String imagePath) {
    return GestureDetector(
      onTap: () async {
        final categoryItems = await _dbHelper.getClothingItemsByCategory(title);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CategoryItemsPage(
                  categoryName: title,
                  items: categoryItems,
                ),
          ),
        ).then((_) => _loadItemsFromDatabase());
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color.fromARGB(255, 7, 150, 151),
            child: ClipOval(
              child: SizedBox(
                height: 80,
                width: 40,
                child: Image.asset(imagePath),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildItemPreview(Map<String, dynamic> item, {Function()? onTap}) {
    return InkWell(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Image.asset(
          item['image_path'],
          height: 100,
          width: 100,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  void _openSidePanel() => _scaffoldKey.currentState?.openDrawer();
  void _openNotificationsPanel() => _scaffoldKey.currentState?.openEndDrawer();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final User? currentUser = userProvider.currentUser;

    return PersistentBottomNav(
      currentIndex: 0,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFF000A3D),
        drawerEnableOpenDragGesture: false,
        endDrawerEnableOpenDragGesture: false,
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF000A3D)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 35,
                        color: Color(0xFF000A3D),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentUser?.name ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currentUser?.email ?? 'user@example.com',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserProfilePage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About Us'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutUsPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Terms & Conditions'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsConditionsPage(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                            'Are you sure you want to logout?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                userProvider.logout();
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomePage(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ],
          ),
        ),
        endDrawer: Drawer(
          width: MediaQuery.of(context).size.width * 0.75,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                  color: const Color(0xFFECECEC),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Stay updated with the latest alerts',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 70,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'No New Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 10),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'You\'re all caught up! We\'ll notify you when we have something new.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
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
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFECECEC),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  Center(
                    child: Text(
                      'Fashion with Technology',
                      style: GoogleFonts.allura(fontSize: 30),
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _openSidePanel,
                        child: const CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, size: 30),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            currentUser?.name ?? 'User',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _openNotificationsPanel,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black),
                          ),
                          child: const Icon(Icons.notifications_none),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search your Design...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleSearch(),
                    ),
                  ),
                  IconButton(
                    onPressed: _handleSearch,
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                      : RefreshIndicator(
                        onRefresh: _loadItemsFromDatabase,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Categories',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildCategoryItem(
                                    'T-Shirts',
                                    'assets/Logos/t-shirt_logo.png',
                                  ),
                                  _buildCategoryItem(
                                    'Shirts',
                                    'assets/Logos/formal-shirt_logo.png',
                                  ),
                                  _buildCategoryItem(
                                    'Jackets',
                                    'assets/Logos/jacket_logo.png',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Popular Designs',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              _popularItems.isEmpty
                                  ? const Center(
                                    child: Text(
                                      'No popular items yet',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  )
                                  : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children:
                                        _popularItems.map((item) {
                                          return _buildItemPreview(
                                            item,
                                            onTap: () async {
                                              if (item['id'] != null) {
                                                await _recordItemClick(
                                                  item['id'],
                                                );
                                              }
                                              if (!mounted) return;
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        context,
                                                      ) => ItemDetailPage(
                                                        imagePath:
                                                            item['image_path'],
                                                        itemName: item['name'],
                                                        itemId: item['id'],
                                                      ),
                                                ),
                                              ).then(
                                                (_) => _loadItemsFromDatabase(),
                                              );
                                            },
                                          );
                                        }).toList(),
                                  ),
                              const SizedBox(height: 20),
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recommended',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _recommendedItems.isEmpty
                                  ? const Center(
                                    child: Text(
                                      'Browse more to get recommendations',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  )
                                  : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children:
                                        _recommendedItems.map((item) {
                                          return _buildItemPreview(
                                            item,
                                            onTap: () async {
                                              if (item['id'] != null) {
                                                await _recordItemClick(
                                                  item['id'],
                                                );
                                              }
                                              if (!mounted) return;
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        context,
                                                      ) => ItemDetailPage(
                                                        imagePath:
                                                            item['image_path'],
                                                        itemName: item['name'],
                                                        itemId: item['id'],
                                                      ),
                                                ),
                                              ).then(
                                                (_) => _loadItemsFromDatabase(),
                                              );
                                            },
                                          );
                                        }).toList(),
                                  ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
