import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lingomaster_final/screens/draw_screen.dart';
import 'package:lingomaster_final/screens/voice_screen.dart';

class LevelDetailScreen extends StatelessWidget {
  final String levelTitle;
  final String collectionName;
  final int currentProgress;
  final int totalQuestions;

  const LevelDetailScreen({
    super.key,
    required this.levelTitle,
    required this.collectionName,
    required this.currentProgress,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    double progress = currentProgress / totalQuestions;

    return Scaffold(
      // Custom AppBar for aesthetic design
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(
            120), // Increased height for a more spacious header
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.deepPurpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),
          backgroundColor:
              Colors.transparent, // Transparent background to show gradient
          elevation: 0,
          centerTitle: true,
          title: Text(
            levelTitle,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(1, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress box at the top
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$levelTitle Progress",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  minHeight: 15,
                ),
                const SizedBox(height: 12),
                Text(
                  "$currentProgress / $totalQuestions",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future:
                  FirebaseFirestore.instance.collection(collectionName).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading data"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No data found"));
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: snapshot.data!.docs.map((doc) {
                    var symbol = doc['english'];
                    final data = doc.data() as Map<String, dynamic>?;
                    var symbolImage = data != null && data['image'] != null
                        ? data['image'] as String
                        : null;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Container(
                        height: 100,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Display symbol value in a larger font
                            Expanded(
                              child: Text(
                                symbol,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            // Display the pen and microphone icons
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.indigo),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DrawScreen(
                                          targetHiragana: doc['hiragana'],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.mic,
                                      color: Colors.redAccent),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VoiceScreen(
                                          hiragana: doc['hiragana'],
                                          english: doc['english'],
                                          audio: doc['audio'],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
