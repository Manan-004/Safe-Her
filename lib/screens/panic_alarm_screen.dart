import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class PanicAlarmPage extends StatefulWidget {
  @override
  _PanicAlarmPageState createState() => _PanicAlarmPageState();
}

class _PanicAlarmPageState extends State<PanicAlarmPage> {
  AudioPlayer? mediaPlayer;

  @override
  void initState() {
    super.initState();
    _playPanicAlarm();
  }

  void _playPanicAlarm() async {
    try {
      mediaPlayer = AudioPlayer();
      await mediaPlayer!.setSource(AssetSource("assets/panic_alarm.mp3"));
      mediaPlayer!.setReleaseMode(ReleaseMode.loop);
      mediaPlayer!.resume();
    } catch (e) {
      print("Error playing panic alarm: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Panic alarm audio not found.")),
      );
    }
  }

  void _stopAndReleaseAlarm() {
    mediaPlayer?.stop();
    mediaPlayer?.dispose();
    mediaPlayer = null;
  }

  @override
  void dispose() {
    _stopAndReleaseAlarm();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFE0E0), // BlushTint equivalent
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Panic Icon
              Container(
                width: 120,
                height: 120,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade100, // placeholder for sos_circle_bg
                ),
                child: Image.asset(
                  "assets/panic_alarm.png",
                  fit: BoxFit.contain,
                ),
              ),

              SizedBox(height: 24),

              // Panic Message
              Text(
                "Panic Alarm Triggered!",
                style: TextStyle(
                  color: Color(0xFFB00020),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 12),

              // Subtext
              Text(
                "Loud alert activated. Emergency attention requested.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 16,
                ),
              ),

              SizedBox(height: 40),

              // Cancel Button
              ElevatedButton(
                onPressed: () {
                  _stopAndReleaseAlarm();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Panic Alarm Cancelled")),
                  );
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFB00020),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  "Cancel Panic",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
