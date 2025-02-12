import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Welcome Back")),
      body: Container(
        color: Colors.green.shade800, // Green background for the whole page
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text("Good Morning, Sustainability Hero!",
                  style: TextStyle(fontSize: 18, color: Colors.white)),
              SizedBox(height: 10),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(children: [
                        Icon(Icons.emoji_events, color: Colors.green),
                        Text("65 pts")
                      ]),
                      Column(children: [
                        Icon(Icons.leaderboard, color: Colors.green),
                        Text("#7th Rank")
                      ]),
                      Column(children: [
                        Icon(Icons.recycling, color: Colors.green),
                        Text("13 Recycled")
                      ]),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: Icon(Icons.map, color: Colors.green),
                  title: Text("Find the closest Recycle Bin"),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipPath(
            clipper: BottomNavBarClipper(),
            child: BottomNavigationBar(
              backgroundColor: Colors.white,
              selectedItemColor: Colors.green, // Selected icon color
              unselectedItemColor: Colors.grey, // Unselected icon color
              showUnselectedLabels:
                  true, // Ensure all labels are always visible
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.emoji_events), label: "Challenges"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.star), label: "Milestones"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.account_circle), label: "Account"),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: () {},
              child: Icon(Icons.qr_code, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class BottomNavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(size.width * 0.4, 0);
    path.quadraticBezierTo(size.width * 0.5, 50, size.width * 0.6, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
