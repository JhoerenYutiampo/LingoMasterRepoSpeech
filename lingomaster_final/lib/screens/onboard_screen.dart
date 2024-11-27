import 'package:flutter/material.dart';
import 'package:lingomaster_final/screens/dashboard/dashboard_screen.dart';
import 'package:lingomaster_final/utlis/color_utils.dart';
import 'package:lingomaster_final/service/databaseMethods.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final DatabaseMethods _databaseMethods = DatabaseMethods();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingPages = [
    {
      'title': 'Learn Hiragana Easily',
      'description': 'Start your Hiragana learning journey with interactive lessons and enjoyable mechanics.'
    },
    {
      'title': 'Practice Makes Perfect',
      'description': 'Complete questions to earn XP and hearts, each level up will give you one heart.'
    },
    {
      'title': 'Track Your Progress',
      'description': 'Monitor you progress with the dashboard and your current level.'
    },
    {
      'title': 'Test Your Capabilities',
      'description': 'Try the randomized Assessment, be careful because failing means losing 1 heart.'
    }
  ];

  void _completeOnboarding() async {
    await _databaseMethods.setOnboarded(true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hexStringToColor("CB2B93"),
              hexStringToColor("5E6148"),
              hexStringToColor("9546C4"),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _onboardingPages.length,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (context, index) {
                return _buildOnboardingPage(_onboardingPages[index]);
              },
            ),
            Positioned(
              top: 40,
              right: 20,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text(
                  'Start',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingPages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index 
                            ? Colors.white 
                            : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  if (_currentPage == _onboardingPages.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: ElevatedButton(
                        onPressed: _completeOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.purple,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(Map<String, String> page) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          Text(
            page['title']!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            page['description']!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}