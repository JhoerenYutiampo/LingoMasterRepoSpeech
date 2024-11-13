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

  Future<void> modifyUserExp(int exp) async {
    try {
      User? user = _auth.currentUser;
      if (user?.uid == null) {
        print("No user is currently signed in or user ID is not available.");
        return;
      }

      DocumentReference userDoc = _firestore.collection('users').doc(user?.uid);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userDoc);
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          int currentExp = data['exp'] ?? 0;
          int currentLevel = data['currentLevel'] ?? 0;
          int hearts = data['hearts'] ?? 0;

          // Update exp with the new value
          currentExp += exp;

          // Check if exp exceeds or equals 100
          while (currentExp >= 100) {
            currentExp -= 100; // Reduce by 100
            currentLevel += 1; // Increase level
            // Increase hearts but ensure it doesn't exceed 5
            hearts = (hearts < 5) ? hearts + 1 : 5;
          }

          // Update user document in Firestore
          transaction.update(userDoc, {
            'exp': currentExp,
            'currentLevel': currentLevel,
            'hearts': hearts,
          });
        } else {
          print("User document does not exist.");
        }
      });
    } catch (e) {
      print("Failed to modify EXP: $e");
      rethrow;
    }
  }

  Future<void> modifyUserHearts(int heartChange) async {
    try {
      // Validate input
      if (heartChange != 1 && heartChange != -1) {
        throw ArgumentError('heartChange must be either 1 or -1');
      }

      User? user = _auth.currentUser;
      if (user?.uid == null) {
        print("No user is currently signed in or user ID is not available.");
        return;
      }

      DocumentReference userDoc = _firestore.collection('users').doc(user?.uid);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userDoc);
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          int currentHearts = data['hearts'] ?? 0;

          // Calculate new heart value
          int newHearts = currentHearts + heartChange;

          // Ensure hearts stay within bounds (0-5)
          newHearts = newHearts.clamp(0, 5);

          // Update user document in Firestore
          transaction.update(userDoc, {
            'hearts': newHearts,
          });
        } else {
          print("User document does not exist.");
        }
      });
    } catch (e) {
      print("Failed to modify hearts: $e");
      rethrow;
    }
  }
}