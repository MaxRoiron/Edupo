import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Make status bar transparent for immersive header
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const EdupoApp());
}

class EdupoApp extends StatefulWidget {
  const EdupoApp({super.key});

  @override
  State<EdupoApp> createState() => _EdupoAppState();
}

class _EdupoAppState extends State<EdupoApp> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Édupo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            final slideDirection = _currentIndex > _previousIndex ? 1.0 : -1.0;
            final inAnimation = Tween<Offset>(
              begin: Offset(slideDirection, 0),
              end: Offset.zero,
            ).animate(animation);
            final outAnimation = Tween<Offset>(
              begin: Offset(-slideDirection, 0),
              end: Offset.zero,
            ).animate(animation);
            // Use the entering animation for the new child, exiting for the old
            if (child.key == ValueKey(_currentIndex)) {
              return SlideTransition(position: inAnimation, child: child);
            } else {
              return SlideTransition(position: outAnimation, child: child);
            }
          },
          child: _buildPage(_currentIndex),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.frBlue,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Accueil'),
                  _buildNavItem(1, Icons.description_rounded, Icons.description_outlined, 'Programmes'),
                  _buildNavItem(2, Icons.account_balance_rounded, Icons.account_balance_outlined, 'Structure'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _previousIndex = _currentIndex;
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.frWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? AppColors.frBlue : AppColors.frWhite,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.frBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const HomeScreen(key: ValueKey(0));
      case 1:
        return _buildPlaceholderPage(
          key: const ValueKey(1),
          icon: Icons.description_rounded,
          title: 'Programmes politiques',
          subtitle: 'Découvrez les programmes',
        );
      case 2:
        return _buildPlaceholderPage(
          key: const ValueKey(2),
          icon: Icons.account_balance_rounded,
          title: 'Structure',
          subtitle: 'Organisation institutionnelle',
        );
      default:
        return const HomeScreen(key: ValueKey(0));
    }
  }

  Widget _buildPlaceholderPage({
    Key? key,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.frBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 48, color: AppColors.frBlue),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.frBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.frBlue.withValues(alpha: 0.15)),
            ),
            child: const Text(
              'Bientôt disponible',
              style: TextStyle(
                color: AppColors.frBlue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
