import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../models/activity_log.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AdminPanelScreen extends StatefulWidget {
  final bool showAppBar;
  const AdminPanelScreen({super.key, this.showAppBar = true});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  List<Map<String, dynamic>> _users = [];
  List<ActivityLog> _logs = [];
  bool _isLoading = true;
  int _currentTabIndex = 0; // 0 for Users, 1 for Logs

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _fetchUsers();
    await _fetchLogs();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchLogs() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final logs = await auth.getAllLogs();
    setState(() {
      _logs = logs;
    });
  }

  Future<void> _fetchUsers() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final users = await auth.getAllUsers();
    
    // Add some mock data if empty for demo purposes
    if (users.isEmpty) {
      users.addAll([
        {
          'userName': 'jane_doe',
          'email': 'jane@example.com',
          'fullName': 'Jane Doe',
          'joinedAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        },
        {
          'userName': 'john_smith',
          'email': 'john@test.com',
          'fullName': 'John Smith',
          'joinedAt': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
        },
      ]);
    }

    setState(() {
      _users = users;
    });
  }

  void _confirmDeleteUser(String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        title: Text('Delete User?', style: TextStyle(color: AppTheme.getTextColor(context))),
        content: Text('Are you sure you want to remove $email from the system?', style: TextStyle(color: AppTheme.getTextColor(context))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.deleteUser(email);
              _fetchUsers();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User $email deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.getTextColor(context);
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: true,
              actions: [
                if (_currentTabIndex == 1) ...[
                  IconButton(
                    icon: const Icon(Icons.download_rounded),
                    tooltip: 'Download Logs (JSON)',
                    onPressed: () => _downloadLogsJSON(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: 'Clear Logs',
                    onPressed: () => _confirmClearLogs(),
                  ),
                ],
              ],
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentTabIndex == 0 ? 'User Management' : 'System Activity Logs',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentTabIndex == 0 
                                ? 'Monitor and control registered users activity.'
                                : 'Track logins, logouts and security events.',
                              style: TextStyle(color: AppTheme.getTextGreyColor(context)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Tab Selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.getCardColor(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildTabItem(0, 'Users', Icons.people_outline),
                          _buildTabItem(1, 'Logs', Icons.list_alt_outlined),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    _currentTabIndex == 0 ? _buildUserTable() : _buildLogsTable(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isSelected = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.getTextGreyColor(context),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.getTextGreyColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClearLogs() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        title: Text('Clear All Logs?', style: TextStyle(color: AppTheme.getTextColor(context))),
        content: Text('This action cannot be undone. Are you sure?', style: TextStyle(color: AppTheme.getTextColor(context))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.clearLogs();
              _fetchLogs();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadLogsJSON() async {
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logs to download')),
      );
      return;
    }

    try {
      final String jsonStr = ActivityLog.encode(_logs);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/activity_logs.json');
      await file.writeAsString(jsonStr);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'System Activity Logs',
        text: 'Exported system activity logs from Smart Expense Tracker.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting logs: $e')),
        );
      }
    }
  }

  Widget _buildLogsTable() {
    final textColor = AppTheme.getTextColor(context);
    final cardColor = AppTheme.getCardColor(context);

    if (_logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.history_toggle_off, size: 64, color: AppTheme.getTextGreyColor(context).withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text('No activity logs found Yet.', style: TextStyle(color: AppTheme.getTextGreyColor(context))),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.1)),
            horizontalMargin: 12,
            columnSpacing: 24,
            columns: [
              DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
              DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
              DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
              DataColumn(label: Text('Details', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
            ],
            rows: _logs.map((log) {
              Color actionColor = Colors.blue;
              if (log.action.contains('Failed')) actionColor = Colors.red;
              if (log.action.contains('Success')) actionColor = Colors.green;
              if (log.action.contains('Registered')) actionColor = Colors.purple;
              if (log.action.contains('Password')) actionColor = Colors.orange;

              return DataRow(cells: [
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: actionColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.action,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: actionColor,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(log.userEmail, style: TextStyle(color: textColor, fontSize: 13))),
                DataCell(Text(
                  DateFormat('HH:mm:ss, MMM dd').format(log.timestamp),
                  style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 12),
                )),
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(
                      log.details,
                      style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTable() {
    final textColor = AppTheme.getTextColor(context);
    final cardColor = AppTheme.getCardColor(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.1)),
            horizontalMargin: 12,
            columnSpacing: 24,
            columns: [
              DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
              DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
              DataColumn(label: Text('Joined', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
            ],
            rows: _users.map((user) {
              final String email = user['email'] ?? '';
              final String name = user['userName'] ?? 'N/A';
              final String role = user['role'] ?? 'user';
              final bool isBlocked = user['isBlocked'] ?? false;
              final String joined = user['joinedAt'] != null 
                  ? DateFormat('MMM dd, yyyy').format(DateTime.parse(user['joinedAt']))
                  : 'N/A';

              final bool isSuperAdmin = email == "ermiasdereje24@gmail.com" || email == "admin@admin.com";

              return DataRow(cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 10, color: AppColors.primary)),
                      ),
                      const SizedBox(width: 8),
                      Text(name, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: role == 'admin' ? Colors.amber.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: role == 'admin' ? Colors.amber[700] : Colors.blue[700],
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isBlocked ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isBlocked ? 'BLOCKED' : 'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isBlocked ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(joined, style: TextStyle(color: textColor.withValues(alpha: 0.7)))),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Toggle Admin Role
                      IconButton(
                        tooltip: role == 'admin' ? 'Demote to User' : 'Promote to Admin',
                        icon: Icon(
                          role == 'admin' ? Icons.security_outlined : Icons.admin_panel_settings_outlined,
                          color: Colors.amber[700],
                          size: 20,
                        ),
                        onPressed: isSuperAdmin ? null : () async {
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          await auth.toggleUserRole(email);
                          _fetchUsers();
                        },
                      ),
                      // Block Toggle
                      IconButton(
                        tooltip: isBlocked ? 'Unblock User' : 'Block User',
                        icon: Icon(
                          isBlocked ? Icons.lock_open_outlined : Icons.lock_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        onPressed: isSuperAdmin ? null : () async {
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          await auth.toggleUserStatus(email);
                          _fetchUsers();
                        },
                      ),
                      // Delete
                      IconButton(
                        tooltip: 'Delete Account',
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: isSuperAdmin ? null : () => _confirmDeleteUser(email),
                      ),
                    ],
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
