import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'homepage.dart';
import 'loginSignUp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures all plugins are loaded
  FilePicker.platform; // Initializes the file_picker instance
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DropIt',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  TextEditingController userNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLogin = true; // Tracks whether we're in Login or Sign Up mode
  @override
  void initState() {
    super.initState();
  }

  void handleAuth(BuildContext context, int statusCode) async {
    if (statusCode == 0) {
      // Fields are empty - Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error"),
            content: const Text("Please fill in all fields."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } else if (statusCode == 200 || statusCode == 201) {
      // Signup/Login successful - Navigate to Main Page
      List<String> files = [];
      if (statusCode == 200) {
        files = await getFileMetaData(userNameController.text);
      }
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomePage(
                  username: userNameController.text,
                  files: files,
                )),
      );
    } else if (statusCode == 400) {
      // User already exists - Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("User Exists"),
            content:
                const Text("This username is already taken. Try another one."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } else {
      // Invalid credentials or server issue - Show generic error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Login Failed"),
            content:
                const Text("Invalid credentials or server issue. Try again."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text("DropIt"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                isLogin = true;
              });
            },
            child: Text("Login",
                style: TextStyle(
                    color: isLogin ? Colors.white : Colors.grey[300])),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                isLogin = false;
              });
            },
            child: Text("Sign Up",
                style: TextStyle(
                    color: isLogin ? Colors.grey[300] : Colors.white)),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Determine card width based on screen size
          double cardWidth = constraints.maxWidth > 600
              ? constraints.maxWidth * 0.3
              : constraints.maxWidth * 0.9;

          // Ensure the card isn't too wide on large screens
          cardWidth = cardWidth > 500 ? 500 : cardWidth;

          return Center(
            child: SingleChildScrollView(
              child: SizedBox(
                width: cardWidth,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                      constraints.maxWidth > 600 ? 20 : 15,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLogin ? "Welcome Back!" : "Create an Account",
                          style: TextStyle(
                            fontSize: constraints.maxWidth > 600 ? 22 : 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: userNameController,
                          decoration: const InputDecoration(
                            labelText: "Name",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: passwordController,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            int statusCode = await auth(
                              userNameController.text.isNotEmpty
                                  ? userNameController.text
                                  : "",
                              passwordController.text.isNotEmpty
                                  ? passwordController.text
                                  : "",
                              isLogin ? "login" : "signup",
                            );
                            if (!context.mounted) return;
                            handleAuth(context, statusCode);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: EdgeInsets.symmetric(
                              horizontal: constraints.maxWidth > 600 ? 50 : 30,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isLogin ? "Login" : "Sign Up",
                            style: TextStyle(
                              fontSize: constraints.maxWidth > 600 ? 18 : 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
