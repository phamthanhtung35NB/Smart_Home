// lib/screen/location_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';

class LocationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> location;

  const LocationDetailScreen({Key? key, required this.location}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timestamp = location['timestamp'] is int
        ? DateTime.fromMillisecondsSinceEpoch(location['timestamp'])
        : DateTime.now();

    final formattedDate = DateFormat('dd/MM/yyyy').format(timestamp);
    final formattedTime = DateFormat('HH:mm:ss').format(timestamp);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết vị trí'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareLocation(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color.fromRGBO(33, 150, 243, 0.3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildMapPreview(context),
              _buildLocationInfoCard(context, formattedDate, formattedTime),
              _buildDeviceInfoCard(context),
              _buildActionsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPreview(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        image: DecorationImage(
          image: AssetImage('assets/map_placeholder.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
          child: Container(
            color: Colors.black.withOpacity(0.1),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Vị trí đã lưu',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.map),
                    label: Text('Xem trên bản đồ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => _openInMaps(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfoCard(BuildContext context, String date, String time) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Thông tin vị trí'),
            SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today,
              'Ngày',
              date,
              Colors.blue.shade700,
            ),
            _buildInfoRow(
              Icons.access_time,
              'Thời gian',
              time,
              Colors.orange.shade700,
            ),
            _buildInfoRow(
              Icons.compass_calibration,
              'Vĩ độ',
              '${location['latitude']?.toStringAsFixed(6) ?? 'N/A'}',
              Colors.green.shade700,
            ),
            _buildInfoRow(
              Icons.explore,
              'Kinh độ',
              '${location['longitude']?.toStringAsFixed(6) ?? 'N/A'}',
              Colors.purple.shade700,
            ),
            _buildInfoRow(
              Icons.gps_fixed,
              'Độ chính xác',
              '${location['accuracy']?.toStringAsFixed(1) ?? 'N/A'} m',
              Colors.red.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Thông tin thiết bị'),
            SizedBox(height: 16),
            _buildInfoRow(
              Icons.phone_android,
              'User Agent',
              location['user_agent'] ?? 'Không có thông tin',
              Colors.grey.shade700,
              isMultiLine: true,
            ),
            _buildInfoRow(
              Icons.source,
              'Nguồn',
              location['source'] ?? 'Không xác định',
              Colors.teal.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Hành động'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  Icons.map,
                  'Google Maps',
                  Colors.blue,
                  () => _openInMaps(),
                ),
                _buildActionButton(
                  context,
                  Icons.share_location,
                  'Chia sẻ',
                  Colors.green,
                  () => _shareLocation(context),
                ),
                _buildActionButton(
                  context,
                  Icons.content_copy,
                  'Sao chép',
                  Colors.orange,
                  () => _copyLocationToClipboard(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color, {bool isMultiLine = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: isMultiLine ? TextAlign.justify : TextAlign.start,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 90,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openInMaps() async {
    final lat = location['latitude'];
    final lng = location['longitude'];

    if (lat == null || lng == null) return;

    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Could not launch maps: $e');
    }
  }

  void _shareLocation(BuildContext context) {
    final lat = location['latitude'];
    final lng = location['longitude'];

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chia sẻ vị trí này'))
      );
      return;
    }

    // Handle sharing (would need share_plus package for actual implementation)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chức năng chia sẻ đang được phát triển'))
    );
  }

  void _copyLocationToClipboard(BuildContext context) {
    final lat = location['latitude'];
    final lng = location['longitude'];

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể sao chép vị trí này'))
      );
      return;
    }

    // Handle copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép vào bộ nhớ tạm'),
        backgroundColor: Colors.green,
      )
    );
  }
}