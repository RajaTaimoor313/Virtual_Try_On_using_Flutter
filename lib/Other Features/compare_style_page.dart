// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_compare_slider/image_compare_slider.dart';

class CompareStylePage extends StatefulWidget {
  const CompareStylePage({Key? key}) : super(key: key);

  @override
  State<CompareStylePage> createState() => _CompareStylePageState();
}

class _CompareStylePageState extends State<CompareStylePage> {
  File? _imageOne;
  File? _imageTwo;
  final ImagePicker _picker = ImagePicker();
  bool _showComparison = false;

  Future<void> _pickImage(int imageNumber) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          if (imageNumber == 1) {
            _imageOne = File(image.path);
          } else {
            _imageTwo = File(image.path);
          }
          if (_imageOne != null && _imageTwo != null) {
            _showComparison = true;
          }
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000A3D),
      appBar: AppBar(
        title: const Text('Compare Styles'),
        backgroundColor: const Color(0xFFECECEC),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.white.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compare Your Styles',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload two photos to compare how they look on you',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Photo Comparison',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildImageUploadButton(
                          1,
                          'Outfit 1',
                          _imageOne,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildImageUploadButton(
                          2,
                          'Outfit 2',
                          _imageTwo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  if (_showComparison && _imageOne != null && _imageTwo != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Slide to Compare',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Move the slider to compare your outfits',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 15),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: SizedBox(
                            height: 400,
                            width: double.infinity,
                            child: ImageCompareSlider(
                              itemOne: Image.file(
                                _imageOne!,
                                fit: BoxFit.cover,
                              ),
                              itemTwo: Image.file(
                                _imageTwo!,
                                fit: BoxFit.cover,
                              ),
                              dividerColor: const Color.fromARGB(
                                255,
                                7,
                                150,
                                151,
                              ),
                              handleSize: const Size(40, 40),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildStyleAnalysisSection(),
                      ],
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadButton(int imageNumber, String label, File? image) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _pickImage(imageNumber),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color.fromARGB(255, 7, 150, 151).withOpacity(0.5),
              ),
            ),
            child:
                image != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 50,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Upload Photo',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyleAnalysisSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 7, 150, 151).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Style Analysis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Based on your body measurements and these photos:',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 10),
          _buildStyleAnalysis(
            'Outfit 1',
            'This outfit has a more structured silhouette that complements your body shape. The color palette works well with your complexion.',
            const Color.fromARGB(255, 7, 150, 151),
          ),
          const SizedBox(height: 10),
          _buildStyleAnalysis(
            'Outfit 2',
            'The relaxed fit of this outfit gives a casual feel, but could benefit from more tailoring around the shoulders for your frame.',
            Colors.amber,
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 7, 150, 151).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Color.fromARGB(255, 7, 150, 151),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Based on these comparisons, we suggest trying our "Minimalist" style recommendations for your body type.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleAnalysis(String title, String analysis, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.style, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  analysis,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
