import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';
import '../models/contact.dart';

class ExpenseProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
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

  ExpenseProvider() {
    _transactionBox = Hive.box<Transaction>('transactions_cache');
    _contactBox = Hive.box<Contact>('contacts_cache');

    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadData(user.uid);
      } else {
        _transactions = [];
        _contacts = [];
        notifyListeners();
      }
    });
  }

  Future<void> _loadData(String uid) async {
    // 1. Instant Load from Hive
    _transactions = _transactionBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    
    _contacts = _contactBox.values.toList();
    notifyListeners();

    // 2. Background Sync from Firestore
    try {
      final transSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .get();
      
      final cloudTransactions = transSnapshot.docs
          .map((doc) => Transaction.fromMap(doc.data()))
          .toList();

      for (var cloudTrans in cloudTransactions) {
        final localTrans = _transactionBox.get(cloudTrans.id);
        
        if (localTrans == null || cloudTrans.updatedAt.isAfter(localTrans.updatedAt)) {
          await _transactionBox.put(cloudTrans.id, cloudTrans);
        } else if (localTrans.updatedAt.isAfter(cloudTrans.updatedAt)) {
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('transactions')
              .doc(localTrans.id)
              .set(localTrans.toMap());
        }
      }

      final contactsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('contacts')
          .get();
      
      for (var doc in contactsSnapshot.docs) {
        final cloudContact = Contact.fromMap(doc.data());
        final localContact = _contactBox.get(cloudContact.name.toLowerCase());
        if (localContact == null) {
          await _contactBox.put(cloudContact.name.toLowerCase(), cloudContact);
        }
      }

      await _pruneHiveCache();

      _transactions = _transactionBox.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      _contacts = _contactBox.values.toList();
      
      if (_transactions.isEmpty && _contactBox.isEmpty) {
        _loadDummyData();
        await _saveAllToCloud(uid);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  Future<void> _pruneHiveCache() async {
    if (_transactionBox.length > 100) {
      final allSorted = _transactionBox.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      
      final toRemove = allSorted.skip(100).toList();
      for (var t in toRemove) {
        await _transactionBox.delete(t.id);
      }
    }
  }

  Future<void> _saveAllToCloud(String uid) async {
    for (var t in _transactions) {
      await _transactionBox.put(t.id, t);
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .doc(t.id)
          .set(t.toMap());
    }
    for (var c in _contacts) {
      await _contactBox.put(c.name.toLowerCase(), c);
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('contacts')
          .doc(c.name.toLowerCase().replaceAll(' ', '_'))
          .set(c.toMap());
    }
  }

  void _loadDummyData() {
    final now = DateTime.now();
    _transactions = [
      Transaction(
        id: '1',
        title: 'Clarissa Bates',
        subtitle: 'Internet Payment',
        amount: 120.24,
        type: TransactionType.expense,
        categoryId: 'internet',
        date: now.subtract(const Duration(days: 1)),
        avatarInitials: 'CB',
        avatarColorValue: const Color(0xFF6C47FF).toARGB32(),
        updatedAt: now,
      ),
      Transaction(
        id: '2',
        title: 'Ariana Marnika',
        subtitle: 'Top Up Balance',
        amount: 500.00,
        type: TransactionType.income,
        categoryId: 'topUp',
        date: now.subtract(const Duration(days: 2)),
        avatarInitials: 'AM',
        avatarColorValue: const Color(0xFF26C6DA).toARGB32(),
        updatedAt: now,
      ),
    ];

    _contacts = [
      Contact(name: 'Clarissa Bates', sub: 'Bank · 1176886610711', initials: 'CB', colorValue: const Color(0xFF6C47FF).toARGB32()),
      Contact(name: 'Ariana Marnika', sub: 'Bank · 8866 4461 2311', initials: 'AM', colorValue: const Color(0xFF26C6DA).toARGB32()),
    ];
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
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _transactionBox.put(transaction.id, transaction);
      _transactions.insert(0, transaction);
      await _pruneHiveCache();
      notifyListeners();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toMap());
    } catch (e) {
      debugPrint('Error adding transaction: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _transactionBox.delete(id);
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(id)
          .delete();
      
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
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
    final user = _auth.currentUser;
    if (user == null) return;

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
        
        final id = name.toLowerCase().replaceAll(' ', '_');
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('contacts')
            .doc(id)
            .set(newContact.toMap());
            
        notifyListeners();
      } catch (e) {
        debugPrint('Error saving contact: $e');
      }
    }
  }
}
