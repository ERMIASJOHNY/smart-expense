import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'contact.g.dart';

@HiveType(typeId: 3)
class Contact {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final String sub;
  @HiveField(2)
  final String initials;
  @HiveField(3)
  final int colorValue;

  Color get color => Color(colorValue);

  Contact({
    required this.name,
    required this.sub,
    required this.initials,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'sub': sub,
        'initials': initials,
        'color': colorValue,
      };

  factory Contact.fromMap(Map<String, dynamic> map) => Contact(
        name: map['name'],
        sub: map['sub'],
        initials: map['initials'],
        colorValue: map['color'],
      );
}

