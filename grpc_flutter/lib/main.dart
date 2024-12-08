import 'package:flutter/material.dart';
import 'services/grpc_client.dart';
import 'config/grpc_config.dart';
import './compte_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Test connection on startup
  final grpcClient = GrpcClient();
  bool isConnected = await grpcClient.testConnection();

  runApp(MyApp(isConnected: isConnected));
}

class MyApp extends StatelessWidget {
  final bool isConnected;

  const MyApp({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black), // Updated to bodyLarge
          bodyMedium: TextStyle(color: Colors.black54), // Updated to bodyMedium
          titleLarge: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold), // Updated to titleLarge
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            textStyle: TextStyle(fontSize: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            backgroundColor: Colors
                .blue, // Updated to backgroundColor (instead of 'primary')
            foregroundColor:
                Colors.white, // Text color (previously 'onPrimary')
          ),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('gRPC Connection Test'),
          centerTitle: true,
        ),
        body: isConnected
            ? CompteScreen() // Your main screen
            : _buildNoConnectionScreen(context),
      ),
    );
  }

  Widget _buildNoConnectionScreen(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 50),
                SizedBox(height: 20),
                Text(
                  'Cannot connect to gRPC server at ${GrpcConfig.host}:${GrpcConfig.port}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final grpcClient = GrpcClient();
                    bool connected = await grpcClient.testConnection();
                    if (connected) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => CompteScreen()),
                      );
                    } else {
                      // Optionally show a message if the retry fails
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Connection failed. Please try again later.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text('Retry Connection'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
