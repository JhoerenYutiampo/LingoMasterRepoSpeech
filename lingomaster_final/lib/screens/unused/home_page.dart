import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:lingomaster_final/screens/profile/profile.dart';
import 'package:lingomaster_final/screens/unused/letters.dart';
import 'package:lingomaster_final/screens/unused/question.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    HomeScreen(),
    Letters(),
    ProfilePage(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
              title: const Text("H O M E"),
              centerTitle: true,
            )
          : null,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
        child: GNav(
          rippleColor: Colors.grey,
          hoverColor: Colors.grey,
          haptic: true,
          tabBorderRadius: 15,
          tabActiveBorder: Border.all(color: Colors.black, width: 1),
          tabBorder: Border.all(color: Colors.grey, width: 1),
          tabShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 8)
          ],
          curve: Curves.easeOutExpo,
          duration: Duration(milliseconds: 200),
          gap: 2, // Reduced gap between icon and text
          color: Colors.grey[800],
          activeColor: Colors.green,
          iconSize: 24,
          tabBackgroundColor: Colors.purple.withOpacity(0.1),
          padding: EdgeInsets.symmetric(
              horizontal: 10, vertical: 5), // Reduced padding
          selectedIndex: _selectedIndex,
          onTabChange: _onTabSelected,
          tabs: [
            GButton(
              icon: Icons.home,
              text: 'Home',
            ),
            GButton(
              icon: Icons.label,
              text: 'Characters',
            ),
            GButton(
              icon: Icons.person,
              text: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 100),
            _buildLevelCard(context, "Tutorial"),
            SizedBox(height: 100),
            _buildLevelCard(context, "Level 1"),
            SizedBox(height: 100),
            _buildLevelCard(context, "Level 2"),
            SizedBox(height: 100),
            _buildLevelCard(context, "Level 3"),
            SizedBox(height: 100),
            _buildLevelCard(context, "Level 4"),
            SizedBox(height: 100),
            _buildLevelCard(context, "Level 5"),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, String category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Question(category: category),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white, // Background color
              border: Border.all(
                  color: Colors.black, width: 2), // Border color and width
              borderRadius: BorderRadius.circular(15), // Rounded corners
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                "assets/images/levels.png",
                fit: BoxFit.cover,
              ),
            ),
          ),
          Text(
            category,
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
