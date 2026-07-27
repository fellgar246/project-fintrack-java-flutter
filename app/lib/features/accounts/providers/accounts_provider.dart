import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/accounts_api.dart';
import '../data/models/account_model.dart';

class AccountsFilter {
  const AccountsFilter({this.includeArchived = false});

  final bool includeArchived;

  AccountsFilter copyWith({bool? includeArchived}) {
    return AccountsFilter(includeArchived: includeArchived ?? this.includeArchived);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountsFilter && includeArchived == other.includeArchived;

  @override
  int get hashCode => includeArchived.hashCode;
}

final accountsFilterProvider = StateProvider<AccountsFilter>((ref) => const AccountsFilter());

class AccountsController extends AsyncNotifier<List<AccountModel>> {
  @override
  Future<List<AccountModel>> build() async {
    final filter = ref.watch(accountsFilterProvider);
    return ref.read(accountsApiProvider).list(includeArchived: filter.includeArchived);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final filter = ref.read(accountsFilterProvider);
      return ref.read(accountsApiProvider).list(includeArchived: filter.includeArchived);
    });
  }

  Future<void> create({
    required String name,
    required AccountType type,
    required String initialBalance,
  }) async {
    await ref.read(accountsApiProvider).create(
          name: name,
          type: type,
          initialBalance: initialBalance,
        );
    ref.invalidateSelf();
  }

  Future<void> updateAccount({
    required String id,
    required String name,
    required AccountType type,
    required String initialBalance,
  }) async {
    await ref.read(accountsApiProvider).update(
          id: id,
          name: name,
          type: type,
          initialBalance: initialBalance,
        );
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await ref.read(accountsApiProvider).delete(id);
    ref.invalidateSelf();
  }
}

final accountsControllerProvider =
    AsyncNotifierProvider<AccountsController, List<AccountModel>>(AccountsController.new);
