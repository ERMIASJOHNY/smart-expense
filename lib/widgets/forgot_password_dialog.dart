import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  int _step = 0; // 0 = Email, 1 = OTP, 2 = New Password
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _generatedOtp = '';
  Timer? _timer;
  int _timeLeft = 60;
  bool _otpUsed = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _sendOtp() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_step == 0) {
        // Generate OTP
        _generatedOtp = (1000 + Random().nextInt(9000)).toString();
        _timeLeft = 60;
        _otpUsed = false;
        
        // Start Timer
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_timeLeft > 0) {
            setState(() {
              _timeLeft--;
            });
          } else {
            timer.cancel();
          }
        });

        setState(() {
          _step = 1;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Your OTP is: $_generatedOtp')),
        );
      }
    }
  }

  void _verifyOtp() {
    if (_otpUsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This OTP has already been used.')),
      );
      return;
    }

    if (_timeLeft == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP expired. Please try again.')),
      );
      return;
    }

    if (_otpCtrl.text.trim() == _generatedOtp) {
      _otpUsed = true;
      _timer?.cancel();
      setState(() {
        _step = 2;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
    }
  }

  void _resetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passCtrl.text == _confirmPassCtrl.text) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final success = await auth.resetPassword(_emailCtrl.text.trim(), _passCtrl.text);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password updated successfully')),
            );
            Navigator.pop(context); // Close dialog
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update. Email not found.')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.getCardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _step == 0 ? 'Forgot Password' : _step == 1 ? 'Enter OTP' : 'New Password',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 16),
              if (_step == 0) ...[
                Text(
                  'Enter your email to receive an OTP.',
                  style: TextStyle(color: AppTheme.getTextGreyColor(context)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  style: TextStyle(color: AppTheme.getTextColor(context)),
                  decoration: InputDecoration(
                    hintText: 'Email Address',
                    hintStyle: TextStyle(color: AppTheme.getTextGreyColor(context)),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBackground : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Enter email' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _sendOtp,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 48)),
                  child: const Text('Send OTP', style: TextStyle(color: Colors.white)),
                ),
              ] else if (_step == 1) ...[
                Text(
                  'An OTP has been generated. It will securely appear on screen.\nTime left: $_timeLeft seconds',
                  style: TextStyle(color: AppTheme.getTextGreyColor(context)),
                  textAlign: TextAlign.center,
                ),
                if (_timeLeft > 0 && !_otpUsed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Your OTP: $_generatedOtp', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otpCtrl,
                  style: TextStyle(color: AppTheme.getTextColor(context)),
                  decoration: InputDecoration(
                    hintText: 'Enter 4-digit OTP',
                    hintStyle: TextStyle(color: AppTheme.getTextGreyColor(context)),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBackground : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _verifyOtp,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 48)),
                  child: const Text('Verify OTP', style: TextStyle(color: Colors.white)),
                ),
              ] else if (_step == 2) ...[
                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  style: TextStyle(color: AppTheme.getTextColor(context)),
                  decoration: InputDecoration(
                    hintText: 'New Password',
                    hintStyle: TextStyle(color: AppTheme.getTextGreyColor(context)),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBackground : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter new password';
                    if (!AppConstants.passwordRegExp.hasMatch(val)) return 'Password must be 8-12 chars, upper, lower, number, special';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: true,
                  style: TextStyle(color: AppTheme.getTextColor(context)),
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    hintStyle: TextStyle(color: AppTheme.getTextGreyColor(context)),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBackground : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _resetPassword,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 48)),
                  child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
