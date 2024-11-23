import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    String currentUserUID = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome to Smart Locks"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Debugging: Recent Activity Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Recent Activity",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('locks')
                        .where('userUID', isEqualTo: currentUserUID)
                        .orderBy('timestamp', descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('Error loading data'));
                      }

                      if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                        print("Recent Activity: No data found for userUID: $currentUserUID");
                        return const Center(child: Text('No recent activity'));
                      }

                      var data = snapshot.data!.docs[0]; // Get the first document
                      var lockName = data['lockName'];
                      var status = data['status']; // "locked" or "unlocked"
                      var timestamp = data['timestamp'].toDate().toString();

                      print("Recent Activity: Lock: $lockName, Status: $status, Timestamp: $timestamp");

                      return ListTile(
                        title: Text(lockName),
                        subtitle: Text('Status: $status, Last activity: $timestamp'),
                        leading: Icon(status == 'locked' ? Icons.lock : Icons.lock_open),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Debugging: Quick Stats Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Quick Stats",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('locks')
                        .where('userUID', isEqualTo: currentUserUID)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('Error loading data'));
                      }

                      if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                        print("Quick Stats: No locks found for userUID: $currentUserUID");
                        return const Center(child: Text('No locks found'));
                      }

                      var data = snapshot.data!.docs;
                      print("Quick Stats: Total Locks: ${data.length}");

                      int totalLocks = data.length;
                      int unlockedLocks = data.where((lock) => lock['status'] == 'unlocked').length;

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Card(
                                  color: Colors.blue[50],
                                  child: ListTile(
                                    title: const Text('Total Locks'),
                                    trailing: Text('$totalLocks'),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Card(
                                  color: Colors.green[50],
                                  child: ListTile(
                                    title: const Text('Locks Unlocked'),
                                    trailing: Text('$unlockedLocks'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Debugging: Lock Status Overview Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Lock Status Overview",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('locks')
                        .where('userUID', isEqualTo: currentUserUID)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('Error loading data'));
                      }

                      if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                        print("Lock Status Overview: No data found for userUID: $currentUserUID");
                        return const Center(child: Text('No locks found'));
                      }

                      var data = snapshot.data!.docs;
                      print("Lock Status Overview: ${data.length} locks found");

                      return Column(
                        children: data.map((lock) {
                          var lockName = lock['lockName'];
                          var status = lock['status']; // "locked" or "unlocked"
                          return ListTile(
                            title: Text(lockName),
                            subtitle: Text('Status: $status'),
                            leading: Icon(status == 'locked' ? Icons.lock : Icons.lock_open),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Debugging: Security Alerts Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Security Alerts",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('locks')
                        .where('userUID', isEqualTo: currentUserUID)
                        .where('securityAlert', isEqualTo: true)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('Error loading data'));
                      }

                      if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                        print("Security Alerts: No data found for userUID: $currentUserUID");
                        return const Center(child: Text('No security alerts'));
                      }

                      var data = snapshot.data!.docs[0];
                      var alertMessage = data['alertMessage'];

                      print("Security Alert: $alertMessage");

                      return Card(
                        color: Colors.red[50],
                        child: ListTile(
                          title: const Text('Security Alert'),
                          subtitle: Text(alertMessage),
                          leading: const Icon(Icons.warning, color: Colors.red),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
