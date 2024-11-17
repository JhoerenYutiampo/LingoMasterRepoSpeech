import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lingomaster_final/screens/assessment_screen.dart';
import 'package:lingomaster_final/screens/draw_screen.dart';
import 'package:lingomaster_final/screens/voice_screen.dart';
import 'package:lingomaster_final/service/databaseMethods.dart';

class LevelDetailScreen extends StatefulWidget {
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
  _LevelDetailScreenState createState() => _LevelDetailScreenState();
}

class _LevelDetailScreenState extends State<LevelDetailScreen> {
  final DatabaseMethods _databaseMethods = DatabaseMethods();
  List<String> completedWrittenQuestions = [];
  List<String> completedVoiceQuestions = [];

  int _getLevelFromCollection() {
    switch (widget.collectionName) {
      case 'characters':
        return 1;
      case 'words':
        return 2;
      case 'phrases':
        return 3;
      default:
        return 1;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCompletedQuestions();
  }

  Future<void> _loadCompletedQuestions() async {
    int level = _getLevelFromCollection();
    List<String> writtenQuestions = await _databaseMethods.getCompletedQuestions(level, 'written');
    List<String> voiceQuestions = await _databaseMethods.getCompletedQuestions(level, 'voice');
    
    setState(() {
      completedWrittenQuestions = writtenQuestions;
      completedVoiceQuestions = voiceQuestions;
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = widget.currentProgress / widget.totalQuestions;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            widget.levelTitle,
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
                  "Progress",
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
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  minHeight: 15,
                ),
                const SizedBox(height: 12),
                Text(
                  "${widget.currentProgress} / ${widget.totalQuestions}",
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
              future: FirebaseFirestore.instance.collection(widget.collectionName).get(),
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
                    bool isWrittenCompleted = completedWrittenQuestions.contains(doc.id);
                    bool isVoiceCompleted = completedVoiceQuestions.contains(doc.id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Container(
                        height: 100,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: isWrittenCompleted ? Colors.green.withOpacity(0.1) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isWrittenCompleted 
                                      ? Border.all(color: Colors.green, width: 2)
                                      : null,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.indigo),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DrawScreen(
                                            targetHiragana: doc['hiragana'],
                                            questionId: doc.id,
                                            collectionName: widget.collectionName,
                                          ),
                                        ),
                                      ).then((_) => _loadCompletedQuestions());
                                    },
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: isVoiceCompleted ? Colors.green.withOpacity(0.1) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isVoiceCompleted 
                                      ? Border.all(color: Colors.green, width: 2)
                                      : null,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.mic, color: Colors.redAccent),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => VoiceScreen(
                                            hiragana: doc['hiragana'],
                                            english: doc['english'],
                                            audio: doc['audio'],
                                            pronunciation: doc['pronunciation'],
                                            questionId: doc.id,
                                            collectionName: widget.collectionName,
                                          ),
                                        ),
                                      ).then((_) => _loadCompletedQuestions());
                                    },
                                  ),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssesmentScreen(widget.collectionName),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                backgroundColor: Colors.purpleAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Go to Assessment',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
