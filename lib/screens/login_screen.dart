// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'signup_screen.dart';
import 'otp2.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _usersRef =
  FirebaseDatabase.instance.ref().child('users');

  bool _isLoading = false;

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateUsername() {
    if (usernameController.text.trim().isEmpty) {
      // show inline error using FormField validator instead of setting .error like Android,
      // but to keep behaviour close we also show a Snack and return false
      _showSnack("Username cannot be empty");
      return false;
    }
    return true;
  }

  bool _validatePassword() {
    if (passwordController.text.trim().isEmpty) {
      _showSnack("Password cannot be empty");
      return false;
    }
    return true;
  }

  Future<void> _checkUserAndLogin() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      // Query: orderByChild("username").equalTo(username)
      final query = _usersRef.orderByChild('username').equalTo(username);
      final snapshot = await query.get();

      if (snapshot.exists) {
        // snapshot.children corresponds to each matched user
        for (final child in snapshot.children) {
          final dbPassword = child.child('password').value?.toString();
          final dbEmail = child.child('email').value?.toString();

          if (dbPassword != null && dbPassword == password) {
            if (dbEmail != null) {
              try {
                final credential = await _auth.signInWithEmailAndPassword(
                  email: dbEmail,
                  password: password,
                );

                // Login successful
                _showSnack("Login successful!");

                // Navigate to Otp2 (same as Kotlin: pass email with intent)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Otp2Screen(email: dbEmail),
                  ),
                );
                setState(() => _isLoading = false);
                return;
              } on FirebaseAuthException catch (e) {
                _showSnack("Authentication failed: ${e.message}");
                setState(() => _isLoading = false);
                // Optionally print to console like Log.e
                // debugPrint("FirebaseAuth Sign-In Failed: $e");
                return;
              } catch (e) {
                _showSnack("Authentication failed: $e");
                setState(() => _isLoading = false);
                return;
              }
            } else {
              // No email in DB — same behavior would have failed in Kotlin too
              _showSnack("User email not found in database.");
              setState(() => _isLoading = false);
              return;
            }
          } else {
            // Invalid password
            _showSnack("Invalid Password");
            // keep focus on password field
            FocusScope.of(context).requestFocus(FocusNode());
            setState(() => _isLoading = false);
            return;
          }
        }
      } else {
        // No user found
        _showSnack("User does not exist");
        setState(() => _isLoading = false);
        return;
      }
    } catch (e) {
      _showSnack("Database error: $e");
      // debugPrint("Database error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The UI tries to mirror your XML: background, CardView, rounded inputs, icons, and a button
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // same background as android:background="@drawable/gradient_splash_background"
          image: DecorationImage(
            image: AssetImage('assets/images/gradient_splash_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Card(
              elevation: 20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  // this mirrors android:background="@drawable/soft_pink_border"
                  image: DecorationImage(
                    image: AssetImage('assets/images/soft_pink_border.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4A5A5),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Username field
                    _buildInputField(
                      controller: usernameController,
                      hint: 'Username',
                      iconPath: 'assets/icons/baseline_person_pin_24.png',
                      obscure: false,
                    ),

                    const SizedBox(height: 16),

                    // Password field
                    _buildInputField(
                      controller: passwordController,
                      hint: 'Password',
                      iconPath: 'assets/icons/baseline_lock_24.png',
                      obscure: true,
                    ),

                    const SizedBox(height: 24),

                    // Login button (mirrors rounded_gradient_button)
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                          if (_validateUsername() && _validatePassword()) {
                            _checkUserAndLogin();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.zero,
                          // Use a decoration image to exactly mimic rounded_gradient_button if you provided an asset
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            image: const DecorationImage(
                              image: AssetImage(
                                  'assets/images/rounded_gradient_button.png'),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                                : const Text(
                              'Login',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: () {
                        // navigate to SignupActivity
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignupScreen()),
                        );
                      },
                      child: const Text(
                        "Not Yet Registered ? Sign Up",
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFFA87C88),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required String iconPath,
    bool obscure = false,
  }) {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/rounded_edittext.png'),
          fit: BoxFit.fill,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Image.asset(iconPath, width: 24, height: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
              ),
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
