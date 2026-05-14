import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_provider.dart';

import 'leaves_repository.dart';
import 'models/leave_request_model.dart';

/// Provides a singleton [LeavesRepository].
final leavesRepositoryProvider = Provider<LeavesRepository>((ref) {
  return LeavesRepository();
});

// ═══════════════════════════════════════════════════════════════════════════
//  Leave Requests List State
// ═══════════════════════════════════════════════════════════════════════════

class LeaveRequestsListState {
  final List<LeaveRequest> requests;
  final bool isLoading;
  final String? searchCode;
  final String? errorMessage;
  final LeavesPaginationInfo? pagination;

  const LeaveRequestsListState({
    this.requests = const [],
    this.isLoading = false,
    this.searchCode,
    this.errorMessage,
    this.pagination,
  });

  LeaveRequestsListState copyWith({
    List<LeaveRequest>? requests,
    bool? isLoading,
    String? searchCode,
    String? errorMessage,
    LeavesPaginationInfo? pagination,
    bool clearError = false,
    bool clearSearch = false,
  }) {
    return LeaveRequestsListState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      searchCode: clearSearch ? null : (searchCode ?? this.searchCode),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pagination: pagination ?? this.pagination,
    );
  }
}

class LeaveRequestsListNotifier
    extends StateNotifier<LeaveRequestsListState> {
  final LeavesRepository _repo;
  final AuthState _authState;

  LeaveRequestsListNotifier(this._repo, this._authState)
      : super(const LeaveRequestsListState());

  /// Load all leave requests (no filter), but use managerId if applicable.
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSearch: true);
    try {
      final managerId = _authState.user?.employeeId;
      final response = await _repo.getLeaveRequests(managerId: managerId);
      state = state.copyWith(
        requests: response.data,
        pagination: response.pagination,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Search by employee code.
  Future<void> searchByCode(String code) async {
    if (code.isEmpty) {
      loadAll();
      return;
    }
    state = state.copyWith(
      isLoading: true,
      searchCode: code,
      clearError: true,
    );
    try {
      final response = await _repo.getLeaveRequests(employeeCode: code);
      state = state.copyWith(
        requests: response.data,
        pagination: response.pagination,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load leave requests for a specific employee (by code).
  Future<void> loadForEmployee(String employeeCode) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      searchCode: employeeCode,
    );
    try {
      final response =
          await _repo.getLeaveRequests(employeeCode: employeeCode);
      state = state.copyWith(
        requests: response.data,
        pagination: response.pagination,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void clearSearch() => loadAll();
}

final leaveRequestsListProvider = StateNotifierProvider<
    LeaveRequestsListNotifier, LeaveRequestsListState>((ref) {
  return LeaveRequestsListNotifier(
      ref.read(leavesRepositoryProvider), ref.read(authStateProvider));
});

// ═══════════════════════════════════════════════════════════════════════════
//  Leave Types
// ═══════════════════════════════════════════════════════════════════════════

final leaveTypesProvider = FutureProvider<List<LeaveType>>((ref) async {
  final repo = ref.read(leavesRepositoryProvider);
  return repo.getLeaveTypes();
});

// ═══════════════════════════════════════════════════════════════════════════
//  Employee-specific Leave Requests (used in employee details)
// ═══════════════════════════════════════════════════════════════════════════

class EmployeeLeaveRequestsState {
  final List<LeaveRequest> requests;
  final bool isLoading;
  final String? errorMessage;

  const EmployeeLeaveRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  EmployeeLeaveRequestsState copyWith({
    List<LeaveRequest>? requests,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EmployeeLeaveRequestsState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class EmployeeLeaveRequestsNotifier
    extends StateNotifier<EmployeeLeaveRequestsState> {
  final LeavesRepository _repo;

  EmployeeLeaveRequestsNotifier(this._repo)
      : super(const EmployeeLeaveRequestsState());

  Future<void> load(String employeeCode) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response =
          await _repo.getLeaveRequests(employeeCode: employeeCode);
      state = state.copyWith(
        requests: response.data,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final employeeLeaveRequestsProvider = StateNotifierProvider<
    EmployeeLeaveRequestsNotifier, EmployeeLeaveRequestsState>((ref) {
  return EmployeeLeaveRequestsNotifier(ref.read(leavesRepositoryProvider));
});
