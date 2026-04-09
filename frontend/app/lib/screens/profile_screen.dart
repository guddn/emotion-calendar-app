import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 프로필 사진 + 이름
            const CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xFFD1C4E9),
              child: Icon(Icons.person, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              '사용자 닉네임',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'user@example.com',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            // 통계 카드
            Row(
              children: [
                _StatCard(label: '작성한 일기', value: '0'),
                const SizedBox(width: 12),
                _StatCard(label: '연속 기록', value: '0일'),
                const SizedBox(width: 12),
                _StatCard(label: '감정 유형', value: '0가지'),
              ],
            ),
            const SizedBox(height: 32),
            // 설정 메뉴
            _MenuSection(items: [
              _MenuItem(icon: Icons.edit_outlined, label: '프로필 편집', onTap: () {}),
              _MenuItem(icon: Icons.notifications_outlined, label: '알림 설정', onTap: () {}),
              _MenuItem(icon: Icons.lock_outline, label: '개인정보 보호', onTap: () {}),
            ]),
            const SizedBox(height: 16),
            _MenuSection(items: [
              _MenuItem(icon: Icons.help_outline, label: '도움말', onTap: () {}),
              _MenuItem(
                icon: Icons.logout,
                label: '로그아웃',
                color: Colors.redAccent,
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;

  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: items
            .asMap()
            .entries
            .map((e) => Column(
                  children: [
                    e.value,
                    if (e.key < items.length - 1)
                      const Divider(height: 1, indent: 56),
                  ],
                ))
            .toList(),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.black87;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: TextStyle(color: c, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
