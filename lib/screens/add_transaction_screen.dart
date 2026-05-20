import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/expense_provider.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  TransactionType _type = TransactionType.expense;
  PaymentCategory? _category;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ExpenseProvider>();
      if (provider.categories.isNotEmpty) {
        setState(() {
          _category = provider.categories.first;
        });
      }
    });
  }

  void _save() {
    if (_titleCtrl.text.isEmpty || _amountCtrl.text.isEmpty || _category == null) return;
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;

    final t = Transaction(
      id: const Uuid().v4(),
      title: _titleCtrl.text,
      subtitle: _noteCtrl.text.isEmpty ? _category!.name : _noteCtrl.text,
      amount: amount,
      type: _type,
      categoryId: _category!.id,
      date: DateTime.now(),
      avatarInitials: _titleCtrl.text.substring(0, 1).toUpperCase() +
          (_titleCtrl.text.length > 1
              ? _titleCtrl.text.substring(1, 2).toUpperCase()
              : ''),
      avatarColorValue: _category!.colorValue,
      updatedAt: DateTime.now(),
    );

    context.read<ExpenseProvider>().addTransaction(t);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.getBackground(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppTheme.getTextColor(context);
    final cardColor = AppTheme.getCardColor(context);
    
    final categories = context.watch<ExpenseProvider>().categories;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8)
                        ],
                      ),
                      child: Icon(Icons.close,
                          size: 18, color: textColor),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Add Transaction',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8)
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _type = TransactionType.expense),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _type == TransactionType.expense
                                      ? AppColors.expense
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('Expense',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _type == TransactionType.expense
                                            ? Colors.white
                                            : AppColors.textGrey)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _type = TransactionType.income),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _type == TransactionType.income
                                      ? AppColors.income
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('Income',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _type == TransactionType.income
                                            ? Colors.white
                                            : AppColors.textGrey)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildLabel('Title', textColor),
                    const SizedBox(height: 8),
                    _buildTextField(_titleCtrl, 'e.g. Clarissa Bates',
                        Icons.person_outline, isDark),

                    const SizedBox(height: 16),

                    _buildLabel('Amount', textColor),
                    const SizedBox(height: 8),
                    _buildTextField(
                        _amountCtrl, '0.00', Icons.attach_money, isDark,
                        keyboardType: TextInputType.number),

                    const SizedBox(height: 16),

                    _buildLabel('Note (optional)', textColor),
                    const SizedBox(height: 8),
                    _buildTextField(
                        _noteCtrl, 'Add a note...', Icons.notes_outlined, isDark),

                    const SizedBox(height: 20),

                    _buildLabel('Category', textColor),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: categories
                          .map((cat) => GestureDetector(
                                onTap: () =>
                                    setState(() => _category = cat),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _category == cat
                                        ? cat.color
                                        : isDark ? AppColors.darkCardLight : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 6)
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(cat.icon,
                                          size: 14,
                                          color: _category == cat
                                              ? Colors.white
                                              : cat.color),
                                      const SizedBox(width: 6),
                                      Text(cat.name,
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: _category == cat
                                                  ? Colors.white
                                                  : textColor)),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Save Transaction',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color textColor) {
    return Text(text,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor));
  }

  Widget _buildTextField(
      TextEditingController ctrl, String hint, IconData icon, bool isDark,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardLight : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
