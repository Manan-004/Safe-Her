import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Otp2Screen extends StatefulWidget {
  final String email;   // <-- added

  const Otp2Screen({super.key, required this.email});   // <-- added

  @override
  State<Otp2Screen> createState() => _Otp2ScreenState();
}

class _Otp2ScreenState extends State<Otp2Screen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/gradient_splash_background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 20,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            margin: const EdgeInsets.all(30),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                image: const DecorationImage(
                  image: AssetImage("assets/images/soft_pink_border.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: Image.asset("assets/images/pin.png"),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Email Verification",
                    style: TextStyle(
                      fontSize: 25,
                      color: Color(0xFFD4A5A5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "We've sent a verification link to your email.\n"
                        "Please check your inbox and click the link to verify.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFD4A5A5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 30),

                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Visibility(
                        visible: !isLoading,
                        child: ElevatedButton(
                          onPressed: checkVerification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 80),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "I’ve Verified",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(
                          width: 35,
                          height: 35,
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void checkVerification() async {
    User? user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user logged in!")),
      );
      return;
    }

    setState(() => isLoading = true);

    await user.reload();
    user = _auth.currentUser;

    setState(() => isLoading = false);

    if (user != null && user.emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email Verified!")),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        "/quickStart",
            (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please verify your email first.")),
      );
    }
  }
}
