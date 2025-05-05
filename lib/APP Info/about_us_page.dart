import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000A3D),
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: const Color(0xFFECECEC),
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Image.asset(
                'assets/Logos/aboutus_logo.png',
                height: 150,
                width: 300,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 150,
                    width: 300,
                    child: Center(
                      child: Text(
                        'Image not available',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Our Story',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Clothify is a revolutionary app that combines fashion with technology to provide an immersive shopping experience. Our mission is to help users find the perfect fit for their clothing without the need to physically try them on.',
              style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'We leverage cutting-edge AR technology and body measurement algorithms to create a virtual try-on experience that is as close to reality as possible. Our team of fashion experts and technology enthusiasts work together to bring you the best of both worlds.',
              style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'Founded in 2025, Clothify aims to revolutionize how people shop for clothes online, reducing returns due to sizing issues and increasing customer satisfaction.',
              style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 40),
            const Text(
              'Contact Us',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildContactItem(Icons.email, 'Email', 'r.taimoor7213@gmail.com'),
            _buildContactItem(Icons.phone, 'Phone', '+92 310 7890229'),
            _buildContactItem(
              Icons.location_on,
              'Address',
              'Main Gujrat City, Punjab, Pakistan',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  static Widget _buildContactItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
