import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Locks"),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Locks')
              .where('accessible_user',
                  isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "No locks assigned to you.",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _showAddLockDialog(context);
                      },
                      child: const Text("Add Lock"),
                    ),
                  ],
                ),
              );
            }

            final locks = snapshot.data!.docs;
            return ListView.builder(
              itemCount: locks.length,
              itemBuilder: (context, index) {
                final lock = locks[index];
                final lockStatus = lock['lock status'] ?? 'Unknown';

                return ListTile(
                  title: Text(lock['lock name'] ?? 'Unnamed Lock'),
                  subtitle: Text("Status: $lockStatus"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        lockStatus == "Unlocked"
                            ? Icons.lock_open
                            : Icons.lock,
                        color: lockStatus == "Unlocked"
                            ? Colors.green
                            : Colors.red,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _confirmDeleteLock(context, lock.id);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    _navigateToLockDetails(context, lock);
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddLockDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddLockDialog(BuildContext context) {
    final TextEditingController lockNameController = TextEditingController();
    final auth = FirebaseAuth.instance;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add New Lock"),
          content: TextField(
            controller: lockNameController,
            decoration: const InputDecoration(
              hintText: "Enter lock name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final String lockName = lockNameController.text.trim();
                final String? userUID = auth.currentUser?.uid;

                if (lockName.isNotEmpty && userUID != null) {
                  try {
                    // Add lock to Firestore
                    final newLockRef =
                        FirebaseFirestore.instance.collection('Locks').doc();
                    await newLockRef.set({
                      'lock name': lockName,
                      'lock status': 'Unlocked', // Default status
                      'accessible_user': userUID,
                      'access locks': [], // Empty access log initially
                    });

                    // Update user document
                    await FirebaseFirestore.instance
                        .collection('Users')
                        .doc(userUID)
                        .update({
                      'assigned lock': newLockRef.id, // Add the lock ID to the user
                    });

                    lockNameController.clear(); // Clear the input field
                    Navigator.pop(context);

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Lock '$lockName' added successfully!"),
                        ),
                      );
                    });
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error adding lock: $e")),
                    );
                  }
                }
              },
              child: const Text("Add Lock"),
            ),
          ],
        );
      },
    );
  }

  void _navigateToLockDetails(BuildContext context, QueryDocumentSnapshot lock) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LockDetailsPage(lock: lock),
      ),
    );
  }

  void _confirmDeleteLock(BuildContext context, String lockId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Lock"),
          content: const Text("Are you sure you want to delete this lock?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await _deleteLock(context, lockId);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteLock(BuildContext context, String lockId) async {
    try {
      // Delete lock document from Firestore
      await FirebaseFirestore.instance.collection('Locks').doc(lockId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lock deleted successfully!"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting lock: $e")),
      );
    }
  }
}

class LockDetailsPage extends StatelessWidget {
  final QueryDocumentSnapshot lock;

  const LockDetailsPage({super.key, required this.lock});

  @override
  Widget build(BuildContext context) {
    final lockName = lock['lock name'] ?? 'Unnamed Lock';
    final lockId = lock.id;
    final lockStatus = lock['lock status'] ?? 'Unknown';
    final isUnlocked = lockStatus == "Unlocked";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lock Details"),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFE0F7FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isUnlocked ? Icons.lock_open : Icons.lock,
                            color: isUnlocked ? Colors.green : Colors.red,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            lockName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Lock ID: $lockId",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Status: $lockStatus",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  _toggleLockStatus(context, lockId, lockStatus);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    isUnlocked ? Colors.red : Colors.green,
                  ),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 24.0,
                    ),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                child: Text(
                  isUnlocked ? "Lock" : "Unlock",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLockStatus(
      BuildContext context, String lockId, String currentStatus) async {
    try {
      // Determine the new status
      final newStatus = currentStatus == "Unlocked" ? "Locked" : "Unlocked";

      // Update the lock status in Firestore
      await FirebaseFirestore.instance
          .collection('Locks')
          .doc(lockId)
          .update({'lock status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lock status updated to $newStatus")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating lock status: $e")),
      );
    }
  }
}
