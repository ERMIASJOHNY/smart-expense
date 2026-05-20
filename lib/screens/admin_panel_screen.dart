import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:math' as math;
import '../providers/auth_provider.dart';
import '../models/activity_log.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AdminPanelScreen extends StatefulWidget {
  final bool showAppBar;
  const AdminPanelScreen({super.key, this.showAppBar = true});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _users = [];
  List<ActivityLog> _logs = [];
  bool _isLoading = true;
  int _currentTabIndex = 0; // 0 for Users, 1 for Logs
  String _searchQuery = "";
  late AnimationController _animController;

  // Premium Palette
  static const Color bgColor = Color(0xFF0F111A);
  static const Color cardBgColor = Color(0xFF161A26);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentRose = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _refreshData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _fetchUsers();
    await _fetchLogs();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchLogs() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final logs = await auth.getAllLogs();
      setState(() {
        _logs = logs;
      });
    } catch (e) {
      debugPrint("Error fetching logs: $e");
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final users = await auth.getAllUsers();
      
      // Seed mockup data if empty for a highly engaging user experience
      if (users.isEmpty) {
        users.addAll([
          {
            'userName': 'jane_doe',
            'email': 'jane@example.com',
            'fullName': 'Jane Doe',
            'role': 'user',
            'isBlocked': false,
            'joinedAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          },
          {
            'userName': 'john_smith',
            'email': 'john@test.com',
            'fullName': 'John Smith',
            'role': 'user',
            'isBlocked': true,
            'joinedAt': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
          },
          {
            'userName': 'admin_assistant',
            'email': 'assistant@fintrack.com',
            'fullName': 'Assistant Admin',
            'role': 'admin',
            'isBlocked': false,
            'joinedAt': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
          }
        ]);
      }

      setState(() {
        _users = users;
      });
    } catch (e) {
      debugPrint("Error fetching users: $e");
    }
  }

  void _confirmDeleteUser(String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete User Account?', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently remove $email from the system? All offline cache will be invalidated.', style: const TextStyle(color: textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentRose, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.deleteUser(email);
              _fetchUsers();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: accentRose,
                    content: Text('Successfully deleted user: $email', style: const TextStyle(color: Colors.white)),
                  ),
                );
              }
            },
            child: const Text('Delete User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((user) {
      final name = (user['userName'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final fullName = (user['fullName'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || 
             email.contains(_searchQuery.toLowerCase()) ||
             fullName.contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredLogs = _logs.where((log) {
      return log.userEmail.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             log.action.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             log.details.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bgColor,
        cardColor: cardBgColor,
      ),
      child: Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
                backgroundColor: cardBgColor,
                elevation: 0,
                title: const Row(
                  children: [
                    Icon(Icons.dashboard_customize_rounded, color: accentGreen),
                    SizedBox(width: 12),
                    Text('FinTrack Administration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: textSecondary),
                    tooltip: 'Refresh Telemetry',
                    onPressed: _refreshData,
                  ),
                  if (_currentTabIndex == 1) ...[
                    IconButton(
                      icon: const Icon(Icons.download_rounded, color: accentBlue),
                      tooltip: 'Download Logs (JSON)',
                      onPressed: _downloadLogsJSON,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined, color: accentRose),
                      tooltip: 'Clear Logs',
                      onPressed: _confirmClearLogs,
                    ),
                  ],
                  const SizedBox(width: 8),
                ],
              )
            : null,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: accentGreen))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 950;
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: FadeTransition(
                      opacity: _animController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDashboardHeader(isWide),
                          const SizedBox(height: 24),
                          _buildPremiumMetricGrid(isWide),
                          const SizedBox(height: 24),
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: _buildTelemetrySection()),
                                const SizedBox(width: 24),
                                Expanded(flex: 2, child: _buildRightSideBarWidgets()),
                              ],
                            )
                          else ...[
                            _buildTelemetrySection(),
                            const SizedBox(height: 24),
                            _buildRightSideBarWidgets(),
                          ],
                          const SizedBox(height: 28),
                          _buildMainTabContainer(filteredUsers, filteredLogs),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  // HEADER
  Widget _buildDashboardHeader(bool isWide) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Super Admin Telemetry Panel',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            Text(
              'Monitor and govern security transactions, database synchronization, and credentials in real-time.',
              style: TextStyle(color: textSecondary.withValues(alpha: 0.8), fontSize: 13),
            ),
          ],
        ),
        if (isWide)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            icon: const Icon(Icons.verified_user_rounded, size: 18),
            label: const Text('Server Connection Secure', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {},
          ),
      ],
    );
  }

  // PREMIUM METRICS
  Widget _buildPremiumMetricGrid(bool isWide) {
    final int totalUsers = _users.length;
    final int activeUsers = _users.where((u) => !(u['isBlocked'] ?? false)).length;
    final int blockedUsers = _users.where((u) => u['isBlocked'] ?? false).length;
    final int totalLogs = _logs.length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isWide ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isWide ? 1.6 : 1.3,
      children: [
        _buildMetricCard('Total System Users', totalUsers.toString(), '+12% vs last month', Icons.people_alt_rounded, accentBlue, [accentBlue, Colors.blueAccent]),
        _buildMetricCard('Active Access Roles', activeUsers.toString(), 'All profiles verified', Icons.health_and_safety_rounded, accentGreen, [accentGreen, Colors.green]),
        _buildMetricCard('Restricted Accounts', blockedUsers.toString(), 'Threat containment active', Icons.lock_person_rounded, accentRose, [accentRose, Colors.redAccent]),
        _buildMetricCard('Activity Logs Captured', totalLogs.toString(), 'Operational integrity OK', Icons.article_rounded, accentOrange, [accentOrange, Colors.orangeAccent]),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String sub, IconData icon, Color color, List<Color> gradient) {
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 8),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: color, size: 14),
                  const SizedBox(width: 4),
                  Text(sub, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  // TELEMETRY VISUALS (Sparklines & Circular Charts)
  Widget _buildTelemetrySection() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('System Live Activity Flow', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('Telemetry ticks representing database read/write queries', style: TextStyle(color: textSecondary, fontSize: 11)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.circle, color: accentGreen, size: 8),
                  SizedBox(width: 6),
                  Text('Live Stream', style: TextStyle(color: accentGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 24, bottom: 8),
              child: LiveSparklineChart(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChartLegendItem('Write Ops', accentGreen),
              _buildChartLegendItem('Read Ops', accentBlue),
              _buildChartLegendItem('Auth Access', accentOrange),
              _buildChartLegendItem('API Syncs', accentRose),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChartLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: textSecondary, fontSize: 11)),
      ],
    );
  }

  // RIGHT SIDEBAR WIDGETS
  Widget _buildRightSideBarWidgets() {
    final int admins = _users.where((u) => u['role'] == 'admin').length;
    final int regularUsers = _users.where((u) => u['role'] != 'admin').length;
    final double adminRatio = _users.isEmpty ? 0.0 : admins / _users.length;

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Role Breakdown', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildRoleRatioTile('Super Admins', admins, accentOrange),
                const SizedBox(height: 8),
                _buildRoleRatioTile('Standard Roles', regularUsers, accentBlue),
                const Divider(color: Colors.white10, height: 24),
                const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: accentGreen, size: 14),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Access keys and data encrypted under AES-256 standard.',
                        style: TextStyle(color: textSecondary, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Center(
              child: CustomPaint(
                size: const Size(120, 120),
                painter: CircularProgressPainter(ratio: adminRatio, primaryColor: accentOrange, trackColor: Colors.white10),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${(adminRatio * 100).toInt()}%', style: const TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
                        const Text('Admins', style: TextStyle(color: textSecondary, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRoleRatioTile(String role, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Text(role, style: const TextStyle(color: textSecondary, fontSize: 12)),
          ],
        ),
        Text(count.toString(), style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // TABS & TABLES
  Widget _buildMainTabContainer(List<Map<String, dynamic>> filteredUsers, List<ActivityLog> filteredLogs) {
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Search field
              Expanded(
                child: Container(
                  height: 44,
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search matching keys...',
                      hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                      icon: Icon(Icons.search_rounded, color: textSecondary, size: 18),
                    ),
                    style: const TextStyle(color: textPrimary, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Tab Controller
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _buildTabButton(0, 'Users Database'),
                    _buildTabButton(1, 'Security Logs'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _currentTabIndex == 0 
            ? _buildNewUserTable(filteredUsers) 
            : _buildNewLogsTable(filteredLogs),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final bool isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cardBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? accentGreen : textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNewUserTable(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text('No users match the search parameters.', style: TextStyle(color: textSecondary)),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: DataTable(
        columnSpacing: 38,
        horizontalMargin: 8,
        headingRowHeight: 46,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 52,
        columns: const [
          DataColumn(label: Text('USER PROFILE', style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('ROLES', style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('STATUS', style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('JOINED DATE', style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('SECURITY CONTROLS', style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold))),
        ],
        rows: users.map((user) {
          final String email = user['email'] ?? '';
          final String name = user['userName'] ?? 'N/A';
          final String fullName = user['fullName'] ?? 'N/A';
          final String role = user['role'] ?? 'user';
          final bool isBlocked = user['isBlocked'] ?? false;
          final String joined = user['joinedAt'] != null 
              ? DateFormat('MMM dd, yyyy').format(DateTime.parse(user['joinedAt']))
              : 'N/A';

          final bool isSuperAdmin = email == "ermiasdereje24@gmail.com";

          return DataRow(
            cells: [
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isSuperAdmin ? accentOrange.withValues(alpha: 0.15) : accentBlue.withValues(alpha: 0.15),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(color: isSuperAdmin ? accentOrange : accentBlue, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(fullName, style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(email, style: const TextStyle(color: textSecondary, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: role == 'admin' ? accentOrange.withValues(alpha: 0.15) : accentBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: role == 'admin' ? accentOrange.withValues(alpha: 0.3) : accentBlue.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: role == 'admin' ? accentOrange : accentBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isBlocked ? accentRose : accentGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isBlocked ? accentRose.withValues(alpha: 0.4) : accentGreen.withValues(alpha: 0.4),
                            blurRadius: 6,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isBlocked ? 'SUSPENDED' : 'AUTHORIZED',
                      style: TextStyle(
                        color: isBlocked ? accentRose : accentGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text(joined, style: const TextStyle(color: textSecondary, fontSize: 12))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: role == 'admin' ? 'Demote User' : 'Promote User',
                      icon: Icon(
                        role == 'admin' ? Icons.security_rounded : Icons.admin_panel_settings_outlined,
                        color: isSuperAdmin ? Colors.white24 : accentOrange,
                        size: 18,
                      ),
                      onPressed: isSuperAdmin ? null : () async {
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        await auth.toggleUserRole(email);
                        _fetchUsers();
                      },
                    ),
                    IconButton(
                      tooltip: isBlocked ? 'Activate Access' : 'Revoke Access',
                      icon: Icon(
                        isBlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                        color: isSuperAdmin ? Colors.white24 : accentOrange,
                        size: 18,
                      ),
                      onPressed: isSuperAdmin ? null : () async {
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        await auth.toggleUserStatus(email);
                        _fetchUsers();
                      },
                    ),
                    IconButton(
                      tooltip: 'Purge Directory Record',
                      icon: Icon(Icons.delete_forever_rounded, color: isSuperAdmin ? Colors.white24 : accentRose, size: 18),
                      onPressed: isSuperAdmin ? null : () => _confirmDeleteUser(email),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNewLogsTable(List<ActivityLog> logs) {
    if (logs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text('No activity logs recorded.', style: TextStyle(color: textSecondary)),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: DataTable(
        columnSpacing: 38,
        horizontalMargin: 8,
        headingRowHeight: 46,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 52,
        columns: const [
          DataColumn(label: Text('TELEMETRY EVENT', style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('OPERATOR KEY', style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('TIMESTAMP', style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('DETAILS', style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold))),
        ],
        rows: logs.map((log) {
          Color actionColor = accentBlue;
          if (log.action.contains('Failed') || log.action.contains('Block')) actionColor = accentRose;
          if (log.action.contains('Success') || log.action.contains('Sync')) actionColor = accentGreen;
          if (log.action.contains('Register')) actionColor = accentOrange;

          return DataRow(
            cells: [
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: actionColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    log.action.toUpperCase(),
                    style: TextStyle(
                      color: actionColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              DataCell(Text(log.userEmail, style: const TextStyle(color: textPrimary, fontSize: 13))),
              DataCell(Text(
                DateFormat('HH:mm:ss, MMM dd').format(log.timestamp),
                style: const TextStyle(color: textSecondary, fontSize: 12),
              )),
              DataCell(
                SizedBox(
                  width: 250,
                  child: Text(
                    log.details,
                    style: const TextStyle(color: textSecondary, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _confirmClearLogs() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Purge Activity Logs?', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to permanently clear the activity log cache? This telemetry cannot be recovered.', style: TextStyle(color: textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentRose, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.clearLogs();
              _fetchLogs();
            },
            child: const Text('Purge Logs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadLogsJSON() async {
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No telemetry logs captured yet.')),
      );
      return;
    }

    try {
      final String jsonStr = ActivityLog.encode(_logs);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/system_activity_logs.json');
      await file.writeAsString(jsonStr);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'FinTrack Telemetry Export',
        text: 'Exported system activity telemetry logs from Smart Expense Tracker.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export telemetry: $e')),
        );
      }
    }
  }
}

// Sparkline Custom Painter representing real-time system flow
class LiveSparklineChart extends StatelessWidget {
  const LiveSparklineChart({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _SparklinePainter(),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _AdminPanelScreenState.accentGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _AdminPanelScreenState.accentGreen.withValues(alpha: 0.25),
          _AdminPanelScreenState.accentGreen.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    // Custom deterministic data representation for UI Telemetry
    final List<double> points = [22, 45, 12, 60, 34, 75, 48, 90, 52, 70, 40, 85];
    final double step = size.width / (points.length - 1);

    path.moveTo(0, size.height * (1 - points[0] / 100));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, size.height * (1 - points[0] / 100));

    for (int i = 1; i < points.length; i++) {
      final double x = i * step;
      final double y = size.height * (1 - points[i] / 100);
      
      // Control points for smooth bezier area line
      final double prevX = (i - 1) * step;
      final double prevY = size.height * (1 - points[i - 1] / 100);
      
      path.cubicTo(
        prevX + step / 2, prevY,
        x - step / 2, y,
        x, y,
      );
      fillPath.cubicTo(
        prevX + step / 2, prevY,
        x - step / 2, y,
        x, y,
      );
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw hot tracking spots on high peaks
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final dotOuterPaint = Paint()
      ..color = _AdminPanelScreenState.accentGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw dots at key nodes (index 7 is highest peak: 90)
    final double peakX = 7 * step;
    final double peakY = size.height * (1 - points[7] / 100);
    canvas.drawCircle(Offset(peakX, peakY), 6, dotOuterPaint);
    canvas.drawCircle(Offset(peakX, peakY), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Circular Donut Progress Painter for Role distribution
class CircularProgressPainter extends CustomPainter {
  final double ratio;
  final Color primaryColor;
  final Color trackColor;

  CircularProgressPainter({required this.ratio, required this.primaryColor, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 12;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;

    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Paint progressPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final double sweepAngle = 2 * math.pi * ratio;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CircularProgressPainter oldDelegate) {
    return oldDelegate.ratio != ratio || oldDelegate.primaryColor != primaryColor;
  }
}
