import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _signIn(BuildContext context) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failed: \${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Allows resizing when keyboard appears
      body: SafeArea( // Prevents overlap with system UI
        child: SingleChildScrollView( // Makes the screen scrollable
          child: Container(
            color: Colors.white, // Plain white background
            height: MediaQuery.of(context).size.height, // Maintain full height
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/eco_eagle_logo.png', height: 150),
                          Text("Welcome Back!",
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black)),
                          SizedBox(height: 20),
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Color(0x1A00853E), // 10% opacity of #00853E
                              prefixIcon: Icon(Icons.person,
                                  color: Color.fromARGB(255, 47, 48, 47)),
                              hintText: "Email",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10), // Rounded corners
                                borderSide: BorderSide(color: Color(0xFF00853E)),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Color(0x1A00853E), // 10% opacity of #00853E
                              prefixIcon: Icon(Icons.lock,
                                  color: Color.fromARGB(255, 47, 48, 47)),
                              hintText: "Password",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10), // Rounded corners
                                borderSide: BorderSide(color: Color(0xFF00853E)),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => _signIn(context),
                            child: Text("SIGN IN",
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF00853E), // Green button
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10), // Rounded corners
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15), // Adjust size
                            ),
                          ),
                          TextButton(
                              onPressed: () {},
                              child: Text("Forgot Password?",
                                  style: TextStyle(
                                      color: const Color.fromARGB(
                                          255, 32, 127, 236)))),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    'assets/trees.png',
                    width: double.infinity, // Full width
                    fit: BoxFit.cover, // Cover the width
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
