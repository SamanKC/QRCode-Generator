import 'package:flutter/material.dart';
import 'package:qrcodegenerator/views/home/home_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'QR Scanner',
      debugShowCheckedModeBanner: false,
      home: QRHomePage(),
    );
  }
}
