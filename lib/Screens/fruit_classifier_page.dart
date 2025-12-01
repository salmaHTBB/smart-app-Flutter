import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';

class FruitClassifierPage extends StatefulWidget {
  const FruitClassifierPage({super.key});

  @override
  State<FruitClassifierPage> createState() => _FruitClassifierPageState();
}

class _FruitClassifierPageState extends State<FruitClassifierPage> {
  File? _image;
  List<dynamic>? _recognitions;
  String _result = '';
  bool _isLoading = false;
  List<String> _labels = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadLabels();
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  // Load the TensorFlow Lite model
  Future<void> _loadModel() async {
    try {
      String? res = await Tflite.loadModel(
        model: "assets/models/fruits_model.tflite",
        labels: "assets/labels/fruits_labels.txt",
        numThreads: 1,
        isAsset: true,
        useGpuDelegate: false,
      );
      print('Model loaded: $res');
    } catch (e) {
      print('Error loading model: $e');
      setState(() {
        _result = 'Error loading model: $e';
      });
    }
  }

  // Load labels from file
  Future<void> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString('assets/labels/fruits_labels.txt');
      setState(() {
        _labels = labelsData.split('\n').where((label) => label.trim().isNotEmpty).toList();
      });
      print('Labels loaded: $_labels');
    } catch (e) {
      print('Error loading labels: $e');
    }
  }

  // Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _result = '';
          _recognitions = null;
        });
        await _classifyImage(File(pickedFile.path));
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _result = 'Error picking image: $e';
      });
    }
  }

  // Take photo with camera
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
      );
      
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _result = '';
          _recognitions = null;
        });
        await _classifyImage(File(pickedFile.path));
      }
    } catch (e) {
      print('Error taking photo: $e');
      setState(() {
        _result = 'Error taking photo: $e';
      });
    }
  }

  // Classify the image using the TFLite model
  Future<void> _classifyImage(File image) async {
    setState(() {
      _isLoading = true;
    });

    try {
      var recognitions = await Tflite.runModelOnImage(
        path: image.path,
        imageMean: 0.0,
        imageStd: 255.0,
        numResults: 5,
        threshold: 0.1,
        asynch: true,
      );

      if (recognitions != null && recognitions.isNotEmpty) {
        setState(() {
          _recognitions = recognitions;
          var topResult = recognitions[0];
          String label = topResult['label'] ?? 'Unknown';
          double confidence = (topResult['confidence'] ?? 0.0) * 100;
          _result = '$label (${confidence.toStringAsFixed(1)}%)';
          _isLoading = false;
        });
        print('Recognition results: $recognitions');
      } else {
        setState(() {
          _result = 'No classification result';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Classification error: $e';
        _isLoading = false;
      });
      print('Classification error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fruit Classifier'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Display selected image or placeholder
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _image == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 80, color: Colors.grey),
                              SizedBox(height: 10),
                              Text(
                                'No image selected',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _image!,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                
                const SizedBox(height: 30),
                
                // Buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickImageFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Result display
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.green)
                else if (_result.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Classification Result:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _result,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Available labels
                if (_labels.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Available Fruits:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _labels.join(', '),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
