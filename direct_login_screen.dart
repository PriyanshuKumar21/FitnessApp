import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/direct_login_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../main.dart';

class DirectLoginScreen extends StatefulWidget {
  const DirectLoginScreen({super.key});

  @override
  State<DirectLoginScreen> createState() => _DirectLoginScreenState();
}

class _DirectLoginScreenState extends State<DirectLoginScreen> {
  final DirectLoginService _loginService = DirectLoginService();
  bool _isLoading = false;
  String? _message;
  final TextEditingController _emailController = TextEditingController();
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _directLogin() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      setState(() {
        _message = 'Please enter an email address';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _message = 'Logging in...';
    });
    
    try {
      // Try to get user from database
      final user = await _loginService.directLoginFromExcel(email);
      
      if (user == null) {
        setState(() {
          _isLoading = false;
          _message = 'User not found. Please check your email or register first.';
        });
        return;
      }
      
      // Set the user in AuthService
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Use a direct login method from AuthService
      final success = await authService.loginWithUser(user);
      
      if (success && mounted) {
        // Navigate to main screen
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        setState(() {
          _isLoading = false;
          _message = 'Login failed: ${authService.error}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error logging in: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct Login'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppTheme.primaryColor.withOpacity(0.2),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Direct Login',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Login directly with your email without password if your account exists in the system.',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _directLogin,
                            icon: const Icon(Icons.login),
                            label: const Text('Direct Login'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (_message != null) ...[
                  const SizedBox(height: 24),
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _message!.contains('Error') 
                                    ? Icons.error 
                                    : Icons.info,
                                color: _message!.contains('Error') 
                                    ? Colors.red 
                                    : AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_message!),
                        ],
                      ),
                    ),
                  ),
                ],
                
                if (_isLoading) ...[
                  const SizedBox(height: 24),
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
} 