import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Ensures the user cannot go back to the home page
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Get current user
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.lightGreen,
        title: const Text( // Using const for Text widget
          "Flutter Home page",
          style: TextStyle(
            fontSize: 40,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome to the Home page",
              style: TextStyle(
                color: Colors.black,
                fontSize: 40,
              ),
            ),
            const SizedBox(height: 20),
            if (user != null)
              Text(
                "Logged in as: ${user.email}",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ⭐ MODIFIED: Dynamic DrawerHeader
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.lightGreen, Colors.black, Colors.indigo],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    // Use user photoURL if available, otherwise use asset
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : const AssetImage("images/imaage.png") as ImageProvider,
                    radius: 40,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    // Use user displayName or a placeholder
                    user?.displayName ?? "SALMA RAHILI",
                    style: const TextStyle(
                      color: Colors.white, // Changed color for better contrast
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    // Use user email
                    user?.email ?? "rahilisalma417@gmail.com",
                    style: const TextStyle(
                      fontSize: 12, // Increased size for readability
                      color: Colors.white, // Changed color for better contrast
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            // ⭐ MODIFIED: Link to FruitClassifierPage
            ListTile(
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.pushNamed(context, '/classifier'); // Navigate to the new page
              },
              leading: const Icon(
                Icons.apple, // Changed icon for relevance
                color: Colors.pinkAccent,
                size: 30,
              ),
              title: const Text(
                'Fruit Classifier (TFLite)',
                style: TextStyle(color: Colors.lightGreen, fontSize: 20),
              ),
            ),
            const Divider(color: Colors.lightGreen, thickness: 5),
            ListTile(
              onTap: () {
                Navigator.pop(context);
              },
              leading: const Icon(
                Icons.chat,
                color: Colors.black,
                size: 30,
              ),
              title: const Text(
                'EMSI CHATBOT',
                style: TextStyle(color: Colors.lightGreen, fontSize: 20),
              ),
            ),
            const Divider(color: Colors.lightGreen, thickness: 5),
            ListTile(
              onTap: () {
                Navigator.pop(context);
              },
              leading: const Icon(
                Icons.person,
                color: Colors.blue,
                size: 30,
              ),
              title: const Text(
                'PROFILE',
                style: TextStyle(color: Colors.lightGreen, fontSize: 20),
              ),
            ),
            const Divider(color: Colors.lightGreen, thickness: 5),
            ListTile(
              onTap: () {
                Navigator.pop(context);
              },
              leading: const Icon(
                Icons.settings,
                color: Colors.purpleAccent,
                size: 30,
              ),
              title: const Text(
                'SETTINGS',
                style: TextStyle(color: Colors.lightGreen, fontSize: 20),
              ),
            ),
            const Divider(color: Colors.lightGreen, thickness: 5),
            ListTile(
              onTap: () => _logout(context),
              leading: const Icon(
                Icons.logout,
                color: Colors.lightBlueAccent,
                size: 30,
              ),
              title: const Text(
                'LOGOUT',
                style: TextStyle(color: Colors.lightGreen, fontSize: 20),
              ),
            ),
            const Divider(color: Colors.lightGreen, thickness: 5),
          ],
        ),
      ),
    );
  }
}