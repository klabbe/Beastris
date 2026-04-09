import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserProfile? _profile;
  UserProfile? get profile => _profile;
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      _profile = null;
    } else {
      _profile = await _fetchProfile(user.uid);
    }
    notifyListeners();
  }

  Future<UserProfile?> _fetchProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) return UserProfile.fromMap(uid, doc.data()!);
    } catch (e) {
      debugPrint('AuthService: failed to fetch profile: $e');
    }
    return null;
  }

  Future<String?> register(
      String email, String password, UserProfile profile) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final newProfile = profile.copyWith();
      await _saveProfile(UserProfile(
        uid: cred.user!.uid,
        alias: profile.alias,
        name: profile.name,
        country: profile.country,
      ));
      _profile = await _fetchProfile(cred.user!.uid);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      _profile = await _fetchProfile(cred.user!.uid);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _profile = null;
    notifyListeners();
  }

  Future<String?> updateProfile(UserProfile profile) async {
    try {
      await _saveProfile(profile);
      _profile = profile;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Failed to save profile.';
    }
  }

  Future<void> _saveProfile(UserProfile profile) async {
    await _db.collection('users').doc(profile.uid).set(profile.toMap());
  }

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Authentication failed ($code).';
    }
  }
}
