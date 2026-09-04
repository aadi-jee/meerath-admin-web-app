import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'admin_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _hidePassword = true;
  bool _rememberMe = true;

  void _signIn() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const AdminShell(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            if (!isWide) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _loginCard(),
                  ),
                ),
              );
            }

            final availableHeight = constraints.maxHeight - 48;
            double panelHeight = availableHeight;

            if (panelHeight > 720) {
              panelHeight = 720;
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: SizedBox(
                    height: panelHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: AppColors.border,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _loginCard(),
                          ),
                          const Expanded(
                            flex: 6,
                            child: _BrandPanel(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _loginCard() {
    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.symmetric(
        horizontal: 48,
        vertical: 40,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MeerathBrand(),

          const SizedBox(height: 44),

          const Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Sign in to manage your restaurant.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            'Work Email',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          const TextField(
            decoration: InputDecoration(
              hintText: 'Enter your work email',
              prefixIcon: Icon(
                Icons.mail_outline_rounded,
                color: AppColors.textMuted,
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Password',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            obscureText: _hidePassword,
            decoration: InputDecoration(
              hintText: 'Enter your password',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.textMuted,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _hidePassword = !_hidePassword;
                  });
                },
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
              ),
              const Text(
                'Remember me',
                style: TextStyle(fontSize: 13),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          const Divider(color: AppColors.border),

          const SizedBox(height: 18),

          const Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 15,
                color: AppColors.textDim,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Secure access for authorized staff only',
                  style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeerathBrand extends StatelessWidget {
  const _MeerathBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentSoft,
            border: Border.all(
              color: AppColors.accent,
              width: 1.8,
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            'M',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 15),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MEERATH',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            Text(
              'ADMIN PORTAL',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 64,
        vertical: 50,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D0D0D),
            Color(0xFF16120C),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage your\nrestaurant.',
            style: TextStyle(
              fontSize: 44,
              height: 1.08,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'From one place.',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 44,
              height: 1.08,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Menu, offers, customers and restaurant performance in one simple dashboard.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 15,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 38),

          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FeatureChip(
                icon: Icons.restaurant_menu_rounded,
                text: 'Menu',
              ),
              _FeatureChip(
                icon: Icons.local_offer_outlined,
                text: 'Offers',
              ),
              _FeatureChip(
                icon: Icons.people_outline_rounded,
                text: 'Customers',
              ),
              _FeatureChip(
                icon: Icons.insights_outlined,
                text: 'Sales',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.accent,
            size: 17,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}