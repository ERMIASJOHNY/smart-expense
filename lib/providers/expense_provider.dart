import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/transaction.dart';
import '../models/contact.dart';

class ExpenseProvider extends ChangeNotifier {
  late Box<Transaction> _transactionBox;
  late Box<Contact> _contactBox;

  final List<PaymentCategory> _categories = [
    PaymentCategory.create(id: 'internet', name: 'Internet', icon: Icons.wifi, color: const Color(0xFF6C47FF)),
    PaymentCategory.create(id: 'electricity', name: 'Electricity', icon: Icons.bolt, color: const Color(0xFFFFA726)),
    PaymentCategory.create(id: 'mobilCredit', name: 'Mobile Credit', icon: Icons.phone_android, color: const Color(0xFFEF5350)),
    PaymentCategory.create(id: 'bill', name: 'Bill', icon: Icons.receipt_long, color: const Color(0xFFAB47BC)),
    PaymentCategory.create(id: 'maxKlim', name: 'MaxKlim', icon: Icons.store, color: const Color(0xFF42A5F5)),
    PaymentCategory.create(id: 'more', name: 'More', icon: Icons.more_horiz, color: const Color(0xFF8D8D8D)),
    PaymentCategory.create(id: 'transfer', name: 'Transfer', icon: Icons.swap_horiz, color: const Color(0xFF6C47FF)),
    PaymentCategory.create(id: 'topUp', name: 'Top Up', icon: Icons.add_circle, color: const Color(0xFF26C6DA)),
    PaymentCategory.create(id: 'salary', name: 'Salary', icon: Icons.account_balance_wallet, color: const Color(0xFF66BB6A)),
    PaymentCategory.create(id: 'shopping', name: 'Shopping', icon: Icons.shopping_bag, color: const Color(0xFFFFA726)),
    PaymentCategory.create(id: 'food', name: 'Food', icon: Icons.restaurant, color: const Color(0xFFEF5350)),
    PaymentCategory.create(id: 'transport', name: 'Transport', icon: Icons.directions_car, color: const Color(0xFF42A5F5)),
  ];

  List<Transaction> _transactions = [];
  List<Contact> _contacts = [];

  String? _currentUserEmail;
  StreamSubscription? _transactionsSub;
  StreamSubscription? _contactsSub;

  ExpenseProvider() {
    _transactionBox = Hive.box<Transaction>('transactions_cache');
    _contactBox = Hive.box<Contact>('contacts_cache');
    _loadData();
  }

  void updateUser(String? email) {
    if (_currentUserEmail == email) return;
    _currentUserEmail = email;

    _transactionsSub?.cancel();
    _contactsSub?.cancel();

    if (email != null) {
      _setupFirestoreSync(email);
    } else {
      _loadData();
    }
  }

  void _setupFirestoreSync(String email) {
    if (Firebase.apps.isEmpty) {
      _loadData();
      return;
    }
    try {
      final db = FirebaseFirestore.instance;

      _transactionsSub = db
          .collection('users')
          .doc(email)
          .collection('transactions')
          .snapshots()
          .listen((querySnap) async {
        final List<Transaction> syncedList = [];
        for (var doc in querySnap.docs) {
          try {
            final t = Transaction.fromMap(doc.data());
            syncedList.add(t);
          } catch (e) {
            debugPrint('Error parsing transaction from Firestore: $e');
          }
        }

        syncedList.sort((a, b) => b.date.compareTo(a.date));
        _transactions = syncedList;

        await _transactionBox.clear();
        for (var t in syncedList) {
          await _transactionBox.put(t.id, t);
        }

        notifyListeners();
      }, onError: (err) {
        debugPrint('Firestore transactions stream error: $err');
        _loadData();
      });

      _contactsSub = db
          .collection('users')
          .doc(email)
          .collection('contacts')
          .snapshots()
          .listen((querySnap) async {
        final List<Contact> syncedList = [];
        for (var doc in querySnap.docs) {
          try {
            final c = Contact.fromMap(doc.data());
            syncedList.add(c);
          } catch (e) {
            debugPrint('Error parsing contact from Firestore: $e');
          }
        }

        _contacts = syncedList;

        await _contactBox.clear();
        for (var c in syncedList) {
          await _contactBox.put(c.name.toLowerCase(), c);
        }

        notifyListeners();
      }, onError: (err) {
        debugPrint('Firestore contacts stream error: $err');
        _loadData();
      });
    } catch (e) {
      debugPrint('Firestore initialization failed (Linux/Offline mode fallback): $e');
      _loadData();
    }
  }

  @override
  void dispose() {
    _transactionsSub?.cancel();
    _contactsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    // 1. Load from local cache (Hive) for immediate UI response
    _transactions = _transactionBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    _contacts = _contactBox.values.toList();
    
    if (_transactions.isEmpty && _contactBox.isEmpty) {
      _loadDummyData();
    }
    notifyListeners();
  }

  void _loadDummyData() {
    _transactions = [];
    _contacts = [];
  }

  PaymentCategory _getCategory(String id) {
    return _categories.firstWhere((c) => c.id == id, orElse: () => _categories.first);
  }

  List<PaymentCategory> get categories => List.unmodifiable(_categories);
  List<Transaction> get transactions => _transactions;
  
  PaymentCategory getTransactionCategory(Transaction t) => _getCategory(t.categoryId);

  List<Contact> get contacts => List.unmodifiable(_contacts);
  List<Transaction> get recentTransactions => _transactions.take(5).toList();

  Map<String, dynamic> getWeeklySummary() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final weeklyTransactions = _transactions.where((t) => t.date.isAfter(sevenDaysAgo)).toList();
    
    double income = 0;
    double expense = 0;
    Map<String, double> categorySpending = {};
    
    for (var t in weeklyTransactions) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
        final cat = _getCategory(t.categoryId);
        categorySpending[cat.name] = (categorySpending[cat.name] ?? 0) + t.amount;
      }
    }
    
    String topCat = 'None';
    double topAmt = 0;
    categorySpending.forEach((name, amt) {
      if (amt > topAmt) {
        topAmt = amt;
        topCat = name;
      }
    });

    return {
      'income': income,
      'expense': expense,
      'topCategory': topCat,
      'topCategoryAmount': topAmt,
      'savings': income - expense,
      'count': weeklyTransactions.length,
    };
  }

  double get totalBalance {
    double balance = 0;
    for (var t in _transactions) {
      if (t.type == TransactionType.income) {
        balance += t.amount;
      } else {
        balance -= t.amount;
      }
    }
    return balance;
  }

  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (total, t) => total + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (total, t) => total + t.amount);

  List<double> get monthlyIncome {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final month = now.month - (5 - i);
      return _transactions
          .where((t) =>
              t.type == TransactionType.income &&
              t.date.month == (month <= 0 ? month + 12 : month))
          .fold(0.0, (total, t) => total + t.amount);
    });
  }

  List<double> get monthlyExpense {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final month = now.month - (5 - i);
      return _transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.date.month == (month <= 0 ? month + 12 : month))
          .fold(0.0, (total, t) => total + t.amount);
    });
  }

  List<Transaction> getTransactionsForPeriod(String period) {
    final now = DateTime.now();
    DateTime startDate;

    switch (period.toLowerCase()) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month);
        break;
      case 'year':
        startDate = DateTime(now.year);
        break;
      default:
        return _transactions;
    }

    return _transactions.where((t) => t.date.isAfter(startDate.subtract(const Duration(seconds: 1)))).toList();
  }

  List<Map<String, dynamic>> getAggregatedData(String period) {
     final now = DateTime.now();
     if (period.toLowerCase() == 'week') {
       return List.generate(7, (i) {
         final date = now.subtract(Duration(days: 6 - i));
         final dayTransactions = _transactions.where((t) => 
           t.date.year == date.year && t.date.month == date.month && t.date.day == date.day
         );
         return {
           'label': DateFormat('E').format(date),
           'income': dayTransactions.where((t) => t.type == TransactionType.income).fold(0.0, (total, t) => total + t.amount),
           'expense': dayTransactions.where((t) => t.type == TransactionType.expense).fold(0.0, (total, t) => total + t.amount),
         };
       });
     } else if (period.toLowerCase() == 'year') {
       return List.generate(12, (i) {
         final month = i + 1;
         final monthTransactions = _transactions.where((t) => 
           t.date.year == now.year && t.date.month == month
         );
         return {
           'label': DateFormat('MMM').format(DateTime(now.year, month)),
           'income': monthTransactions.where((t) => t.type == TransactionType.income).fold(0.0, (total, t) => total + t.amount),
           'expense': monthTransactions.where((t) => t.type == TransactionType.expense).fold(0.0, (total, t) => total + t.amount),
         };
       });
     } else {
       return List.generate(4, (i) {
         final end = now.subtract(Duration(days: (3 - i) * 7));
         final start = end.subtract(const Duration(days: 7));
         final weekTransactions = _transactions.where((t) => 
           t.date.isAfter(start) && t.date.isBefore(end.add(const Duration(seconds: 1)))
         );
         return {
           'label': 'W${i + 1}',
           'income': weekTransactions.where((t) => t.type == TransactionType.income).fold(0.0, (total, t) => total + t.amount),
           'expense': weekTransactions.where((t) => t.type == TransactionType.expense).fold(0.0, (total, t) => total + t.amount),
         };
       });
     }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      // Save locally first
      await _transactionBox.put(transaction.id, transaction);
      if (!_transactions.any((t) => t.id == transaction.id)) {
        _transactions.insert(0, transaction);
      }
      notifyListeners();

      // Sync online to Firestore if logged in and Firebase is initialized
      if (_currentUserEmail != null && Firebase.apps.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserEmail)
              .collection('transactions')
              .doc(transaction.id)
              .set(transaction.toMap());
        } catch (e) {
          debugPrint('Error syncing new transaction to Firestore: $e');
        }
      }
    } catch (e) {
      debugPrint('Error adding transaction: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      // Delete locally
      await _transactionBox.delete(id);
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();

      // Sync delete to Firestore if logged in and Firebase is initialized
      if (_currentUserEmail != null && Firebase.apps.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserEmail)
              .collection('transactions')
              .doc(id)
              .delete();
        } catch (e) {
          debugPrint('Error syncing deleted transaction to Firestore: $e');
        }
      }
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
    }
  }

  void addCategory(String name) {
    final newCategory = PaymentCategory.create(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      icon: Icons.star_outline,
      color: Colors.blueAccent,
    );
    _categories.add(newCategory);
    notifyListeners();
  }

  Future<void> topUp(double amount) async {
    final now = DateTime.now();
    await addTransaction(Transaction(
      id: now.millisecondsSinceEpoch.toString(),
      title: 'Top Up',
      subtitle: 'Wallet Top Up',
      amount: amount,
      type: TransactionType.income,
      categoryId: 'topUp',
      date: now,
      avatarInitials: 'TU',
      avatarColorValue: const Color(0xFF26C6DA).toARGB32(),
      updatedAt: now,
    ));
  }

  Future<void> saveContactIfNeeded(String name, String sub) async {
    final exists = _contacts.any((c) => c.name.toLowerCase() == name.toLowerCase());
    if (!exists) {
      final newContact = Contact(
        name: name,
        sub: sub,
        initials: name.isNotEmpty ? name.substring(0, name.length > 1 ? 2 : 1).toUpperCase() : '?',
        colorValue: Colors.purpleAccent.toARGB32(),
      );
      
      try {
        await _contactBox.put(name.toLowerCase(), newContact);
        _contacts.add(newContact);
        notifyListeners();

        // Sync to Firestore if logged in and Firebase is initialized
        if (_currentUserEmail != null && Firebase.apps.isNotEmpty) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_currentUserEmail)
                .collection('contacts')
                .doc(name.toLowerCase())
                .set(newContact.toMap());
          } catch (e) {
            debugPrint('Error syncing contact to Firestore: $e');
          }
        }
      } catch (e) {
        debugPrint('Error saving contact: $e');
      }
    }
  }
}
