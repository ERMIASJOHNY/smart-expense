import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/image_helper.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(AuthProvider authProvider) async {
    try {
      final XFile? selected = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (selected != null) {
        await authProvider.updateProfileImage(selected.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile image')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final textColor = AppTheme.getTextColor(context);
    final textGrey = AppTheme.getTextGreyColor(context);

    final displayName = authProvider.fullName ?? authProvider.userName ?? 'User Name';
    final displayEmail = authProvider.userEmail ?? 'user@example.com';

    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: AppBar(
        title: Text('Profile',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 3),
                      image: authProvider.profileImagePath != null
                          ? DecorationImage(
                              image: getPlatformImageProvider(authProvider.profileImagePath!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: authProvider.profileImagePath == null
                        ? Center(
                            child: Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 44,
                              ),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _pickImage(authProvider),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.getBackground(context), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(displayName,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 4),
            Text(displayEmail,
                style: TextStyle(fontSize: 14, color: textGrey)),
            const SizedBox(height: 40),

            // Account Settings Section (Matches requested image)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.getCardColor(context),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, size: 28, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Account Settings',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      // Dark Mode Toggle Button
                      IconButton(
                        onPressed: () => themeProvider.toggleTheme(!themeProvider.isDarkMode),
                        icon: Icon(
                          themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          color: themeProvider.isDarkMode ? Colors.amber : AppColors.primary,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _buildSubSettingTile(
                    context,
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    onTap: () {},
                  ),
                  _buildSubSettingTile(
                    context,
                    icon: Icons.security_rounded,
                    title: 'Security',
                    onTap: () {},
                  ),
                  if (authProvider.isAdmin)
                    _buildSubSettingTile(
                      context,
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'Admin Panel',
                      iconColor: AppColors.secondary,
                      onTap: () => Navigator.pushNamed(context, '/admin'),
                    ),
                  _buildSubSettingTile(
                    context,
                    icon: Icons.delete_forever_rounded,
                    title: 'Delete Account',
                    iconColor: Colors.redAccent,
                    textColor: Colors.redAccent,
                    onTap: () => _showDeleteAccountDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About Us',
              trailing:
                  Icon(Icons.arrow_forward_ios, size: 16, color: textGrey),
              onTap: () {
                Navigator.pushNamed(context, '/about_us');
              },
              textColor: textColor,
              textGrey: textGrey,
              cardColor: AppTheme.getCardColor(context),
            ),
            const SizedBox(height: 16),
            _SettingsTile(
              icon: Icons.logout,
              title: 'Log Out',
              trailing: const SizedBox(), 
              onTap: () {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                auth.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
              textColor: Colors.redAccent,
              textGrey: textGrey,
              iconColor: Colors.redAccent,
              cardColor: AppTheme.getCardColor(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubSettingTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, Color? iconColor, Color? textColor}) {
    final defaultTextColor = AppTheme.getTextColor(context);
    final defaultTextGrey = AppTheme.getTextGreyColor(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 22, color: iconColor ?? defaultTextGrey),
      title: Text(title, style: TextStyle(color: textColor ?? defaultTextColor, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: iconColor ?? defaultTextGrey),
      onTap: onTap,
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          title: Text(
            'Delete Account',
            style: TextStyle(color: AppTheme.getTextColor(context), fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to permanently delete your account? This action cannot be undone. You will need to register again.',
            style: TextStyle(color: AppTheme.getTextColor(context)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.of(ctx).pop(); // Close dialog
                final auth = Provider.of<AuthProvider>(context, listen: false);
                await auth.deleteAccount();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;
  final Color textColor;
  final Color textGrey;
  final Color? iconColor;
  final Color cardColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
    required this.textColor,
    required this.textGrey,
    this.iconColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor)),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
