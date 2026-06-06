import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Data
    final notifications = [
      {
        'title': 'تمت الموافقة على الإجازة',
        'body': 'تمت الموافقة على طلب الإجازة الخاص بك من 10 مايو إلى 12 مايو.',
        'time': 'منذ ساعتين',
        'isRead': false,
        'icon': Icons.check_circle_outline_rounded,
        'color': AppColors.success,
      },
      {
        'title': 'تذكير بتسجيل الحضور',
        'body': 'يرجى التأكد من تسجيل حضورك اليومي في الوقت المحدد.',
        'time': 'منذ 5 ساعات',
        'isRead': true,
        'icon': Icons.access_time_rounded,
        'color': AppColors.warning,
      },
      {
        'title': 'إعلان إداري',
        'body': 'اجتماع الشركة الشهري سيعقد غداً في تمام الساعة 10 صباحاً في قاعة الاجتماعات الرئيسية.',
        'time': 'منذ يوم',
        'isRead': true,
        'icon': Icons.campaign_outlined,
        'color': AppColors.primary,
      },
      {
        'title': 'رفض طلب الإجازة',
        'body': 'نأسف، تم رفض طلب الإجازة الخاص بك نظراً لضغط العمل الحالي.',
        'time': 'منذ يومين',
        'isRead': true,
        'icon': Icons.cancel_outlined,
        'color': AppColors.danger,
      },
      {
        'title': 'تحديث سياسة الموارد البشرية',
        'body': 'تم تحديث سياسة الموارد البشرية، يرجى مراجعة المستند المرفق في البريد الإلكتروني.',
        'time': 'منذ 3 أيام',
        'isRead': true,
        'icon': Icons.article_outlined,
        'color': AppColors.primary,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'الإشعارات',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.border.withValues(alpha: 0.5),
            height: 1,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final isRead = notification['isRead'] as bool;
          final color = notification['color'] as Color;

          return Container(
            decoration: BoxDecoration(
              color: isRead ? Colors.white : color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRead ? AppColors.border.withValues(alpha: 0.5) : color.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: isRead
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification['icon'] as IconData,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'] as String,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 15,
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification['body'] as String,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        notification['time'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
