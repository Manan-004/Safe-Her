import 'package:flutter/material.dart';

class NavHeader extends StatelessWidget {
  final String username;
  final String imagePath;

  const NavHeader({
    super.key,
    required this.username,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, bottom: 24, top: 36),
      alignment: Alignment.bottomLeft,
      decoration: const BoxDecoration(
        color: Color(0xFFFFC0CB), // BabyPink
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular profile picture
          CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage(imagePath),
          ),

          const SizedBox(height: 8),

          // Greeting text
          Text(
            "Hey $username !!!",
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
