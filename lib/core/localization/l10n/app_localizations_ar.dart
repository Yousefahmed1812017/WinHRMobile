// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Win HR';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get employeeId => 'رقم الموظف';

  @override
  String get password => 'كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get loginButton => 'دخول';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutConfirm => 'هل أنت متأكد من تسجيل الخروج؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get home => 'الرئيسية';

  @override
  String get attendance => 'الحضور';

  @override
  String get leaves => 'الإجازات';

  @override
  String get shifts => 'الورديات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get settings => 'الإعدادات';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get checkIn => 'تسجيل حضور';

  @override
  String get checkOut => 'تسجيل انصراف';

  @override
  String checkedInAt(String time) {
    return 'تم التسجيل في $time';
  }

  @override
  String get workHoursToday => 'ساعات العمل اليوم';

  @override
  String get attendanceHistory => 'سجل الحضور';

  @override
  String get attendanceStats => 'الإحصائيات';

  @override
  String get leaveBalance => 'رصيد الإجازات';

  @override
  String get newLeaveRequest => 'طلب إجازة جديد';

  @override
  String get leaveType => 'نوع الإجازة';

  @override
  String get startDate => 'تاريخ البداية';

  @override
  String get endDate => 'تاريخ النهاية';

  @override
  String get reason => 'السبب';

  @override
  String get attachment => 'مرفق';

  @override
  String get submit => 'إرسال';

  @override
  String get pending => 'قيد المراجعة';

  @override
  String get approved => 'مقبول';

  @override
  String get rejected => 'مرفوض';

  @override
  String get cancelled => 'ملغي';

  @override
  String get myShifts => 'ورديات العمل';

  @override
  String get shiftChangeRequest => 'طلب تعديل وردية';

  @override
  String get currentShift => 'الوردية الحالية';

  @override
  String get personalInfo => 'البيانات الشخصية';

  @override
  String get jobInfo => 'البيانات الوظيفية';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get darkMode => 'الوضع الليلي';

  @override
  String get noDataFound => 'لا توجد بيانات';

  @override
  String get errorOccurred => 'حدث خطأ';

  @override
  String get noInternet => 'لا يوجد اتصال بالإنترنت';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get todaySummary => 'ملخص اليوم';

  @override
  String get annualLeave => 'إجازة سنوية';

  @override
  String get sickLeave => 'إجازة مرضية';

  @override
  String get casualLeave => 'إجازة عارضة';

  @override
  String daysRemaining(int count) {
    return '$count يوم متبقي';
  }
}
