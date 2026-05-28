import 'package:flutter/material.dart';

class SecondFragmentPage extends StatelessWidget {
  const SecondFragmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // button_second
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/firstFragment");
                },
                child: const Text("Previous"),
              ),

              const SizedBox(height: 16),

              // textview_second
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
