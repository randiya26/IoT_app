import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("/history");

  List<Map<String, dynamic>> _historyData = [];
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  void _fetchHistory() {
    _dbRef.onValue.listen((event) {
      final rawData = event.snapshot.value;

      if (rawData is Map) {
        final List<Map<String, dynamic>> tempList = [];

        rawData.forEach((key, value) {
          if (value is Map) {
            tempList.add({
              "time": key,
              "temperature": (value["temperature"] ?? 0).toDouble(),
              "humidity": (value["humidity"] ?? 0).toDouble(),
              "moisture": (value["moisture"] ?? 0).toDouble(),
              "soilTemperature": (value["soilTemperature"] ?? 0).toDouble(),
            });
          }
        });

        setState(() {
          _historyData = tempList.reversed.toList();
          _dataLoaded = true;
        });
      } else {
        setState(() => _dataLoaded = true);
      }
    });
  }

  /// Format Firebase keys like "20250705065300" or ISO strings into "yyyy-MM-dd HH:mm:ss"
  String _formatTime(String rawTime) {
    try {
      if (rawTime.length >= 14 && RegExp(r'^\d+$').hasMatch(rawTime)) {
        final year = rawTime.substring(0, 4);
        final month = rawTime.substring(4, 6);
        final day = rawTime.substring(6, 8);
        final hour = rawTime.substring(8, 10);
        final minute = rawTime.substring(10, 12);
        final second = rawTime.substring(12, 14);
        return "$year-$month-$day $hour:$minute:$second";
      }

      final dt = DateTime.tryParse(rawTime);
      if (dt != null) {
        return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
      }

      return rawTime;
    } catch (_) {
      return rawTime;
    }
  }

  List<FlSpot> _createSpots(String key) {
    return List.generate(
      _historyData.length,
      (index) => FlSpot(index.toDouble(), _historyData[index][key] ?? 0),
    );
  }

  Widget _buildChart(String title, String key, Color color) {
    final data = _createSpots(key);
    double maxY = data.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 5;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            if (_historyData.isNotEmpty)
              Text(
                "Latest: ${_historyData.last[key].toString()}",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: true),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: (maxY / 5).ceilToDouble(),
                        getTitlesWidget: (value, _) =>
                            Text(value.toInt().toString(), style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (_historyData.length / 4).floorToDouble().clamp(1, double.infinity),
                        getTitlesWidget: (value, _) {
                          int index = value.round();
                          if (index < 0 || index >= _historyData.length) return const SizedBox.shrink();

                          String label = _formatTime(_historyData[index]["time"]);
                          return Text(
                            label.length >= 16 ? label.substring(11) : label,
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  minX: 0,
                  maxX: (_historyData.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data,
                      isCurved: true,
                      color: color,
                      barWidth: 2.5,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    if (_historyData.isEmpty) return const SizedBox.shrink();

    final latest = _historyData.last;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Latest Sensor Readings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildInfoTile("Temperature", latest["temperature"], "°C", Colors.orange),
              _buildInfoTile("Humidity", latest["humidity"], "%", Colors.blue),
              _buildInfoTile("Moisture", latest["moisture"], "%", Colors.brown),
              _buildInfoTile("Soil Temp", latest["soilTemperature"], "°C", Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, dynamic value, String unit, Color color) {
    return Chip(
      backgroundColor: color.withOpacity(0.1),
      label: Text("$label: ${value.toString()}$unit", style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.resolveWith((states) => Colors.green.shade200),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 14,
          ),
          dataRowColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) return Colors.green.shade100;
              return null;
            },
          ),
          columns: const [
            DataColumn(label: Text('Date & Time')),
            DataColumn(label: Text('Temp (°C)')),
            DataColumn(label: Text('Humidity (%)')),
            DataColumn(label: Text('Moisture (%)')),
            DataColumn(label: Text('Soil Temp (°C)')),
          ],
          rows: List.generate(
            _historyData.length,
            (index) {
              final data = _historyData[index];
              final isEvenRow = index % 2 == 0;
              return DataRow(
                color: MaterialStateProperty.all(isEvenRow ? Colors.green.shade50 : Colors.white),
                cells: [
                  DataCell(Text(_formatTime(data['time'] ?? "-"))),
                  DataCell(Text(data['temperature'].toString())),
                  DataCell(Text(data['humidity'].toString())),
                  DataCell(Text(data['moisture'].toString())),
                  DataCell(Text(data['soilTemperature'].toString())),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Sensor Data History"),
        backgroundColor: Colors.green.shade200,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: !_dataLoaded
            ? const Center(child: CircularProgressIndicator())
            : _historyData.isEmpty
                ? const Center(child: Text("No history data found."))
                : ListView(
                    children: [
                      _buildSummaryRow(),
                      _buildChart("Temperature", "temperature", Colors.orange),
                      _buildChart("Humidity", "humidity", Colors.blue),
                      _buildChart("Soil Moisture", "moisture", Colors.brown),
                      _buildChart("Soil Temperature", "soilTemperature", Colors.teal),
                      const SizedBox(height: 20),
                      const Text("Data Table", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildTable(),
                    ],
                  ),
      ),
    );
  }
}
