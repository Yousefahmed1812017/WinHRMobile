import 'dart:io';

void main() {
  final path = 'lib/features/employees/presentation/screens/employees_list_screen.dart';
  final file = File(path);
  final lines = file.readAsLinesSync();
  
  final newLines = lines.sublist(0, 647);
  newLines.add('''
class _EmployeeActionSheet extends StatelessWidget {
  final Employee employee;

  const _EmployeeActionSheet({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            employee.fullNameAr,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '#' + employee.code + ' · ' + (employee.jobTitle ?? '-'),
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.primary),
            title: Text('الملف الشخصي', style: GoogleFonts.ibmPlexSansArabic(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              GoRouter.of(context).push(RouteNames.employeeDetails, extra: employee);
            },
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint, color: AppColors.primary),
            title: Text('سجل الحضور والانصراف', style: GoogleFonts.ibmPlexSansArabic(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              GoRouter.of(context).push(RouteNames.employeeAttendance, extra: employee);
            },
          ),
          ListTile(
            leading: const Icon(Icons.beach_access_outlined, color: AppColors.primary),
            title: Text('سجل الإجازات', style: GoogleFonts.ibmPlexSansArabic(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              GoRouter.of(context).push(RouteNames.leaveRequests);
            },
          ),
        ],
      ),
    );
  }
}
''');
  file.writeAsStringSync(newLines.join('\\n'));
}
