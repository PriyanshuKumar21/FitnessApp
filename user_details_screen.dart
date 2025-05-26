import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_button.dart';
import '../widgets/glass_card.dart';
import '../main.dart';
// In a real app, you would import image_picker:
import 'package:image_picker/image_picker.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _selectedGoal = 'Lose weight'; // Default goal
  String _selectedGender = 'male'; // Default gender
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final List<String> _fitnessGoals = [
    'Lose weight',
    'Build muscle',
    'Improve fitness',
    'Stay active',
    'Train for sport',
  ];

  @override
  void initState() {
    super.initState();
    
    // Set up animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveUserDetails() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user != null) {
        // Get the values
        final height = int.tryParse(_heightController.text) ?? 0;
        final weight = int.tryParse(_weightController.text) ?? 0;
        final age = int.tryParse(_ageController.text) ?? 0;
        
        // Show loading indicator
        setState(() {
          _isLoading = true;
        });
        
        try {
          // Save user profile details to database
          final success = await authService.saveUserProfileDetails(
            height: height,
            weight: weight,
            age: age,
            fitnessGoal: _selectedGoal,
            gender: _selectedGender,
          );
          
          if (success) {
            debugPrint('User details saved successfully');
            
            // Navigate to main screen
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainScreen()),
              );
            }
          } else {
            // Show error
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(authService.error ?? 'Failed to save user details')),
              );
            }
          }
        } catch (e) {
          debugPrint('Error saving user details: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${e.toString()}')),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Add top padding to account for the removed header
                        const SizedBox(height: 56),
                        
                        // Title
                        const Text(
                          'Complete Your Profile',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Text(
                          'Help us personalize your fitness experience',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // User details form
                        GlassContainer(
                          borderRadius: 24,
                          padding: const EdgeInsets.all(24),
                          addGlow: true,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Height field
                                TextFormField(
                                  controller: _heightController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Height (cm)',
                                    prefixIcon: const Icon(Icons.height, size: 20),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[800]!.withOpacity(0.5),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your height';
                                    }
                                    final height = int.tryParse(value);
                                    if (height == null || height < 50 || height > 300) {
                                      return 'Please enter a valid height';
                                    }
                                    return null;
                                  },
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Weight field
                                TextFormField(
                                  controller: _weightController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Weight (kg)',
                                    prefixIcon: const Icon(Icons.monitor_weight_outlined, size: 20),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[800]!.withOpacity(0.5),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your weight';
                                    }
                                    final weight = int.tryParse(value);
                                    if (weight == null || weight < 20 || weight > 300) {
                                      return 'Please enter a valid weight';
                                    }
                                    return null;
                                  },
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Age field
                                TextFormField(
                                  controller: _ageController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Age (years)',
                                    prefixIcon: const Icon(Icons.calendar_today, size: 20),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[800]!.withOpacity(0.5),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your age';
                                    }
                                    final age = int.tryParse(value);
                                    if (age == null || age < 12 || age > 120) {
                                      return 'Please enter a valid age';
                                    }
                                    return null;
                                  },
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Gender selection
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Gender',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: RadioListTile<String>(
                                            title: const Text('Male'),
                                            value: 'male',
                                            groupValue: _selectedGender,
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedGender = value!;
                                              });
                                            },
                                            activeColor: AppTheme.primaryColor,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                        Expanded(
                                          child: RadioListTile<String>(
                                            title: const Text('Female'),
                                            value: 'female',
                                            groupValue: _selectedGender,
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedGender = value!;
                                              });
                                            },
                                            activeColor: AppTheme.primaryColor,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Fitness goal dropdown
                                DropdownButtonFormField<String>(
                                  value: _selectedGoal,
                                  decoration: InputDecoration(
                                    labelText: 'Fitness Goal',
                                    prefixIcon: const Icon(Icons.fitness_center, size: 20),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[800]!.withOpacity(0.5),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  dropdownColor: Colors.grey[900],
                                  items: _fitnessGoals.map((goal) {
                                    return DropdownMenuItem<String>(
                                      value: goal,
                                      child: Text(goal),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGoal = value!;
                                    });
                                  },
                                ),
                                
                                const SizedBox(height: 32),
                                
                                // Submit button
                                AnimatedGlowButton(
                                  text: 'Complete Setup',
                                  onPressed: _isLoading 
                                    ? () {} // Empty function when loading 
                                    : () { 
                                        _saveUserDetails(); 
                                      },
                                  color: AppTheme.primaryColor,
                                  textColor: Colors.black,
                                  height: 50,
                                  width: double.infinity,
                                  addRipple: true,
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Skip button
                                TextButton(
                                  onPressed: _isLoading 
                                    ? () {} // Empty function when loading
                                    : () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (context) => const MainScreen()),
                                        );
                                      },
                                  child: const Text(
                                    'Skip for now',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
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
              // Loading overlay
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Saving your profile...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 