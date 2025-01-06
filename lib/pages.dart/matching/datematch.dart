import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

class BookingPage extends StatefulWidget {
  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<DateTime?> _selectedDates = [];

  Future<void> _bookDates() async {
    if (_selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณาเลือกวันที่')),
      );
      return;
    }

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนทำการจอง')),
        );
        return;
      }

      List<Timestamp> bookingDates = _selectedDates
          .where((date) => date != null)
          .map((date) => Timestamp.fromDate(date!))
          .toList();

      await _firestore.collection('bookings').add({
        'ownerId': currentUser.uid,
        'dates': bookingDates,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('จองสำเร็จ')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เลือกวันที่ต้องการฝากเลี้ยง'),
      ),
      body: Column(
        children: [
          Expanded(
            child: CalendarDatePicker2(
              config: CalendarDatePicker2Config(
                calendarType: CalendarDatePicker2Type.multi,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(Duration(days: 365)),
                selectedDayHighlightColor: Colors.blue,
                selectableDayPredicate: (date) {
                  return date.compareTo(
                          DateTime.now().subtract(Duration(days: 1))) >
                      0;
                },
              ),
              value: _selectedDates,
              onValueChanged: (dates) {
                setState(() {
                  _selectedDates = dates;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _selectedDates.isEmpty ? null : _bookDates,
              label: Text('Submit'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
                backgroundColor: Colors.green,
                disabledBackgroundColor: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
