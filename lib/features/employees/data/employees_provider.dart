import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/storage_keys.dart';
import 'employees_repository.dart';
import 'models/employee_model.dart';

/// Provides a singleton [EmployeesRepository].
final employeesRepositoryProvider = Provider<EmployeesRepository>((ref) {
  return EmployeesRepository();
});

/// State for the employees list with pagination.
class EmployeesListState {
  final List<Employee> employees;
  final PaginationInfo? pagination;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSearching;
  final String? searchCode;
  final String? errorMessage;
  final int currentPage;

  const EmployeesListState({
    this.employees = const [],
    this.pagination,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSearching = false,
    this.searchCode,
    this.errorMessage,
    this.currentPage = 1,
  });

  EmployeesListState copyWith({
    List<Employee>? employees,
    PaginationInfo? pagination,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSearching,
    String? searchCode,
    String? errorMessage,
    int? currentPage,
    bool clearError = false,
    bool clearSearch = false,
  }) {
    return EmployeesListState(
      employees: employees ?? this.employees,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSearching: isSearching ?? this.isSearching,
      searchCode: clearSearch ? null : (searchCode ?? this.searchCode),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentPage: currentPage ?? this.currentPage,
    );
  }

  bool get hasMore =>
      pagination != null && currentPage < pagination!.totalPages;
}

/// StateNotifier for managing the employees list.
class EmployeesListNotifier extends StateNotifier<EmployeesListState> {
  final EmployeesRepository _repo;

  EmployeesListNotifier(this._repo) : super(const EmployeesListState());

  /// Loads the first page of employees.
  Future<void> loadEmployees() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSearch: true,
    );
    try {
      final response = await _repo.getEmployees(pageNumber: 1);
      state = state.copyWith(
        employees: response.employees,
        pagination: response.pagination,
        isLoading: false,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Loads the next page (appends to existing list).
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;

    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _repo.getEmployees(pageNumber: nextPage);
      state = state.copyWith(
        employees: [...state.employees, ...response.employees],
        pagination: response.pagination,
        isLoadingMore: false,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Searches by employee code.
  Future<void> searchByCode(String code) async {
    if (code.isEmpty) {
      loadEmployees();
      return;
    }

    state = state.copyWith(
      isSearching: true,
      isLoading: true,
      searchCode: code,
      clearError: true,
    );

    try {
      final response = await _repo.searchByCode(code);
      state = state.copyWith(
        employees: response.employees,
        pagination: response.pagination,
        isLoading: false,
        isSearching: false,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSearching: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Clears search and reloads all employees.
  Future<void> clearSearch() async {
    state = state.copyWith(clearSearch: true);
    await loadEmployees();
  }
}

/// Provides the employees list state notifier.
final employeesListProvider =
    StateNotifierProvider.autoDispose<EmployeesListNotifier, EmployeesListState>((ref) {
  return EmployeesListNotifier(ref.read(employeesRepositoryProvider));
});

// ─────────────────────────────────────────────────────────────────────────────
//  Subordinates (manager's team)
// ─────────────────────────────────────────────────────────────────────────────

class SubordinatesState {
  final List<Employee> employees;
  final PaginationInfo? pagination;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String? checkDate;
  final String? statusFilter; // 'ALL', 'LEAVE', 'ABSENT', 'PRESENT_COMPLETE', 'PRESENT_NO_OUT', 'NOT_PRESENT'

  const SubordinatesState({
    this.employees = const [],
    this.pagination,
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.checkDate,
    this.statusFilter = 'ALL',
  });

  SubordinatesState copyWith({
    List<Employee>? employees,
    PaginationInfo? pagination,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? checkDate,
    String? statusFilter,
    bool clearError = false,
  }) {
    return SubordinatesState(
      employees: employees ?? this.employees,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      checkDate: checkDate ?? this.checkDate,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  List<Employee> get filtered {
    var result = employees;

    // Apply status filter
    if (statusFilter != null && statusFilter != 'ALL') {
      if (statusFilter == 'PRESENT') {
        result = result.where((e) =>
            e.attendanceStatus == 'PRESENT' ||
            e.attendanceStatus == 'PRESENT_COMPLETE' ||
            e.attendanceStatus == 'PRESENT_NO_OUT').toList();
      } else {
        result = result.where((e) => e.attendanceStatus == statusFilter).toList();
      }
    }

    // Apply search query
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((e) =>
          e.code.contains(q) ||
          e.fullNameAr.toLowerCase().contains(q)).toList();
    }
    return result;
  }
}

class SubordinatesNotifier extends StateNotifier<SubordinatesState> {
  final EmployeesRepository _repo;

  SubordinatesNotifier(this._repo) : super(const SubordinatesState());

  Future<void> load({String? checkDate}) async {
    if (checkDate != null) {
      state = state.copyWith(checkDate: checkDate);
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      const storage = FlutterSecureStorage();
      final idStr = await storage.read(key: StorageKeys.userEmployeeId);
      final managerId = int.tryParse(idStr ?? '');
      if (managerId == null) {
        state = state.copyWith(
            isLoading: false, errorMessage: 'لم يتم العثور على بيانات المدير');
        return;
      }
      final response = await _repo.getSubordinates(
        managerId: managerId,
        checkDate: state.checkDate,
      );
      state = state.copyWith(
        isLoading: false,
        employees: response.employees,
        pagination: response.pagination,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
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

final subordinatesProvider =
    StateNotifierProvider.autoDispose<SubordinatesNotifier, SubordinatesState>((ref) {
  return SubordinatesNotifier(ref.read(employeesRepositoryProvider));
});
