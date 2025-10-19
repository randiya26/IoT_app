import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SensorDataPage extends StatefulWidget {
  final String plantType; //  to receive plant name

  const SensorDataPage({super.key, required this.plantType});

  @override
  State<SensorDataPage> createState() => _SensorDataPageState();
}

class _SensorDataPageState extends State<SensorDataPage> {
  final _dbRef = FirebaseDatabase.instance.ref();

  double temperature = 0.0;
  double humidity = 0.0;
  double soilMoisture = 0.0;
  double soilTemp = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchSensorData();
  }

  void _fetchSensorData() {
    _dbRef.child('soilMonitor').onValue.listen((event) {
      final data = event.snapshot.value;
      print("DATA FROM FIREBASE: $data");

      if (data is Map) {
        setState(() {
          temperature = (data['temperature'] ?? 0).toDouble();
          humidity = (data['humidity'] ?? 0).toDouble();
          soilMoisture = (data['moisture'] ?? 0).toDouble();
          soilTemp = (data['soilTemperature'] ?? 0).toDouble();
        });
      } else {
        print("Unexpected format: $data");
      }
    });
  }

  // 🔍 Helper to generate warning message
  List<String> getAlerts() {
    List<String> alerts = [];

    if (widget.plantType == "Rose") {
      if (temperature < 18 || temperature > 26) alerts.add("Air temperature not ideal for Rose");
      if (humidity < 60 || humidity > 70) alerts.add("Humidity out of ideal range for Rose");
      if (soilMoisture < 60 || soilMoisture > 70) alerts.add("Soil moisture too low/high for Rose");
      if (soilTemp < 20 || soilTemp > 25) alerts.add("Soil temperature not ideal for Rose");
    } else if (widget.plantType == "Lily") {
      if (temperature < 18 || temperature > 24) alerts.add("Air temperature not ideal for Lily");
      if (humidity < 40 || humidity > 60) alerts.add("Humidity out of ideal range for Lily");
      if (soilMoisture < 50 || soilMoisture > 60) alerts.add("Soil moisture too low/high for Lily");
      if (soilTemp < 15 || soilTemp > 20) alerts.add("Soil temperature not ideal for Lily");
    }

    return alerts;
  }

  Widget _buildStatCard(String title, double value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Text(
                "$value $unit",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alerts = getAlerts(); // 🔔 Get list of alerts

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F7),
      appBar: AppBar(
        backgroundColor: Colors.green.shade100,
        title: Text('${widget.plantType} Measurements', style: const TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔴 Show alerts if any
            if (alerts.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: alerts.map((msg) => Text("⚠️ $msg", style: const TextStyle(color: Colors.red))).toList(),
                ),
              ),

            _buildStatCard("Temperature", temperature, "°C", Icons.thermostat, Colors.orange),
            const SizedBox(height: 16),
            _buildStatCard("Humidity", humidity, "%", Icons.water_drop, Colors.blue),
            const SizedBox(height: 16),
            _buildStatCard("Soil Moisture", soilMoisture, "%", Icons.grass, Colors.brown),
            const SizedBox(height: 16),
            _buildStatCard("Soil Temp", soilTemp, "°C", Icons.thermostat_auto, Colors.teal),
          ],
        ),
      ),
    );
  }
}
