import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_lock/home_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _emailController = TextEditingController(); // Email controller
  final _passwordController = TextEditingController(); // Password controller
  final _displayNameController = TextEditingController(); // Display Name controller

  bool _isLoading = false; // Indicates whether the registration is in progress
  String _errorMessage = ''; // Holds error messages

  @override
  void dispose() {
    // Dispose controllers when not needed
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  // Function to register the user
  Future<void> _registerUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final displayName = _displayNameController.text.trim();

    if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'All fields are required.';
      });
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'displayName': displayName,
        'email': email,
        'assignedLock': null, // Initially, no lock is assigned
      });

      print("User registered successfully: ${userCredential.user!.uid}");

      // Navigate to the Lock Selection Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage()
              //LockSelectionPage(user: FirebaseAuth.instance.currentUser!),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error registering user: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'Enter your display name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _registerUser,
                    child: const Text('Register'),
                  ),
          ],
        ),
      ),
    );
  }
}

// Lock Selection Page
class LockSelectionPage extends StatefulWidget {
  final User user;

  const LockSelectionPage({super.key, required this.user});

  @override
  _LockSelectionPageState createState() => _LockSelectionPageState();
}

class _LockSelectionPageState extends State<LockSelectionPage> {
  String? _selectedLock;

  // Fetch unassigned locks from Firestore
  Stream<List<DocumentSnapshot>> _fetchLocks() {
    return FirebaseFirestore.instance
        .collection('locks')
        .where('accessibleUser', isEqualTo: null)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // Assign the selected lock to the user
  Future<void> _assignLock() async {
    if (_selectedLock == null) {
      print("No lock selected.");
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('locks')
          .doc(_selectedLock)
          .update({
        'accessibleUser': widget.user.uid,
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({
        'assignedLock': _selectedLock,
      });

      print("Lock assigned successfully!");
      Navigator.pop(context); // Navigate back after assigning lock
    } catch (e) {
      print("Error assigning lock: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Lock'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Select a lock to assign to your account:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<DocumentSnapshot>>(
              stream: _fetchLocks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text(
                    'No locks available.',
                    style: TextStyle(fontSize: 14, color: Colors.redAccent),
                  );
                }
                List<DocumentSnapshot> locks = snapshot.data!;
                return DropdownButton<String>(
                  value: _selectedLock,
                  hint: const Text('Select a Lock'),
                  onChanged: (value) {
                    setState(() {
                      _selectedLock = value;
                    });
                  },
                  items: locks.map((lock) {
                    return DropdownMenuItem<String>(
                      value: lock.id,
                      child: Text(lock['lockName'] ?? 'Unnamed Lock'),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _assignLock,
              child: const Text('Assign Lock'),
            ),
          ],
        ),
      ),
    );
  }
}
