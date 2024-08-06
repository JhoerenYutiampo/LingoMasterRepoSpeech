import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lingomaster_final/main.dart';
import 'package:lingomaster_final/screens/home_page.dart';
import 'package:lingomaster_final/service/database.dart';
import 'package:lingomaster_final/screens/speech_card.dart';

class Question extends StatefulWidget {
  final String category;
  Question({required this.category});

  @override
  State<Question> createState() => _QuestionState();
}

class _QuestionState extends State<Question> {
  bool show = false;
  bool isCorrectAnswer = false;
  Stream? quizStream;
  PageController controller = PageController();
  int totalPages = 0;

  @override
  void initState() {
    super.initState();
    getOnTheLoad();
  }

  getOnTheLoad() async {
    quizStream = await DatabaseMethods().getCategoryQuiz(widget.category);
    setState(() {});
  }

  void _handleNextPage() {
    if (isCorrectAnswer) {
      if (controller.page?.toInt() == totalPages - 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SpeechCard(category: widget.category),
          ),
        );
      } else {
        setState(() {
          show = false;
          isCorrectAnswer = false;
        });
        controller.nextPage(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeIn,
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  Widget allQuiz() {
    return StreamBuilder(
      stream: quizStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        totalPages = snapshot.data.docs.length;

        return PageView.builder(
          controller: controller,
          itemCount: totalPages,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];
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
                  ...List.generate(4, (i) {
                    String optionKey = 'option${i + 1}';
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          show = true;
                          isCorrectAnswer = ds["correct"] == ds[optionKey];
                        });
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 1.1,
                        padding: EdgeInsets.all(15),
                        margin: EdgeInsets.only(bottom: 20.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: show && ds["correct"] == ds[optionKey]
                                ? Colors.green
                                : show
                                    ? Colors.red
                                    : Color(0xFF818181),
                            width: 2.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ds[optionKey],
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }),
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
            child: GestureDetector(
              onTap: show ? _handleNextPage : null,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(30),
                  color: show ? Colors.white : Colors.grey,
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: show ? Color.fromARGB(230, 62, 170, 58) : Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
