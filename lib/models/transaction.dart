import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 2)
enum TransactionType { 
  @HiveField(0)
  income, 
  @HiveField(1)
  expense 
}

@HiveType(typeId: 1)
class PaymentCategory {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final int iconCode;
  @HiveField(3)
  final int colorValue;

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  const PaymentCategory({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
  });

  // Keep these for UI convenience if needed
  static PaymentCategory create({
    required String id,
    required String name,
    required IconData icon,
    required Color color,
  }) => PaymentCategory(
    id: id,
    name: name,
    iconCode: icon.codePoint,
    colorValue: color.toARGB32(),
  );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': iconCode,
        'color': colorValue,
      };

  factory PaymentCategory.fromMap(Map<String, dynamic> map) => PaymentCategory(
        id: map['id'],
        name: map['name'],
        iconCode: map['icon'],
        colorValue: map['color'],
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@HiveType(typeId: 0)
class Transaction {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String? subtitle;
  @HiveField(3)
  final double amount;
  @HiveField(4)
  final TransactionType type;
  @HiveField(5)
  final String categoryId; // Store ID to link with provider
  @HiveField(6)
  final DateTime date;
  @HiveField(7)
  final String? avatarInitials;
  @HiveField(8)
  final int? avatarColorValue;
  @HiveField(9)
  final DateTime updatedAt;

  Transaction({
    required this.id,
    required this.title,
    this.subtitle,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.avatarInitials,
    this.avatarColorValue,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'amount': amount,
        'type': type.index,
        'category': categoryId,
        'date': date.toIso8601String(),
        'avatarInitials': avatarInitials,
        'avatarColor': avatarColorValue,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Transaction.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    if (map['date'] != null && map['date'] is String) {
      parsedDate = DateTime.parse(map['date']);
    } else {
      parsedDate = DateTime.now(); // Fallback
    }

    DateTime parsedUpdatedAt;
    if (map['updatedAt'] != null && map['updatedAt'] is String) {
      parsedUpdatedAt = DateTime.parse(map['updatedAt']);
    } else {
      parsedUpdatedAt = parsedDate; // Fallback
    }

    return Transaction(
      id: map['id'],
      title: map['title'],
      subtitle: map['subtitle'],
      amount: map['amount'],
      type: TransactionType.values[map['type']],
      categoryId: map['category'],
      date: parsedDate,
      avatarInitials: map['avatarInitials'],
      avatarColorValue: map['avatarColor'],
      updatedAt: parsedUpdatedAt,
    );
  }
}

