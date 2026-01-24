import 'package:flutter/material.dart';

class HourlyForecastItem extends StatelessWidget {
  final IconData icon1;
  final String time;
  final String temp;
  const HourlyForecastItem({
    super.key,
    required this.icon1,
    required this.time,
    required this.temp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF333333),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Icon(icon1, size: 32, color: Colors.white),
            SizedBox(height: 20),
            Text(temp, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
