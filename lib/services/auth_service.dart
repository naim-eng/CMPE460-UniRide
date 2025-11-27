import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // REGISTER USER
  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = cred.user!.uid;

      // Save user data to Firestore
      UserModel user = UserModel(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        role: "user", // default role
      );

      await _db.collection("users").doc(uid).set(user.toMap());

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // LOGIN USER
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // FETCH USER PROFILE
  Future<UserModel?> getUserProfile() async {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) return null;

    DocumentSnapshot doc = await _db
        .collection("users")
        .doc(currentUser.uid)
        .get();

    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}
