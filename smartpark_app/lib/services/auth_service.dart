import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Web requires clientId explicitly; mobile gets it from google-services.json
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '852869663452-dbmpvg4hlla9lafe32ffpgkb8nr2dvha.apps.googleusercontent.com'
        : null,
    scopes: ['email', 'profile'],
  );

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: Use Firebase's GoogleAuthProvider popup directly
        // This is the recommended approach for web with firebase_auth
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        final userCredential =
            await _auth.signInWithPopup(googleProvider);

        await _saveUserToFirestore(userCredential.user!);
        return userCredential;
      } else {
        // Mobile: Use google_sign_in package (works great on Android/iOS)
        final GoogleSignInAccount? googleUser =
            await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential =
            await _auth.signInWithCredential(credential);
        await _saveUserToFirestore(userCredential.user!);
        return userCredential;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    final userRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid);

    final doc = await userRef.get();
    if (!doc.exists) {
      final userModel = UserModel(
        userId: user.uid,
        name: user.displayName ?? 'SmartPark User',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      );
      await userRef.set(userModel.toMap());
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

