import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart' as loc; // aliased to avoid conflict
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class SosPage extends StatefulWidget {
  @override
  _SosPageState createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<String> emergencyEmails = [];
  User? currentUser;
  bool isSending = false;

  File? capturedPhoto;
  loc.LocationData? currentLocation;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You must be logged in to use SOS.")),
        );
        Navigator.of(context).pop();
      });
    } else {
      fetchEmergencyContacts();
    }
  }

  void fetchEmergencyContacts() async {
    final uid = currentUser!.uid;
    DatabaseReference ref =
    FirebaseDatabase.instance.ref("users/$uid/emergency_contacts");

    final snapshot = await ref.get();
    if (snapshot.exists) {
      emergencyEmails.clear();
      for (var child in snapshot.children) {
        final email = child.child("email").value;
        if (email != null && (email as String).isNotEmpty) {
          emergencyEmails.add(email);
        }
      }
      if (emergencyEmails.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("No emergency emails configured.")));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Emergency contacts loaded successfully.")));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("No emergency emails found.")));
    }
  }

  Future<void> startSosSequence() async {
    if (emergencyEmails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No emergency contacts found. Please add them.")),
      );
      return;
    }

    setState(() {
      isSending = true;
    });

    await _capturePhoto();
    await _getLocation();
    await _sendEmail();

    setState(() {
      isSending = false;
    });
  }

  Future<void> _capturePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      capturedPhoto = File(pickedFile.path);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("SOS canceled.")));
    }
  }

  Future<void> _getLocation() async {
    try {
      final loc.Location location = loc.Location(); // use alias

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return;
      }

      loc.PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) return;
      }

      currentLocation = await location.getLocation();
    } catch (e) {
      debugPrint('Failed to get location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not get location. Please try again.")),
      );
    }
  }

  Future<void> _sendEmail() async {
    final smtpServer = SmtpServer(
      'smtp-relay.brevo.com',
      username: '939aa1001@smtp-brevo.com',
      password:
      'password: 'YOUR_SMTP_PASSWORD',',
      port: 587,
    );

    final recipients = emergencyEmails.where((e) => e != "kingpin2432005@gmail.com").toList();

    final locationLink = currentLocation != null
        ? "http://maps.google.com/maps?q=${currentLocation!.latitude},${currentLocation!.longitude}"
        : "Location not available. Please try to call me.";

    final message = Message()
      ..from = Address('kingpin2432005@gmail.com', 'Safe Her App')
      ..recipients.addAll(recipients)
      ..subject = '🚨 Emergency SOS Alert from Safe Her'
      ..text =
          "I need your help urgently!\n\nMy current location is:\n$locationLink\n\n(Sent via Safe Her App)";

    if (capturedPhoto != null) {
      message.attachments.add(FileAttachment(capturedPhoto!)
        ..location = Location.inline // this is mailer's Location
        ..fileName = 'sos_photo.jpg');
    }

    try {
      await send(message, smtpServer);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("SOS Email Sent Successfully!")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to send email: $e")));
    } finally {
      capturedPhoto?.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF3E9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              SizedBox(height: 24),
              Text(
                "Emergency SOS",
                style: TextStyle(
                  color: Color(0xFFD32F2F),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Click below to send your live location",
                style: TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 32),
              Image.asset(
                "assets/sos.png",
                width: 140,
                height: 140,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: isSending ? null : startSosSequence,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFD32F2F),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  isSending ? "Sending..." : "Send SOS",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Your emergency contacts will be alerted",
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
