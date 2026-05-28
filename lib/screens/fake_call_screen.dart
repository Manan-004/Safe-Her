import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:audioplayers/audioplayers.dart';

class FakeCallPage extends StatefulWidget {
  @override
  _FakeCallPageState createState() => _FakeCallPageState();
}

class _FakeCallPageState extends State<FakeCallPage> {
  String callerName = "Unknown Caller";
  String callerNumber = "N/A";
  bool isCallAnswered = false;

  AudioPlayer? ringtonePlayer;
  AudioPlayer? voicePlayer;
  String uid = "";

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  void _checkUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("You must be logged in.")));
      Navigator.of(context).pop();
      return;
    }
    uid = user.uid;
    _fetchFakeCallSettings();
    _playRingtone();

    // Auto-decline after 20 seconds
    Timer(Duration(seconds: 20), () {
      if (!isCallAnswered) {
        _stopRingtone();
        _logFakeCall("Missed (Timeout)");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Missed call")));
        _goToDashboard();
      }
    });
  }

  void _fetchFakeCallSettings() async {
    DatabaseReference ref =
    FirebaseDatabase.instance.ref("users/$uid/fake_call_settings");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        callerName = data['callerName'] ?? "Private Number";
        callerNumber = data['callerNumber'] ?? "N/A";
      });
      print("Fake call settings loaded: $callerName");
    } else {
      print("Failed to load fake call settings.");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to load settings")));
      setState(() {
        callerName = "Private Number";
      });
    }
  }

  void _playRingtone() async {
    try {
      ringtonePlayer = AudioPlayer();
      await ringtonePlayer!.setSource(AssetSource("assets/ringtone.mp3"));
      ringtonePlayer!.setReleaseMode(ReleaseMode.loop);
      ringtonePlayer!.resume();
    } catch (e) {
      print("Error playing ringtone: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ringtone audio not found.")));
    }
  }

  void _stopRingtone() {
    ringtonePlayer?.stop();
    ringtonePlayer?.dispose();
    ringtonePlayer = null;
  }

  void _playVoiceAudio() async {
    try {
      voicePlayer = AudioPlayer();
      await voicePlayer!.setSource(AssetSource("assets/fake_call.mp3"));
      voicePlayer!.setReleaseMode(ReleaseMode.stop);
      voicePlayer!.resume();
    } catch (e) {
      print("Error playing fake call audio: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Fake call audio not found.")));
    }
  }

  void _stopVoiceAudio() {
    voicePlayer?.stop();
    voicePlayer?.dispose();
    voicePlayer = null;
  }

  void _logFakeCall(String status) {
    final log = {
      "status": status,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      "callerName": callerName,
      "callerNumber": callerNumber,
    };
    FirebaseDatabase.instance
        .ref("users/$uid/fake_call_logs")
        .push()
        .set(log);
  }

  void _goToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DashboardPage()), // Your main page
    );
  }

  void _onAnswer() {
    _stopRingtone();
    setState(() {
      isCallAnswered = true;
    });
    _playVoiceAudio();
    _logFakeCall("Answered");
  }

  void _onDecline() {
    _stopRingtone();
    _logFakeCall("Declined");
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Call declined")));
    _goToDashboard();
  }

  void _onEndCall() {
    _stopVoiceAudio();
    _logFakeCall("Ended");
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Call ended")));
    _goToDashboard();
  }

  @override
  void dispose() {
    _stopRingtone();
    _stopVoiceAudio();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 100),
            Text(callerName,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Text("Incoming Call",
                style: TextStyle(color: Colors.white, fontSize: 16)),
            SizedBox(height: 24),
            if (isCallAnswered)
              Text("Call in progress...",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!isCallAnswered)
                  IconButton(
                    icon: Image.asset("assets/accept_call.png"),
                    iconSize: 80,
                    onPressed: _onAnswer,
                  ),
                if (!isCallAnswered)
                  IconButton(
                    icon: Image.asset("assets/decline_call.png"),
                    iconSize: 80,
                    onPressed: _onDecline,
                  ),
                if (isCallAnswered)
                  IconButton(
                    icon: Image.asset("assets/decline_call.png"),
                    iconSize: 80,
                    onPressed: _onEndCall,
                  ),
              ],
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Replace with your actual dashboard/main page
class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text("Dashboard")));
  }
}
