import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_scanner_screen.dart'; 

late List<CameraDescription> _cameras;

void main() async {
  // 1. Initialize native bindings to prevent the ML Kit black screen crash
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Query available system cameras
  _cameras = await availableCameras();
  
  // 3. Initialize your Supabase database client instance using publishableKey
  await Supabase.initialize(
    url: 'https://ivzloxwkokirozungdxj.supabase.co', 
    publishableKey: 'sb_publishable_zQQYp0_h_n3Tlc2FwanFuA_ApGTqc8X',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Order Staging Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: Colors.blue,
      ),
      home: OrderScannerScreen(cameras: _cameras),
    );
  }
}
