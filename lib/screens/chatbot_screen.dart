// lib/screens/chatbot_screen.dart
//
// Exact conversion of your Kotlin ChatBotActivity + XML -> Flutter
// UI and logic preserved (message model, adapter behavior, left/right bubbles,
// 1s bot response delay, back button, input area with multi-line EditText).
//
// Place this file in lib/screens/ and navigate with:
// Navigator.push(context, MaterialPageRoute(builder: (_) => ChatBotScreen()));
//
// NOTE: This uses only Flutter SDK (no extra packages).

import 'dart:async';
import 'package:flutter/material.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final List<Message> _messages = <Message>[];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(Message(text: text, isUser: true));
    });
    _scrollToBottom();
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(Message(text: text, isUser: false));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    // Use a short delay to let the new item render before scrolling.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getBotResponse(String userMessage) {
    final lowerCaseMessage = ' ' + userMessage.toLowerCase() + ' ';

    if (lowerCaseMessage.contains(' hi ') ||
        lowerCaseMessage.contains(' hello ') ||
        lowerCaseMessage.contains(' hey ')) {
      return "Hey! How can I assist you with the app's features?";
    }
    if (lowerCaseMessage.contains('sos') ||
        lowerCaseMessage.contains('emergency')) {
      return "The SOS feature sends your live location and a picture to your emergency contacts for immediate assistance.";
    }
    if (lowerCaseMessage.contains('panic alarm') ||
        lowerCaseMessage.contains('alarm')) {
      return "The panic alarm creates a loud sound to attract attention in a dangerous situation. You can find it on the main screen.";
    }
    if (lowerCaseMessage.contains('fake call') ||
        lowerCaseMessage.contains('fake')) {
      return "The fake call feature simulates an incoming call, helping you to safely exit an uncomfortable situation.";
    }
    if (lowerCaseMessage.contains('edit profile') ||
        lowerCaseMessage.contains('profile')) {
      return "You can edit your personal details, such as name and profile picture, in the 'Edit Profile' section of the navigation menu.";
    }
    if (lowerCaseMessage.contains('contacts') ||
        lowerCaseMessage.contains('emergency contacts')) {
      return "To manage your emergency contacts, go to the 'Emergency Contacts' option in the navigation menu. This is where you can add, remove, and view your contacts.";
    }
    if (lowerCaseMessage.contains('safe places') ||
        lowerCaseMessage.contains('places')) {
      return "The 'Safe Places' feature allows you to save and view locations that you consider safe. You can find this in the navigation menu.";
    }
    if (lowerCaseMessage.contains('help') ||
        lowerCaseMessage.contains('support')) {
      return "For more detailed information, please visit the 'Help/Support' section in the navigation menu. You'll find FAQs and contact information there.";
    }
    if (lowerCaseMessage.contains('log out') ||
        lowerCaseMessage.contains('logout')) {
      return "To log out of your account, select the 'Log Out' option from the navigation menu.";
    }
    return "I am sorry I cannot answer the question related to this topic.";
  }

  void _onSendPressed() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _addUserMessage(text);
    _controller.clear();

    // simulate typing delay like Handler(Looper.getMainLooper()).postDelayed(...)
    Future.delayed(const Duration(seconds: 1), () {
      final botResponse = _getBotResponse(text);
      _addBotMessage(botResponse);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Colors approximated from your XML/drawables:
    const Color babyPink = Color(0xFFFFC0CB); // header background (BabyPink)
    const Color hotPink = Color(0xFFFF1493); // "Chat" color (HotPink)
    const Color lavender = Color(0xFFE6E6FA); // "bot" color (lavender)
    const Color blushTint = Color(0xFFFFEBF1); // background (BlushTint)
    const Color sentBubbleColor = Color(0xFF6C4B5D); // DeepMauve-ish for sent bubble

    return Scaffold(
      backgroundColor: blushTint,
      // header + body + input similar to your ConstraintLayout arrangement
      body: SafeArea(
        child: Column(
          children: [
            // Header layout (RelativeLayout equivalent)
            Container(
              height: kToolbarHeight,
              color: babyPink,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // back button aligned to start
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: IconButton(
                      icon: Image.asset(
                        'assets/images/back.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (_, __, ___) => const Icon(Icons.arrow_back),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  // centered two-color title
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Chat',
                          style: TextStyle(
                            color: hotPink,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'bot',
                          style: TextStyle(
                            color: lavender,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Messages list (RecyclerView equivalent) - expands to fill
            Expanded(
              child: Container(
                color: Colors.transparent,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    if (message.isUser) {
                      return _UserMessageBubble(text: message.text);
                    } else {
                      return _BotMessageBubble(text: message.text);
                    }
                  },
                ),
              ),
            ),

            // Input container (ConstraintLayout anchored to bottom)
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  // Expanded EditText (multi-line)
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 48,
                        maxHeight: 120,
                      ),
                      child: Scrollbar(
                        child: TextField(
                          controller: _controller,
                          maxLines: 4,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Type a message',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send button
                  ElevatedButton(
                    onPressed: _onSendPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sentBubbleColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Send', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Message model equivalent to Message.kt
class Message {
  final String text;
  final bool isUser;
  Message({required this.text, required this.isUser});
}

// User message bubble -> matches item_message_sent.xml visuals (right aligned, rounded background, white text)
class _UserMessageBubble extends StatelessWidget {
  final String text;
  const _UserMessageBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    const Color sentColor = Color(0xFF6C4B5D); // DeepMauve-like
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end, // align to end (right)
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: sentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Bot message bubble -> matches item_message_received.xml visuals (left aligned, rounded background, black text)
class _BotMessageBubble extends StatelessWidget {
  final String text;
  const _BotMessageBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // align to start (left)
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
              ),
              child: Text(
                text,
                style: const TextStyle(color: Colors.black, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
