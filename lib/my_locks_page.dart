import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_page.dart';

class MyLocksPage extends StatelessWidget {
  const MyLocksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Locks"),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Locks')
              .where('accessible_user', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
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
                  trailing: Icon(
                    lockStatus == "Unlocked" ? Icons.lock_open : Icons.lock,
                    color: lockStatus == "Unlocked" ? Colors.green : Colors.red,
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
                    final newLockRef = FirebaseFirestore.instance.collection('Locks').doc();
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
}
