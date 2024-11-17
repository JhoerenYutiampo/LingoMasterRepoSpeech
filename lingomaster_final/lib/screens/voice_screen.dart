import 'package:flutter/material.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:lingomaster_final/service/databaseMethods.dart';
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

class _VoiceScreenState extends State<VoiceScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SpeechToText _speechToText = SpeechToText();
  final DatabaseMethods _databaseMethods = DatabaseMethods();
  final Random _random = Random();
  
  bool _isRecordingAvailable = false;
  String _wordsSpoken = "";
  double _confidenceLevel = 0;
  double _similarityScore = 0;
  bool _isRecording = false;
  bool _isAudioCompleted = false;
  bool get _isCharacterMode => widget.collectionName == 'characters';

  int _getLevelFromCollection() => switch (widget.collectionName) {
    'characters' => 1,
    'words' => 2,
    'phrases' => 3,
    _ => 1,
  };

  @override
  void initState() {
    super.initState();
    if (!_isCharacterMode) {
      _initSpeech();
      _checkPermissions();
    }
    _setupAudioListener();
  }

  void _setupAudioListener() {
    _audioPlayer.onPlayerComplete.listen((event) {
      if (_isCharacterMode && !_isAudioCompleted) {
        _handleCharacterCompletion();
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speechToText.initialize(
        onError: (error) => print('Speech recognition error: $error'),
        onStatus: (status) => print('Speech recognition status: $status'),
      );
      if (mounted) {
        setState(() => _isRecordingAvailable = available);
      }
    } catch (e) {
      print('Failed to initialize speech recognition: $e');
      if (mounted) {
        setState(() => _isRecordingAvailable = false);
      }
    }
  }

  Future<void> _checkPermissions() async {
    final micPermission = await Permission.microphone.request();
    if (!micPermission.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required for this feature'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _playAudio() async {
    try {
      await _audioPlayer.play(UrlSource(widget.audio));
    } catch (e) {
      print('Error playing audio: $e');
      if (_isCharacterMode) {
        // If audio fails but we're in character mode, still complete
        _handleCharacterCompletion();
      }
    }
  }

  Future<void> _handleCharacterCompletion() async {
    if (_isAudioCompleted) return; // Prevent multiple completions

    setState(() {
      _isAudioCompleted = true;
    });

    await _databaseMethods.addCompletedQuestion(
      widget.questionId,
      _getLevelFromCollection(),
      'voice'
    );
    
    if (mounted) {
      _showCompletionDialog(passed: true, isCharacter: true);
    }
  }

  Future<void> _startRecording() async {
    if (!_isRecordingAvailable || _isRecording) return;

    setState(() {
      _isRecording = true;
      _wordsSpoken = "";
      _confidenceLevel = 0;
      _similarityScore = 0;
    });

    await _speechToText.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _wordsSpoken = result.recognizedWords;
            _confidenceLevel = result.confidence;
            _similarityScore = _wordsSpoken.toLowerCase()
                .similarityTo(widget.pronunciation.toLowerCase());
          });
        }
      },
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
    );
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    await _speechToText.stop();
    if (mounted) {
      setState(() => _isRecording = false);
      
      if (_wordsSpoken.isNotEmpty) {
        _showCompletionDialog(
          passed: _similarityScore >= 0.60,
          isCharacter: false,
        );
      }
    }
  }

  Future<void> _showCompletionDialog({
    required bool passed,
    required bool isCharacter,
  }) async {
    if (passed) {
      final level = _getLevelFromCollection();
      await _databaseMethods.addCompletedQuestion(
        widget.questionId,
        level,
        'voice'
      );
      
      if (!isCharacter) {
        final randomBonus = _random.nextInt(10) + 1;
        final totalExp = 20 + randomBonus;
        await _databaseMethods.modifyUserExp(totalExp);
      }
    }
    
    if (!mounted) return;

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
            if (!isCharacter) ...[
              Text(
                'Your pronunciation score: ${(_similarityScore * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Confidence level: ${(_confidenceLevel * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'You said: $_wordsSpoken',
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Target pronunciation: ${widget.pronunciation}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (passed && !isCharacter) ...[
              const SizedBox(height: 10),
              const Text(
                "XP Added!",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!passed)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _wordsSpoken = "";
                  _confidenceLevel = 0;
                  _similarityScore = 0;
                });
              },
              child: const Text('Try Again', style: TextStyle(fontSize: 16)),
            ),
          if (passed)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text(
                'Continue', 
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
        title: const Text('Practice Pronunciation'),
        backgroundColor: Colors.purple,
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
            const SizedBox(height: 20),
            
            Text(
              'Pronounced as: ${widget.pronunciation}',
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 40),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.hearing, size: 40),
                      onPressed: _isAudioCompleted ? null : _playAudio,
                      color: _isAudioCompleted ? Colors.grey : Colors.black,
                    ),
                    Text(
                      _isAudioCompleted ? 'Completed!' : 'Listen to it',
                      style: TextStyle(
                        color: _isAudioCompleted ? Colors.grey : Colors.black,
                      ),
                    ),
                  ],
                ),
                if (!_isCharacterMode) ...[
                  const SizedBox(width: 60),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isRecording ? Icons.mic : Icons.mic_none,
                          size: 40,
                          color: _isRecording 
                              ? Colors.red 
                              : (_isRecordingAvailable ? Colors.black : Colors.grey),
                        ),
                        onPressed: _isRecordingAvailable && !_isAudioCompleted
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
              ],
            ),
            const SizedBox(height: 20),
              
            if (_wordsSpoken.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'You said: $_wordsSpoken',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}