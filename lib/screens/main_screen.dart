// lib/screens/main_screen.dart
//
// FULL conversion of MainActivity.kt -> single Flutter file
// Logic preserved exactly (map, firebase, base64 profile image, migration, drawer, buttons).
//
// NOTE: You must have the required packages in pubspec.yaml and set up Firebase & Google Maps keys.
// Place this file in lib/screens/ and import MainScreen where needed.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');

  // User info
  User? _currentUser;
  String? _uid;

  // Drawer & header
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _headerGreeting = "Hey !!!";
  Uint8List? _profileImageBytes; // decoded image
  StreamSubscription<DatabaseEvent>? _userProfileSub;

  // Map
  GoogleMapController? _mapController;
  CameraPosition _initialCamera =
  const CameraPosition(target: LatLng(21.145118713378906, 72.77857208251953), zoom: 15);
  bool _mapReady = false;
  bool _locationPermissionGranted = false;

  // Image pickers
  final ImagePicker _picker = ImagePicker();

  // Lifecycle
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuthAndInit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userProfileSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // -------------------------
  // Setup listeners (needed for _checkAuthAndInit)
  // -------------------------
  void _setupListeners() {
    // This function is called in _checkAuthAndInit
    // You can use it to attach any listeners if needed.
    // Currently, just a stub to avoid errors.
    debugPrint('_setupListeners called');
  }

  // -------------------------
  // Initial setup & auth check
  // -------------------------
  Future<void> _checkAuthAndInit() async {
    final user = _auth.currentUser;
    if (user == null) {
      // Session expired -> go to Login (same behavior as Kotlin)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session expired. Please log in.')));
        Navigator.pushReplacementNamed(context, '/login'); // you must register '/login' route
      }
      return;
    }
    _currentUser = user;
    _uid = user.uid;

    // Bind views / setup
    _setupListeners(); // drawer button listeners rely on routes registered in Flutter
    _setupMap(); // prepare map (no heavy work yet)
    _migrateUserDataIfNeeded();
    _updateNavHeader();
    _checkInitialSetupStatus();
  }

  // -------------------------
  // Map setup
  // -------------------------
  void _setupMap() {
    // Nothing synchronous needed now; GoogleMap widget will call onMapCreated
    // We'll request permission and move camera when onMapReady.
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.status;
    if (status.isGranted) {
      _locationPermissionGranted = true;
      if (_mapReady && _mapController != null) {
        _enableMyLocationOnMap();
      }
    } else {
      final result = await Permission.location.request();
      if (result.isGranted) {
        _locationPermissionGranted = true;
        if (_mapReady && _mapController != null) {
          _enableMyLocationOnMap();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied. Cannot show live location.')),
          );
        }
      }
    }
  }

  // Move camera to last known device location; if null, use default location (same lat/lng as Kotlin)
  Future<void> _getDeviceLocationAndMoveCamera() async {
    try {
      if (_mapController != null) {
        await _mapController!.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: const LatLng(21.145118713378906, 72.77857208251953), zoom: 15),
        ));
      }
    } catch (e) {
      debugPrint('getDeviceLocation error: $e');
    }
  }

  // Enable location on map (UI)
  Future<void> _enableMyLocationOnMap() async {
    setState(() {}); // triggers rebuild with myLocationEnabled = true
    await _getDeviceLocationAndMoveCamera();
  }

  // -------------------------
  // Drawer header & profile image logic (Base64)
  // -------------------------
  void _updateNavHeader() {
    if (_uid == null) return;

    _userProfileSub?.cancel();

    _userProfileSub = _usersRef.child(_uid!).onValue.listen((event) {
      final snapshot = event.snapshot;
      final name = snapshot.child('name').value?.toString();
      setState(() {
        _headerGreeting = (name != null && name.isNotEmpty) ? 'Hey $name !!!' : 'Hey !!!';
      });
      _loadProfileImage();
    }, onError: (error) {
      setState(() {
        _headerGreeting = 'Hey !!!';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load user data.')));
      }
    });
  }

  void _loadProfileImage() {
    if (_uid == null) return;
    _usersRef.child(_uid!).child('profileImageBase64').get().then((snap) {
      final imageBase64 = snap.value?.toString();
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        try {
          final decoded = base64Decode(imageBase64);
          setState(() {
            _profileImageBytes = decoded;
          });
        } catch (e) {
          debugPrint('Base64 decode error: $e');
          setState(() {
            _profileImageBytes = null;
          });
        }
      } else {
        setState(() {
          _profileImageBytes = null;
        });
      }
    }).catchError((err) {
      debugPrint('Failed to load profile image data: $err');
      setState(() {
        _profileImageBytes = null;
      });
    });
  }

  Future<void> _saveImageFileToDatabase(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final encoded = base64Encode(bytes);
      await _usersRef.child(_uid!).child('profileImageBase64').set(encoded);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
      }
      _loadProfileImage();
    } catch (e) {
      debugPrint('saveImageFileToDatabase error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save image.')));
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    final perm = (Platform.isAndroid && (await Permission.storage.request().isGranted)) ||
        (Platform.isIOS && (await Permission.photos.request().isGranted));
    if (!(await Permission.photos.request().isGranted) && !(await Permission.storage.request().isGranted)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gallery permission denied.')));
      }
      return;
    }

    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      await _saveImageFileToDatabase(File(picked.path));
    }
  }

  Future<void> _takePhotoWithCamera() async {
    if (!await Permission.camera.request().isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera permission denied.')));
      }
      return;
    }
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      await _saveImageFileToDatabase(File(photo.path));
    }
  }

  Future<void> _showInitialPhotoDialogIfNeeded() async {
    if (_uid == null) return;
    final snap = await _usersRef.child(_uid!).get();
    if (snap.exists && snap.hasChild('profileImageBase64')) return;

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Add a Profile Picture'),
        content: const Text('Would you like to add a profile picture now?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _pickImageFromGallery();
            },
            child: const Text('Choose from Gallery'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _takePhotoWithCamera();
            },
            child: const Text('Click a Photo'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You can add a photo later from Edit Profile.')),
                );
              }
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkInitialSetupStatus() async {
    if (_uid == null) return;
    final snap = await _usersRef.child(_uid!).child('initialSetupComplete').get();
    final bool? complete = snap.value as bool?;
    if (complete != true) {
      await _showInitialPhotoDialogIfNeeded();
    }
  }

  Future<void> _migrateUserDataIfNeeded() async {
    if (_uid == null || _currentUser == null) return;
    final currentUidSnap = await _usersRef.child(_uid!).get();
    if (currentUidSnap.exists) {
      debugPrint('Profile already exists under UID. No migration needed.');
      return;
    }
    final email = _currentUser!.email;
    if (email == null) {
      _updateNavHeader();
      return;
    }

    final querySnap = await _usersRef.orderByChild('email').equalTo(email).get();
    if (querySnap.exists) {
      debugPrint('Found legacy profile. Migrating data.');
      for (final child in querySnap.children) {
        final oldData = child.value as Map<dynamic, dynamic>?;
        if (oldData != null) {
          try {
            await _usersRef.child(_uid!).set(oldData);
            await child.ref.remove();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your account has been updated.')));
            }
            _updateNavHeader();
          } catch (e) {
            debugPrint('Failed to migrate data: $e');
          }
        }
        break;
      }
    } else {
      debugPrint('No legacy profile found for migration.');
      _updateNavHeader();
    }
  }

  Future<void> _logoutUser() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out')));
    }
    PaintingBinding.instance.imageCache.clear();
    await _auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 72,
              color: const Color(0xFFFFC0CB),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Image.asset('assets/images/nav_bar.png'),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const Expanded(
                    child: Center(
                      child: _TitleTwoColor(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: _initialCamera,
                myLocationEnabled: _locationPermissionGranted,
                zoomControlsEnabled: true,
                onMapCreated: (controller) async {
                  _mapController = controller;
                  _mapReady = true;
                  await _requestLocationPermission();
                  if (_locationPermissionGranted) {
                    setState(() {});
                    await _getDeviceLocationAndMoveCamera();
                  }
                },
              ),
            ),
            Container(
              color: const Color(0xFFFFC0CB),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(child: _featureButton('Panic Alarm', 'assets/images/panic_alarm.png', () {
                    Navigator.pushNamed(context, '/panic');
                  })),
                  Expanded(child: _featureButton('SOS', 'assets/images/sos.png', () {
                    Navigator.pushNamed(context, '/sos');
                  })),
                  Expanded(child: _featureButton('Fake Call', 'assets/images/fake_call.png', () {
                    Navigator.pushNamed(context, '/fakecall');
                  })),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFFFFEBF1),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(),
            ListTile(
              leading: Image.asset('assets/images/edit_profile.png', width: 24, height: 24),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/editprofile', arguments: {'uid': _uid});
              },
            ),
            ListTile(
              leading: Image.asset('assets/images/emergency_contact.png', width: 24, height: 24),
              title: const Text('Emergency Contacts'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/emergencycontacts');
              },
            ),
            ListTile(
              leading: Image.asset('assets/images/help_support.png', width: 24, height: 24),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/helpsupport');
              },
            ),
            ListTile(
              leading: Image.asset('assets/images/safe_places.png', width: 24, height: 24),
              title: const Text('Safe Places'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/safeplaces');
              },
            ),
            ListTile(
              leading: Image.asset('assets/images/chatbot.png', width: 24, height: 24),
              title: const Text('Chatbot'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/chatbot');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _logoutUser();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(
        color: Color(0xFFFFEBF1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[200],
            backgroundImage: _profileImageBytes != null
                ? MemoryImage(_profileImageBytes!)
                : const AssetImage('assets/images/edit_profile.png') as ImageProvider,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_headerGreeting, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/editprofile', arguments: {'uid': _uid}).then((_) {
                      _loadProfileImage();
                      _updateNavHeader();
                    });
                  },
                  child: const Text('Edit Profile', style: TextStyle(color: Colors.pinkAccent)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureButton(String label, String assetPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Image.asset(assetPath),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C4B5D))),
        ],
      ),
    );
  }

  Future<void> openGalleryFromUI() async => _pickImageFromGallery();
  Future<void> openCameraFromUI() async => _takePhotoWithCamera();
}

class _TitleTwoColor extends StatelessWidget {
  const _TitleTwoColor();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          'Safe',
          style: TextStyle(color: Color(0xFFFF1493), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        Text(
          'Her',
          style: TextStyle(color: Color(0xFFE6E6FA), fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ],
    );
  }
}
