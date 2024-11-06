import 'package:flutter/material.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceScreen extends StatefulWidget {
  final String hiragana;
  final String english;
  final String audio;

  const VoiceScreen({
    Key? key,
    required this.hiragana,
    required this.english,
    required this.audio,
  }) : super(key: key);

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SpeechToText _speechToText = SpeechToText();
  final List<double> _audioLevels = List.filled(30, 0.0);
  late AnimationController _animationController;
  
  bool _isRecordingAvailable = false;
  String _wordsSpoken = "";
  double _confidenceLevel = 0;
  double _similarityScore = 0;
  bool _isRecording = false;
  double _currentAudioLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _checkPermissions();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 50),
    );
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
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
      // Reset audio levels when starting new recording
      for (int i = 0; i < _audioLevels.length; i++) {
        _audioLevels[i] = 0.0;
      }
    });

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _wordsSpoken = result.recognizedWords;
          _confidenceLevel = result.confidence;
          _similarityScore = _wordsSpoken.toLowerCase().similarityTo(widget.english.toLowerCase());
        });
      },
      listenFor: Duration(seconds: 5),
      pauseFor: Duration(seconds: 2),
      partialResults: true,
      onSoundLevelChange: (level) {
        setState(() {
          // Convert the level to a value between 0 and 1
          _currentAudioLevel = (level + 160) / 160; // Normalize from dB
          _currentAudioLevel = _currentAudioLevel.clamp(0.0, 1.0);
          
          // Shift array and add new value
          _audioLevels.removeAt(0);
          _audioLevels.add(_currentAudioLevel);
        });
      },
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );

    _animationController.repeat();
  }

  Future<void> _stopRecording() async {
    await _speechToText.stop();
    setState(() {
      _isRecording = false;
      _currentAudioLevel = 0.0;
    });
    _animationController.stop();
    
    if (_wordsSpoken.isNotEmpty) {
      _showScoreDialog();
    }
  }

  void _showScoreDialog() {
    final bool passed = _similarityScore >= 0.60;
    
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
            Text(
              'Your pronunciation score: ${(_similarityScore * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Confidence level: ${(_confidenceLevel * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'You said: $_wordsSpoken',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 4),
            Text(
              'Target word: ${widget.english}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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

  Widget _buildAudioLevelIndicator() {
    return Container(
      height: 100,
      width: MediaQuery.of(context).size.width * 0.8,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: AudioLevelPainter(
            audioLevels: _audioLevels,
            isListening: _isRecording,
          ),
          size: Size(MediaQuery.of(context).size.width * 0.8, 100),
        ),
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
                fontSize: 120,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            
            Text(
              'Pronounced as: ${widget.english}',
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
                      style: TextStyle(
                        color: _isRecordingAvailable ? Colors.black : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            
            _buildAudioLevelIndicator(),
            
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

class AudioLevelPainter extends CustomPainter {
  final List<double> audioLevels;
  final bool isListening;

  AudioLevelPainter({
    required this.audioLevels,
    required this.isListening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = (size.width / audioLevels.length) * 0.8
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / audioLevels.length;
    final centerY = size.height / 2;
    
    for (int i = 0; i < audioLevels.length; i++) {
      final barHeight = audioLevels[i] * (size.height * 0.8); // Use 80% of the height
      final x = i * barWidth;
      
      // Create a gradient effect based on the audio level
      paint.color = isListening 
          ? Color.lerp(Colors.blue[300]!, Colors.blue[700]!, audioLevels[i])!
          : Colors.grey[300]!;

      // Draw bar from center, expanding both up and down
      final halfBarHeight = barHeight / 2;
      canvas.drawLine(
        Offset(x + barWidth / 2, centerY - halfBarHeight),
        Offset(x + barWidth / 2, centerY + halfBarHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(AudioLevelPainter oldDelegate) => 
      oldDelegate.isListening != isListening ||
      oldDelegate.audioLevels != audioLevels;
}