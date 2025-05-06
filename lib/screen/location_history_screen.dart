// lib/screen/location_history_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import 'location_detail_screen.dart';

class LocationHistoryScreen extends StatefulWidget {
  @override
  _LocationHistoryScreenState createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<MapEntry<String, Map<String, dynamic>>> _locationEntries = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await _database.child('locations').get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> locationsData =
            snapshot.value as Map<dynamic, dynamic>;

        final List<MapEntry<String, Map<String, dynamic>>> entries =
            locationsData.entries.map((entry) {
          return MapEntry(
            entry.key.toString(),
            Map<String, dynamic>.from(entry.value as Map),
          );
        }).toList();

        entries.sort((a, b) {
          final int timestampA = a.value['timestamp'] as int? ?? 0;
          final int timestampB = b.value['timestamp'] as int? ?? 0;
          return timestampB.compareTo(timestampA);
        });

        setState(() {
          _locationEntries = entries;
          _isLoading = false;
        });
      } else {
        setState(() {
          _locationEntries = [];
          _isLoading = false;
          _errorMessage = 'Không có dữ liệu vị trí';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Đã xảy ra lỗi: ${e.toString()}';
      });
    }
  }

  String _formatTimestamp(int timestamp) {
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch sử truy cập web'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadLocationData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLocationData,
              child: Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_locationEntries.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu vị trí',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLocationData,
      child: ListView.builder(
        itemCount: _locationEntries.length,
        itemBuilder: (context, index) {
          final entry = _locationEntries[index];
          final locationData = entry.value;
          final timestamp = locationData['timestamp'] as int? ?? 0;
          final source = locationData['source'] as String? ?? 'unknown';
          final userAgent = locationData['user_agent'] as String? ?? 'Unknown';

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(_formatTimestamp(timestamp)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nguồn: ${source}'),
                  Text(userAgent.length > 40
                      ? '${userAgent.substring(0, 40)}...'
                      : userAgent),
                ],
              ),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationDetailScreen(
                      locationData: locationData,
                      id: entry.key,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}