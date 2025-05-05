import 'package:clothify/Measurements/measurements_screen.dart';
import 'package:clothify/Other%20Features/other_features_page.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'favorites_page.dart';

class PersistentBottomNav extends StatefulWidget {
  final int currentIndex;
  final Widget child;

  const PersistentBottomNav({
    Key? key,
    required this.currentIndex,
    required this.child,
  }) : super(key: key);

  @override
  State<PersistentBottomNav> createState() => _PersistentBottomNavState();
}

class _PersistentBottomNavState extends State<PersistentBottomNav> {
  void _onItemTapped(int index) {
    if (index == widget.currentIndex) return;

    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MeasurementsScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FavoritesPage()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OtherFeaturesPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFFECECEC),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.stacked_line_chart),
            label: 'Size',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Favorites'),
          BottomNavigationBarItem(
            icon: Icon(Icons.style),
            label: 'Other Features',
          ),
        ],
      ),
    );
  }
}
