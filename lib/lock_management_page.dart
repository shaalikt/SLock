import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LockManagementPage extends StatefulWidget {
  const LockManagementPage({super.key});

  @override
  _LockManagementPageState createState() => _LockManagementPageState();
}

class _LockManagementPageState extends State<LockManagementPage> {
  String? _selectedLock; // To hold the selected lock
  bool _loading = false;

  // Fetch available unassigned locks
  Stream<List<DocumentSnapshot>> _fetchLocks() {
    return FirebaseFirestore.instance
        .collection('locks')
        .where('accessibleUser', isEqualTo: null) // Only fetch unassigned locks
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // Create a new lock
  Future<void> _createLock() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in");
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final lockRef = FirebaseFirestore.instance.collection('locks').doc();

      // Create a new lock
      await lockRef.set({
        'lockName': 'New Lock', // Default name, can be changed later
        'accessibleUser': null, // Unassigned initially
        'lockStatus': 'locked', // Default lock status
        'accessLocks': [], // Empty access history
      });

      print("New lock created successfully.");
    } catch (e) {
      print("Error creating lock: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // Assign lock to the current user
  Future<void> _assignLock(String lockId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in");
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('locks').doc(lockId).update({
        'accessibleUser': user.uid,
      });

      print("Lock successfully assigned to user.");
    } catch (e) {
      print("Error assigning lock: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Locks'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _createLock,
              child: _loading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('Create New Lock'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Available Locks:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<DocumentSnapshot>>(
                stream: _fetchLocks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No available locks.',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    );
                  }

                  List<DocumentSnapshot> locks = snapshot.data!;
                  return ListView.builder(
                    itemCount: locks.length,
                    itemBuilder: (context, index) {
                      final lock = locks[index];
                      return ListTile(
                        title: Text(lock['lockName'] ?? 'Unnamed Lock'),
                        trailing: ElevatedButton(
                          onPressed: _loading
                              ? null
                              : () => _assignLock(lock.id),
                          child: const Text('Assign'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
