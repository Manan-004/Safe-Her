// lib/screens/edit_profile.dart
//
// Exact Flutter conversion of EditProfileActivity.kt
// Logic preserved: load profile, edit fields, pick/capture image, save Base64 to RTDB,
// delete photo, update password, disable email editing, back button behavior.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img_pkg;
import 'dart:typed_data';


class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref().child('users');

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  String? _uid;
  Uint8List? _profileBytes; // decoded image bytes to display
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initUserAndLoad();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _initUserAndLoad() async {
    final user = _auth.currentUser;
    if (user == null) {
      // Mirror Kotlin: show toast and finish
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not authenticated.')));
        Navigator.of(context).pop();
      }
      return;
    }
    _uid = user.uid;
    _emailCtrl.text = user.email ?? '';
    await _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (_uid == null) return;
    try {
      final snap = await _db.child(_uid!).get();
      if (!snap.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User data not found.')));
        }
        return;
      }

      final data = snap.value as Map<dynamic, dynamic>?;

      final name = data?['name']?.toString();
      final username = data?['username']?.toString();
      final imageBase64 = data?['profileImageBase64']?.toString();

      if (name != null) _nameCtrl.text = name;
      // email from FirebaseAuth should be used and is shown as disabled; keep it
      if (username != null) _usernameCtrl.text = username;

      if (imageBase64 != null && imageBase64.isNotEmpty) {
        try {
          final decoded = base64Decode(imageBase64);
          setState(() {
            _profileBytes = decoded;
          });
        } catch (e) {
          // invalid base64 — fallback to asset
          debugPrint('Base64 decode invalid: $e');
          setState(() => _profileBytes = null);
        }
      } else {
        setState(() => _profileBytes = null);
      }
    } catch (e) {
      debugPrint('Failed to load user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load user data.')));
      }
    }
  }

  // -------------------------
  // Image handling
  // -------------------------
  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose a Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(ctx).pop();
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _requestGalleryPermissionIfNeeded() async {
    if (Platform.isAndroid) {
      // handle Android storage / photos permission differences using permission_handler
      final status = await Permission.storage.status;
      if (status.isGranted) return true;
      final req = await Permission.storage.request();
      return req.isGranted;
    } else {
      final status = await Permission.photos.status;
      if (status.isGranted) return true;
      final req = await Permission.photos.request();
      return req.isGranted;
    }
  }

  Future<void> _pickFromGallery() async {
    final ok = await _requestGalleryPermissionIfNeeded();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gallery permission denied.')));
      }
      return;
    }

    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      await _processPickedFile(File(file.path));
    }
  }

  Future<void> _takePhoto() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No camera app found or permission denied.')));
      }
      return;
    }

    final XFile? file = await _picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      await _processPickedFile(File(file.path));
    }
  }

  // This mirrors Kotlin's saveImageToDatabase(bitmap) which compresses to JPEG @25%
  Future<void> _processPickedFile(File file) async {
    setState(() => _loading = true);
    try {
      final bytes = await file.readAsBytes();

      // Re-encode as JPEG at 25% quality to match Kotlin compression
      // Use package:image for re-encoding
      try {
        final decodedImage = img_pkg.decodeImage(bytes);
        if (decodedImage != null) {
          final jpg = img_pkg.encodeJpg(decodedImage, quality: 25);
          final base64Str = base64Encode(jpg);
          await _db.child(_uid!).child('profileImageBase64').set(base64Str);
          setState(() {
            _profileBytes = Uint8List.fromList(jpg);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
          }
        } else {
          // fallback: store raw bytes base64
          final base64Str = base64Encode(bytes);
          await _db.child(_uid!).child('profileImageBase64').set(base64Str);
          setState(() {
            _profileBytes = bytes;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
          }
        }
      } catch (e) {
        // if image package fails, fallback to raw bytes
        final base64Str = base64Encode(bytes);
        await _db.child(_uid!).child('profileImageBase64').set(base64Str);
        setState(() {
          _profileBytes = bytes;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
        }
      }
    } catch (e) {
      debugPrint('Image processing failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image processing failed.')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteProfilePhoto() async {
    if (_uid == null) return;
    try {
      await _db.child(_uid!).child('profileImageBase64').remove();
      setState(() {
        _profileBytes = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo deleted.')));
      }
    } catch (e) {
      debugPrint('Failed to delete photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete photo.')));
      }
    }
  }

  // -------------------------
  // Save profile changes (name, username) and update password if provided
  // -------------------------
  Future<void> _saveProfileChanges() async {
    final name = _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final newPassword = _passwordCtrl.text.trim();

    if (name.isEmpty || username.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Username are required.')));
      }
      return;
    }

    setState(() => _loading = true);

    try {
      await _db.child(_uid!).child('name').set(name);
      await _db.child(_uid!).child('username').set(username);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
      }

      if (newPassword.isNotEmpty) {
        await _updatePassword(newPassword);
      } else {
        // setResult(RESULT_OK) and finish() in Kotlin -> here pop with result
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Failed to save profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save profile.')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not authenticated.')));
      }
      return;
    }

    try {
      await user.updatePassword(newPassword);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!')));
      }
    } catch (e) {
      debugPrint('Failed to update password: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update password. Please re-login to update.')));
      }
    } finally {
      // In Kotlin they call setResult(RESULT_OK) and finish() after update attempt.
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  // -------------------------
  // UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF1), // BlushTint approximation
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Image.asset(
                        'assets/images/back.png',
                        width: 32,
                        height: 32,
                        errorBuilder: (_, __, ___) => const Icon(Icons.arrow_back),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Profile image
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _profileBytes != null
                          ? MemoryImage(_profileBytes!)
                          : const AssetImage('assets/images/edit_profile.png') as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Edit + Delete row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Image.asset('assets/images/edit.png', width: 24, height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.edit)),
                              const SizedBox(width: 8),
                              const Text('Edit', style: TextStyle(fontSize: 16, color: Color(0xFF6C4B5D))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      InkWell(
                        onTap: _deleteProfilePhoto,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Image.asset('assets/images/delete.png', width: 24, height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.delete)),
                              const SizedBox(width: 8),
                              const Text('Delete', style: TextStyle(fontSize: 16, color: Color(0xFF6C4B5D))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  const Center(
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(fontSize: 24, color: Color(0xFF6C4B5D), fontWeight: FontWeight.w600),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Full Name
                  _buildTextField(controller: _nameCtrl, hint: 'Full Name'),

                  const SizedBox(height: 16),

                  // Email (disabled)
                  _buildTextField(controller: _emailCtrl, hint: 'New Email', enabled: false),

                  const SizedBox(height: 16),

                  // Username
                  _buildTextField(controller: _usernameCtrl, hint: 'Username'),

                  const SizedBox(height: 16),

                  // Password
                  _buildTextField(controller: _passwordCtrl, hint: 'New Password', obscure: true),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _loading ? null : _saveProfileChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C4B5D), // DeepMauve approx
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),

            // Optional floating loader overlay (keeps UX like Kotlin's Toasts + progress indicators)
            if (_loading)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, bool enabled = true, bool obscure = false}) {
    return SizedBox(
      height: 55,
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscure,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
        style: const TextStyle(color: Colors.black, fontSize: 16),
      ),
    );
  }
}
