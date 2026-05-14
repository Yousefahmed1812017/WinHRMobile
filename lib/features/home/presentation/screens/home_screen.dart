import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../auth/data/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Red Header ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: ClipOval(
                    child: user?.imageUrl != null && user!.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: user.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const Icon(Icons.person, color: Colors.white, size: 40),
                            errorWidget: (context, url, error) =>
                                _buildDefaultAvatar(user.fullName),
                          )
                        : _buildDefaultAvatar(user?.fullName),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Greeting
                Text(
                  'مرحباً، ${user?.fullName?.split(' ').first ?? 'يا زميل'}!',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (user?.roleName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user!.roleName!,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _HomeCard(
                  title: 'طلبات الإجازات',
                  icon: Icons.event_note_rounded,
                  color: const Color(0xFF3B82F6), // Blue
                  onTap: () => context.go(RouteNames.leaveRequests),
                ),
                const SizedBox(height: 16),
                _HomeCard(
                  title: 'تسجيل الحضور',
                  icon: Icons.fingerprint_rounded,
                  color: const Color(0xFF10B981), // Green
                  onTap: () => context.go(RouteNames.attendance),
                ),
                const SizedBox(height: 16),
                _HomeCard(
                  title: 'حسابي',
                  icon: Icons.person_rounded,
                  color: const Color(0xFF8B5CF6), // Purple
                  onTap: () => context.go(RouteNames.profile),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String? name) {
    final initials = (name ?? '?')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join();
    return Center(
      child: Text(
        initials.isNotEmpty ? initials : '?',
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HomeCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}
