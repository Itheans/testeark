import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class SitterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> findAllSitters() async {
    try {
      QuerySnapshot sitterSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'sitter')
          .get();

      List<Map<String, dynamic>> sitters = [];

      for (var doc in sitterSnapshot.docs) {
        // ดึงข้อมูล location
        var locationData = await _getLocationData(doc.id);

        sitters.add({
          'id': doc.id,
          'name': doc['name'],
          'email': doc['email'],
          'photo': doc['photo'],
          'username': doc['username'],
          'location': locationData,
        });
      }

      return sitters;
    } catch (e) {
      throw Exception('ไม่สามารถดึงข้อมูลผู้รับเลี้ยงแมวได้: $e');
    }
  }

  Future<Map<String, dynamic>?> _getLocationData(String userId) async {
    try {
      QuerySnapshot locationSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('locations')
          .get();

      if (locationSnapshot.docs.isNotEmpty) {
        var locationDoc = locationSnapshot.docs.first;
        return {
          'description': locationDoc['description'],
          'lat': locationDoc['lat'],
          'lng': locationDoc['lng'],
          'name': locationDoc['name'],
        };
      }
      return null;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> findNearestSitters({
    required double latitude,
    required double longitude,
    double radiusInKm = 10,
  }) async {
    List<Map<String, dynamic>> allSitters = await findAllSitters();
    List<Map<String, dynamic>> nearestSitters = [];

    for (var sitter in allSitters) {
      if (sitter['location'] != null) {
        double sitterLat = sitter['location']['lat'];
        double sitterLng = sitter['location']['lng'];

        double distance = _calculateDistance(
          latitude,
          longitude,
          sitterLat,
          sitterLng,
        );

        if (distance <= radiusInKm) {
          nearestSitters.add({
            ...sitter,
            'distance': distance.toStringAsFixed(1),
          });
        }
      }
    }

    nearestSitters.sort((a, b) =>
        double.parse(a['distance']).compareTo(double.parse(b['distance'])));

    return nearestSitters;
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}
