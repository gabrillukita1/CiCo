import 'package:cico_project/core/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brand700,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _buildStage(context),
          Expanded(child: _buildSheet()),
        ],
      ),
    );
  }

  // ── Teal Terminal Stage ────────────────────────────────────────────────────
  Widget _buildStage(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.brand700],
        ),
      ),
      child: Stack(
        children: [
          // Radial glow (top-right)
          Positioned(
            top: -150, right: -110,
            child: _DecorCircle(size: 320, isGlow: true, opacity: 0.22),
          ),
          Positioned(
            top: -60, right: -120,
            child: _DecorCircle(size: 260, isGlow: false, opacity: 0.14),
          ),
          Positioned(
            bottom: -240, left: -120,
            child: _DecorCircle(size: 360, isGlow: false, opacity: 0.10),
          ),
          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(28, top + 28, 28, 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App logo + "Driver Terminal" label
                Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 42, height: 42,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'DRIVER TERMINAL',
                      style: TextStyle(fontFamily: 'SpaceGrotesk',
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // cico. wordmark
                RichText(
                  text: TextSpan(
                    text: 'cico',
                    style: TextStyle(fontFamily: 'SpaceGrotesk',
                      color: Colors.white,
                      fontSize: 62,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -2.5,
                      height: 0.9,
                    ),
                    children: [
                      TextSpan(
                        text: '.',
                        style: TextStyle(fontFamily: 'SpaceGrotesk',
                          color: const Color(0xFF9FE9ED),
                          fontSize: 62,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Clock in, clock out, and track\nevery shift in one tap.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── White Sheet ────────────────────────────────────────────────────────────
  Widget _buildSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sign in',
                style: TextStyle(fontFamily: 'SpaceGrotesk',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Use your assigned driver account.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),

              // Email
              _TicketInput(
                label: 'EMAIL ADDRESS',
                icon: Icons.alternate_email_rounded,
                textController: controller.emailController,
                placeholder: 'driver@company.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 16),

              // Password
              Obx(() => _TicketInput(
                label: 'PASSWORD',
                icon: Icons.lock_outline_rounded,
                textController: controller.passwordController,
                placeholder: '••••••••',
                obscureText: controller.obscurePassword.value,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => controller.login(),
                trailing: GestureDetector(
                  onTap: () => controller.obscurePassword.value =
                      !controller.obscurePassword.value,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      controller.obscurePassword.value
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 20,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 24),

              // Sign In button
              Obx(() => GestureDetector(
                onTap: controller.isLoading.value ? null : controller.login,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.panelInk,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.panelInk.withValues(alpha: 0.5),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (controller.isLoading.value)
                        const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5,
                          ),
                        )
                      else
                        const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16.5,
                          ),
                        ),
                    ],
                  ),
                ),
              )),

              const SizedBox(height: 20),
              Center(
                child: Obx(() => Text(
                  controller.appVersion.value.isEmpty
                      ? ''
                      : 'CICO  ·  ${controller.appVersion.value}',
                  style: TextStyle(
                    color: AppColors.muted.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Decorative circle helper ──────────────────────────────────────────────────
class _DecorCircle extends StatelessWidget {
  final double size;
  final bool isGlow;
  final double opacity;

  const _DecorCircle({
    required this.size,
    required this.isGlow,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    if (isGlow) {
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: opacity),
              Colors.transparent,
            ],
            stops: const [0, 0.65],
          ),
        ),
      );
    }
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: 1.5,
        ),
      ),
    );
  }
}

// ── Ticket-style input field ──────────────────────────────────────────────────
class _TicketInput extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController textController;
  final String placeholder;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final Function(String)? onSubmitted;
  final Widget? trailing;

  const _TicketInput({
    required this.label,
    required this.icon,
    required this.textController,
    required this.placeholder,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.transparent, width: 1.5),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 11),
              Expanded(
                child: TextField(
                  controller: textController,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  autofillHints: autofillHints,
                  onSubmitted: onSubmitted,
                  cursorColor: AppColors.primary,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: const TextStyle(
                      color: Color(0xFFA7B2C2),
                      fontWeight: FontWeight.w500,
                      fontSize: 15.5,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
