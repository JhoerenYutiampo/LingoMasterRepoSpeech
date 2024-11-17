import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AssessmentMultiChoice extends StatefulWidget {
  final String collectionName;
  final String hiragana;
  final String english;

  const AssessmentMultiChoice({
    Key? key,
    required this.collectionName,
    required this.hiragana,
    required this.english,
  }) : super(key: key);

  @override
  State<AssessmentMultiChoice> createState() => _AssessmentMultiChoiceState();
}

class _AssessmentMultiChoiceState extends State<AssessmentMultiChoice> {
  List<String> _choices = [];
  bool _isLoading = true;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadChoices();
  }

  Future<void> _loadChoices() async {
    try {
      // Get all documents from the specified collection
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .get();

      // Extract all English translations
      List<String> allChoices = querySnapshot.docs
          .map((doc) => doc['english'] as String)
          .where((english) => english != widget.english) // Exclude correct answer
          .toList();

      // Randomly select 3 wrong answers
      allChoices.shuffle(_random);
      List<String> wrongChoices = allChoices.take(3).toList();

      // Add correct answer and shuffle
      _choices = [...wrongChoices, widget.english];
      _choices.shuffle(_random);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading choices: $e');
      setState(() {
        _isLoading = false;
        _choices = ['Error loading choices'];
      });
    }
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Leave Assessment?"),
        content: const Text("If you leave now, you will receive a score of 0 for this question."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Stay"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pop(context, 0); // Return 0 when user confirms exit
            },
            child: const Text("Leave"),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _handleChoice(String choice) {
    bool isCorrect = choice == widget.english;
    _showResultDialog(isCorrect);
  }

  void _showResultDialog(bool isCorrect) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          isCorrect ? 'Correct!' : 'Incorrect',
          style: TextStyle(
            color: isCorrect ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          isCorrect 
              ? 'Great job! You selected the correct translation.'
              : 'The correct translation was: ${widget.english}',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, isCorrect ? 1 : 0); // Return score based on correctness
            },
            child: Text(
              'Continue',
              style: TextStyle(
                fontSize: 16,
                color: isCorrect ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _showExitConfirmationDialog();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Choose the Correct Translation'),
          backgroundColor: Colors.purple,
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: _showExitConfirmationDialog,
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.hiragana,
                      style: TextStyle(
                        fontSize: 120 / (widget.hiragana.length.clamp(1, 10) * 0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 40),
                    ..._choices.map((choice) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.all(16),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.purple, width: 2),
                            ),
                          ),
                          onPressed: () => _handleChoice(choice),
                          child: Text(
                            choice,
                            style: TextStyle(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )).toList(),
                  ],
                ),
              ),
      ),
    );
  }
}