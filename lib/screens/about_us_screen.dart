import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.getTextColor(context);
    final textGrey = AppTheme.getTextGreyColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'About Us',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We are a passionate team of developers and designers focused on building a smart and user-friendly expense tracker application. Our goal is to help users manage their daily finances efficiently by providing clear insights, simple tracking tools, and an intuitive interface.',
              style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.8), height: 1.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Our mission is to help users monitor spending, control budgets, and make informed financial decisions with ease and confidence.',
              style: TextStyle(
                  fontSize: 14,
                  color: textColor.withValues(alpha: 0.8),
                  height: 1.5,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 48),
            Text(
              'OUR TEAM',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: textGrey,
              ),
            ),
            const SizedBox(height: 24),
            _TeamCard(
              name: 'Ermias Dereje',
              role: 'UI/UX Designer',
              id: 'ATE/4952/15',
              description: 'Crafts a clean, intuitive, and engaging user experience.',
              imagePath: 'assets/ermias.jpg',
              borderColor: const Color(0xFF00B4DB).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            _TeamCard(
              name: 'Habtewold Mazengiya',
              role: 'Developer',
              id: 'ATE/5127/25',
              description: 'Develops core features focusing on performance and scalability.',
              imagePath: 'assets/habte.png',
              borderColor: const Color(0xFF00B4DB).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            _TeamCard(
              name: 'Yassin Rahmeto',
              role: 'Team Leader',
              id: 'ATE/6776/15',
              description: 'Oversees the project and ensures successful delivery.',
              imagePath: 'assets/yassin.png',
              borderColor: const Color(0xFF00B4DB).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 48),
            _MissionVisionCard(
              title: 'OUR MISSION',
              content:
                  'To provide a reliable and easy-to-use expense tracking solution that helps users gain full control over their finances.',
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _MissionVisionCard(
              title: 'OUR VISION',
              content:
                  'To become a trusted personal finance tool that simplifies money management through innovation and user-centered design.',
              isDark: isDark,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final String name;
  final String role;
  final String id;
  final String description;
  final String? imagePath;
  final Color borderColor;

  const _TeamCard({
    required this.name,
    required this.role,
    required this.id,
    required this.description,
    this.imagePath,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2130).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.2),
                shape: imagePath != null ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: imagePath != null ? BorderRadius.circular(12) : null,
                border: Border.all(color: borderColor.withValues(alpha: 0.4), width: 1),
                image: imagePath != null ? DecorationImage(
                  image: AssetImage(imagePath!),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: imagePath == null ? Center(
                child: Text(
                  name.split(' ').map((e) => e[0]).join(),
                  style: TextStyle(
                    color: borderColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5CC8FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    id,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
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

class _MissionVisionCard extends StatelessWidget {
  final String title;
  final String content;
  final bool isDark;

  const _MissionVisionCard({
    required this.title,
    required this.content,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2130).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
