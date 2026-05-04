import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/data/auth_provider.dart';
import '../../../../features/employees/data/employees_provider.dart';
import '../../../../features/employees/data/models/employee_model.dart';
import '../../data/leaves_provider.dart';

import '../../data/models/leave_request_model.dart';

/// Create leave request screen — 2-step flow (form → confirmation).
class CreateLeaveRequestScreen extends ConsumerStatefulWidget {
  /// If provided, the employee is pre-filled and locked.
  final Employee? prefilledEmployee;

  const CreateLeaveRequestScreen({super.key, this.prefilledEmployee});

  @override
  ConsumerState<CreateLeaveRequestScreen> createState() =>
      _CreateLeaveRequestScreenState();
}

class _CreateLeaveRequestScreenState
    extends ConsumerState<CreateLeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _leaveReasonController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  Employee? _selectedEmployee;
  LeaveType? _selectedLeaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isConfirmationStep = false;
  bool _isSubmitting = false;
  bool _isSearchingEmployee = false;
  List<Employee> _searchResults = [];

  @override
  void initState() {
    super.initState();
    if (widget.prefilledEmployee != null) {
      _selectedEmployee = widget.prefilledEmployee;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _leaveReasonController.dispose();
    _emergencyPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _totalLeaveDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _searchEmployees(String code) async {
    if (code.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearchingEmployee = false;
      });
      return;
    }

    setState(() => _isSearchingEmployee = true);
    try {
      final repo = ref.read(employeesRepositoryProvider);
      final response = await repo.searchByCode(code);
      if (mounted) {
        setState(() {
          _searchResults = response.employees;
          _isSearchingEmployee = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearchingEmployee = false);
      }
    }
  }

  void _goToConfirmation() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى اختيار الموظف',
              style: GoogleFonts.cairo()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_selectedLeaveType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى اختيار نوع الإجازة',
              style: GoogleFonts.cairo()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى تحديد تاريخ البداية والنهاية',
              style: GoogleFonts.cairo()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isConfirmationStep = true);
  }

  Future<void> _submitRequest() async {
    setState(() => _isSubmitting = true);

    try {
      final authState = ref.read(authStateProvider);
      final repo = ref.read(leavesRepositoryProvider);

      await repo.createLeaveRequest(
        employeeId: _selectedEmployee!.employeeId,
        leaveTypeId: _selectedLeaveType!.id,
        startDate: _formatDate(_startDate),
        endDate: _formatDate(_endDate),
        totalLeaveDays: _totalLeaveDays,
        leaveReason: _leaveReasonController.text.trim(),
        emergencyPhone: _emergencyPhoneController.text.trim(),
        notes: _notesController.text.trim(),
        username: authState.user?.username ?? '',
        userId: authState.user?.userId ?? 0,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('تم إنشاء طلب الإجازة بنجاح',
                  style: GoogleFonts.cairo()),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إنشاء الطلب', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isConfirmationStep ? 'تأكيد الطلب' : 'إنشاء طلب إجازة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_isConfirmationStep) {
              setState(() => _isConfirmationStep = false);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: _isConfirmationStep ? _buildConfirmation() : _buildForm(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Form Step
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildForm() {
    final leaveTypesAsync = ref.watch(leaveTypesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Employee Selection ──────────────────────────────────
            _SectionHeader(title: 'الموظف', icon: Icons.person_outline_rounded),
            const SizedBox(height: 8),

            if (widget.prefilledEmployee != null)
              _buildSelectedEmployeeChip()
            else ...[
              TextFormField(
                controller: _searchController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.cairo(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'بحث بكود الموظف...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _isSearchingEmployee
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _selectedEmployee != null
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                setState(() {
                                  _selectedEmployee = null;
                                  _searchResults = [];
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                ),
                onChanged: (val) => _searchEmployees(val.trim()),
              ),
              if (_selectedEmployee != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildSelectedEmployeeChip(),
                ),
              if (_searchResults.isNotEmpty && _selectedEmployee == null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final emp = _searchResults[index];
                      return ListTile(
                        dense: true,
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              emp.code,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          emp.fullNameAr,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          emp.department ?? '',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedEmployee = emp;
                            _searchResults = [];
                            _searchController.text = emp.code;
                          });
                        },
                      );
                    },
                  ),
                ),
            ],

            const SizedBox(height: 20),

            // ── Leave Type ──────────────────────────────────────────
            _SectionHeader(
                title: 'نوع الإجازة', icon: Icons.category_outlined),
            const SizedBox(height: 8),
            leaveTypesAsync.when(
              data: (types) => DropdownButtonFormField<LeaveType>(
                initialValue: _selectedLeaveType,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.event_note_outlined),
                ),
                hint: Text('اختر نوع الإجازة',
                    style: GoogleFonts.cairo(fontSize: 14)),
                items: types
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                            t.nameAr,
                            style: GoogleFonts.cairo(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedLeaveType = val),
                validator: (val) => val == null ? 'مطلوب' : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('خطأ في تحميل أنواع الإجازات',
                  style: GoogleFonts.cairo(color: AppColors.danger)),
            ),

            const SizedBox(height: 20),

            // ── Date Range ──────────────────────────────────────────
            _SectionHeader(
                title: 'الفترة', icon: Icons.date_range_rounded),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'من',
                    value: _formatDate(_startDate),
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'إلى',
                    value: _formatDate(_endDate),
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Total days (read-only)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.accentSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timelapse_rounded,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'إجمالي الأيام',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$_totalLeaveDays يوم',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Leave Reason (optional) ─────────────────────────────
            _SectionHeader(
                title: 'سبب الإجازة (اختياري)',
                icon: Icons.edit_note_rounded),
            const SizedBox(height: 8),
            TextFormField(
              controller: _leaveReasonController,
              style: GoogleFonts.cairo(fontSize: 14),
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'أدخل سبب الإجازة...',
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 20),

            // ── Emergency Phone (optional) ──────────────────────────
            _SectionHeader(
                title: 'هاتف الطوارئ (اختياري)',
                icon: Icons.phone_outlined),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emergencyPhoneController,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: const InputDecoration(
                hintText: '01012345678',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),

            const SizedBox(height: 32),

            // ── Submit Button ───────────────────────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _goToConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'التالي - مراجعة الطلب',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_back_rounded, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedEmployeeChip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                _selectedEmployee!.code,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedEmployee!.fullNameAr,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_selectedEmployee!.department != null)
                  Text(
                    _selectedEmployee!.department!,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.success, size: 22),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Confirmation Step
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildConfirmation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.warning, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'يرجى مراجعة البيانات قبل تأكيد الطلب',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Summary Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _ConfirmRow(
                    label: 'الموظف',
                    value:
                        '${_selectedEmployee!.fullNameAr} (${_selectedEmployee!.code})'),
                const Divider(height: 1),
                _ConfirmRow(
                    label: 'نوع الإجازة',
                    value: _selectedLeaveType!.nameAr),
                const Divider(height: 1),
                _ConfirmRow(
                    label: 'من',
                    value: _formatDate(_startDate)),
                const Divider(height: 1),
                _ConfirmRow(
                    label: 'إلى',
                    value: _formatDate(_endDate)),
                const Divider(height: 1),
                _ConfirmRow(
                    label: 'إجمالي الأيام',
                    value: '$_totalLeaveDays يوم',
                    highlight: true),
                if (_leaveReasonController.text.trim().isNotEmpty) ...[
                  const Divider(height: 1),
                  _ConfirmRow(
                      label: 'سبب الإجازة',
                      value: _leaveReasonController.text.trim()),
                ],
                if (_emergencyPhoneController.text.trim().isNotEmpty) ...[
                  const Divider(height: 1),
                  _ConfirmRow(
                      label: 'هاتف الطوارئ',
                      value: _emergencyPhoneController.text.trim()),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Notes field (in confirmation step)
          _SectionHeader(
              title: 'ملاحظات إضافية (اختياري)',
              icon: Icons.notes_rounded),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            style: GoogleFonts.cairo(fontSize: 14),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'أدخل ملاحظات إضافية...',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 28),

          // Actions
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() => _isConfirmationStep = false),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text('رجوع',
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.success.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'تأكيد الطلب',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Reusable Widgets
// ═══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 18, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  Text(
                    value.isEmpty ? '-- / -- / ----' : value,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: value.isEmpty
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _ConfirmRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
