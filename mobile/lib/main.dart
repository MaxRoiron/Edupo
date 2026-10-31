import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'theme/civic_theme.dart';
import 'widgets/civic_components.dart';
import 'screens/home_screen.dart';
import 'screens/programs_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EdupoApp());
}

class EdupoApp extends StatefulWidget {
  const EdupoApp({super.key});
  @override
  State<EdupoApp> createState() => _EdupoAppState();
}

class _EdupoAppState extends State<EdupoApp> {
  int _currentIndex = 0;
  final List<Widget?> _pages = [const HomeScreen(), null, null, null];
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Édupo',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    home: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Civic.paper,
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(
            4,
            (index) => TickerMode(
              enabled: index == _currentIndex,
              child: _pages[index] ?? const SizedBox.shrink(),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Material(
                  color: Colors.white,
                  elevation: 3,
                  shadowColor: Civic.ink.withValues(alpha: .12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                    side: const BorderSide(color: Civic.line),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      children: [
                        _nav(
                          0,
                          Icons.home_rounded,
                          Icons.home_outlined,
                          'Lois',
                        ),
                        _nav(
                          1,
                          Icons.description_rounded,
                          Icons.description_outlined,
                          'Partis',
                        ),
                        _nav(
                          2,
                          Icons.account_balance_rounded,
                          Icons.account_balance_outlined,
                          'Structure',
                        ),
                        _nav(
                          3,
                          Icons.person_rounded,
                          Icons.person_outline_rounded,
                          'Compte',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _nav(int index, IconData selectedIcon, IconData icon, String label) {
    final selected = _currentIndex == index;
    return Expanded(
      child: Semantics(
        selected: selected,
        child: Material(
          color: selected ? Civic.blue : Colors.white,
          borderRadius: BorderRadius.circular(19),
          child: CivicPress(
            radius: 19,
            onTap: () {
              if (index == _currentIndex) return;
              setState(() {
                _currentIndex = index;
                _pages[index] ??= _buildPage(index);
              });
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 61),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? selectedIcon : icon,
                      color: selected ? Colors.white : Civic.muted,
                      size: 22,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : Civic.muted,
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(int index) => switch (index) {
    0 => const HomeScreen(),
    1 => const ProgramsScreen(),
    2 => _buildPlaceholderPage(
      icon: Icons.account_balance_rounded,
      title: 'Structure',
      subtitle: 'Organisation institutionnelle',
    ),
    3 => const ProfileScreen(embedded: true),
    _ => const HomeScreen(),
  };

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
            style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.frBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.frBlue.withValues(alpha: 0.15),
              ),
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
