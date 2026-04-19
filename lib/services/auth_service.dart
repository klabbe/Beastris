import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  UserProfile? _profile;
  UserProfile? get profile => _profile;
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  late final _authSub = _auth.authStateChanges().listen(_onAuthChanged);

  bool _disposed = false;
  bool _registering = false;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance {
    _authSub; // Force listener creation
  }

  @override
  void dispose() {
    _disposed = true;
    _authSub.cancel();
    super.dispose();
  }

  Future<void> _onAuthChanged(User? user) async {
    if (_disposed || _registering) return;
    if (user == null) {
      _profile = null;
      notifyListeners();
    } else if (_profile?.uid != user.uid) {
      _profile = await _fetchProfile(user.uid);
      if (_disposed) return;
      notifyListeners();
    }
  }

  Future<UserProfile?> _fetchProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) return UserProfile.fromMap(uid, doc.data()!);
      // Profile missing (e.g. save failed at registration) — create a default one
      final email = _auth.currentUser?.email ?? '';
      final alias = email.contains('@') ? email.split('@').first : 'Player';
      final defaultProfile = UserProfile(uid: uid, alias: alias);
      await _saveProfile(defaultProfile);
      return defaultProfile;
    } catch (e) {
      debugPrint('AuthService: failed to fetch profile: $e');
    }
    return null;
  }

  Future<bool> _isAliasAvailable(String alias, {String? excludeUid}) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('alias', isEqualTo: alias)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return true;
      // Available if the only match is the current user
      return snapshot.docs.first.id == excludeUid;
    } catch (_) {
      return true; // Fail open on network errors
    }
  }

  Future<String?> register(
      String email, String password, UserProfile profile) async {
    try {
      final available = await _isAliasAvailable(profile.alias);
      if (!available) return 'That alias is already taken. Please choose another.';
      _registering = true;
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final fullProfile = UserProfile(
        uid: cred.user!.uid,
        alias: profile.alias,
        name: profile.name,
        country: profile.country,
      );
      // Set profile immediately so _onAuthChanged skips the redundant fetch
      _profile = fullProfile;
      // Await Firestore save so callers can rely on it being persisted
      try {
        await _saveProfile(fullProfile);
      } catch (e) {
        debugPrint('Save profile failed: $e');
      }
      _registering = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _registering = false;
      return _authError(e.code);
    } catch (e) {
      _registering = false;
      return 'Registration failed. Please try again.';
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      // Fetch profile before returning so the caller has it immediately
      _profile = await _fetchProfile(cred.user!.uid);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    } catch (e) {
      return 'Sign in failed. Please try again.';
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    } catch (e) {
      return 'Failed to send reset email. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _profile = null;
    notifyListeners();
  }

  /// Permanently delete the account and all associated data (GDPR Art. 17).
  /// Deletes: all leaderboard entries, users/{uid} doc, Firebase Auth account.
  Future<String?> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return 'Not signed in.';
    final uid = user.uid;
    try {
      // 1. Anonymize leaderboard entries — clear uid so they are no longer
      //    linked to any account, even if Firebase recycles this uid later.
      final leaderboard = await _db
          .collection('leaderboard')
          .where('uid', isEqualTo: uid)
          .get();
      if (leaderboard.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in leaderboard.docs) {
          batch.update(doc.reference, {'uid': ''});
        }
        await batch.commit();
      }
      // 2. Delete profile document (individual delete, not batch, for reliability)
      await _db.collection('users').doc(uid).delete();
      // 3. Delete Firebase Auth account (must be last)
      await user.delete();
      _profile = null;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      // delete() can fail if the session is stale — requires re-authentication
      if (e.code == 'requires-recent-login') {
        return 'For security, please sign out and sign in again before deleting your account.';
      }
      return _authError(e.code);
    } catch (e) {
      return 'Failed to delete account. Please try again.';
    }
  }

  Future<String?> updateProfile(UserProfile profile) async {
    try {
      if (profile.alias != _profile?.alias) {
        final available =
            await _isAliasAvailable(profile.alias, excludeUid: profile.uid);
        if (!available) return 'That alias is already taken. Please choose another.';
      }
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
