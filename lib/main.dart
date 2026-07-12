import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // 1. Initialize native bindings to stop the ML Kit black screen crash
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Supabase directly with your hardcoded keys
  await Supabase.initialize(
    url: 'https://ivzloxwkokirozungdxj.supabase.co', 
    publishableKey: 'sb_publishable_zQQYp0_h_n3Tlc2FwanFuA_ApGTqc8X', // Put your publishable key here
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scanner App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner & Supabase App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_sync_rounded,
              size: 80,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 20),
            Text(
              supabase.auth.currentUser == null 
                  ? 'Not logged into Supabase' 
                  : 'Logged in as: ${supabase.auth.currentUser!.email}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // Your scanning logic or database operations go here
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Start Scanning'),
            ),
          ],
        ),
      ),
    );
  }
}
