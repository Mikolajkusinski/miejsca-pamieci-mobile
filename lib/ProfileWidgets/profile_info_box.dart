import 'package:flutter/material.dart';

class ProfileInfoBox extends StatelessWidget {
  final String username;
  final String email;

  const ProfileInfoBox(
      {super.key, required this.username, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 58,
            backgroundColor: Colors.transparent,
            child: ClipOval(
              child: Image.asset(
                'lib/assets/images/user.png',
              ),
            ),
          ),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 80,
              ),
              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
