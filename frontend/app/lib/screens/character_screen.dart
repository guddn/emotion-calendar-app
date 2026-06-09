// 캐릭터가 보여지는 메인 인터페이스
import 'package:flutter/material.dart';

import 'chat_screen.dart';

class MainChatScreen extends StatelessWidget {
  const MainChatScreen({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFE082).withOpacity(0.5),
                        blurRadius: 25, 
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'lib/characters/Iro.png',
                    width: 170,
                    height: 170,
                    fit: BoxFit.contain,
                    ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDE7),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: ChatScreen(userId: userId),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}