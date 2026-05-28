import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Same as lateinit EditText
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Firebase
  final FirebaseAuth auth = FirebaseAuth.instance;
  final DatabaseReference usersRef =
  FirebaseDatabase.instance.ref().child("users");

  // SIGNUP FUNCTION (exact Kotlin logic)
  void handleSignup() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        username.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    try {
      // Create user account
      UserCredential credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? firebaseUser = credential.user;

      if (firebaseUser != null) {
        // Send verification SAME AS KOTLIN
        await firebaseUser.sendEmailVerification();

        // Save extra data to Realtime DB
        final userProfile = {
          "name": name,
          "email": email,
          "username": username,
          "password": password,
        };

        await usersRef.child(firebaseUser.uid).set(userProfile);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verification email sent!")),
        );

        // Navigate to LoginActivity
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup Failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // SAME BACKGROUND AS android:background="@drawable/gradient_splash_background"
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/gradient_splash_background.png"),
            fit: BoxFit.cover,
          ),
        ),

        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Card(
              elevation: 20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/soft_pink_border.png"),
                    fit: BoxFit.fill,
                  ),
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4A5A5),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 30),

                    // NAME
                    buildInputField(
                      controller: nameController,
                      hint: "Name",
                      icon: "baseline_person_24.png",
                    ),

                    const SizedBox(height: 20),

                    // EMAIL
                    buildInputField(
                      controller: emailController,
                      hint: "Email",
                      icon: "baseline_email_24.png",
                    ),

                    const SizedBox(height: 20),

                    // USERNAME
                    buildInputField(
                      controller: usernameController,
                      hint: "Username",
                      icon: "baseline_person_pin_24.png",
                    ),

                    const SizedBox(height: 20),

                    // PASSWORD
                    buildInputField(
                      controller: passwordController,
                      hint: "Password",
                      icon: "baseline_lock_24.png",
                      obscure: true,
                    ),

                    const SizedBox(height: 30),

                    // SIGN UP BUTTON
                    GestureDetector(
                      onTap: handleSignup,
                      child: Container(
                        height: 60,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image:
                            AssetImage("assets/images/rounded_gradient_button.png"),
                            fit: BoxFit.fill,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        "Already an User ? Login",
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFFB76E79),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // CUSTOM INPUT FIELD (similar to XML EditText + drawableLeft)
  Widget buildInputField({
    required TextEditingController controller,
    required String hint,
    required String icon,
    bool obscure = false,
  }) {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/rounded_edittext.png"),
          fit: BoxFit.fill,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Image.asset(
            "assets/icons/$icon",
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
              ),
              style: const TextStyle(color: Color(0xFF333333), fontSize: 16),
            ),
          )
        ],
      ),
    );
  }
}
