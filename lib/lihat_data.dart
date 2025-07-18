import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
  
class LihatDataPage extends StatefulWidget {
  const LihatDataPage({super.key});

  @override
  _LihatDataPageState createState() => _LihatDataPageState();
}

class _LihatDataPageState extends State<LihatDataPage> {
  List<List<dynamic>> data = [];
  bool isLoading = true;
  Timer? autoRefreshTimer;

  final String spreadsheetUrl =
      'https://opensheet.elk.sh/1_z8Aw5EW3NAOw-JXaq1eHURTEqUVj_1HGSByP5Keo5Q/Absen%20Scan';

  final Color pastelPink = const Color(0xFFFFE4EC);
  final Color pastelBlue = const Color(0xFF6A7BA2);
  final Color pastelButton = const Color.fromARGB(255, 225, 131, 182);

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse(spreadsheetUrl),
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        if (jsonData.isNotEmpty && jsonData.first is Map) {
          final headers = (jsonData.first as Map<String, dynamic>).keys.toList();

          final List<List<dynamic>> rows = [
            headers,
            ...jsonData.map((row) => headers.map((key) => row[key] ?? '').toList()),
          ];

          setState(() {
            data = rows;
            isLoading = false;
          });
        } else {
          setState(() {
            data = [];
            isLoading = false;
          });
        }
      } else {
        throw Exception('Gagal memuat data');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
        data = [];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    autoRefreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fetchData();
    });
  }

  @override
  void dispose() {
    autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pastelPink,
      appBar: AppBar(
        title: const Text("Data Absensi"),
        backgroundColor: pastelBlue,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              fetchData();
            },
            color: pastelButton,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data.isEmpty
              ? const Center(child: Text('Tidak ada data'))
              : data[0].isEmpty
                  ? const Center(child: Text('Belum Ada Absensi'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              headingRowColor: MaterialStateColor.resolveWith(
                                  (states) => pastelBlue.withOpacity(0.3)),
                              dataRowColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.white),
                              columnSpacing: 24,
                              columns: data[0]
                                  .map(
                                    (header) => DataColumn(
                                      label: Text(
                                        header.toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: pastelBlue,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              rows: data.sublist(1).map(
                                (row) {
                                  return DataRow(
                                    cells: row
                                        .map(
                                          (cell) => DataCell(
                                            Text(
                                              cell.toString(),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  );
                                },
                              ).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
    );
  }
}