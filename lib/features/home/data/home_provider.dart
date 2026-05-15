import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/storage_keys.dart';
import 'home_repository.dart';
import 'models/pending_approval_model.dart';

/// Provides a singleton [HomeRepository].
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository();
});

// ═══════════════════════════════════════════════════════════════════════════
//  Pending Approvals State
// ═══════════════════════════════════════════════════════════════════════════

class PendingApprovalsState {
  final List<PendingApproval> approvals;
  final bool isLoading;
  final String? errorMessage;
  final int totalRecords;

  const PendingApprovalsState({
    this.approvals = const [],
    this.isLoading = false,
    this.errorMessage,
    this.totalRecords = 0,
  });

  PendingApprovalsState copyWith({
    List<PendingApproval>? approvals,
    bool? isLoading,
    String? errorMessage,
    int? totalRecords,
    bool clearError = false,
  }) {
    return PendingApprovalsState(
      approvals: approvals ?? this.approvals,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      totalRecords: totalRecords ?? this.totalRecords,
    );
  }
}

class PendingApprovalsNotifier extends StateNotifier<PendingApprovalsState> {
  final HomeRepository _repo;

  PendingApprovalsNotifier(this._repo) : super(const PendingApprovalsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      const storage = FlutterSecureStorage();
      final idStr = await storage.read(key: StorageKeys.userEmployeeId);
      final managerId = int.tryParse(idStr ?? '');

      if (managerId == null) {
        state = state.copyWith(
          isLoading: false,
          approvals: [],
          totalRecords: 0,
        );
        return;
      }

      final response = await _repo.getPendingApprovals(managerId: managerId);
      state = state.copyWith(
        isLoading: false,
        approvals: response.data,
        totalRecords: response.totalRecords,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final pendingApprovalsProvider =
    StateNotifierProvider<PendingApprovalsNotifier, PendingApprovalsState>(
        (ref) {
  return PendingApprovalsNotifier(ref.read(homeRepositoryProvider));
});
