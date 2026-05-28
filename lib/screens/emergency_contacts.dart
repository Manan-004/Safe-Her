// lib/screens/emergency_contacts.dart
// Conversion of EmergencyContactsActivity.kt -> Flutter
// Logic preserved exactly (Realtime DB listener, add/edit/delete, UI flow).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _rootRef = FirebaseDatabase.instance.ref();

  String? _uid;
  late DatabaseReference _contactsRef;
  StreamSubscription<DatabaseEvent>? _contactsSub;

  // form controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _relationCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  List<EmergencyContact> _contacts = [];
  EmergencyContact? _contactToEdit;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initUserAndListener();
  }

  @override
  void dispose() {
    _contactsSub?.cancel();
    _nameCtrl.dispose();
    _relationCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _initUserAndListener() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      // Mirror Kotlin: Toast + go to MainActivity (here we pop)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first.')));
        Navigator.of(context).pushReplacementNamed('/main'); // ensure route '/main' exists or adjust
      }
      return;
    }

    _uid = currentUser.uid;
    _contactsRef = _rootRef.child('users').child(_uid!).child('emergency_contacts');

    // Set up listener like addValueEventListener
    _contactsSub = _contactsRef.onValue.listen((event) {
      final snapshot = event.snapshot;
      final List<EmergencyContact> list = [];
      if (snapshot.exists && snapshot.children.isNotEmpty) {
        for (final child in snapshot.children) {
          final map = child.value as Map<dynamic, dynamic>?;
          if (map != null) {
            final c = EmergencyContact(
              name: map['name']?.toString(),
              relation: map['relation']?.toString(),
              email: map['email']?.toString(),
              key: child.key,
            );
            list.add(c);
          }
        }
      }
      setState(() {
        _contacts = list;
      });
    }, onError: (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load contacts: ${error.toString()}')));
      }
    });
  }

  void _clearInputFields() {
    _nameCtrl.clear();
    _relationCtrl.clear();
    _emailCtrl.clear();
  }

  Future<void> _saveContact() async {
    final newName = _nameCtrl.text.trim();
    final newRelation = _relationCtrl.text.trim();
    final newEmail = _emailCtrl.text.trim();

    if (newName.isEmpty || newRelation.isEmpty || newEmail.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields')));
      }
      return;
    }

    setState(() => _loading = true);

    if (_contactToEdit != null) {
      // update existing contact (same logic as Kotlin)
      final key = _contactToEdit!.key;
      if (key != null) {
        final updatedContact = {
          'name': newName,
          'relation': newRelation,
          'email': newEmail,
        };
        await _contactsRef.child(key).set(updatedContact).then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact updated successfully')));
          }
          _clearInputFields();
          setState(() {
            _contactToEdit = null;
          });
        }).catchError((e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update contact: ${e.toString()}')));
          }
        });
      }
    } else {
      // add new contact (push)
      final newContact = {
        'name': newName,
        'relation': newRelation,
        'email': newEmail,
      };
      await _contactsRef.push().set(newContact).then((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact added successfully')));
        }
        _clearInputFields();
      }).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add contact: ${e.toString()}')));
        }
      });
    }

    setState(() => _loading = false);
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    if (contact.key == null) return;
    await _contactsRef.child(contact.key!).remove().then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact deleted successfully')));
      }
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete contact: ${e.toString()}')));
      }
    });
  }

  void _editContact(EmergencyContact contact) {
    _nameCtrl.text = contact.name ?? '';
    _relationCtrl.text = contact.relation ?? '';
    _emailCtrl.text = contact.email ?? '';
    setState(() {
      _contactToEdit = contact;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Editing contact: ${contact.name ?? ''}')));
    }
  }

  Widget _buildListItem(BuildContext context, int index) {
    final contact = _contacts[index];
    // initial is position + 1, as in Kotlin adapter: initialTextView.text = (position + 1).toString()
    final initialText = (index + 1).toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        // emulate contact_card_background elevation
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0,1))],
      ),
      child: Row(
        children: [
          // circle initial
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary, // approximate colored circle
            ),
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: 16),
            child: Text(initialText, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),

          // contact details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name?.isNotEmpty == true ? contact.name! : 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6C4B5D))),
                const SizedBox(height: 4),
                Text(contact.relation?.isNotEmpty == true ? contact.relation! : 'N/A', style: const TextStyle(fontSize: 14, color: Color(0xFFFFEBF1))),
                const SizedBox(height: 4),
                Text(contact.email?.isNotEmpty == true ? contact.email! : 'N/A', style: const TextStyle(fontSize: 14, color: Colors.black)),
              ],
            ),
          ),

          // edit and delete icons
          Row(
            children: [
              GestureDetector(
                onTap: () => _editContact(contact),
                child: Image.asset('assets/images/edit_profile.png', width: 24, height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.edit)),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _deleteContact(contact),
                child: Image.asset('assets/images/delete.png', width: 24, height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.delete)),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saveButtonText = _contactToEdit != null ? 'Update Contact' : 'Add Contact';

    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF1), // BlushTint approx
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Image.asset('assets/images/back.png', width: 24, height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.arrow_back)),
                ),
              ),
              const SizedBox(height: 16),

              // logo image
              Image.asset('assets/images/emergency_contact.png', width: 100, height: 100, errorBuilder: (_, __, ___) => const SizedBox()),
              const SizedBox(height: 12),

              const Text('Emergency Contacts', style: TextStyle(fontSize: 24, color: Color(0xFF6C4B5D), fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Saved Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),

              // ListView inside ScrollView -> shrinkWrap + physics NeverScrollable to match nestedScrollingEnabled
              _contacts.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _contacts.length,
                itemBuilder: _buildListItem,
              ),

              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Add New Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),

              // Name
              SizedBox(
                height: 55,
                child: TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Name',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Relation
              SizedBox(
                height: 55,
                child: TextField(
                  controller: _relationCtrl,
                  decoration: InputDecoration(
                    hintText: 'Relation',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Email
              SizedBox(
                height: 55,
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveContact,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C4B5D), // DeepMauve approx
                  ),
                  child: _loading ? const CircularProgressIndicator(color: Colors.white) : Text(saveButtonText, style: const TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Model class (equivalent to Kotlin data class)
class EmergencyContact {
  String? name;
  String? relation;
  String? email;
  String? key;

  EmergencyContact({this.name, this.relation, this.email, this.key});

  factory EmergencyContact.fromMap(Map<dynamic, dynamic> map, String? key) {
    return EmergencyContact(
      name: map['name']?.toString(),
      relation: map['relation']?.toString(),
      email: map['email']?.toString(),
      key: key,
    );
  }
}
