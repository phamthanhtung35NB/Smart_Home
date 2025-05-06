import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationHistoryScreen extends StatefulWidget {
  @override
  _LocationHistoryScreenState createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> locations = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchLocationData();
  }

  Future<void> _fetchLocationData() async {
    try {
      final String today = _getFormattedDate(DateTime.now());
      print('📅 Fetching location data for date: $today');

      final QuerySnapshot snapshot = await _firestore
          .collection('location')
          .doc(today)
          .collection('location_entries')
          .get();

      if (snapshot.docs.isEmpty) {
        print('⚠️ No documents found for $today');
        setState(() {
          _errorMessage = 'No data available for this date.';
          _isLoading = false;
        });
        return;
      }

      final List<Map<String, dynamic>> fetchedLocations = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('📍 Document data: $data');
        return data;
      }).toList();

      print('✅ Fetched ${fetchedLocations.length} location entries');

      setState(() {
        locations.addAll(fetchedLocations);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error while fetching location data: $e');
      setState(() {
        _errorMessage = 'Failed to fetch data: $e';
        _isLoading = false;
      });
    }
  }


  String _getFormattedDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}${date.month.toString().padLeft(2, '0')}${date.year}';
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is int) {
      final DateTime date =
      DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    }
    return 'Invalid timestamp';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location History'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : ListView.builder(
        itemCount: locations.length,
        itemBuilder: (context, index) {
          final location = locations[index];
          return ListTile(
            leading: Icon(Icons.location_on, color: Colors.blue),
            title: Text(
                'Lat: ${location['latitude']}, Lng: ${location['longitude']}'),
            subtitle: Text(
                'Accuracy: ${location['accuracy']}m, Source: ${location['source']}'),
            trailing: Text(
              _formatTimestamp(location['timestamp']),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}
