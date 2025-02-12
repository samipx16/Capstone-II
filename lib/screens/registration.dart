import 'package:flutter/material.dart';
import 'dashboard.dart';

class RegisterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white, // Full white background
        child: SingleChildScrollView(
          // Prevents overflow issues
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/eco_eagle_logo.png', height: 100),
                    Text(
                      "Join Us & Get Started!",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0x1A00853E), // 10% opacity of #00853E
                        prefixIcon: Icon(Icons.person),
                        hintText: "First and Last Name",
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(10), // Rounded corners
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0x1A00853E), // 10% opacity of #00853E
                        prefixIcon: Icon(Icons.email),
                        hintText: "Email",
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(10), // Rounded corners
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0x1A00853E), // 10% opacity of #00853E
                        prefixIcon: Icon(Icons.lock),
                        hintText: "Password",
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(10), // Rounded corners
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0x1A00853E), // 10% opacity of #00853E
                        prefixIcon: Icon(Icons.lock),
                        hintText: "Re-Type Password",
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(10), // Rounded corners
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DashboardScreen()),
                        );
                      },
                      child: Text("REGISTER",
                          style: TextStyle(
                              color: Colors.white)), // White text color
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF00853E), // #00853E color
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10), // 10 corner radius
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15), // Adjust size
                      ),
                    ),
                  ],
                ),
              ),
              Image.asset(
                'assets/trees.png',
                width: double.infinity, // Full width
                fit: BoxFit.cover, // Cover the width
              ),
            ],
          ),
        ),
      ),
    );
  }
}
