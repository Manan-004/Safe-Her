import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class QuickStartPage extends StatefulWidget {
  const QuickStartPage({super.key});

  @override
  State<QuickStartPage> createState() => _QuickStartPageState();
}

class _QuickStartPageState extends State<QuickStartPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    // SAME LOGIC: play video from assets
    _controller = VideoPlayerController.asset("assets/women_safety_video.mp4")
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA), // same background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFFFC0CB), // BabyPink
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              "Safe",
              style: TextStyle(
                color: Color(0xFFFF1493), // HotPink
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Her",
              style: TextStyle(
                color: Color(0xFFE6E6FA), // lavender
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      // Body Scroll
      body: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 16),

                // Title
                const Center(
                  child: Text(
                    "Your Safety, Our Priority",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Center(
                  child: Text(
                    "Welcome to SafeHer, a space designed to help you feel safer and more secure.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  "Precautionary Measures",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "• Be aware of your surroundings at all times.\n"
                      "• Avoid walking alone in poorly lit areas.\n"
                      "• Inform a friend or family member of your whereabouts.",
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  "Empowering Tips",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 16),

                // Video Player
                AspectRatio(
                  aspectRatio:
                  _controller.value.isInitialized ? _controller.value.aspectRatio : 16 / 9,
                  child: _controller.value.isInitialized
                      ? VideoPlayer(_controller)
                      : const Center(child: CircularProgressIndicator()),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Knowing some basic self-defense moves can boost your confidence "
                      "and provide a crucial skill in a threatening situation.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 24),

                // image
                Image.asset(
                  "assets/womensafety1.png",
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                const SizedBox(height: 8),

                const Text(
                  "In a public setting, a fake phone call can be a simple yet "
                      "effective way to exit an uncomfortable situation.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),

      // Bottom fixed button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              // SAME LOGIC AS KOTLIN → Go to Dashboard
              Navigator.pushNamed(context, "/dashboard");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC0CB),
              foregroundColor: Colors.white,
            ),
            child: const Text(
              "Go to Dashboard",
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
