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
  String get username => 'اسم المستخدم';

  @override
  String get password => 'كلمة المرور';

  @override
  String get loginButton => 'دخول';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get signInSubtitle => 'سجل دخولك للوصول إلى بوابة الموارد البشرية';

  @override
  String get noDataFound => 'لا توجد بيانات';

  @override
  String get errorOccurred => 'حدث خطأ';

  @override
  String get noInternet => 'لا يوجد اتصال بالإنترنت';

  @override
  String get employees => 'الموظفين';

  @override
  String get employeesList => 'قائمة الموظفين';

  @override
  String get employeeDetails => 'تفاصيل الموظف';

  @override
  String get employeeCode => 'كود الموظف';

  @override
  String get searchByCode => 'بحث بكود الموظف...';

  @override
  String get search => 'بحث';

  @override
  String get employeeName => 'اسم الموظف';

  @override
  String get jobTitle => 'المسمى الوظيفي';

  @override
  String get department => 'الإدارة';

  @override
  String get hireDate => 'تاريخ التعيين';

  @override
  String get personalInfo => 'البيانات الشخصية';

  @override
  String get jobInfo => 'البيانات الوظيفية';

  @override
  String get shiftInfo => 'بيانات الوردية';

  @override
  String get shiftType => 'نوع الوردية';

  @override
  String get shiftName => 'اسم الوردية';

  @override
  String get groupName => 'المجموعة';

  @override
  String get employeeStatus => 'حالة الموظف';

  @override
  String get employmentStatus => 'الحالة الوظيفية';

  @override
  String get active => 'يعمل';

  @override
  String get retired => 'متقاعد';

  @override
  String get deceased => 'وفاة';

  @override
  String get terminationDate => 'تاريخ إنهاء الخدمة';

  @override
  String get jobGrade => 'الدرجة الوظيفية';

  @override
  String get jobGradeDate => 'تاريخ الدرجة';

  @override
  String get totalEmployees => 'إجمالي الموظفين';

  @override
  String pageOf(int current, int total) {
    return 'صفحة $current من $total';
  }

  @override
  String get loadMore => 'تحميل المزيد';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get loginFailed => 'فشل تسجيل الدخول';

  @override
  String get loginSuccess => 'تم تسجيل الدخول بنجاح';

  @override
  String get invalidCredentials => 'بيانات الدخول غير صحيحة';

  @override
  String get code => 'الكود';

  @override
  String get decisionNumber => 'رقم القرار';

  @override
  String get fixed => 'ثابت';

  @override
  String get rotating => 'المناوبة';
}
