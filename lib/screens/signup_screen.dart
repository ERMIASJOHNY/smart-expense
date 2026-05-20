import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/image_helper.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 6;

  // Controllers for all fields
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _userNameController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  XFile? _profileImage;
  final ImagePicker _picker = ImagePicker();

  final List<GlobalKey<FormState>> _formKeys = List.generate(6, (_) => GlobalKey<FormState>());

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? selected = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (selected != null) {
        setState(() => _profileImage = selected);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() => _profileImage = null);
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      if (_formKeys[_currentStep].currentState!.validate()) {
        if (_currentStep == 4 && !_agreedToTerms) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please agree to the Terms and Conditions')),
          );
          return;
        }
        
        if (_currentStep == 2) {
           if (_passwordController.text != _confirmPasswordController.text) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Passwords do not match')),
            );
            return;
          }
        }

        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeRegistration() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signup(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      fullName: _fullNameController.text.trim(),
      userName: _userNameController.text.trim(),
      profileImagePath: _profileImage?.path,
    );

    if (success && mounted) {
      _nextStep(); // Move to completion screen
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.getBackground(context);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0 && _currentStep < 5
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: AppTheme.getTextColor(context)),
                onPressed: _previousStep,
              )
            : IconButton(
                icon: Icon(Icons.arrow_back, color: AppTheme.getTextColor(context)),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          'User Registration',
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildProgressBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildWelcomeStep(),
                _buildBasicInfoStep(),
                _buildPasswordStep(),
                _buildProfileSetupStep(),
                _buildTermsStep(),
                _buildCompletionStep(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          bool isCompleted = index < _currentStep;
          bool isCurrent = index == _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCurrent || isCompleted ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent || isCompleted ? Colors.white : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (index < _totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // --- STEPS ---

  Widget _buildStepContainer({required String title, String? subtitle, required List<Widget> children, required int stepIndex}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[stepIndex],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.secondary, AppColors.primaryLight, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                title,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 40),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return _buildStepContainer(
      stepIndex: 0,
      title: 'Welcome!',
      subtitle: "Let's create your account.",
      children: [
        const SizedBox(height: 40),
        _buildPrimaryButton(label: 'Register', onPressed: _nextStep),
        const SizedBox(height: 16),
        _buildSecondaryButton(label: 'Login', onPressed: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildBasicInfoStep() {
    return _buildStepContainer(
      stepIndex: 1,
      title: 'Basic Information',
      children: [
        _buildTextField(
          label: 'Full Name',
          hint: 'Enter your full name',
          controller: _fullNameController,
          validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'Email Address',
          hint: 'Enter your email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (val) => val != null && AppConstants.emailRegExp.hasMatch(val) ? null : 'Enter a valid email',
        ),
        const SizedBox(height: 40),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return _buildStepContainer(
      stepIndex: 2,
      title: 'Create Password',
      children: [
        _buildTextField(
          label: 'Password',
          hint: 'Enter your password',
          controller: _passwordController,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return 'Password is required';
            if (!AppConstants.passwordRegExp.hasMatch(val)) {
              return 'Must be 10+ chars, with uppercase, lowercase, number & special char';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'Confirm Password',
          hint: 'Confirm your password',
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          validator: (val) => val == null || val.isEmpty ? 'Please confirm' : null,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text('• Password must be at least 10 characters.', style: TextStyle(color: AppTheme.getTextGreyColor(context), fontSize: 12)),
        ),
        const SizedBox(height: 40),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildProfileSetupStep() {
    return _buildStepContainer(
      stepIndex: 3,
      title: 'Profile Setup',
      children: [
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                        image: _profileImage != null
                            ? DecorationImage(
                                image: getPlatformImageProvider(_profileImage!.path),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profileImage == null
                          ? const Icon(Icons.person_outline, size: 60, color: Colors.white54)
                          : null,
                    ),
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                          ],
                        ),
                        child: Icon(
                          _profileImage == null ? Icons.camera_alt : Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_profileImage != null)
                TextButton.icon(
                  onPressed: _removeImage,
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                  label: const Text('Remove Photo', style: TextStyle(color: Colors.redAccent)),
                ),
              if (_profileImage == null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Tap to add photo',
                    style: TextStyle(color: AppTheme.getTextColor(context).withValues(alpha: 0.7)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildTextField(
          label: 'Username',
          hint: 'Choose a username',
          controller: _userNameController,
          validator: (val) => val == null || val.isEmpty ? 'Username is required' : null,
        ),
        const SizedBox(height: 40),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildTermsStep() {
    return _buildStepContainer(
      stepIndex: 4,
      title: 'Terms & Conditions',
      children: [
        Text(
          'Please agree to our Terms and Privacy Policy.',
          style: TextStyle(color: AppTheme.getTextColor(context).withValues(alpha: 0.7)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        CheckboxListTile(
          value: _agreedToTerms,
          onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
          title: Text('I agree to the Terms and Conditions', style: TextStyle(color: AppTheme.getTextColor(context), fontSize: 14)),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.primary,
          checkColor: Colors.white,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 40),
        _buildNavigationButtons(nextLabel: 'Finish', onNext: _completeRegistration),
      ],
    );
  }

  Widget _buildCompletionStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 32),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.secondary, AppColors.primaryLight, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Text(
              'Registration Complete!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your account has been successfully created!',
            style: TextStyle(color: AppTheme.getTextGreyColor(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildPrimaryButton(label: 'Go to Dashboard', onPressed: () => Navigator.pushReplacementNamed(context, '/')),
          const SizedBox(height: 16),
          _buildSecondaryButton(label: 'Finish', onPressed: () => Navigator.pushReplacementNamed(context, '/login')),
        ],
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(color: AppTheme.getTextColor(context), fontWeight: FontWeight.w600, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.getTextColor(context).withValues(alpha: 0.3)),
            filled: true,
            fillColor: AppTheme.getTextColor(context).withValues(alpha: 0.04),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.getTextColor(context).withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.getTextColor(context).withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondary, width: 2),
            ),
            suffixIcon: suffixIcon,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildNavigationButtons({String nextLabel = 'Next', VoidCallback? onNext}) {
    return Row(
      children: [
        Expanded(
          child: _buildSecondaryButton(label: 'Back', onPressed: _previousStep),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPrimaryButton(label: nextLabel, onPressed: onNext ?? _nextStep),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({required String label, required VoidCallback onPressed}) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSecondaryButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.getTextColor(context),
          side: BorderSide(color: AppTheme.getTextColor(context).withValues(alpha: 0.2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
