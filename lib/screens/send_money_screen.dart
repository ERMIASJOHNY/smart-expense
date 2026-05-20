import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/contact.dart';
import '../theme/app_theme.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  String _amount = '0';
  Contact? _selectedContact;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _subCtrl = TextEditingController();
  bool _transferDone = false;
  bool _isNewRecipient = false;

  void _onKeyPress(String key) {
    setState(() {
      if (key == '⌫') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = '0';
        }
      } else if (key == '.') {
        if (!_amount.contains('.')) {
          _amount += '.';
        }
      } else {
        if (_amount == '0') {
          _amount = key;
        } else {
          if (_amount.length < 8) _amount += key;
        }
      }
    });
  }

  void _doTransfer() {
    if (_amount == '0' || _amount == '0.') return;
    
    final provider = context.read<ExpenseProvider>();
    String targetName = _isNewRecipient ? _nameCtrl.text : (_selectedContact?.name ?? '');
    String targetSub = _isNewRecipient ? _subCtrl.text : (_selectedContact?.sub ?? '');

    if (targetName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a recipient name')),
      );
      return;
    }

    // Save contact if it was manually entered
    provider.saveContactIfNeeded(targetName, targetSub);
    
    setState(() => _transferDone = true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final bgColor = AppTheme.getBackground(context);
    final cardColor = AppTheme.getCardColor(context);
    final textColor = AppTheme.getTextColor(context);
    final textGrey = AppTheme.getTextGreyColor(context);

    if (_transferDone) return _buildReceiptScreen(textColor, textGrey, bgColor, cardColor);

    final contacts = provider.contacts;

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
                      child: Icon(Icons.arrow_back_ios_new,
                          size: 16, color: textColor),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Send Money',
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

            // Contact selector
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: contacts.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == 0) {
                    // Add New Button
                    return GestureDetector(
                      onTap: () => setState(() {
                        _isNewRecipient = true;
                        _selectedContact = null;
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _isNewRecipient ? AppColors.primary : cardColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                              ),
                              child: Icon(Icons.add, color: _isNewRecipient ? Colors.white : AppColors.primary),
                            ),
                            const SizedBox(height: 8),
                            Text('Add New', style: TextStyle(fontSize: 11, color: textColor)),
                          ],
                        ),
                      ),
                    );
                  }

                  final c = contacts[i - 1];
                  final isSelected = !_isNewRecipient && c == _selectedContact;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _isNewRecipient = false;
                      _selectedContact = c;
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : c.color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(c.initials,
                                  style: TextStyle(
                                      color: isSelected ? Colors.white : c.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(c.name.split(' ')[0],
                              style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 11,
                                  color: textColor)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_isNewRecipient) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameCtrl,
                            style: TextStyle(color: textColor, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Recipient Name',
                              hintStyle: TextStyle(color: textGrey, fontSize: 13),
                              isDense: true,
                            ),
                          ),
                          TextField(
                            controller: _subCtrl,
                            style: TextStyle(color: textColor, fontSize: 11),
                            decoration: InputDecoration(
                              hintText: 'Bank Info (optional)',
                              hintStyle: TextStyle(color: textGrey, fontSize: 11),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_selectedContact != null) ...[
              const SizedBox(height: 8),
              Text(_selectedContact!.sub,
                  style: TextStyle(fontSize: 12, color: textGrey)),
            ],

            const SizedBox(height: 32),

            // Amount Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('\$',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ),
                const SizedBox(width: 4),
                Text(
                  _amount,
                  style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: -2),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Container(
              height: 3,
              width: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const Spacer(),

            // Numpad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildNumRow(['1', '2', '3'], cardColor, textColor),
                  const SizedBox(height: 16),
                  _buildNumRow(['4', '5', '6'], cardColor, textColor),
                  const SizedBox(height: 16),
                  _buildNumRow(['7', '8', '9'], cardColor, textColor),
                  const SizedBox(height: 16),
                  _buildNumRow(['.', '0', '⌫'], cardColor, textColor),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Send Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _doTransfer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Send Money',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNumRow(List<String> keys, Color cardColor, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys
          .map((k) => GestureDetector(
                onTap: () => _onKeyPress(k),
                child: Container(
                  width: 72,
                  height: 56,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Center(
                    child: k == '⌫'
                        ? Icon(Icons.backspace_outlined,
                            color: textColor, size: 20)
                        : Text(k,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: textColor)),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildReceiptScreen(Color textColor, Color textGrey, Color bgColor, Color cardColor) {
    String recipientName = _isNewRecipient ? _nameCtrl.text : (_selectedContact?.name ?? '');

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _transferDone = false),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back_ios_new,
                          size: 16, color: textColor),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Receipt',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.share_outlined,
                        size: 18, color: textColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.income.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.income, size: 50),
            ),

            const SizedBox(height: 16),

            Text('Transfer Successful!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 6),
            Text('Your money has been transferred\nsuccessfully',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: textGrey, height: 1.5)),

            const SizedBox(height: 32),

            // Receipt card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _ReceiptRow(
                        label: 'Transfer Amount',
                        value: '\$$_amount',
                        textColor: textColor,
                        textGrey: textGrey),
                    Divider(height: 24, color: textGrey.withValues(alpha: 0.2)),
                    _ReceiptRow(label: 'To', value: recipientName, textColor: textColor, textGrey: textGrey),
                    const SizedBox(height: 12),
                    _ReceiptRow(label: 'No. Ref', value: '1176886610711', textColor: textColor, textGrey: textGrey),
                    const SizedBox(height: 12),
                    _ReceiptRow(
                        label: 'Date & time',
                        value:
                            '${DateTime.now().day} Feb ${DateTime.now().year}, ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} PM',
                        textColor: textColor,
                        textGrey: textGrey),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Done button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Done',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color textGrey;
  const _ReceiptRow({
    required this.label, 
    required this.value,
    required this.textColor,
    required this.textGrey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13, color: textGrey)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor)),
      ],
    );
  }
}
