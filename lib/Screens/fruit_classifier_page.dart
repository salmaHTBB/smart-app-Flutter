import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img_lib;


class FruitClassifierPage extends StatefulWidget {
  const FruitClassifierPage({super.key});

  @override
  State<FruitClassifierPage> createState() => _FruitClassifierPageState();
}

class _FruitClassifierPageState extends State<FruitClassifierPage> {
  // --- Model and Preprocessing Constants ---
  static const int _modelInputSize = 32; // <--- CORRECTED: Matches your Keras model's (32, 32) resize
  static const int _outputSize = 3;
  // -----------------------------------------

  late Interpreter _interpreter;
  List<String> _labels = ["Apple", "Banana", "Orange"]; // Matches your Keras classes list
  File? _image;
  String _result = "Tap the camera to start!";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to ensure context is available before attempting to load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadModel();
    });
  }

  // ⭐ Step 1: Load the TFLite model and labels
  Future<void> _loadModel() async {
    try {
      // NOTE: Your model must be converted from 'Fruits.h5' to 'fruits_model.tflite'
      _interpreter = await Interpreter.fromAsset('assets/models/fruits_model.tflite');
      print("Model loaded successfully. Input Shape: ${_interpreter.getInputTensor(0).shape}");

      // Verify the input shape based on your model file
      final inputShape = _interpreter.getInputTensor(0).shape;
      if (inputShape[1] != _modelInputSize || inputShape[2] != _modelInputSize) {
        throw Exception("Model input size mismatch. Expected: [1, $_modelInputSize, $_modelInputSize, 3], Found: $inputShape");
      }

    } catch (e) {
      print("Failed to load model: $e");
      if (mounted) {
        setState(() {
          _result = "Failed to load model: $e";
        });
      }
    }
  }

  // ⭐ Step 2: Pick an image from the camera
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    // Using `source: source` allows flexibility (camera or gallery)
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
        _image = File(pickedFile.path);
        _result = "Processing...";
      });
      // Ensure the model is loaded before trying to classify
      if (_interpreter != null) {
        await _classifyImage(_image!);
      } else {
        setState(() {
          _result = "Model is not loaded. Please restart the app.";
          _isLoading = false;
        });
      }
    }
  }

  // ⭐ Step 3: Classify the image using the TFLite model
  Future<void> _classifyImage(File image) async {
    // Read the image file and decode it
    final originalImage = img_lib.decodeImage(image.readAsBytesSync());

    if (originalImage == null) {
      setState(() {
        _result = "Could not decode image.";
        _isLoading = false;
      });
      return;
    }

    // Resize image to 32x32 to match your Keras model's training/input size
    final resizedImage = img_lib.copyResize(originalImage,
        width: _modelInputSize,
        height: _modelInputSize
    );

    // Convert image to a 4D tensor ([1, 32, 32, 3])
    // Data type is float32 (Float32List) as your code uses division by 255.0
    final inputTensor = Float32List(1 * _modelInputSize * _modelInputSize * 3);

    int bufferIndex = 0;
    for (int y = 0; y < _modelInputSize; y++) {
      for (int x = 0; x < _modelInputSize; x++) {
        final pixel = resizedImage.getPixel(x, y);

        // Normalize pixel values to [0, 1] (as done in Keras when scaling)
        // Keras code implicitly does this by loading/training on scaled images
        // with the PIL .resize() and numpy conversion.
        inputTensor[bufferIndex++] = img_lib.getRed(pixel)(pixel) / 255.0;
        inputTensor[bufferIndex++] = img_lib.getGreen(pixel) / 255.0;
        inputTensor[bufferIndex++] = img_lib.getBlue(pixel) / 255.0;
      }
    }

    // Reshape the flat list into the 4D input tensor for the interpreter
    final inputShape = [1, _modelInputSize, _modelInputSize, 3];
    final reshapedInput = inputTensor.reshape(inputShape);

    // Create output buffer ([1, 3] for 3 classes)
    final outputTensor = Float32List(1 * _outputSize).reshape([1, _outputSize]);

    try {
      // Run inference
      _interpreter.run(reshapedInput, outputTensor);

      // ⭐ Step 4: Process the output
      final List<double> confidences = outputTensor[0];
      double maxConfidence = confidences.reduce((a, b) => a > b ? a : b);
      int maxIndex = confidences.indexOf(maxConfidence);

      setState(() {
        _isLoading = false;
        _result =
        "Prediction: ${_labels[maxIndex]} \nConfidence: ${(maxConfidence * 100).toStringAsFixed(2)}%";
      });
    } catch (e) {
      print("TFLite inference failed: $e");
      setState(() {
        _isLoading = false;
        _result = "Inference Error: $e";
      });
    }
  }

  @override
  void dispose() {
    _interpreter.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fruit Classifier", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image Display
            Container(
              margin: const EdgeInsets.all(20),
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.indigo, width: 3),
                borderRadius: BorderRadius.circular(15),
              ),
              child: _image == null
                  ? const Center(
                  child: Text("No image selected", style: TextStyle(fontSize: 18)))
                  : Image.file(_image!, fit: BoxFit.cover),
            ),
            const SizedBox(height: 30),
            // Result Text
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _result,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _result.startsWith("Prediction") ? Colors.green : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Classification Button
            _isLoading
                ? const CircularProgressIndicator(color: Colors.indigo)
                : ElevatedButton.icon(
              // Allow picking from gallery as an alternative to camera
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_album, color: Colors.white),
              label: const Text(
                "Pick Image (Classify)",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}