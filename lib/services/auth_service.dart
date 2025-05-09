import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? get currentUser => _auth.currentUser;
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  Future<UserCredential?> registerWithEmailAndPassword(String email, String password, String username) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _createUserDocument(userCredential.user!.uid, email, username);
      
      return userCredential;
    } catch (e) {
      print('Error registering with email and password: $e');
      rethrow;
    }
  }
  
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        bool userExists = await _checkUserExists(userCredential.user!.uid);
        if (!userExists) {
          print('User document not found in Firestore, creating one for email login.');
          await _createUserDocument(
            userCredential.user!.uid, 
            userCredential.user!.email ?? '', 
            userCredential.user!.email?.split('@').first ?? 'User',
          );
        }
      }
      
      return userCredential;
    } catch (e) {
      print('Error signing in with email and password: $e');
      rethrow;
    }
  }
  
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        bool userExists = await _checkUserExists(userCredential.user!.uid);
        if (!userExists) {
          await _createUserDocument(
            userCredential.user!.uid, 
            userCredential.user!.email ?? '', 
            userCredential.user!.displayName ?? 'User',
            userCredential.user!.photoURL,
          );
        }
      }
      
      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }
  
  Future<void> _createUserDocument(String userId, String email, String username, [String? photoURL]) async {
    await _firestore.collection('users').doc(userId).set({
      'username': username,
      'email': email,
      'photoURL': photoURL ?? '',
      'dateOfBirth': null,
      'bodyWeight': null,
      'bodyHeight': null,
      'gender': null,
      'points': 0,
      'isProfileComplete': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  
  Future<bool> _checkUserExists(String userId) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
    return doc.exists;
  }
  
  Future<UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
  
  Future<bool> ensureUserDocument(String userId, String email, [String? name, String? photoURL]) async {
    try {
      bool exists = await _checkUserExists(userId);
      
      if (!exists) {
        String username = name ?? email.split('@').first;
        await _createUserDocument(userId, email, username, photoURL);
        print('Created new user document for userId: $userId, username: $username');
        return true;
      }
      
      return exists;
    } catch (e) {
      print('Error ensuring user document: $e');
      return false;
    }
  }
  
  Future<void> updateUserProfile(UserModel user) async {
    try {
      Map<String, dynamic> userData = user.toMap();
      
      bool isComplete = user.dateOfBirth != null && 
                       user.bodyWeight != null && 
                       user.bodyHeight != null && 
                       user.gender != null;
      
      userData['isProfileComplete'] = isComplete;
      
      await _firestore.collection('users').doc(user.id).update(userData);
      print('Profile updated successfully for user ${user.id}');
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
  
  Future<void> deleteAccount() async {
    try {
      String userId = _auth.currentUser!.uid;
      
      await _firestore.collection('users').doc(userId).delete();
      
      QuerySnapshot scansSnapshot = await _firestore.collection('foodScans').where('userId', isEqualTo: userId).get();
      for (var doc in scansSnapshot.docs) {
        await doc.reference.delete();
      }
      
      await _auth.currentUser!.delete();
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
  
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
  }
}