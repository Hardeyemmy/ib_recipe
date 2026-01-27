import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Auth extends StatelessWidget {
  const Auth({required this.loggedIn, required this.signOut, super.key});

  final bool loggedIn;
  final VoidCallback signOut;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
              onPressed: () {
                !loggedIn ? context.push('/login') : signOut();
              },
              child: !loggedIn ? const Text('RSVP') : const Text('Logout')),
        ),
        Visibility(
            visible: loggedIn,
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                    onPressed: () {
                      context.push('/profile');
                    },
                    child: const Text("Profile"))))
      ],
    );
  }
}
