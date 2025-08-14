import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:cognoapp/presentation/authentication/auth_provider.dart';
import 'package:cognoapp/core/widgets/custom_snackbar.dart';
import 'package:cognoapp/core/error/exceptions.dart';
import 'package:cognoapp/config/theme.dart';
import 'package:cognoapp/config/constants.dart';
import 'package:cognoapp/presentation/common_widgets/app_button.dart';
import 'package:cognoapp/presentation/common_widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    
    // Set up animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _animationController.forward();
    
    // Check if remember me was previously enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      setState(() {
        _rememberMe = authProvider.isRememberMeEnabled();
      });
      
      // Pre-fill email if saved
      final savedEmail = authProvider.getSavedEmail();
      if (savedEmail != null && savedEmail.isNotEmpty) {
        _emailController.text = savedEmail;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Server status check utility method
  Future<void> _checkServerStatus() async {
    try {
      CustomSnackbar.show(
        context: context,
        message: 'Checking server status...',
      );
      
      final response = await http.get(
        Uri.parse(AppConstants.BASE_URL),
      ).timeout(const Duration(seconds: 5));
      
      CustomSnackbar.show(
        context: context,
        message: 'Server is running! Status: ${response.statusCode}',
      );
    } catch (e) {
      CustomSnackbar.showError(
        context: context,
        message: 'Server check failed: ${e.toString()}',
      );
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty) {
      CustomSnackbar.showError(
        context: context,
        message: 'Please enter your email',
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      CustomSnackbar.showError(
        context: context,
        message: 'Please enter your password',
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.login(
        _emailController.text,
        _passwordController.text,
        _rememberMe,
      );

      if (success && mounted) {
        if (authProvider.isAdmin && !authProvider.requireZoneWardSelection) {
          // Admin users who have already selected zone/ward go directly to admin dashboard
          Navigator.pushReplacementNamed(context, '/admin/dashboard');
        } else {
          // All other users go to zone/ward selection first
          Navigator.pushReplacementNamed(context, '/zone-ward-selection');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Login failed';
        
        if (e is ServerException) {
          errorMessage = e.message;
        } else {
          // Handle general errors
          errorMessage = 'Connection error: ${e.toString()}';
        }
        
        CustomSnackbar.showError(
          context: context,
          message: errorMessage,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeInAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  height: size.height - MediaQuery.of(context).padding.top - 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),
                      
                      // Logo and app name
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cleaning_services_rounded,
                                size: 40,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Cognoclean',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 50),
                      
                      // "Login to your Account" heading
                      const Text(
                        'Login to your account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Welcome back! Please enter your credentials',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Email field
                      AppTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        textInputAction: TextInputAction.next,
                        margin: const EdgeInsets.only(bottom: 20),
                      ),
                      
                      // Password field
                      AppPasswordField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        margin: const EdgeInsets.only(bottom: 16),
                      ),
                      
                      // Remember me & Forgot password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  activeColor: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Remember Me',
                                style: TextStyle(
                                  color: AppTheme.textPrimaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              CustomSnackbar.show(
                                context: context,
                                message: 'Forgot password functionality coming soon',
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(100, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Login button
                      AppButton(
                        text: 'Sign In',
                        isLoading: authProvider.isLoading,
                        onPressed: authProvider.isLoading ? null : _login,
                      ),
                      
                      const Spacer(),
                      
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 15,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              CustomSnackbar.show(
                                context: context,
                                message: 'Sign up functionality coming soon',
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.only(left: 4),
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Hidden server check button for debug
                      Opacity(
                        opacity: 0.0,
                        child: TextButton(
                          onPressed: _checkServerStatus,
                          child: const Text('Check Server'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
