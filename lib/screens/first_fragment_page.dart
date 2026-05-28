import 'package:flutter/material.dart';

class FirstFragmentPage extends StatelessWidget {
  const FirstFragmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Button (button_first)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/secondFragment");
                },
                child: const Text("Next"),
              ),

              const SizedBox(height: 16),

              // TextView (textview_first)
              const Text(
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
