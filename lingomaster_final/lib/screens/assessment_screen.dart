import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:lingomaster_final/service/databaseMethods.dart';
import 'package:lingomaster_final/screens/assessment/assessmentDraw.dart';
import 'package:lingomaster_final/screens/assessment/assessmentVoice.dart';
import 'package:lingomaster_final/screens/assessment/assessmentMultiChoice.dart';

class AssesmentScreen extends StatefulWidget {
  final String collection;
  
  const AssesmentScreen(this.collection, {Key? key}) : super(key: key);

  @override
  _AssesmentScreenState createState() => _AssesmentScreenState();
}

class _AssesmentScreenState extends State<AssesmentScreen> {
  final DatabaseMethods _databaseMethods = DatabaseMethods();
  List<DocumentSnapshot> randomQuestions = [];
  List<int> questionScores = List.filled(5, -1); // -1 means not attempted
  int previousScore = 0;
  int hearts = 3;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    
    // Load previous score and hearts
    previousScore = await _databaseMethods.getUserScore(widget.collection);
    hearts = await _databaseMethods.getUserHearts();
    
    // Get all documents from collection
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection(widget.collection)
        .get();
    
    // Randomly select 5 questions
    List<DocumentSnapshot> allDocs = snapshot.docs;
    Random random = Random();
    while (randomQuestions.length < 5 && allDocs.isNotEmpty) {
      int index = random.nextInt(allDocs.length);
      randomQuestions.add(allDocs[index]);
      allDocs.removeAt(index);
    }
    
    setState(() => isLoading = false);
  }

  Future<void> _navigateToRandomScreen(DocumentSnapshot question) async {
  if (!mounted) return;
  
  // Randomly select screen type (0, 1, or 2)
  Random random = Random();
  int screenType = random.nextInt(3);
  
  int? result;
  
  switch (screenType) {
    case 0:
      // Navigate to Draw Assessment
      result = await Navigator.push<int>(
        context,
        MaterialPageRoute(
          builder: (context) => AssessmentDraw(
            targetHiragana: question['hiragana'],
          ),
        ),
      );
      break;
      
    case 1:
      // Navigate to Voice Assessment
      result = await Navigator.push<int>(
        context,
        MaterialPageRoute(
          builder: (context) => AssessmentVoice(
            hiragana: question['hiragana'],
            english: question['english'],
            audio: question['audio'],
            pronunciation: question['pronunciation'],
          ),
        ),
      );
      break;
      
    case 2:
      // Navigate to Multiple Choice Assessment
      result = await Navigator.push<int>(
        context,
        MaterialPageRoute(
          builder: (context) => AssessmentMultiChoice(
            collectionName: widget.collection,
            hiragana: question['hiragana'],
            english: question['english'],
          ),
        ),
      );
      break;
  }
  
  // Handle the result
  if (result != null) {
    _handleQuestionCompletion(
      randomQuestions.indexOf(question),
      result
    );
  }
}

  Future<bool> _onWillPop() async {
    bool hasUnfinishedQuestions = questionScores.any((score) => score == -1);
    
    if (!hasUnfinishedQuestions) return true;
    
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text(
          'Your progress will be lost and questions will be randomized when you return.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _handleQuestionCompletion(int index, int score) {
    setState(() {
      questionScores[index] = score;
    });

    // Check if all questions are completed
    if (!questionScores.contains(-1)) {
      _submitAssessment();
    }
  }

  Future<void> _submitAssessment() async {
    int totalScore = questionScores.fold(0, (sum, score) => sum + score);
    await _databaseMethods.updateUserScore(widget.collection, totalScore);
    
    // Show completion dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Assessment Complete!'),
        content: Text('Your score: $totalScore/5'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assessment',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.stars, color: Colors.amber[300]),
                    const SizedBox(width: 4),
                    Text(
                      'Previous Score: $previousScore',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.favorite, color: Colors.red[300]),
                    const SizedBox(width: 4),
                    Text(
                      'Lives: $hearts',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: randomQuestions.length,
                itemBuilder: (context, index) {
                  final question = randomQuestions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          'Question ${index + 1}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          question['english'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: questionScores[index] == -1
                            ? const Icon(Icons.arrow_forward_ios)
                            : Icon(
                                questionScores[index] == 1
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: questionScores[index] == 1
                                    ? Colors.green
                                    : Colors.red,
                              ),
                        onTap: questionScores[index] == -1
                          ? () => _navigateToRandomScreen(randomQuestions[index])
                          : null,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}