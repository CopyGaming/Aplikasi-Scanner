import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LihatDataPage extends StatefulWidget {
  const LihatDataPage({super.key});

  @override
  _LihatDataPageState createState() => _LihatDataPageState();
}

class _LihatDataPageState extends State<LihatDataPage> {
  List<List<dynamic>> data = [];
  bool isLoading = true;

  // URL Google Sheets JSON (via opensheet.elk.sh)
  final String spreadsheetUrl = 'https://opensheet.elk.sh/1_z8Aw5EW3NAOw-JXaq1eHURTEqUVj_1HGSByP5Keo5Q/Absen%20Scan';

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse(spreadsheetUrl));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Ambil semua baris sebagai list of map
        List<List<dynamic>> rawData = List<List<dynamic>>.from(
          jsonData.map((row) => row.values.toList()),
        );

        // Ambil header
        final header = rawData.isNotEmpty ? rawData.first : [];

        // Filter hanya baris yang sesuai panjang header
        final validData = rawData.where((row) => row.length == header.length).toList();

        setState(() {
          data = validData;
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Data Absensi")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data.isEmpty
              ? const Center(child: Text('Tidak ada data'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: data[0]
                        .map((header) => DataColumn(label: Text(header.toString())))
                        .toList(),
                    rows: data.sublist(1).map((row) {
                      return DataRow(
                        cells: row
                            .map((cell) => DataCell(Text(cell.toString())))
                            .toList(),
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}