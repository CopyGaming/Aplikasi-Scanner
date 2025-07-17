import 'package:flutter/material.dart';
import 'qr_scanner.dart'; // kita akan bikin file ini pakai mobile_scanner

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QR Code Scanner',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      home: QrCodeScan(),
    );
  }
}