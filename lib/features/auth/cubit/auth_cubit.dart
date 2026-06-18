import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/di/injection.dart';
import '../../../domain/repositories/trip_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthCubit({
    required FirebaseAuth auth,
    required GoogleSignIn googleSignIn,
  })  : _auth = auth,
        _googleSignIn = googleSignIn,
        super(const AuthInitial()) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        emit(AuthAuthenticated(
          userId: user.uid,
          isAnonymous: user.isAnonymous,
          displayName: _getDisplayName(user),
          email: _getEmail(user),
          photoUrl: _getPhotoUrl(user),
        ));
      } else {
        emit(const AuthUnauthenticated());
      }
    });
  }

  /// Anonim (misafir) giriş
  Future<void> signInAnonymously() async {
    try {
      emit(const AuthLoading());
      await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_authErrorMessage(e.code)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Google ile giriş
  Future<void> signInWithGoogle() async {
    try {
      emit(const AuthLoading());
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        await checkAuthState();
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Anonim kullanıcıyı Google hesabıyla birleştir
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        try {
          await currentUser.linkWithCredential(credential);
          await currentUser.reload();
        } on FirebaseAuthException catch (linkException) {
          if (linkException.code == 'credential-already-in-use' ||
              linkException.code == 'email-already-in-use') {
            // Google hesabı zaten başka bir hesaba bağlıysa:
            
            // 1. Anonim kullanıcının gezilerini oku (Hala anonim oturum aktifken)
            final anonymousUid = currentUser.uid;
            final tripRepo = getIt<TripRepository>();
            final anonymousTrips = await tripRepo.getUserTrips(anonymousUid);
            
            // 2. Eski anonim gezileri Firestore'dan sil (Orphaned veri kalmaması için)
            for (final trip in anonymousTrips) {
              try {
                await tripRepo.deleteTrip(trip.id);
              } catch (deleteDocError) {
                // ignore: avoid_print
                print('Eski gezi silinirken hata: $deleteDocError');
              }
            }
            
            // 3. Eski anonim kullanıcıyı Firebase Authentication'dan sil (Console'da birikmemesi için)
            try {
              await currentUser.delete();
            } catch (deleteUserError) {
              // ignore: avoid_print
              print('Eski anonim kullanıcı silinirken hata: $deleteUserError');
            }
            
            // 4. Google hesabı ile doğrudan oturum aç (Bu işlem oturumu Google kullanıcısına geçirir)
            final googleUserCredential = await _auth.signInWithCredential(credential);
            final googleUid = googleUserCredential.user?.uid;
            
            if (googleUid != null && anonymousTrips.isNotEmpty) {
              // 5. Okuduğumuz gezileri yeni Google kullanıcısının UID'si ile kopyalayarak Firestore'a kaydet
              for (final trip in anonymousTrips) {
                await tripRepo.saveTripAsNew(trip, googleUid);
              }
            }
          } else {
            rethrow;
          }
        }
      } else {
        await _auth.signInWithCredential(credential);
      }
      await checkAuthState();
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_authErrorMessage(e.code)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Çıkış
  Future<void> signOut() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.isAnonymous) {
      // Eğer çıkış yapan kullanıcı misafir (anonim) ise:
      // 1. Önce onun gezilerini Firestore'dan sil (çöp veri kalmaması için)
      final anonymousUid = currentUser.uid;
      final tripRepo = getIt<TripRepository>();
      try {
        final anonymousTrips = await tripRepo.getUserTrips(anonymousUid);
        for (final trip in anonymousTrips) {
          await tripRepo.deleteTrip(trip.id);
        }
      } catch (e) {
        // ignore: avoid_print
        print('Misafir gezileri silinirken hata: $e');
      }

      // 2. Misafir kullanıcı kaydını Firebase Auth'tan tamamen sil (Console'da birikmesin)
      try {
        await currentUser.delete();
      } catch (e) {
        // ignore: avoid_print
        print('Misafir kullanıcı silinirken hata: $e');
      }
    }

    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Mevcut kullanıcıyı kontrol et
  Future<void> checkAuthState() async {
    var user = _auth.currentUser;
    if (user != null) {
      try {
        await user.reload();
        user = _auth.currentUser;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'user-disabled') {
          await signOut();
          emit(const AuthUnauthenticated());
          return;
        }
      } catch (_) {
        // Ağ hatası vb. durumlarda yerel oturumu bozma (çevrimdışı desteği için)
      }
    }

    if (user != null) {
      emit(AuthAuthenticated(
        userId: user.uid,
        isAnonymous: user.isAnonymous,
        displayName: _getDisplayName(user),
        email: _getEmail(user),
        photoUrl: _getPhotoUrl(user),
      ));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  String? _getDisplayName(User user) {
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName;
    }
    for (final profile in user.providerData) {
      if (profile.displayName != null && profile.displayName!.isNotEmpty) {
        return profile.displayName;
      }
    }
    return null;
  }

  String? _getPhotoUrl(User user) {
    if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      return user.photoURL;
    }
    for (final profile in user.providerData) {
      if (profile.photoURL != null && profile.photoURL!.isNotEmpty) {
        return profile.photoURL;
      }
    }
    return null;
  }

  String? _getEmail(User user) {
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email;
    }
    for (final profile in user.providerData) {
      if (profile.email != null && profile.email!.isNotEmpty) {
        return profile.email;
      }
    }
    return null;
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'network-request-failed':
        return 'İnternet bağlantısı yok. Lütfen tekrar deneyin.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Biraz bekleyin.';
      case 'account-exists-with-different-credential':
        return 'Bu e-posta farklı bir giriş yöntemiyle kayıtlı.';
      case 'credential-already-in-use':
        return 'Bu Google hesabı zaten başka bir hesapla eşleştirilmiş. Lütfen çıkış yapıp doğrudan Google ile giriş yapın.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten başka bir hesap tarafından kullanılıyor.';
      case 'provider-already-linked':
        return 'Bu misafir hesabı zaten bir Google hesabına bağlanmış.';
      case 'invalid-credential':
        return 'Geçersiz kimlik bilgisi. Lütfen tekrar deneyin.';
      default:
        return 'Giriş yapılamadı ($code). Lütfen tekrar deneyin.';
    }
  }
}
