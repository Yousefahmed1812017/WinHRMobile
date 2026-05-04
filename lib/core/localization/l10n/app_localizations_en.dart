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
  String get employeeId => 'Employee ID';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get loginButton => 'Sign In';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get retry => 'Retry';

  @override
  String get home => 'Home';

  @override
  String get attendance => 'Attendance';

  @override
  String get leaves => 'Leaves';

  @override
  String get shifts => 'Shifts';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get checkIn => 'Check In';

  @override
  String get checkOut => 'Check Out';

  @override
  String checkedInAt(String time) {
    return 'Checked in at $time';
  }

  @override
  String get workHoursToday => 'Work Hours Today';

  @override
  String get attendanceHistory => 'Attendance History';

  @override
  String get attendanceStats => 'Statistics';

  @override
  String get leaveBalance => 'Leave Balance';

  @override
  String get newLeaveRequest => 'New Leave Request';

  @override
  String get leaveType => 'Leave Type';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get reason => 'Reason';

  @override
  String get attachment => 'Attachment';

  @override
  String get submit => 'Submit';

  @override
  String get pending => 'Pending';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get myShifts => 'My Shifts';

  @override
  String get shiftChangeRequest => 'Change Request';

  @override
  String get currentShift => 'Current Shift';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get jobInfo => 'Job Information';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get noDataFound => 'No data found';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get noInternet => 'No internet connection';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get todaySummary => 'Today\'s Summary';

  @override
  String get annualLeave => 'Annual Leave';

  @override
  String get sickLeave => 'Sick Leave';

  @override
  String get casualLeave => 'Casual Leave';

  @override
  String daysRemaining(int count) {
    return '$count days remaining';
  }
}
