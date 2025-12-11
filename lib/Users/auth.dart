import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var errorText = "".obs;

  // LOGIN
  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      errorText.value = "";

      await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // SUCCESS → CHECK ROLE
      await _redirectUserByRole();
    } on FirebaseAuthException catch (e) {
      errorText.value = e.message ?? "Login failed";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _redirectUserByRole() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _db.collection("users").doc(user.uid).get();
    final role = doc['role'];

    if (role == "admin") {
      Get.offAllNamed('/admin');
    } else if (role == "staff") {
      Get.offAllNamed('/staff');
    } else {
      Get.offAllNamed('/customer');
    }
  }
}
