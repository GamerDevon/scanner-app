import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_scanner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase client
  // TODO: Replace placeholders with your actual Supabase URL and Anon Key
  await Supabase.initialize(
    url: 'https://YOUR_SUPABASE_PROJECT_URL.supabase.co',
    anonKey: 'YOUR_SUPABASE_ANON_PUBLIC_KEY',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Order Digitizer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const OrderScannerScreen(),
    );
  }
}
