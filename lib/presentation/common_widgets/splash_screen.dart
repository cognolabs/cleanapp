import 'package:flutter/material.dart';
import 'package:cognoapp/config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeInAnimation1;
  late Animation<double> _fadeInAnimation2;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeInAnimation1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _fadeInAnimation2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo container with animated gradient background
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing background
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withOpacity(0.7 * (1 - _pulseAnimation.value)),
                              AppTheme.primaryColor.withOpacity(0.0),
                            ],
                            stops: const [0.4, 0.6, 1.0],
                            center: Alignment.center,
                            radius: 0.5 + (_pulseAnimation.value * 0.5),
                          ),
                        ),
                      ),
                      
                      // Icon
                      const Icon(
                        Icons.cleaning_services_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 40),
            
            // App name with fade in animation
            AnimatedBuilder(
              animation: _fadeInAnimation1,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeInAnimation1.value,
                  child: child,
                );
              },
              child: const Text(
                'Cognoclean',
                style: TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Subtitle with fade in animation
            AnimatedBuilder(
              animation: _fadeInAnimation1,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeInAnimation1.value,
                  child: child,
                );
              },
              child: const Text(
                'Smart Cleaning Solutions',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Loading indicator
            AnimatedBuilder(
              animation: _fadeInAnimation2,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeInAnimation2.value,
                  child: child,
                );
              },
              child: const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  strokeWidth: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
