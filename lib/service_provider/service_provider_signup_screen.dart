import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'identity_verification_screen.dart';

class ServiceProviderSignUpScreen extends StatefulWidget {
  const ServiceProviderSignUpScreen({super.key});

  @override
  State<ServiceProviderSignUpScreen> createState() =>
      _ServiceProviderSignUpScreenState();
}

class _ServiceProviderSignUpScreenState
    extends State<ServiceProviderSignUpScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  bool _isDataLoading = true;

  String? _selectedCategory;
  String? _selectedCity;
  List<Map<String, dynamic>> _serviceCategories = [];
  List<Map<String, dynamic>> _cities = [];

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isDataLoading = true);

    try {
      // Load cities and categories from Firebase
      final cities = await _authService.getCities();
      final categories = await _authService.getCategories();

      debugPrint('Loaded ${cities.length} cities: ${cities
          .map((c) => c['name'])
          .toList()}');
      debugPrint('Loaded ${categories.length} categories: ${categories.map((
          c) => c['name']).toList()}');

      if (mounted) {
        setState(() {
          _cities = cities;
          _serviceCategories = categories;
          _isDataLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading data: $e');
        setState(() => _isDataLoading = false);
        _showErrorSnackBar('Failed to load data. Please try again.');
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDataLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black54),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Service Provider Registration',
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF4169E1),
              ),
              SizedBox(height: 16),
              Text(
                'Loading registration form...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7F8C8D),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Service Provider Registration',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.build_circle,
                  size: 35,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              // Welcome text
              const Text(
                'Join as Service Provider',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Create your professional account',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7F8C8D),
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 30),

              // Full Name field
              _buildTextField(
                controller: _fullNameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
              ),

              const SizedBox(height: 20),

              // Email field
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'Enter your email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              // Phone field
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter your phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 20),

              // Business Name field
              _buildTextField(
                controller: _businessNameController,
                label: 'Business Name (Optional)',
                hint: 'Enter your business name',
                icon: Icons.business_outlined,
                keyboardType: TextInputType.text,
              ),

              const SizedBox(height: 20),

              // City dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'City',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCity,
                      onChanged: (_isLoading || _isDataLoading) ? null : (
                          String? newValue) {
                        setState(() {
                          _selectedCity = newValue;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: _isDataLoading
                            ? 'Loading cities...'
                            : _cities.isEmpty
                            ? 'No cities available'
                            : 'Select your city',
                        hintStyle: const TextStyle(color: Color(0xFFBDC3C7)),
                        prefixIcon: const Icon(
                          Icons.location_city_outlined,
                          color: Color(0xFFBDC3C7),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _cities.isEmpty
                          ? []
                          : _cities.map<DropdownMenuItem<String>>((Map<String, dynamic> city) {
                          return DropdownMenuItem<String>(
                            value: city['name'],
                            child: Text(city['name']),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                  if (_cities.isEmpty && !_isDataLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'No cities available. Contact admin.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    )],
              ),

              const SizedBox(height: 20),

              // Service Category dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Primary Service Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      onChanged: (_isLoading || _isDataLoading) ? null : (
                          String? newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: _isDataLoading
                            ? 'Loading categories...'
                            : 'Select your service category',
                        hintStyle: const TextStyle(color: Color(0xFFBDC3C7)),
                        prefixIcon: const Icon(
                          Icons.category_outlined,
                          color: Color(0xFFBDC3C7),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _serviceCategories.map<DropdownMenuItem<String>>(
                            (Map<String, dynamic> category) {
                          return DropdownMenuItem<String>(
                            value: category['name'],
                            child: Text(category['name']),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Experience field
              _buildTextField(
                controller: _experienceController,
                label: 'Years of Experience',
                hint: 'Enter years of experience',
                icon: Icons.work_outline,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 20),

              // Password field
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Create a password',
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscurePassword,
                onTogglePassword: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Confirm Password field
              _buildTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hint: 'Confirm your password',
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscureConfirmPassword,
                onTogglePassword: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Terms and conditions
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: _isLoading ? null : (value) {
                      setState(() {
                        _agreeToTerms = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF4169E1),
                  ),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          color: Color(0xFF7F8C8D),
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: Color(0xFF4169E1),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: Color(0xFF4169E1),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Sign Up button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_agreeToTerms && !_isLoading)
                      ? _handleSignUp
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4169E1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Continue to Verification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Sign in link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: Color(0xFF7F8C8D),
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isLoading ? null : () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color(0xFF4169E1),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: !_isLoading,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFBDC3C7)),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFFBDC3C7),
            ),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFFBDC3C7),
              ),
              onPressed: onTogglePassword,
            )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4169E1)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignUp() async {
    // Basic validation
    if (_fullNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _experienceController.text.isEmpty ||
        _selectedCategory == null ||
        _selectedCity == null) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    // Password confirmation validation
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    // Email validation
    if (!_emailController.text.contains('@')) {
      _showErrorSnackBar('Please enter a valid email');
      return;
    }

    // Password strength validation
    if (_passwordController.text.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create service provider account with Firebase
      await _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        userType: 'service_provider',
        additionalData: {
          'businessName': _businessNameController.text.trim(),
          'serviceCategory': _selectedCategory,
          'city': _selectedCity,
          'yearsOfExperience': int.tryParse(_experienceController.text) ?? 0,
          'verificationStatus': 'pending',
        },
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Account created successfully! Please complete identity verification.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to identity verification
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const IdentityVerificationScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
