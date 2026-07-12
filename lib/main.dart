import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

late List<CameraDescription> _cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize device cameras before starting the UI
  _cameras = await availableCameras();
  
  // Initialize Supabase with your direct project parameters
  await Supabase.initialize(
    url: 'https://ivzloxwkokirozungdxj.supabase.co', 
    anonKey: 'sb_publishable_zQQYp0_h_n3Tlc2FwanFuA_ApGTqc8X',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Batch Text Scanner',
      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _controller;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  
  bool _isProcessing = false;
  List<TextBlock> _detectedBlocks = [];
  String _selectedText = "";
  final List<String> _scannedRowItems = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Targets and spins up the back camera view lens
  void _initializeCamera() async {
    if (_cameras.isEmpty) return;
    
    final backCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(backCamera, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  // Snaps the picture, forwards it to ML Kit, and updates state with detected blocks
  void _captureAndProcessText() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _detectedBlocks = [];
      _selectedText = "";
    });

    try {
      final XFile photo = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      setState(() {
        _detectedBlocks = recognizedText.blocks;
      });
    } catch (e) {
      debugPrint("Text recognition processing error: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // Writes the grouped batch list into Supabase and clears UI state for the next sequence
  void _saveRowToSupabase() async {
    if (_scannedRowItems.isEmpty) return;

    try {
      await Supabase.instance.client.from('scanned_data').insert({
        'items': _scannedRowItems,
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Row saved successfully! Ready for next scan.')),
      );

      setState(() {
        _scannedRowItems.clear();
        _detectedBlocks = [];
        _selectedText = "";
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Row Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 1. Live Frame Feed (Upper Window)
          SizedBox(
            height: 250,
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),

          // 2. Action Capture Trigger
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _captureAndProcessText,
              icon: _isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.camera_alt),
              label: Text(_isProcessing ? 'Reading Text...' : 'Snap & Find Text'),
            ),
          ),

          const Divider(),

          // 3. Tappable Text Detection Selection Bubbles
          const Text('Tap detected text to select it:', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _detectedBlocks.map((block) {
                  return ChoiceChip(
                    label: Text(block.text),
                    selected: _selectedText == block.text,
                    onSelected: (selected) {
                      setState(() {
                        _selectedText = selected ? block.text : "";
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),

          // 4. Staging Platform & Confirmation Panel
          if (_selectedText.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(child: Text('Confirm Text: "$_selectedText"', style: const TextStyle(fontSize: 14))),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _scannedRowItems.add(_selectedText);
                        _selectedText = "";
                      });
                    },
                    child: const Text('Add to Row'),
                  ),
                ],
              ),
            ),
          ],

          const Divider(),

          // 5. Current Data Entry Display & Database Submission Anchor
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Current Active Row: ${_scannedRowItems.isEmpty ? "[Empty]" : _scannedRowItems.join(" | ")}', 
                    style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic)),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _scannedRowItems.isEmpty ? null : _saveRowToSupabase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, 
                    foregroundColor: Colors.white
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Row Done (Push to Database)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
