import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseMethods {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future addQuizCategory(
      Map<String, dynamic> userQuizCategory, String category) async {
    return await FirebaseFirestore.instance
        .collection(category)
        .add(userQuizCategory);
  }

  Future<Stream<QuerySnapshot>> getCategoryQuiz(String category) async {
    return FirebaseFirestore.instance.collection(category).snapshots();
  }

  Future<void> addExpToUser(int exp) async {
  try {
    User? user = _auth.currentUser;
    if (user?.email == null) {
      print("No user is currently signed in or email is not available.");
      return;
    }
    
    DocumentReference userDoc = _firestore.collection('users').doc(user?.email);
    
    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userDoc);
      if (!snapshot.exists) {
        transaction.set(userDoc, {'exp': exp});
      } else {
        int currentExp = (snapshot.data() as Map<String, dynamic>)['exp'] ?? 0;
        transaction.update(userDoc, {'exp': currentExp + exp});
      }
    });
  } catch (e) {
    print("Failed to add EXP: $e");
    rethrow;
  }
  }
}
