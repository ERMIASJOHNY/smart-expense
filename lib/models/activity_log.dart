import 'dart:convert';

class ActivityLog {
  final String id;
  final String userEmail;
  final String action;
  final DateTime timestamp;
  final String details;

  ActivityLog({
    required this.id,
    required this.userEmail,
    required this.action,
    required this.timestamp,
    required this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userEmail': userEmail,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
    };
  }

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'],
      userEmail: json['userEmail'],
      action: json['action'],
      timestamp: DateTime.parse(json['timestamp']),
      details: json['details'],
    );
  }

  static String encode(List<ActivityLog> logs) => json.encode(
        logs.map<Map<String, dynamic>>((log) => log.toJson()).toList(),
      );

  static List<ActivityLog> decode(String logs) =>
      (json.decode(logs) as List<dynamic>)
          .map<ActivityLog>((item) => ActivityLog.fromJson(item))
          .toList();
}
