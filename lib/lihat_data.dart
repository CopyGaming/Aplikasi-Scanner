import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:ui';

class LihatDataPage extends StatefulWidget {
  const LihatDataPage({super.key});

  @override
  _LihatDataPageState createState() => _LihatDataPageState();
}

class _LihatDataPageState extends State<LihatDataPage> {
  List<List<dynamic>> data = [];
  List<List<dynamic>> filteredData = [];
  bool isLoading = true;
  Timer? autoRefreshTimer;

  final String spreadsheetUrl =
      'https://opensheet.elk.sh/1_z8Aw5EW3NAOw-JXaq1eHURTEqUVj_1HGSByP5Keo5Q/Absen%20Scan';

  final Color pastelPink = const Color(0xFFe8f5e9);
  final Color pastelBlue = const Color(0xFF2e7d32);
  final Color pastelButton = const Color(0xFFa1887f);

  String kelompokFilter = 'Semua';
  String searchQuery = '';

  List<String> kelompokList = ['Semua'];

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

          // Ambil daftar kelompok unik
          final kelompokIndex = headers.indexWhere((h) => h.toLowerCase().contains('kelompok'));
          final kelompokSet = <String>{};
          for (var r in rows.skip(1)) {
            if (kelompokIndex != -1 && r.length > kelompokIndex) {
              kelompokSet.add(r[kelompokIndex].toString());
            }
          }
          kelompokList = ['Semua', ...kelompokSet.where((k) => k.trim().isNotEmpty)];

          setState(() {
            data = rows;
            isLoading = false;
          });
          applyFilter();
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

  void applyFilter() {
    if (data.isEmpty || data[0].isEmpty) {
      filteredData = [];
      return;
    }
    final headers = data[0];
    final kelompokIndex = headers.indexWhere((h) => h.toLowerCase().contains('kelompok'));
    final namaIndex = headers.indexWhere((h) => h.toLowerCase().contains('nama'));
    final nimIndex = headers.indexWhere((h) => h.toLowerCase().contains('nim'));

    filteredData = [
      headers,
      ...data.sublist(1).where((row) {
        final matchKelompok = kelompokFilter == 'Semua' ||
            (kelompokIndex != -1 && row[kelompokIndex].toString() == kelompokFilter);
        final matchSearch = searchQuery.isEmpty ||
            (namaIndex != -1 && row[namaIndex].toString().toLowerCase().contains(searchQuery.toLowerCase())) ||
            (nimIndex != -1 && row[nimIndex].toString().toLowerCase().contains(searchQuery.toLowerCase()));
        return matchKelompok && matchSearch;
      }).toList(),
    ];
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
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
        title: const Text(
          "Data Absensi",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color.fromARGB(255, 228, 255, 229),
          ),
        ),
        backgroundColor: pastelBlue,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,),
          color: Colors.white,
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
      body: Stack(
        children: [
          // Background hutan
          SizedBox.expand(
            child: Image.asset(
              'assets/hutan.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Efek blur
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
          // Konten utama
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      // Filter kelompok
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: kelompokFilter,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            labelText: "Kelompok",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: kelompokList
                              .map((k) => DropdownMenuItem(
                                    value: k,
                                    child: Text(k),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            kelompokFilter = val ?? 'Semua';
                            applyFilter();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Search nama/NIM
                      Expanded(
                        flex: 3,
                        child: TextField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            labelText: "Cari Nama/NIM",
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (val) {
                            searchQuery = val;
                            applyFilter();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredData.isEmpty || filteredData[0].isEmpty
                          ? const Center(child: Text('Tidak ada data'))
                          : Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: DataTable(
                                      headingRowColor: WidgetStateColor.resolveWith(
                                          (states) => pastelBlue.withOpacity(0.3)),
                                      dataRowColor: WidgetStateColor.resolveWith(
                                          (states) => Colors.white.withOpacity(0.85)),
                                      columnSpacing: 24,
                                      columns: filteredData[0]
                                          .map(
                                            (header) => DataColumn(
                                              label: Text(
                                                header.toString(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: pastelPink,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      rows: filteredData.sublist(1).map(
                                        (row) {
                                          return DataRow(
                                            cells: row
                                                .map(
                                                  (cell) => DataCell(
                                                    Text(
                                                      cell.toString(),
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Color.fromARGB(221, 0, 0, 0),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}