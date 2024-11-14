import 'package:flutter/material.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:lingomaster_final/service/database.dart';
import 'dart:math';

class VoiceScreen extends StatefulWidget {
  final String hiragana;
  final String english;
  final String audio;
  final String questionId;
  final String collectionName;
  final String pronunciation;

  const VoiceScreen({
    Key? key,
    required this.hiragana,
    required this.english,
    required this.audio,
    required this.questionId,
    required this.collectionName,
    required this.pronunciation,
  }) : super(key: key);

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SpeechToText _speechToText = SpeechToText();
  final DatabaseMethods _databaseMethods = DatabaseMethods();
  final Random _random = Random();
  
  bool _isRecordingAvailable = false;
  String _wordsSpoken = "";
  double _confidenceLevel = 0;
  double _similarityScore = 0;
  bool _isRecording = false;

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

  Future<void> _showScoreDialog() async {
    bool isCharacterCollection = widget.collectionName == 'characters';
    bool passed = isCharacterCollection ? true : _similarityScore >= 0.60;
    
    if (!mounted) return;

    if (passed) {
      int level = _getLevelFromCollection();
      await _databaseMethods.addCompletedQuestion(
        widget.questionId,
        level,
        'voice'
      );
      
      int randomBonus = _random.nextInt(10) + 1;
      int baseExp = 20;
      int totalExp = baseExp + randomBonus;
      await _databaseMethods.modifyUserExp(totalExp);
    } else {
      await _databaseMethods.modifyUserHearts(-1);
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          passed ? 'Great Job!' : 'Keep Practicing!',
          style: TextStyle(
            color: passed ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCharacterCollection) ...[
              Text(
                'Your pronunciation score: ${(_similarityScore * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Confidence level: ${(_confidenceLevel * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 16),
              ),
            ],
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
            if (passed) ...[
              SizedBox(height: 10),
              Text(
                "XP Added!",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
            ] else ...[
              SizedBox(height: 10),
              Text(
                "Lost 1 Heart",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _wordsSpoken = "";
                _confidenceLevel = 0;
                _similarityScore = 0;
              });
            },
            child: Text('Try Again', style: TextStyle(fontSize: 16)),
          ),
          if (passed)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('Continue', 
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green,
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Practice Pronunciation'),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.hiragana,
              style: TextStyle(
                fontSize: 120 / (widget.hiragana.length.clamp(1, 10) * 0.6), // Adjusts size based on length
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            
            Text(
              'Pronounced as: ${widget.pronunciation}',
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
                      onPressed: _isRecordingAvailable && (widget.collectionName != 'characters' || !_isRecording)
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
    );
  }
}