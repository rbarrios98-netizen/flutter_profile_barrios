import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Developer Profile',
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueGrey[50],
          title: const Text('My Developer Profile'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              // Full Name
              Icon(Icons.person, size: 80),
              SizedBox(height: 10),
              Text(
                'Roshaine Barrios',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 10),

              // Section
              Text('BSIT-3A'),

              SizedBox(height: 10),

              // Age
              Text('Age: 21'),

              SizedBox(height: 10),

              // Hobbies
              Text('Hobbies:'),
              SizedBox(height: 5),
              Text('• Coding'),
              Text('• Watching Movies'),
              Text('• Playing Mobile Games'),
            ],
          ),
        ),
      ),
    );
  }
}
