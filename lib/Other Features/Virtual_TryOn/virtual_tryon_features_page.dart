// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:clothify/persistent_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class VirtualTryOnFeaturesPage extends StatefulWidget {
  const VirtualTryOnFeaturesPage({Key? key}) : super(key: key);

  @override
  _VirtualTryOnFeaturesPageState createState() =>
      _VirtualTryOnFeaturesPageState();
}

class _VirtualTryOnFeaturesPageState extends State<VirtualTryOnFeaturesPage>
    with SingleTickerProviderStateMixin {
  File? _userImage;
  File? _designImage;
  bool _isLoading = false;
  String? _resultImageUrl;
  bool _showTips = true;
  late String _serverBaseUrl;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    _serverBaseUrl = const String.fromEnvironment(
      'SERVER_BASE_URL',
      defaultValue: 'http://192.168.1.75:3000',
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _isCloudinaryUrl(String url) {
    return url.startsWith('http');
  }

  String _ensureCorrectExtension(String url) {
    if (url.endsWith('.png')) {
      return url.replaceAll('.png', '.jpg');
    } else if (!url.contains('.jpg') && !url.contains('.jpeg')) {
      return '$url.jpg';
    }
    return url;
  }

  String _getFullUrl(String url) {
    if (_isCloudinaryUrl(url)) {
      return url;
    } else {
      return '$_serverBaseUrl${_ensureCorrectExtension(url)}';
    }
  }

  Future<void> _pickImage(bool isUserImage) async {
    final ImageSource? source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (isUserImage) {
            _userImage = File(pickedFile.path);
          } else {
            _designImage = File(pickedFile.path);
          }
          _resultImageUrl = null;
        });
      }
    } catch (e) {
      _showErrorMessage('Failed to pick image: ${e.toString()}');
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFFECECEC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Select Image Source'),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  Icons.camera_alt,
                  'Camera',
                  ImageSource.camera,
                ),
                const SizedBox(width: 20),
                _buildSourceOption(
                  Icons.photo_library,
                  'Gallery',
                  ImageSource.gallery,
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSourceOption(IconData icon, String label, ImageSource source) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor:
              source == ImageSource.camera
                  ? const Color(0xFF000A3D)
                  : const Color.fromARGB(255, 7, 150, 151),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 36),
            onPressed: () => Navigator.pop(context, source),
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  Future<void> _processImages() async {
    if (_userImage == null || _designImage == null) {
      _showErrorMessage('Please upload both your picture and design');
      return;
    }

    setState(() {
      _isLoading = true;
      _resultImageUrl = null;
    });

    try {
      _showProcessingDialog();

      final response = await _sendTryOnRequest();

      if (!mounted) return;
      Navigator.of(context).pop();

      if (response['success'] == true && response['resultUrl'] != null) {
        final resultUrl = response['resultUrl'];
        setState(() => _resultImageUrl = resultUrl);
        _showResultImage(resultUrl);
      } else {
        _showErrorMessage(response['message'] ?? 'Invalid response format');
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorMessage('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _sendTryOnRequest() async {
    final url = Uri.parse('$_serverBaseUrl/api/cloudinary-tryon/process');

    var request = http.MultipartRequest('POST', url);

    final userImageFile = File(_userImage!.path);
    final designImageFile = File(_designImage!.path);
    print('User image size: ${await userImageFile.length()} bytes');
    print('Design image size: ${await designImageFile.length()} bytes');

    request.files.add(
      await http.MultipartFile.fromPath('userImage', _userImage!.path),
    );
    request.files.add(
      await http.MultipartFile.fromPath('designImage', _designImage!.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      final errorData = json.decode(response.body);
      throw Exception(
        'Server error: ${response.statusCode} - ${errorData['message'] ?? 'Unknown error'}',
      );
    }

    return json.decode(response.body);
  }

  Future<void> _showProcessingDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _animationController,
                  builder:
                      (_, child) => Transform.rotate(
                        angle: _animationController.value * 2 * 3.14159,
                        child: const SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            color: Color(0xFF000A3D),
                            strokeWidth: 4,
                          ),
                        ),
                      ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'AI is processing your images...\nThis may take a moment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'RETRY',
          textColor: Colors.white,
          onPressed: () {
            if (_userImage != null && _designImage != null) {
              _processImages();
            }
          },
        ),
      ),
    );
  }

  Future<void> _saveAndShareImage(String imageUrl) async {
    try {
      setState(() => _isLoading = true);

      final String fullUrl = _getFullUrl(imageUrl);

      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/clothify_tryon_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(response.bodyBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Check out my virtual try-on from Clothify!');
    } catch (e) {
      _showErrorMessage('Error sharing image: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showResultImage(String resultUrl) {
    final fullUrl = _getFullUrl(resultUrl);

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildResultHeader(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildResultImage(fullUrl),
                      const SizedBox(height: 20),
                      _buildResultButtons(resultUrl),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildResultHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF000A3D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Your Virtual Try-On',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildResultImage(String fullUrl) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Hero(
            tag: 'tryonResult',
            child: Image.network(
              fullUrl,
              height: 350,
              fit: BoxFit.contain,
              cacheWidth: 1200,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  height: 350,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                          color: const Color(0xFF000A3D),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Loading image...',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorWidget(error);
              },
            ),
          ),
        ),
        _buildWatermark(),
      ],
    );
  }

  Widget _buildErrorWidget(Object error) {
    return SizedBox(
      height: 350,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Error loading image',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                error.toString(),
                style: TextStyle(color: Colors.red[300], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000A3D),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _processImages();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatermark() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Clothify',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildResultButtons(String resultUrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.check,
          label: 'Done',
          color: const Color.fromARGB(255, 7, 150, 151),
          onPressed: () => Navigator.pop(context),
        ),
        _buildActionButton(
          icon: Icons.share,
          label: 'Share',
          color: Colors.deepPurple,
          onPressed: () => _saveAndShareImage(resultUrl),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PersistentBottomNav(
      currentIndex: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF000A3D),
        appBar: AppBar(
          title: const Text('Virtual Try-On'),
          backgroundColor: const Color(0xFFECECEC),
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => setState(() => _showTips = !_showTips),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_showTips) _buildTipsCard(),
              _buildUploadButton(
                label:
                    _userImage != null
                        ? 'Picture Uploaded'
                        : 'Upload Your Picture',
                icon: _userImage != null ? Icons.check_circle : Icons.person,
                color: const Color.fromARGB(255, 7, 150, 151),
                onTap: () => _pickImage(true),
                showSubtitle: _userImage != null,
              ),
              const SizedBox(height: 20),
              _buildUploadButton(
                label:
                    _designImage != null
                        ? 'Design Uploaded'
                        : 'Upload Your Design',
                icon: _designImage != null ? Icons.check_circle : Icons.style,
                color: Colors.deepPurple,
                onTap: () => _pickImage(false),
                showSubtitle: _designImage != null,
              ),
              const SizedBox(height: 30),
              _buildTryOnButton(),
              if (_userImage != null || _designImage != null)
                _buildPreviewSection(),
              if (_resultImageUrl != null) _buildResultSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Tips for best results:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 16),
                onPressed: () => setState(() => _showTips = false),
                constraints: const BoxConstraints.tightFor(
                  width: 20,
                  height: 20,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Use photos with good lighting\n• Choose front-facing poses\n• Select clothing designs with clear outlines',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool showSubtitle = false,
  }) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showSubtitle)
                Text(
                  'Tap to change',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTryOnButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _processImages,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFECECEC),
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      child:
          _isLoading
              ? const CircularProgressIndicator(color: Color(0xFF000A3D))
              : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.smart_toy, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'AI Try On',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Uploaded Files:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (_userImage != null)
                _buildPreviewImage(_userImage!, 'Your Picture'),
              if (_designImage != null)
                _buildPreviewImage(_designImage!, 'Your Design'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewImage(File image, String label) {
    return Column(
      children: [
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(image, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _buildResultSection() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Latest Result:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: () => _showResultImage(_resultImageUrl!),
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Hero(
                  tag: 'tryonResult',
                  child: Image.network(
                    _getFullUrl(_resultImageUrl!),
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                          color: const Color(0xFF000A3D),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white.withOpacity(0.5),
                          size: 48,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Tap to view full size',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSmallButton(
                icon: Icons.share,
                label: 'Share',
                color: Colors.deepPurple,
                onPressed: () => _saveAndShareImage(_resultImageUrl!),
              ),
              const SizedBox(width: 10),
              _buildSmallButton(
                icon: Icons.refresh,
                label: 'Try Again',
                color: const Color.fromARGB(255, 7, 150, 151),
                onPressed: _processImages,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
