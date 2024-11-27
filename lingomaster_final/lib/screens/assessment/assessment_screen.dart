import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:lingomaster_final/service/databaseMethods.dart';
import 'package:lingomaster_final/screens/assessment/assessmentDraw.dart';
import 'package:lingomaster_final/screens/assessment/assessmentVoice.dart';
import 'package:lingomaster_final/screens/assessment/assessmentMultiChoice.dart';

class AssessmentScreen extends StatefulWidget {
  final String collection;
  
  const AssessmentScreen(this.collection, {Key? key}) : super(key: key);

  @override
  _AssessmentScreenState createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final DatabaseMethods _databaseMethods = DatabaseMethods();
  
  // Cache the data
  late final Future<Map<String, dynamic>> _initialDataFuture;
  List<DocumentSnapshot> randomQuestions = [];
  final List<int> questionScores = List.filled(5, -1);
  int previousScore = 0;
  int hearts = 3;

  @override
  void initState() {
    super.initState();
    _initialDataFuture = _loadInitialData();
  }

  Future<Map<String, dynamic>> _loadInitialData() async {
    final Future<int> scoreFuture = _databaseMethods.getUserScore(widget.collection);
    final Future<int> heartsFuture = _databaseMethods.getUserHearts();
    final Future<QuerySnapshot> questionsFuture = FirebaseFirestore.instance
        .collection(widget.collection)
        .limit(10) 
        .get();

    final results = await Future.wait([
      scoreFuture,
      heartsFuture,
      questionsFuture,
    ]);

    // Process questions
    final List<DocumentSnapshot> allDocs = (results[2] as QuerySnapshot).docs;
    final random = Random();
    final selectedIndices = <int>{};
    
    while (randomQuestions.length < 5 && selectedIndices.length < allDocs.length) {
      final index = random.nextInt(allDocs.length);
      if (selectedIndices.add(index)) {
        randomQuestions.add(allDocs[index]);
      }
    }

    return {
      'previousScore': results[0] as int,
      'hearts': results[1] as int,
    };
  }

  Widget _buildQuestionCard(DocumentSnapshot question, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
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
          //subtitle: Text(
          //  question['english'],
          //  style: const TextStyle(fontSize: 16),
          //),
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
              ? () => _navigateToRandomScreen(question, index)
              : null,
        ),
      ),
    );
  }

  Future<void> _navigateToRandomScreen(DocumentSnapshot question, int index) async {
    if (!mounted) return;
    
    // Determine available screen types based on collection
    List<int> availableScreenTypes;
    if (widget.collection == "characters") {
      // Exclude voice assessment (index 1) for characters collection
      availableScreenTypes = [0, 2]; // Only drawing and multiple choice
    } else {
      availableScreenTypes = [0, 1, 2]; // All assessment types
    }
    
    // Randomly select from available screen types
    final screenType = availableScreenTypes[Random().nextInt(availableScreenTypes.length)];
    int? result;
    
    switch (screenType) {
      case 0:
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
    
    if (result != null && mounted) {
      setState(() {
        questionScores[index] = result!;
      });
      
      if (!questionScores.contains(-1)) {
        await _submitAssessment();
      }
    }
  }

  Future<void> _submitAssessment() async {
    final totalScore = questionScores.fold(0, (sum, score) => sum + score);
    await _databaseMethods.updateUserScore(widget.collection, totalScore);
    
    final isPassed = totalScore >= 3;
    
    if (!isPassed) {
      await _databaseMethods.modifyUserHearts(-1);
      setState(() => hearts--);
    }
    
    if (!mounted) return;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isPassed ? 'Assessment Passed!' : 'Assessment Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your score: $totalScore/5'),
            if (!isPassed) const Text(
              '\nYou lost 1 heart. Try again!',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context)
                ..pop()
                ..pop();
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
      onWillPop: () async {
        final hasUnfinishedQuestions = questionScores.contains(-1);
        if (!hasUnfinishedQuestions) return true;
        
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text(
              'Your progress will be lost and questions will be randomized when you return.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ?? false;
      },
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
            title: FutureBuilder<Map<String, dynamic>>(
              future: _initialDataFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                
                previousScore = snapshot.data!['previousScore'];
                hearts = snapshot.data!['hearts'];
                
                return Column(
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
                );
              },
            ),
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _initialDataFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: randomQuestions.length,
              itemBuilder: (context, index) => _buildQuestionCard(
                randomQuestions[index],
                index,
              ),
            );
          },
        ),
      ),
    );
  }
}