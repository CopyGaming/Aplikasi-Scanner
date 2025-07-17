import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

class QrCodeScan extends StatefulWidget {
  const QrCodeScan({super.key});

  @override
  _QrCodeScanState createState() => _QrCodeScanState();
}

class _QrCodeScanState extends State<QrCodeScan> {
  String result = "Waiting QR Scan Text";
  bool isScanning = false;
  bool isLoading = false;
  bool sudahKirim = false;
  bool isQrValid = false;
  bool isOnline = true;

  String? nim, nama, kelompok, timestamp;

  final String scriptURL = 'https://script.google.com/macros/s/AKfycbyO176Yl4zx0hgo-q8zi8s3JxQcBEQmKPdQ9etsqMixNW4R4CQ_KaqglsXEbs3p_fLKGA/exec';

  final Color pastelPink = const Color(0xFFFFE4EC);
  final Color pastelBlue = const Color(0xFF6A7BA2);
  final Color pastelButton = const Color.fromARGB(255, 225, 131, 182);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    checkInternetConnection();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => checkInternetConnection());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      setState(() {
        isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      });
    } on SocketException catch (_) {
      setState(() {
        isOnline = false;
      });
    }
  }

  void startScanner() {
    setState(() {
      isScanning = true;
      result = "Waiting QR Scan Text";
      sudahKirim = false;
      isQrValid = false;
    });
  }

  void stopScanner() {
    setState(() {
      isScanning = false;
    });
  }

  String getCurrentTimestamp() {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}/"
        "${now.month.toString().padLeft(2, '0')}/"
        "${now.year}, ${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}";
  }

  Future<void> kirimDataKeSheet() async {
    if (nim != null && nama != null && kelompok != null && timestamp != null && !sudahKirim && isQrValid) {
      setState(() {
        isLoading = true;
      });

      try {
        
        final response = await http.post(
          Uri.parse(scriptURL),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'nim': nim,
            'nama': nama,
            'kelompok': kelompok,
            'timestamp': timestamp
          }),
        );

        setState(() {
          isLoading = false;
          sudahKirim = true;

          // Reset data setelah berhasil kirim
          result = "Waiting QR Scan Text";
          nim = null;
          nama = null;
          kelompok = null;
          timestamp = null;
          isQrValid = false;
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("✅ Berhasil Tercatat"),
            content: const Text("Data kehadiran kamu sudah tercatat di Google Sheet."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } catch (e) {
        setState(() {
          isLoading = false;
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("❌ Terjadi Kesalahan"),
            content: Text("Gagal mengirim data: $e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pastelPink,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      appBar: AppBar(
        backgroundColor: pastelButton,
        title: Row(
          children: [
            Image.asset('assets/logo.jpg', width: 35, height: 35),
            const SizedBox(width: 10),
            const Text(
              "Absensi NSOP",
              style: TextStyle(color: Color(0xFF6A7BA2)),
            ),
          ],
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF6A7BA2)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color: isOnline ? Colors.green : Colors.red,
                  size: 12,
                ),
                const SizedBox(width: 5),
                Text(
                  isOnline ? "Online" : "Offline",
                  style: TextStyle(color: isOnline ? Colors.green : Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: isScanning
            ? Stack(
                children: [
                  MobileScanner(
                    onDetect: (barcodeCapture) {
                      final List<Barcode> barcodes = barcodeCapture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final String? code = barcodes.first.rawValue;
                        if (code != null) {
                          List<String> parts = code.split(',');
                          if (parts.length == 3) {
                            setState(() {
                              nim = parts[0].trim();
                              nama = parts[1].trim();
                              kelompok = parts[2].trim();
                              timestamp = getCurrentTimestamp();
                              result = '''
NIM        : $nim
Nama       : $nama
Kelompok   : $kelompok

Scanned at : $timestamp
''';
                              isScanning = false;
                              sudahKirim = false;
                              isQrValid = true;
                            });
                          } else {
                            setState(() {
                              result = 'Format QR tidak valid.\nPastikan format: NIM,Nama,Kelompok';
                              isScanning = false;
                              isQrValid = false;
                            });
                          }
                        }
                      }
                    },
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: ElevatedButton(
                        onPressed: stopScanner,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pastelButton,
                          foregroundColor: pastelBlue,
                        ),
                        child: const Text("Stop Scanning"),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: nim == null ? MainAxisAlignment.center : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 40),
                  ClipOval(
                    child: Image.asset(
                      'assets/logo.jpg',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      width: double.infinity,
                      child: Text(
                        result,
                        style: const TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6A7BA2),
                          height: 1.5,
                          fontFamily: 'Courier',
                        ),
                        textAlign: nim == null ? TextAlign.center : TextAlign.left,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: startScanner,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pastelButton,
                      foregroundColor: pastelBlue,
                    ),
                    child: const Text('Scan QR CODE', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(height: 20),
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: (!isQrValid || sudahKirim || nim == null || !isOnline)
                              ? null
                              : kirimDataKeSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pastelButton,
                            foregroundColor: pastelBlue,
                          ),
                          child: const Text('Hadir Lah', style: TextStyle(fontSize: 18)),
                        ),
                ],
              ),
      ),
    );
  }
}