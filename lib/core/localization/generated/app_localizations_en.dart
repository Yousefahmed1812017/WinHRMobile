// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Win HR';

  @override
  String get login => 'Login';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get logout => 'Logout';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get retry => 'Retry';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInSubtitle => 'Sign in to access the HR portal';

  @override
  String get noDataFound => 'No data found';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get noInternet => 'No internet connection';

  @override
  String get employees => 'Employees';

  @override
  String get employeesList => 'Employees List';

  @override
  String get employeeDetails => 'Employee Details';

  @override
  String get employeeCode => 'Employee Code';

  @override
  String get searchByCode => 'Search by employee code...';

  @override
  String get search => 'Search';

  @override
  String get employeeName => 'Employee Name';

  @override
  String get jobTitle => 'Job Title';

  @override
  String get department => 'Department';

  @override
  String get hireDate => 'Hire Date';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get jobInfo => 'Job Information';

  @override
  String get shiftInfo => 'Shift Information';

  @override
  String get shiftType => 'Shift Type';

  @override
  String get shiftName => 'Shift Name';

  @override
  String get groupName => 'Group';

  @override
  String get employeeStatus => 'Employee Status';

  @override
  String get employmentStatus => 'Employment Status';

  @override
  String get active => 'Active';

  @override
  String get retired => 'Retired';

  @override
  String get deceased => 'Deceased';

  @override
  String get terminationDate => 'Termination Date';

  @override
  String get jobGrade => 'Job Grade';

  @override
  String get jobGradeDate => 'Grade Date';

  @override
  String get totalEmployees => 'Total Employees';

  @override
  String pageOf(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get loadMore => 'Load More';

  @override
  String get loading => 'Loading...';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get loginSuccess => 'Login successful';

  @override
  String get invalidCredentials => 'Invalid credentials';

  @override
  String get code => 'Code';

  @override
  String get decisionNumber => 'Decision Number';

  @override
  String get fixed => 'Fixed';

  @override
  String get rotating => 'Rotating';
}
