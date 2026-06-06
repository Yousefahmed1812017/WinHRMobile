import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/storage_keys.dart';
import 'daily_logs_repository.dart';
import 'models/daily_attendance_model.dart';

class DailyAttendanceState {
  final List<DailyAttendanceRecord> records;
  final bool isLoading;
  final String? errorMessage;
  final DateTime selectedDate;
  final String searchQuery;
  final String statusFilter; // 'ALL', 'PRESENT', 'ABSENT', 'LEAVE', 'OFF_DAYS'

  const DailyAttendanceState({
    this.records = const [],
    this.isLoading = false,
    this.errorMessage,
    required this.selectedDate,
    this.searchQuery = '',
    this.statusFilter = 'ALL',
  });

  DailyAttendanceState copyWith({
    List<DailyAttendanceRecord>? records,
    bool? isLoading,
    String? errorMessage,
    DateTime? selectedDate,
    String? searchQuery,
    String? statusFilter,
    bool clearError = false,
  }) {
    return DailyAttendanceState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedDate: selectedDate ?? this.selectedDate,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  List<DailyAttendanceRecord> get filtered {
    var result = records;

    // Apply status filter
    if (statusFilter != 'ALL') {
      if (statusFilter == 'PRESENT') {
        result = result.where((e) => e.status == 'PRESENT').toList();
      } else if (statusFilter == 'LEAVE') {
        result = result.where((e) => e.status == 'LEAVE').toList();
      } else if (statusFilter == 'ABSENT') {
        result = result.where((e) => e.status == 'ABSENT').toList();
      } else if (statusFilter == 'OFF_DAYS') {
        result = result.where((e) =>
            e.status == 'PUBLIC_HOLIDAY' ||
            e.status == 'WEEKLY_OFF' ||
            e.status == 'COMP_DAY').toList();
      }
    }

    // Apply search query
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((e) =>
          e.code.toLowerCase().contains(q) ||
          e.fullName.toLowerCase().contains(q)).toList();
    }
    return result;
  }
}

class DailyAttendanceNotifier extends StateNotifier<DailyAttendanceState> {
  final DailyLogsRepository _repo;

  DailyAttendanceNotifier(this._repo)
      : super(DailyAttendanceState(selectedDate: DateTime.now()));

  Future<void> load({DateTime? date}) async {
    final targetDate = date ?? state.selectedDate;
    state = state.copyWith(
      selectedDate: targetDate,
      isLoading: true,
      clearError: true,
    );

    try {
      const storage = FlutterSecureStorage();
      final idStr = await storage.read(key: StorageKeys.userEmployeeId);
      final managerId = int.tryParse(idStr ?? '');
      if (managerId == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'لم يتم العثور على بيانات المدير',
        );
        return;
      }

      final dateStr = DateFormat('dd/MM/yyyy').format(targetDate);
      final response = await _repo.getDailyAttendance(
        managerId: managerId,
        checkDate: dateStr,
      );

      state = state.copyWith(
        isLoading: false,
        records: response.data,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void selectDate(DateTime date) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final targetZero = DateTime(date.year, date.month, date.day);
    if (targetZero.isAfter(today)) return; // Disable future dates selection
    load(date: date);
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
  }
}

final dailyLogsRepositoryProvider = Provider<DailyLogsRepository>((ref) {
  return DailyLogsRepository();
});

final dailyAttendanceProvider =
    StateNotifierProvider.autoDispose<DailyAttendanceNotifier, DailyAttendanceState>((ref) {
  final repo = ref.read(dailyLogsRepositoryProvider);
  final notifier = DailyAttendanceNotifier(repo);
  // Auto load upon creation
  Future.microtask(() => notifier.load());
  return notifier;
});
