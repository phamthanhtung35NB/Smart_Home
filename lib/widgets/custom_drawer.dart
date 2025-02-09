import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        margin: const EdgeInsets.only(top: kToolbarHeight),
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
                image: DecorationImage(
                  fit: BoxFit.contain,
                  image: AssetImage('assets/images/logo.png'),
                ),
              ),
              child: null,
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Navigate to Home screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Quick Reply'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Navigate to Quick Reply screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Navigate to Settings screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(builder: (context) => const LoginScreen()),
                // );
              },
            ),
          ],
        ),
      ),
    );
  }
}
