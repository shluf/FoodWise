import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/local_auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isInitialized => _isInitialized;
  
  AuthProvider() {
    _init();
  }
  
  Future<void> _init() async {
    _setLoading(true);
    
    try {
      // Cek status login lokal terlebih dahulu
      bool isLoggedInLocally = await LocalAuthService.isLoggedIn();
      String? cachedUserId = await LocalAuthService.getUserId();
      
      if (isLoggedInLocally && cachedUserId != null) {
        // Jika ada data login lokal, coba ambil data user dari Firestore
        final userData = await _authService.getUserData(cachedUserId);
        if (userData != null) {
          _user = userData;
          notifyListeners();
        }
      }
      
      _listenToAuthChanges();
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }
  
  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        // User terautentikasi di Firebase, update data lokal
        final userData = await _authService.getUserData(firebaseUser.uid);
        if (userData != null) {
          if (_user?.id != userData.id) {
            _user = userData;
            // Simpan status login ke lokal
            await LocalAuthService.saveLoginStatus(isLoggedIn: true, userId: userData.id);
            notifyListeners();
          }
        }
      } else if (_user != null) {
        // User tidak terautentikasi di Firebase tapi masih ada di lokal
        // ini berarti sesi telah berakhir, paksa logout
        await signOut();
      }
    });
  }
  
  // Cek dan validasi sesi lokal dengan Firebase
  Future<void> validateSession() async {
    final currentUser = _authService.currentUser;
    final isLoggedInLocally = await LocalAuthService.isLoggedIn();
    
    if (isLoggedInLocally && currentUser == null) {
      // Sesi lokal ada tapi Firebase tidak ada, hapus sesi lokal
      await signOut();
    }
  }
  
  Future<bool> registerWithEmailAndPassword(String email, String password, String username) async {
    try {
      _setLoading(true);
      _error = null;
      
      final userCredential = await _authService.registerWithEmailAndPassword(email, password, username);
      
      if (userCredential != null) {
        // Ambil data user setelah register berhasil
        if (userCredential.user != null) {
          final userData = await _authService.getUserData(userCredential.user!.uid);
          if (userData != null) {
            _user = userData;
            // Simpan status login ke lokal
            await LocalAuthService.saveLoginStatus(isLoggedIn: true, userId: userData.id);
            notifyListeners();
          }
        }
        return true;
      } else {
        _error = 'Gagal mendaftar dengan email dan password';
        return false;
      }
    } catch (e) {
      // Tangkap error yang dispesifikkan
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            _error = '[firebase_auth/email-already-in-use] The email address is already in use by another account.';
            break;
          case 'invalid-email':
            _error = 'Format email tidak valid.';
            break;
          case 'weak-password':
            _error = 'Password terlalu lemah. Gunakan minimal 6 karakter.';
            break;
          default:
            _error = e.message ?? e.toString();
        }
      } else {
        _error = e.toString();
      }
      print('Error registering with email and password: $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _error = null;
      
      print('DEBUG: Starting login with email: $email');
      final userCredential = await _authService.signInWithEmailAndPassword(email, password);
      print('DEBUG: Authentication successful, getting user data from Firestore');
      
      if (userCredential != null) {
        // Ambil data user setelah login berhasil
        if (userCredential.user != null) {
          print('DEBUG: User ID: ${userCredential.user!.uid}');
          final userData = await _authService.getUserData(userCredential.user!.uid);
          
          if (userData != null) {
            print('DEBUG: User data found in Firestore: ${userData.username}');
            _user = userData;
            // Simpan status login ke lokal
            await LocalAuthService.saveLoginStatus(isLoggedIn: true, userId: userData.id);
            notifyListeners();
          } else {
            print('DEBUG: User data not found in Firestore, creating document');
            // Coba buat dokumen pengguna
            await _authService.ensureUserDocument(
              userCredential.user!.uid,
              userCredential.user!.email ?? '',
              userCredential.user!.displayName
            );
            
            // Coba ambil data lagi
            final retryUserData = await _authService.getUserData(userCredential.user!.uid);
            if (retryUserData != null) {
              print('DEBUG: Successfully retrieved user data after creating document');
              _user = retryUserData;
              // Simpan status login ke lokal
              await LocalAuthService.saveLoginStatus(isLoggedIn: true, userId: retryUserData.id);
              notifyListeners();
            } else {
              print('DEBUG: Failed to retrieve user data after creating document');
              _error = 'Gagal memuat data pengguna setelah login';
            }
          }
        }
        return true;
      } else {
        _error = 'Gagal masuk dengan email dan password';
        return false;
      }
    } catch (e) {
      // Tangkap error yang dispesifikkan
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-email':
            _error = 'Format email tidak valid.';
            break;
          case 'user-disabled':
            _error = 'Akun ini telah dinonaktifkan.';
            break;
          case 'user-not-found':
            _error = 'Email tidak terdaftar. Silakan buat akun baru.';
            break;
          case 'wrong-password':
            _error = 'Password salah. Silakan coba lagi.';
            break;
          default:
            _error = e.message ?? e.toString();
        }
      } else {
        _error = e.toString();
      }
      print('Error signing in with email and password: $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _error = null;
      
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential != null) {
        // Ambil data user setelah login dengan Google berhasil
        if (userCredential.user != null) {
          final userData = await _authService.getUserData(userCredential.user!.uid);
          if (userData != null) {
            _user = userData;
            // Simpan status login ke lokal
            await LocalAuthService.saveLoginStatus(isLoggedIn: true, userId: userData.id);
            notifyListeners();
          }
        }
        return true;
      } else {
        _error = 'Gagal masuk dengan Google';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> updateUserProfile(UserModel updatedUser) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _authService.updateUserProfile(updatedUser);
      _user = updatedUser;
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }
  
  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _error = null;
      
      await _authService.deleteAccount();
      // Hapus data login lokal
      await LocalAuthService.clearAuthData();
      _user = null;
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _error = null;
      
      await _authService.signOut();
      // Hapus data login lokal
      await LocalAuthService.clearAuthData();
      _user = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}