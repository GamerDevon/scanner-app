import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderScannerScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const OrderScannerScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<OrderScannerScreen> createState() => _OrderScannerScreenState();
}

class _OrderScannerScreenState extends State<OrderScannerScreen> {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  List<String> _scannedBubbles = [];
  bool _isProcessing = false;

  final TextEditingController _jmenoController = TextEditingController();
  final TextEditingController _telefonController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _adresaController = TextEditingController();
  final TextEditingController _mestoController = TextEditingController();
  final TextEditingController _pscController = TextEditingController();
  final TextEditingController _zboziController = TextEditingController();
  final TextEditingController _dopravaController = TextEditingController();
  final TextEditingController _vsController = TextEditingController();
  final TextEditingController _cenaController = TextEditingController();
  final TextEditingController _platbaController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Locates the back camera lens and initializes the stream controller
  void _initializeCamera() async {
    if (widget.cameras.isEmpty) return;
    
    final backCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );

    _cameraController = CameraController(
      backCamera, 
      ResolutionPreset.medium, 
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera subsystem error: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _jmenoController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _adresaController.dispose();
    _mestoController.dispose();
    _pscController.dispose();
    _zboziController.dispose();
    _dopravaController.dispose();
    _vsController.dispose();
    _cenaController.dispose();
    _platbaController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _scannedBubbles.clear();
      _jmenoController.clear();
      _telefonController.clear();
      _emailController.clear();
      _adresaController.clear();
      _mestoController.clear();
      _pscController.clear();
      _zboziController.clear();
      _dopravaController.clear();
      _vsController.clear();
      _cenaController.clear();
      _platbaController.clear();
    });
  }

  // Snaps via inline back lens frame buffer, passing to ML Kit engine instantly
  Future<void> _scanNotebookPage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      final XFile pickedFile = await _cameraController!.takePicture();

      final InputImage inputImage = InputImage.fromFilePath(pickedFile.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      final List<String> lines = recognizedText.text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      setState(() {
        _scannedBubbles = lines;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showSnackBar('Error processing text: ${e.toString()}', isError: true);
    }
  }

  void _assignValue(String value, String fieldKey) {
    setState(() {
      switch (fieldKey) {
        case 'jmeno': _jmenoController.text = value; break;
        case 'telefon': _telefonController.text = value; break;
        case 'email': _emailController.text = value; break;
        case 'adresa': _adresaController.text = value; break;
        case 'mesto': _mestoController.text = value; break;
        case 'psc': _pscController.text = value; break;
        case 'zbozi':
          if (_zboziController.text.isEmpty) {
            _zboziController.text = value;
          } else {
            _zboziController.text += ' $value';
          }
          break;
        case 'doprava': _dopravaController.text = value; break;
        case 'vs': _vsController.text = value; break;
        case 'cena': _cenaController.text = value; break;
        case 'platba': _platbaController.text = value; break;
      }
    });
  }

  double? _parseNumeric(String text) {
    if (text.isEmpty) return null;
    final normalized = text.replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(normalized);
  }

  Future<void> _commitRowToSupabase() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final double? cena = _parseNumeric(_cenaController.text);
      final double? platba = _parseNumeric(_platbaController.text);

      final Map<String, dynamic> payload = {
        'jmeno_zakaznika': _jmenoController.text.trim(),
        'telefon': _telefonController.text.trim(),
        'email': _emailController.text.trim(),
        'adresa': _adresaController.text.trim(),
        'mesto': _mestoController.text.trim(),
        'psc': _pscController.text.trim(),
        'zbozi': _zboziController.text.trim(),
        'doprava': _dopravaController.text.trim(),
        'stav': 'Nová',
        'variabilni_symbol': _vsController.text.trim(),
        'cena': cena,
        'prijata_platba': platba,
      };

      await Supabase.instance.client.from('orders').insert(payload);

      _showSnackBar('Order successfully committed to Supabase.');
      _resetForm();
    } catch (e) {
      _showSnackBar('Database connection error: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Staging Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Form',
            onPressed: _resetForm,
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Inline Camera Frame Element
          if (_cameraController != null && _cameraController!.value.isInitialized)
            SizedBox(
              height: 200,
              width: double.infinity,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _cameraController!.value.previewSize!.height,
                      height: _cameraController!.value.previewSize!.width,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),

          // 2. Scan Snap Execution Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _scanNotebookPage,
              icon: _isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.camera_alt),
              label: Text(_isProcessing ? 'Processing Text...' : 'Scan Notebook Page'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(45),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 3. Extracted Bubble Selection Grid
          if (_scannedBubbles.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 140),
              width: double.infinity,
              color: Colors.grey.shade100,
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _scannedBubbles.map((bubbleText) {
                    return PopupMenuButton<String>(
                      onSelected: (String fieldKey) => _assignValue(bubbleText, fieldKey),
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(value: 'jmeno', child: Text('Jméno zákazníka')),
                        const PopupMenuItem(value: 'telefon', child: Text('Telefon')),
                        const PopupMenuItem(value: 'email', child: Text('Email')),
                        const PopupMenuItem(value: 'adresa', child: Text('Adresa')),
                        const PopupMenuItem(value: 'mesto', child: Text('Město')),
                        const PopupMenuItem(value: 'psc', child: Text('PSČ')),
                        const PopupMenuItem(value: 'zbozi', child: Text('Zboží (Append)')),
                        const PopupMenuItem(value: 'doprava', child: Text('Doprava')),
                        const PopupMenuItem(value: 'vs', child: Text('Variabilní symbol')),
                        const PopupMenuItem(value: 'cena', child: Text('Cena')),
                        const PopupMenuItem(value: 'platba', child: Text('Přijatá platba')),
                      ],
                      child: Chip(
                        backgroundColor: Colors.blue.shade50,
                        side: BorderSide(color: Colors.blue.shade200),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                bubbleText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.blue.shade900),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down, size: 18, color: Colors.blue.shade700),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // 4. Input Target Form Setup
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _jmenoController,
                    decoration: const InputDecoration(labelText: 'Jméno zákazníka', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _telefonController,
                          decoration: const InputDecoration(labelText: 'Telefon', border: OutlineInputBorder()),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _adresaController,
                    decoration: const InputDecoration(labelText: 'Adresa', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _mestoController,
                          decoration: const InputDecoration(labelText: 'Město', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _pscController,
                          decoration: const InputDecoration(labelText: 'PSČ', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _zboziController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Zboží', 
                      border: OutlineInputBorder(),
                      helperText: 'Selecting multi-line text appends onto this field.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dopravaController,
                    decoration: const InputDecoration(labelText: 'Doprava', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vsController,
                    decoration: const InputDecoration(labelText: 'Variabilní symbol', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cenaController,
                          decoration: const InputDecoration(labelText: 'Cena', border: OutlineInputBorder(), suffixText: 'Kč'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _platbaController,
                          decoration: const InputDecoration(labelText: 'Přijatá platba', border: OutlineInputBorder(), suffixText: 'Kč'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 5. Global Supabase Commit Panel
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _commitRowToSupabase,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(55),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Commit Row to Supabase'),
            ),
          ),
        ],
      ),
    );
  }
}
