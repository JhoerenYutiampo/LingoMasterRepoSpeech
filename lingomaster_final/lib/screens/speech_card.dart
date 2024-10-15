import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lingomaster_final/screens/home_page.dart';
import 'package:lingomaster_final/service/database.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:string_similarity/string_similarity.dart';

class SpeechCard extends StatefulWidget {
  final String category;
  const SpeechCard({super.key, required this.category});

  @override
  State<SpeechCard> createState() => _SpeechCardState();
}

class _SpeechCardState extends State<SpeechCard> {
  Stream? quizStream;
  PageController controller = PageController();
  int totalPages = 0;
  int currentPage = 0;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _wordsSpoken = "";
  double _confidenceLevel = 0;
  double _similarityScore = 0;
  String _targetText = "";
  bool _canProceed = false;

  @override
  void initState() {
    super.initState();
    initSpeech();
    getOnTheLoad();
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: Duration(seconds: 5),
      cancelOnError: true,
      partialResults: false,
    );
    setState(() {
      _confidenceLevel = 0;
      _similarityScore = 0;
      _canProceed = false;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(result) {
    setState(() {
      _wordsSpoken = result.recognizedWords;
      _confidenceLevel = result.confidence;
      _similarityScore = _wordsSpoken.similarityTo(_targetText);
      _canProceed = _similarityScore >= 0.60;
    });
  }

  void _handleNextPage() {
    if (_canProceed) {
      if (currentPage == totalPages - 1) {
        completeLevel();
      } else {
        setState(() {
          currentPage++;
          _wordsSpoken = "";
          _confidenceLevel = 0;
          _similarityScore = 0;
          _canProceed = false;
        });
        controller.nextPage(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeIn,
        );
      }
    }
  }

  Future<void> completeLevel() async {
  await DatabaseMethods().addExpToUser(10);

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => HomePage(),
    ),
  );

  Future.delayed(Duration(milliseconds: 100), () {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Level Complete'),
        content: Text(totalPages > 0 
          ? 'You have finished all questions and earned 10 EXP!' 
          : 'Level completed. You earned 10 EXP!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  });
}

  getOnTheLoad() async {
    quizStream = await DatabaseMethods().getCategoryQuiz(widget.category);
    setState(() {});
  }

  Widget allQuiz() {
    return StreamBuilder(
      stream: quizStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data.docs.isEmpty) {
          // Handle empty database case
          WidgetsBinding.instance.addPostFrameCallback((_) {
            completeLevel();
          });
          return Center(child: Text("No questions available."));
        }

        totalPages = snapshot.data.docs.length;

        return PageView.builder(
          controller: controller,
          itemCount: totalPages,
          physics: NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];
            _targetText = ds["sound"];
            return Container(
              padding: EdgeInsets.all(16),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: Image.network(
                      ds["Image"],
                      height: 300,
                      width: MediaQuery.of(context).size.width,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Container(
                    width: MediaQuery.of(context).size.width / 1.1,
                    padding: EdgeInsets.all(15),
                    margin: EdgeInsets.only(bottom: 20.0),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.green,
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ds["sound"],
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      _speechToText.isListening
                          ? "Listening..."
                          : _speechEnabled
                              ? ""
                              : "Tap the microphone to start listening",
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        _wordsSpoken,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                  if (_speechToText.isNotListening && _confidenceLevel > 0)
                    Text(
                      "Confidence: ${(_confidenceLevel * 100).toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w200,
                      ),
                    ),
                  if (_speechToText.isNotListening && _confidenceLevel > 0)
                    Text(
                      "Score: ${(_similarityScore * 100).toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w200,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(230, 62, 170, 58),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 159, 61, 172),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 20.0),
                    Text(
                      widget.category,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.0),
              Expanded(child: allQuiz()),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Row(
              children: [
                FloatingActionButton(
                  onPressed: _speechToText.isListening
                      ? _stopListening
                      : _startListening,
                  tooltip: 'Listen',
                  child: Icon(
                    _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 20.0),
                if (_canProceed)
                  ElevatedButton(
                    onPressed: _handleNextPage,
                    child: Text(currentPage == totalPages - 1 ? 'Complete' : 'Next'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}