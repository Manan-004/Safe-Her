import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _messageController = TextEditingController();

  final String supportEmail = "safeher.support@gmail.com";
  final String supportPhone = "1800-123-456";
  final String supportWebsite = "https://www.safeherapp.com/support";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4E9), // BlushTint
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // BACK BUTTON
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      "assets/images/back.png",
                      width: 32,
                      height: 32,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // LOGO
              Image.asset(
                "assets/images/help_support.png",
                width: 100,
                height: 100,
              ),

              const SizedBox(height: 12),

              // TITLE
              const Text(
                "Help / Support",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6A3EA1), // DeepMauve
                ),
              ),

              const SizedBox(height: 24),

              // DESCRIPTION
              const Text(
                "Need help or want to report an issue? We're here for you:",
                style: TextStyle(fontSize: 16, height: 1.4),
              ),

              const SizedBox(height: 24),

              // EMAIL LAYOUT
              GestureDetector(
                onTap: () => launchUrl(Uri.parse("mailto:$supportEmail")),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/images/email_new.png",
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      supportEmail,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // PHONE LAYOUT
              GestureDetector(
                onTap: () => launchUrl(Uri.parse("tel:$supportPhone")),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/images/new_call.png",
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      supportPhone,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // WEBSITE LAYOUT
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(supportWebsite)),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/images/new_link.png",
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      supportWebsite,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // MESSAGE BOX
              Container(
                height: 150,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Describe Your Message Here...",
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6A3EA1), // DeepMauve
                  ),
                  onPressed: submitMessage,
                  child: const Text(
                    "Submit",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // NOTE
              const Text(
                "We respond within 24 hours. Your safety is our priority 💗.",
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // SAME LOGIC AS YOUR KOTLIN FILE (Firebase)
  // ------------------------------------------------------------------
  void submitMessage() async {
    String message = _messageController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a message")),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in")),
      );
      return;
    }

    String uid = user.uid;

    DatabaseReference ref = FirebaseDatabase.instance
        .ref("users")
        .child(uid)
        .child("help_support_messages");

    await ref.push().set({
      "message": message,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Message sent successfully!")),
    );

    Navigator.pop(context);
  }
}
