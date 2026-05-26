import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_log.dart';
import 'package:uuid/uuid.dart';

class AuthProvider extends ChangeNotifier {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _userEmail;
  String? _fullName;
  String? _userName;
  String? _profileImagePath;
  String? _role;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  
  bool get isAdmin => _role == 'admin' || _userEmail == "ermiasdereje24@gmail.com" || _userEmail == "admin@admin.com";
  
  String? get userEmail => _userEmail;
  String? get fullName => _fullName;
  String? get userName => _userName;
  String? get profileImagePath => _profileImagePath;

  AuthProvider() {
    _auth.authStateChanges().listen((fb_auth.User? user) {
      if (user != null) {
        _userEmail = user.email;
        _isAuthenticated = true;
        _loadUserProfile(user.uid);
      } else {
        _isAuthenticated = false;
        _userEmail = null;
        _fullName = null;
        _userName = null;
        _profileImagePath = null;
        _role = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _fullName = data['fullName'];
        _userName = data['userName'];
        _profileImagePath = data['profileImagePath'];
        _role = data['role'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> _addLog(String email, String action, String details) async {
    try {
      await _firestore.collection('activity_logs').add({
        'id': const Uuid().v4(),
        'userEmail': email,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
        'details': details,
      });
    } catch (e) {
      debugPrint('Error adding activity log: $e');
    }
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
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        final role = (email == "ermiasdereje24@gmail.com" || email == "admin@admin.com") ? 'admin' : 'user';
        
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'fullName': fullName,
          'userName': userName,
          'profileImagePath': profileImagePath,
          'joinedAt': FieldValue.serverTimestamp(),
          'role': role,
          'isBlocked': false,
        });

        _addLog(email, "User Registered", "User successfully created an account.");
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Signup error: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userQuery = await _firestore.collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        if (userData['isBlocked'] == true) {
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _addLog(email, "Login Success", "User successfully logged in.");
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _addLog(email, "Login Attempt (Failed)", "Invalid credentials or blocked user.");
      
      _isLoading = false;
      notifyListeners();
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> updateProfileImage(String path) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'profileImagePath': path,
      });
      _profileImagePath = path;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile image: $e');
    }
  }

  Future<void> logout() async {
    if (_userEmail != null) {
      await _addLog(_userEmail!, "Logout", "User manually logged out.");
    }
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    } catch (e) {
      debugPrint('Error deleting account: $e');
    }
  }

  Future<bool> resetPassword(String email, String newPassword) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      await _addLog(email, "Password Reset Sent", "Password reset email requested.");
      return true;
    } catch (e) {
      debugPrint('Reset password error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => {
        ...doc.data(),
        'uid': doc.id,
      }).toList();
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      return [];
    }
  }

  Future<void> deleteUser(String email) async {
    try {
      final query = await _firestore.collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.delete();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting user: $e');
    }
  }

  Future<void> toggleUserRole(String email) async {
    if (email == "ermiasdereje24@gmail.com" || email == "admin@admin.com") return;

    try {
      final query = await _firestore.collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final currentRole = doc.data()['role'];
        await doc.reference.update({
          'role': currentRole == 'admin' ? 'user' : 'admin',
        });
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling role: $e');
    }
  }

  Future<void> toggleUserStatus(String email) async {
    if (email == "ermiasdereje24@gmail.com" || email == "admin@admin.com") return;

    try {
      final query = await _firestore.collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final currentStatus = doc.data()['isBlocked'] ?? false;
        await doc.reference.update({
          'isBlocked': !currentStatus,
        });
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling status: $e');
    }
  }

  Future<List<ActivityLog>> getAllLogs() async {
    try {
      final snapshot = await _firestore.collection('activity_logs')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        DateTime ts = DateTime.now();
        if (data['timestamp'] is Timestamp) {
          ts = (data['timestamp'] as Timestamp).toDate();
        }
        return ActivityLog(
          id: data['id'] ?? doc.id,
          userEmail: data['userEmail'] ?? 'Unknown',
          action: data['action'] ?? 'Unknown',
          timestamp: ts,
          details: data['details'] ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching logs: $e');
      return [];
    }
  }

  Future<void> clearLogs() async {
    try {
      final snapshots = await _firestore.collection('activity_logs').get();
      for (var doc in snapshots.docs) {
        await doc.reference.delete();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing logs: $e');
    }
  }
}
