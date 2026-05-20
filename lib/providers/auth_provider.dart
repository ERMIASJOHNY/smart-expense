import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/activity_log.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _userEmail;
  String? _fullName;
  String? _userName;
  String? _profileImagePath;
  String? _role;

  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _lockoutTimes = {};
  final List<DateTime> _requestTimes = [];

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin =>
      _role == 'admin' || _userEmail == "ermiasdereje24@gmail.com";

  String? get userEmail => _userEmail;
  String? get fullName => _fullName;
  String? get userName => _userName;
  String? get profileImagePath => _profileImagePath;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    // Seed default offline users database if it doesn't exist
    final usersDbJson = await _secureStorage.read(key: 'users_db');
    final initialUsers = {
      'ermiasdereje24@gmail.com': {
        'email': 'ermiasdereje24@gmail.com',
        'password': 'Ermiasdereje@24',
        'fullName': 'ERMIAS DEREJE',
        'userName': 'Ermias',
        'role': 'admin',
      },
      'user@example.com': {
        'email': 'user@example.com',
        'password': 'User@12345',
        'fullName': 'Standard User',
        'userName': 'user',
        'role': 'user',
      }
    };

    if (usersDbJson == null) {
      await _secureStorage.write(
          key: 'users_db', value: jsonEncode(initialUsers));
    } else {
      // If database already exists, merge/upsert the new admin credentials to ensure they are available
      try {
        final Map<String, dynamic> existingUsers =
            Map<String, dynamic>.from(jsonDecode(usersDbJson));
        if (!existingUsers.containsKey('ermiasdereje24@gmail.com')) {
          existingUsers['ermiasdereje24@gmail.com'] =
              initialUsers['ermiasdereje24@gmail.com'];
          await _secureStorage.write(
              key: 'users_db', value: jsonEncode(existingUsers));
          debugPrint('Successfully seeded new admin credentials into existing users database.');
        }
      } catch (e) {
        debugPrint('Error merging initial users: $e');
      }
    }

    final storedToken = await _secureStorage.read(key: 'access_token');
    if (storedToken != null) {
      _isAuthenticated = true;
      _userEmail =
          await _secureStorage.read(key: 'user_email') ?? 'user@example.com';
      _fullName = await _secureStorage.read(key: 'full_name') ?? 'User';
      _profileImagePath = await _secureStorage.read(key: 'profile_image');
      _role = await _secureStorage.read(key: 'role') ?? 'user';
    }
    notifyListeners();

    if (storedToken != null && storedToken.startsWith('offline_token_')) {
      _trySyncOfflineSession();
    }
  }

  Future<void> _trySyncOfflineSession() async {
    try {
      if (_userEmail == null) return;

      final usersDbJson = await _secureStorage.read(key: 'users_db');
      if (usersDbJson == null) return;

      final users = Map<String, dynamic>.from(jsonDecode(usersDbJson));
      if (!users.containsKey(_userEmail)) return;

      final userData = Map<String, dynamic>.from(users[_userEmail]);
      final password = userData['password'];
      final fullName = userData['fullName'];
      final userName = userData['userName'] ?? 'user';
      final profilePic = userData['profileImagePath'];

      await _syncOfflineAccountWithFirebase(
          _userEmail!, password, fullName, userName, profilePic);
    } catch (e) {
      debugPrint('Error in _trySyncOfflineSession: $e');
    }
  }

  Future<void> _syncOfflineAccountWithFirebase(
    String email,
    String password,
    String fullName,
    String userName,
    String? profileImagePath,
  ) async {
    if (Firebase.apps.isEmpty) return; // Skip if Firebase is not initialized
    try {
      // 1. Try to register with Firebase Auth
      UserCredential credential;
      try {
        credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (fe) {
        if (fe.code == 'email-already-in-use') {
          // If already exists in Firebase Auth, just sign in to establish session
          credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      if (credential.user != null) {
        // 2. Sync profile details to Firestore
        await FirebaseFirestore.instance.collection('users').doc(email).set({
          'email': email,
          'fullName': fullName,
          'userName': userName,
          'profileImagePath': profileImagePath,
          'role': email == 'ermiasdereje24@gmail.com' ? 'admin' : 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update local session to be online
        await _secureStorage.write(
            key: 'access_token', value: 'online_token_${credential.user!.uid}');

        _addLog(email, "Firebase Sync Success",
            "Synced offline user account to Firebase successfully.");
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing offline account to Firebase: $e');
    }
  }

  Future<void> _addLog(String email, String action, String details) async {
    debugPrint('Log: $email - $action - $details');
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String fullName,
    required String userName,
    String? profileImagePath,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Try to register with Firebase Auth if online and Firebase is initialized
      try {
        if (Firebase.apps.isNotEmpty) {
          final credential =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (credential.user != null) {
          // Store profile metadata in Firestore
          await FirebaseFirestore.instance.collection('users').doc(email).set({
            'email': email,
            'fullName': fullName,
            'userName': userName,
            'profileImagePath': profileImagePath,
            'role': email == 'ermiasdereje24@gmail.com' ? 'admin' : 'user',
            'createdAt': FieldValue.serverTimestamp(),
          });
          _addLog(email, "Firebase Signup Success",
              "User registered online via Firebase.");
        }
        }
      } on FirebaseAuthException catch (fe) {
        debugPrint('Firebase signup exception: ${fe.code} - ${fe.message}');
        // If it's a duplicate email or other absolute auth error, prevent duplicate local signup
        if (fe.code == 'email-already-in-use') {
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } catch (e) {
        debugPrint(
            'Firebase signup connection issue (offline mode fallback): $e');
      }

      // 2. Register/Cache locally in Secure Storage
      final usersDbJson = await _secureStorage.read(key: 'users_db');
      Map<String, dynamic> users = {};
      if (usersDbJson != null) {
        users = Map<String, dynamic>.from(jsonDecode(usersDbJson));
      }

      if (users.containsKey(email)) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final newUser = {
        'email': email,
        'password': password,
        'fullName': fullName,
        'userName': userName,
        'profileImagePath': profileImagePath,
        'role': email == 'ermiasdereje24@gmail.com' ? 'admin' : 'user',
      };

      users[email] = newUser;
      await _secureStorage.write(key: 'users_db', value: jsonEncode(users));

      // 3. Immediately log the user in locally to avoid redundant slow/failing login network requests
      final role = email == 'ermiasdereje24@gmail.com' ? 'admin' : 'user';
      await _secureStorage.write(
          key: 'access_token',
          value: 'offline_token_${DateTime.now().millisecondsSinceEpoch}');
      await _secureStorage.write(key: 'user_email', value: email);
      await _secureStorage.write(key: 'full_name', value: fullName);
      if (profileImagePath != null) {
        await _secureStorage.write(
            key: 'profile_image', value: profileImagePath);
      }
      await _secureStorage.write(key: 'role', value: role);

      _userEmail = email;
      _fullName = fullName;
      _profileImagePath = profileImagePath;
      _role = role;
      _isAuthenticated = true;

      _failedAttempts[email] = 0;
      _lockoutTimes.remove(email);

      _addLog(email, "Signup direct local login success",
          "User logged in automatically after signup.");

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Offline Signup error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();

    // 1. Rate Limiting Check (Max 5 requests within 10 seconds)
    _requestTimes.removeWhere((time) => now.difference(time).inSeconds > 10);
    if (_requestTimes.length >= 5) {
      _isLoading = false;
      notifyListeners();
      return 'Too many attempts. Please try again in 30 seconds.';
    }
    _requestTimes.add(now);

    // 2. Account Lockout Check
    if (_lockoutTimes.containsKey(email)) {
      final lockoutExpiration = _lockoutTimes[email]!;
      if (now.isBefore(lockoutExpiration)) {
        _isLoading = false;
        notifyListeners();
        return 'Account temporarily locked after 5 failed attempts. Please try again in 30 seconds.';
      } else {
        _lockoutTimes.remove(email);
        _failedAttempts[email] = 0;
      }
    }

    // 3. Try Firebase Auth if online and Firebase is initialized
    if (Firebase.apps.isNotEmpty) {
      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (credential.user != null) {
        // Fetch profile details from Firestore
        String fullName = 'User';
        String? profilePic;
        String role = 'user';

        try {
          final snap = await FirebaseFirestore.instance
              .collection('users')
              .doc(email)
              .get();
          if (snap.exists && snap.data() != null) {
            final data = snap.data()!;
            fullName = data['fullName'] ?? 'User';
            profilePic = data['profileImagePath'];
            role = data['role'] ?? 'user';
          }
        } catch (fsErr) {
          debugPrint('Firestore fetch failed (using defaults): $fsErr');
        }

        // Cache session securely locally
        await _secureStorage.write(
            key: 'access_token', value: 'online_token_${credential.user!.uid}');
        await _secureStorage.write(key: 'user_email', value: email);
        await _secureStorage.write(key: 'full_name', value: fullName);
        if (profilePic != null) {
          await _secureStorage.write(key: 'profile_image', value: profilePic);
        }
        await _secureStorage.write(key: 'role', value: role);

        _userEmail = email;
        _fullName = fullName;
        _profileImagePath = profilePic;
        _role = role;
        _isAuthenticated = true;

        _failedAttempts[email] = 0;
        _lockoutTimes.remove(email);

        _addLog(email, "Firebase Login Success",
            "User successfully authenticated online.");
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } on FirebaseAuthException catch (fe) {
      debugPrint('Firebase login exception: ${fe.code} - ${fe.message}');
      // If credentials wrong or Firebase config fails, check local first before failing
      final usersDbJson = await _secureStorage.read(key: 'users_db');
      if (usersDbJson != null) {
        final users = Map<String, dynamic>.from(jsonDecode(usersDbJson));
        if (users.containsKey(email)) {
            final userData = Map<String, dynamic>.from(users[email]);
            if (userData['password'] == password) {
              // Local authentication matches! Bypasses the online exception
              final userEmail = userData['email'];
              final fullName = userData['fullName'];
              final profilePic = userData['profileImagePath'];
              final role = userData['role'] ?? 'user';

              // Try to sync offline account to Firebase and Firestore
              _syncOfflineAccountWithFirebase(
                userEmail,
                password,
                fullName,
                userData['userName'] ?? 'user',
                profilePic,
              );

              await _secureStorage.write(
                  key: 'access_token',
                  value:
                      'offline_token_${DateTime.now().millisecondsSinceEpoch}');
              await _secureStorage.write(key: 'user_email', value: userEmail);
              await _secureStorage.write(key: 'full_name', value: fullName);
              if (profilePic != null) {
                await _secureStorage.write(
                    key: 'profile_image', value: profilePic);
              }
              await _secureStorage.write(key: 'role', value: role);

              _userEmail = userEmail;
              _fullName = fullName;
              _profileImagePath = profilePic;
              _role = role;
              _isAuthenticated = true;

              _failedAttempts[email] = 0;
              _lockoutTimes.remove(email);

              _addLog(userEmail, "Offline Login Success",
                  "User successfully authenticated locally after Firebase check.");
              _isLoading = false;
              notifyListeners();
              return null;
            }
          }
        }

        final currentAttempts = (_failedAttempts[email] ?? 0) + 1;
        _failedAttempts[email] = currentAttempts;
        if (currentAttempts >= 5) {
          _lockoutTimes[email] = now.add(const Duration(seconds: 30));
        }
        _isLoading = false;
        notifyListeners();
        return 'Invalid email or password';
      } catch (e) {
        debugPrint(
            'Firebase login connection issue (falling back to offline local auth): $e');
      }
    }

    // 4. Fallback to Local Offline Authentication
    try {
      final usersDbJson = await _secureStorage.read(key: 'users_db');
      if (usersDbJson == null) {
        _isLoading = false;
        notifyListeners();
        return 'Invalid email or password';
      }

      final users = Map<String, dynamic>.from(jsonDecode(usersDbJson));
      if (!users.containsKey(email)) {
        final currentAttempts = (_failedAttempts[email] ?? 0) + 1;
        _failedAttempts[email] = currentAttempts;
        if (currentAttempts >= 5) {
          _lockoutTimes[email] = now.add(const Duration(seconds: 30));
        }
        _isLoading = false;
        notifyListeners();
        return 'Invalid email or password';
      }

      final userData = Map<String, dynamic>.from(users[email]);
      if (userData['password'] != password) {
        final currentAttempts = (_failedAttempts[email] ?? 0) + 1;
        _failedAttempts[email] = currentAttempts;
        if (currentAttempts >= 5) {
          _lockoutTimes[email] = now.add(const Duration(seconds: 30));
        }
        _isLoading = false;
        notifyListeners();
        return 'Invalid email or password';
      }

      // Successful local login
      final userEmail = userData['email'];
      final fullName = userData['fullName'];
      final profilePic = userData['profileImagePath'];
      final role = userData['role'] ?? 'user';

      await _secureStorage.write(
          key: 'access_token',
          value: 'offline_token_${DateTime.now().millisecondsSinceEpoch}');
      await _secureStorage.write(key: 'user_email', value: userEmail);
      await _secureStorage.write(key: 'full_name', value: fullName);
      if (profilePic != null) {
        await _secureStorage.write(key: 'profile_image', value: profilePic);
      }
      await _secureStorage.write(key: 'role', value: role);

      _userEmail = userEmail;
      _fullName = fullName;
      _profileImagePath = profilePic;
      _role = role;
      _isAuthenticated = true;

      _failedAttempts[email] = 0;
      _lockoutTimes.remove(email);

      _addLog(userEmail, "Offline Login Success",
          "User successfully authenticated locally.");
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _addLog(email, "Offline Login Attempt (Failed)",
          "Failed to authenticate locally.");
      _isLoading = false;
      notifyListeners();
      debugPrint('Offline Login error: $e');
      return 'Invalid email or password';
    }
  }

  Future<void> updateProfileImage(String path) async {
    try {
      _profileImagePath = path;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile image: $e');
    }
  }

  Future<void> logout() async {
    if (_userEmail != null) {
      await _addLog(_userEmail!, "Logout", "User logged out.");
    }

    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'id_token');
    await _secureStorage.delete(key: 'user_email');
    await _secureStorage.delete(key: 'full_name');
    await _secureStorage.delete(key: 'profile_image');
    await _secureStorage.delete(key: 'role');

    _isAuthenticated = false;
    _userEmail = null;
    _fullName = null;
    _userName = null;
    _profileImagePath = null;
    _role = null;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (_userEmail != null) {
      await deleteUser(_userEmail!);
    }
    await logout();
  }

  Future<bool> resetPassword(String email, String newPassword) async {
    try {
      final usersDbJson = await _secureStorage.read(key: 'users_db');
      if (usersDbJson != null) {
        final users = Map<String, dynamic>.from(jsonDecode(usersDbJson));
        if (users.containsKey(email)) {
          final user = Map<String, dynamic>.from(users[email]);
          user['password'] = newPassword;
          users[email] = user;
          await _secureStorage.write(key: 'users_db', value: jsonEncode(users));
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error resetting password: $e');
    }
    return false;
  }

  // Admin Methods
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final usersDbJson = await _secureStorage.read(key: 'users_db');
      if (usersDbJson != null) {
        final users = Map<String, dynamic>.from(jsonDecode(usersDbJson));
        return users.values.map((u) => Map<String, dynamic>.from(u)).toList();
      }
    } catch (e) {
      debugPrint('Error getting all users: $e');
    }
    return [];
  }

  Future<void> deleteUser(String email) async {
    try {
      final usersDbJson = await _secureStorage.read(key: 'users_db');
      if (usersDbJson != null) {
        final users = Map<String, dynamic>.from(jsonDecode(usersDbJson));
        if (users.containsKey(email)) {
          users.remove(email);
          await _secureStorage.write(key: 'users_db', value: jsonEncode(users));
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error deleting user: $e');
    }
  }

  Future<void> toggleUserRole(String email) async {
    try {
      final usersDbJson = await _secureStorage.read(key: 'users_db');
      if (usersDbJson != null) {
        final users = Map<String, dynamic>.from(jsonDecode(usersDbJson));
        if (users.containsKey(email)) {
          final user = Map<String, dynamic>.from(users[email]);
          user['role'] = user['role'] == 'admin' ? 'user' : 'admin';
          users[email] = user;
          await _secureStorage.write(key: 'users_db', value: jsonEncode(users));

          if (email == _userEmail) {
            _role = user['role'];
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error toggling user role: $e');
    }
  }

  Future<void> toggleUserStatus(String email) async {
    notifyListeners();
  }

  Future<List<ActivityLog>> getAllLogs() async {
    return [];
  }

  Future<void> clearLogs() async {
    notifyListeners();
  }
}
