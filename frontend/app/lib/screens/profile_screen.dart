import 'package:flutter/material.dart';
import '../data/user_api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.userId,
    required this.email,
    required this.nickname,
  });

  final int userId;
  final String email;
  final String nickname;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await UserApiService.fetchStats(widget.userId);
    if (mounted) setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final diaryCount = _stats?.diaryCount ?? 0;
    final streak = _stats?.streak ?? 0;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xFFFFE082),
              child: Icon(Icons.person, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              widget.nickname,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.email,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                _StatCard(label: '작성한 일기', value: '$diaryCount'),
                const SizedBox(width: 12),
                _StatCard(label: '연속 기록', value: '$streak일'),
                const SizedBox(width: 12),
                _StatCard(label: '감정 유형', value: '0가지'),
              ],
            ),
            const SizedBox(height: 32),
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
                onTap: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                ),
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
