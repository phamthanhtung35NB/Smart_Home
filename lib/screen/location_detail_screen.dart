// lib/screen/location_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter/services.dart';

import 'package:url_launcher/url_launcher.dart';
class LocationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> locationData;
  final String id;

  LocationDetailScreen({
    required this.locationData,
    required this.id,
  });

  String _formatTimestamp(int timestamp) {
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
  }

// Future<void> _openInMaps(BuildContext context, double lat, double lng) async {
//   final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
//
// }
  Future<void> _openInMaps(BuildContext context, double lat, double lng) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở bản đồ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double latitude = (locationData['latitude'] as num?)?.toDouble() ?? 0;
    final double longitude = (locationData['longitude'] as num?)?.toDouble() ?? 0;
    final double accuracy = (locationData['accuracy'] as num?)?.toDouble() ?? 0;
    final int timestamp = locationData['timestamp'] as int? ?? 0;
    final String userAgent = locationData['user_agent'] as String? ?? 'Unknown';
    final String source = locationData['source'] as String? ?? 'unknown';

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết vị trí'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin cơ bản',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(),
                    _buildInfoRow('ID', id),
                    _buildInfoRow('Thời gian', _formatTimestamp(timestamp)),
                    _buildInfoRow('Nguồn dữ liệu', source),
                  ],
                ),
              ),
            ),

            Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin vị trí',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(),
                    _buildInfoRow('Vĩ độ', latitude.toString()),
                    _buildInfoRow('Kinh độ', longitude.toString()),
                    _buildInfoRow('Độ chính xác', '${accuracy.toStringAsFixed(2)} m'),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.map),
                        label: Text('Xem trên bản đồ'),
                        onPressed: () => _openInMaps(context, latitude, longitude),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin thiết bị',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(),
                    _buildInfoRow('User Agent', userAgent, isMultiLine: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMultiLine = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16),
            textAlign: isMultiLine ? TextAlign.justify : TextAlign.start,
          ),
        ],
      ),
    );
  }
}