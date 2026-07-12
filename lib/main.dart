import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Looks directly in the same lib folder for the screen
import 'order_scanner_screen.dart'; 

late List<CameraDescription> _cameras;

void main() async {
  // 1. Initialize native bindings to stop the ML Kit black screen crash
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialize device cameras before starting the UI
  _cameras = await availableCameras();
  
  // 3. Initialize Supabase directly with your project credentials
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
      // Hands the camera list over to your custom scanning screen
      home: OrderScannerScreen(cameras: _cameras),
    );
  }
}
