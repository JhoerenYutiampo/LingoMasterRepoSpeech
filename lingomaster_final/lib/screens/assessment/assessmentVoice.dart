import 'package:flutter/material.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AssessmentVoice extends StatefulWidget {
  final String hiragana;
  final String english;
  final String audio;
  final String pronunciation;

  const AssessmentVoice({
    Key? key,
    required this.hiragana,
    required this.english,
    required this.audio,
    required this.pronunciation,
  }) : super(key: key);

  @override
  State<AssessmentVoice> createState() => _AssessmentVoiceState();
}

class _AssessmentVoiceState extends State<AssessmentVoice> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SpeechToText _speechToText = SpeechToText();
  
  bool _isRecordingAvailable = false;
  String _wordsSpoken = "";
  double _confidenceLevel = 0;
  double _similarityScore = 0;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _checkPermissions();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speechToText.initialize(
        onError: (error) => print('Speech recognition error: $error'),
        onStatus: (status) => print('Speech recognition status: $status'),
      );
      setState(() {
        _isRecordingAvailable = available;
      });
    } catch (e) {
      print('Failed to initialize speech recognition: $e');
      setState(() {
        _isRecordingAvailable = false;
      });
    }
  }

  Future<void> _checkPermissions() async {
    final micPermission = await Permission.microphone.request();
    
    if (!micPermission.isGranted) {
      _showPermissionError('Microphone');
    }
  }

  void _showPermissionError(String permissionType) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$permissionType permission is required for this feature'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _playAudio() async {
    await _audioPlayer.play(UrlSource(widget.audio));
  }

  Future<void> _startRecording() async {
    if (!_isRecordingAvailable) return;

    setState(() {
      _isRecording = true;
      _wordsSpoken = "";
      _confidenceLevel = 0;
      _similarityScore = 0;
    });

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _wordsSpoken = result.recognizedWords;
          _confidenceLevel = result.confidence;
          _similarityScore = _wordsSpoken.toLowerCase().similarityTo(widget.pronunciation.toLowerCase());
        });
      },
      listenFor: Duration(seconds: 5),
      pauseFor: Duration(seconds: 2),
      partialResults: true,
    );
  }

  Future<void> _stopRecording() async {
    await _speechToText.stop();
    setState(() {
      _isRecording = false;
    });
    
    if (_wordsSpoken.isNotEmpty) {
      _showScoreDialog();
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

  Future<void> _showScoreDialog() async {
    bool passed = _similarityScore >= 0.60;
    int score = passed ? 1 : 0;
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          passed ? 'Great Job!' : 'Incorrect',
          style: TextStyle(
            color: passed ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your pronunciation score: ${(_similarityScore * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'You said: $_wordsSpoken',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 4),
            Text(
              'Target pronunciation: ${widget.pronunciation}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, score);
            },
            child: Text('Continue', 
              style: TextStyle(
                fontSize: 16,
                color: passed ? Colors.green : Colors.red,
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
          title: Text('Practice Pronunciation'),
          backgroundColor: Colors.purple,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showExitConfirmationDialog,
          ),
        ),
      body: Center(
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
            SizedBox(height: 20),
            
            Text(
              'English: ${widget.english}',
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 40),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.hearing, size: 40),
                      onPressed: _playAudio,
                    ),
                    Text('Listen to it'),
                  ],
                ),
                SizedBox(width: 60),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        size: 40,
                        color: _isRecording ? Colors.red : (_isRecordingAvailable ? Colors.black : Colors.grey),
                      ),
                      onPressed: _isRecordingAvailable
                          ? (_isRecording ? _stopRecording : _startRecording)
                          : null,
                      tooltip: _isRecordingAvailable 
                          ? (_isRecording ? 'Stop' : 'Start') 
                          : 'Recording not available',
                    ),
                    Text(
                      _isRecording 
                          ? 'Recording...' 
                          : (_isRecordingAvailable ? 'Begin' : 'Not available'),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
              
            if (_wordsSpoken.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'You said: $_wordsSpoken',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}