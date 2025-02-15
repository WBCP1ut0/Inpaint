import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../services/lama_service.dart';
import '../widgets/drawing_canvas.dart';
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedImage;
  ui.Image? _maskImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeLama();
  }

  Future<void> _initializeLama() async {
    try {
      await LamaService.initializeModel();
    } catch (e) {
      // Handle initialization error
      print('Failed to initialize LaMa: $e');
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      // Show drawing canvas for masking
      _showMaskingDialog();
    }
  }

  Future<void> _showMaskingDialog() async {
    if (_selectedImage == null) return;

    final bytes = await _selectedImage!.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DrawingCanvas(
              image: frame.image,
              onMaskComplete: (mask) async {
                _maskImage = mask;
                // Process the image with LaMa
                await _processImage();
              },
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processImage();
              },
              child: const Text('Apply Inpainting'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processImage() async {
    if (_selectedImage == null || _maskImage == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final maskBytes = await _maskImage!.toByteData();
      final tempDir = await getTemporaryDirectory();
      final maskFile = File('${tempDir.path}/mask.png');
      await maskFile.writeAsBytes(maskBytes!.buffer.asUint8List());

      final result = await LamaService.inpaintImage(_selectedImage!, maskFile);
      
      setState(() {
        _selectedImage = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process image: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'InPaintX',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.5,
        child: Container(
          color: Colors.black,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  // Add support functionality
                },
                child: const Text(
                  'Support',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_selectedImage != null)
                  Image.file(
                    _selectedImage!,
                    height: 300,
                    width: 300,
                    fit: BoxFit.contain,
                  ),
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _pickImage,
                  child: Text(_isLoading ? 'Processing...' : 'Upload Image'),
                ),
                const SizedBox(height: 16),
                const Text('Take an image right now'),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 