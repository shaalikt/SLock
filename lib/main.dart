import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Firestore Import
import 'home.dart'; // New: Home Page
import 'login.dart'; // Login Page Import
import 'registration.dart'; // Registration Page Import
import 'my_locks_page.dart'; // Core functionality
import './settings_page.dart'; // New: Settings page

// Lock class to represent lock data
class Lock {
  final String lockName;
  final bool lockStatus;
  final String lockID;

  Lock({
    required this.lockName,
    required this.lockStatus,
    required this.lockID,
  });
}

// Main function to initialize Firebase and run the app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAqXW4MjDY5pOnIv9BQz9b5LRHJ82jITVQ",
        authDomain: "smart-lock-application-66a02.firebaseapp.com",
        projectId: "smart-lock-application-66a02",
        storageBucket: "smart-lock-application-66a02.firebasestorage.app",
        messagingSenderId: "75765673184",
        appId: "1:75765673184:web:0345052f444ebc9248f485",
        measurementId: "G-YBYJWP05ZQ",
      ),
    );
    print("Firebase initialized successfully.");
  } catch (e) {
    print("Firebase initialization failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isUserLoggedIn = false;
  bool _firebaseInitialized = false;

  @override
  void initState() {
    super.initState();
    initializeFirebaseAndCheckLogin();
  }

  Future<void> initializeFirebaseAndCheckLogin() async {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyAqXW4MjDY5pOnIv9BQz9b5LRHJ82jITVQ",
          authDomain: "smart-lock-application-66a02.firebaseapp.com",
          projectId: "smart-lock-application-66a02",
          storageBucket: "smart-lock-application-66a02.firebasestorage.app",
          messagingSenderId: "75765673184",
          appId: "1:75765673184:web:0345052f444ebc9248f485",
          measurementId: "G-YBYJWP05ZQ",
        ),
      );
      setState(() {
        _firebaseInitialized = true;
      });

      User? user = FirebaseAuth.instance.currentUser;
      setState(() {
        _isUserLoggedIn = user != null;
      });
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
      setState(() {
        _firebaseInitialized = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Lock Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: _firebaseInitialized
          ? (_isUserLoggedIn ? const MainPage() : const LoginPage())
          : const LoadingScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegistrationPage(),
        '/home': (context) => const HomePage(), // Updated to HomePage
        '/myLocks': (context) => const MyLocksPage(),
        '/settings': (context) =>  SettingsPage(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  // Bottom navigation bar pages
  final List<Widget> _pages = [
    const HomePage(), // Updated: HomePage (Home page content)
    const MyLocksPage(), // Moved locks here
    SettingsPage(), // Settings page
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock),
            label: "My Locks",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Initializing..."),
        centerTitle: true,
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   _HomePageState createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   late String _userUID;
//   late Future<List<Lock>> _locksFuture;
//   Lock? _selectedLock;

//   @override
//   void initState() {
//     super.initState();
//     _userUID = FirebaseAuth.instance.currentUser!.uid;
//     _locksFuture = fetchUserLocks(_userUID);
//   }

//   Future<List<Lock>> fetchUserLocks(String userUID) async {
//     try {
//       QuerySnapshot snapshot = await FirebaseFirestore.instance
//           .collection('locks')
//           .where('assignedUser', isEqualTo: userUID)
//           .get();

//       return snapshot.docs.map((doc) {
//         return Lock(
//           lockName: doc['lockName'],
//           lockStatus: doc['lockStatus'],
//           lockID: doc.id,
//         );
//       }).toList();
//     } catch (e) {
//       print('Error fetching locks: $e');
//       return [];
//     }
//   }

//   void _showLockSelectionDialog(List<Lock> locks) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Select a Lock'),
//           content: SizedBox(
//             width: double.maxFinite,
//             child: ListView.builder(
//               shrinkWrap: true,
//               itemCount: locks.length,
//               itemBuilder: (context, index) {
//                 Lock lock = locks[index];
//                 return ListTile(
//                   title: Text(lock.lockName),
//                   onTap: () {
//                     setState(() {
//                       _selectedLock = lock;
//                     });
//                     Navigator.of(context).pop();
//                   },
//                 );
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Smart Locks"),
//       ),
//       body: FutureBuilder<List<Lock>>(
//         future: _locksFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           List<Lock>? locks = snapshot.data;

//           if (locks == null || locks.isEmpty) {
//             return const Center(child: Text('No locks assigned to you.'));
//           }

//           if (_selectedLock == null) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               _showLockSelectionDialog(locks);
//             });
//           }

//           return _selectedLock != null
//               ? Center(
//                   child: Text(
//                       'Selected Lock: ${_selectedLock!.lockName} (${_selectedLock!.lockStatus ? 'Open' : 'Closed'})'),
//                 )
//               : const SizedBox();
//         },
//       ),
//     );
//   }
// }