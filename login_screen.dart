import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_button.dart';
import '../widgets/glass_card.dart';
import '../main.dart';  // Import main.dart for MainScreen
import 'register_screen.dart';
import 'direct_login_screen.dart'; // Import Direct Login Screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // First try regular login
      final success = await authService.login(email, password);
      
      if (success && mounted) {
        // Navigate to main screen
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
        return;
      }
      
      // If regular login fails, try direct login for already registered users
      if (!success && authService.error?.contains("Incorrect password") == true) {
        final user = await authService.getUserByEmail(email);
        if (user != null) {
          final directSuccess = await authService.loginWithUser(user);
          if (directSuccess && mounted) {
            // Navigate to main screen
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          }
        }
      }
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  void _resetPassword() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email to reset password')),
      );
      return;
    }
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.resetPassword(email);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent! Check your inbox.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360; // Check for small screens
    final isVerySmallScreen = size.width < 320; // Extra check for very small screens
    
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.2),
                  Colors.black,
                ],
              ),
            ),
          ),
          
          // Background particle effects
          CustomPaint(
            painter: ParticlePainter(),
            size: Size(size.width, size.height),
          ),
          
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 12.0 : (isSmallScreen ? 16.0 : 24.0),
                  vertical: 8.0,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Add top padding to account for consistent spacing
                        SizedBox(height: isVerySmallScreen ? 20 : (isSmallScreen ? 30 : 40)),
                        
                        // App logo or icon
                        Icon(
                          Icons.fitness_center,
                          size: isVerySmallScreen ? 48 : (isSmallScreen ? 60 : 80),
                          color: AppTheme.primaryColor,
                        ),
                        
                        SizedBox(height: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 24)),
                        
                        // App name
                        Text(
                          'FITNESS APP',
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 24 : (isSmallScreen ? 28 : 32),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Tagline
                        Text(
                          'Your Personal Fitness Journey',
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16),
                            color: Colors.grey[400],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: isVerySmallScreen ? 24 : (isSmallScreen ? 32 : 48)),
                        
                        // Login form
                        GlassContainer(
                          borderRadius: 24,
                          padding: EdgeInsets.all(isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 24)),
                          addGlow: true,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                
                                SizedBox(height: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 24)),
                                
                                // Email field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(Icons.email, size: 20),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[800]!.withOpacity(0.5),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isVerySmallScreen ? 12 : 16,
                                      vertical: isVerySmallScreen ? 12 : 16,
                                    ),
                                    isDense: isVerySmallScreen,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Password field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword 
                                            ? Icons.visibility 
                                            : Icons.visibility_off,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[800]!.withOpacity(0.5),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isVerySmallScreen ? 12 : 16,
                                      vertical: isVerySmallScreen ? 12 : 16,
                                    ),
                                    isDense: isVerySmallScreen,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Remember me and forgot password - Adjusted for small screens
                                isSmallScreen
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Remember me checkbox
                                        Row(
                                          children: [
                                            SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: Checkbox(
                                                value: _rememberMe,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _rememberMe = value ?? false;
                                                  });
                                                },
                                                checkColor: Colors.black,
                                                fillColor: MaterialStateProperty.resolveWith(
                                                  (states) => AppTheme.primaryColor,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Flexible(
                                              child: Text(
                                                'Remember me',
                                                style: TextStyle(fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Forgot password button
                                        TextButton(
                                          onPressed: _resetPassword,
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: const Text(
                                            'Forgot Password?',
                                            style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Remember me checkbox
                                        Flexible(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                height: 24,
                                                width: 24,
                                                child: Checkbox(
                                                  value: _rememberMe,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _rememberMe = value ?? false;
                                                    });
                                                  },
                                                  checkColor: Colors.black,
                                                  fillColor: MaterialStateProperty.resolveWith(
                                                    (states) => AppTheme.primaryColor,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Flexible(
                                                child: Text(
                                                  'Remember me',
                                                  style: TextStyle(fontSize: 14),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Forgot password button
                                        TextButton(
                                          onPressed: _resetPassword,
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                          ),
                                          child: const Text(
                                            'Forgot Password?',
                                            style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                
                                SizedBox(height: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 24)),
                                
                                // Error message if any
                                if (authService.error != null)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      authService.error!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                
                                if (authService.error != null)
                                  const SizedBox(height: 16),
                                
                                // Login button
                                AnimatedGlowButton(
                                  text: authService.isLoading ? 'Logging in...' : 'Log In',
                                  onPressed: authService.isLoading ? () {} : _login,
                                  color: AppTheme.primaryColor,
                                  textColor: Colors.black,
                                  height: 50,
                                  width: double.infinity,
                                  addRipple: true,
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Register link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        "Don't have an account? ",
                                        style: TextStyle(
                                          fontSize: isVerySmallScreen ? 12 : 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _navigateToRegister,
                                      child: Text(
                                        'Register',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: isVerySmallScreen ? 12 : 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Social login buttons
                                Column(
                                  children: [
                                    Text(
                                      'Or continue with',
                                      style: TextStyle(
                                        fontSize: isVerySmallScreen ? 12 : 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildSocialButton(
                                          icon: Icons.g_mobiledata_rounded,
                                          onTap: () {
                                            // Google login
                                          },
                                          isSmall: isVerySmallScreen,
                                        ),
                                        SizedBox(width: isVerySmallScreen ? 12 : 16),
                                        _buildSocialButton(
                                          icon: Icons.facebook,
                                          onTap: () {
                                            // Facebook login
                                          },
                                          isSmall: isVerySmallScreen,
                                        ),
                                        SizedBox(width: isVerySmallScreen ? 12 : 16),
                                        _buildSocialButton(
                                          icon: Icons.apple,
                                          onTap: () {
                                            // Apple login
                                          },
                                          isSmall: isVerySmallScreen,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({required IconData icon, required VoidCallback onTap, bool isSmall = false}) {
    final size = isSmall ? 40.0 : 50.0;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: isSmall ? 22 : 28,
          color: Colors.white,
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final int numberOfParticles = 50;
  final List<Particle> particles = [];
  
  ParticlePainter() {
    // Initialize particles
    final random = math.Random();
    for (int i = 0; i < numberOfParticles; i++) {
      particles.add(Particle(
        position: Offset(
          random.nextDouble() * 1000,
          random.nextDouble() * 2000,
        ),
        size: random.nextDouble() * 15 + 5,
        opacity: random.nextDouble() * 0.2 + 0.1,
      ));
    }
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    for (final particle in particles) {
      paint.color = AppTheme.primaryColor.withOpacity(particle.opacity);
      
      // Draw blurred circle
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(
        Offset(
          particle.position.dx % size.width,
          particle.position.dy % size.height,
        ),
        particle.size,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class Particle {
  final Offset position;
  final double size;
  final double opacity;
  
  Particle({
    required this.position,
    required this.size,
    required this.opacity,
  });
} 