import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/group.dart';

/// Model representing a recorded settlement for audit and persistence.
class SettlementRecord {
  final String id;
  final String fromName;
  final String toName;
  final double amount;
  final DateTime settledAt;
  final String paymentMethod;
  final bool isSettled;

  SettlementRecord({
    required this.id,
    required this.fromName,
    required this.toName,
    required this.amount,
    required this.settledAt,
    this.paymentMethod = 'UPI',
    this.isSettled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromName': fromName,
        'toName': toName,
        'amount': amount,
        'settledAt': settledAt.toIso8601String(),
        'paymentMethod': paymentMethod,
        'isSettled': isSettled,
      };

  factory SettlementRecord.fromJson(Map<String, dynamic> json) =>
      SettlementRecord(
        id: json['id'] as String,
        fromName: json['fromName'] as String? ?? '',
        toName: json['toName'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        settledAt: json['settledAt'] != null
            ? DateTime.tryParse(json['settledAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        paymentMethod: json['paymentMethod'] as String? ?? 'UPI',
        isSettled: json['isSettled'] as bool? ?? true,
      );
}

/// Service to persistently store and retrieve settlement statuses.
/// Once marked as paid, settlement state is saved permanently in local storage.
class SettlementStorageService {
  static const String _settledIdsKey = 'splitico_settled_tx_ids';
  static const String _settledMembersKey = 'splitico_settled_members';
  static const String _settledRecordsKey = 'splitico_settled_records';

  static final ValueNotifier<Set<String>> settledIdsNotifier =
      ValueNotifier<Set<String>>({});

  static Set<String> _cachedIds = {};
  static Set<String> _cachedMembers = {};
  static List<SettlementRecord> _cachedRecords = [];
  static bool _isLoaded = false;

  /// Ensures cache is loaded from SharedPreferences
  static Future<void> init() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList(_settledIdsKey) ?? [];
      _cachedIds = savedList.toSet();

      final savedMembers = prefs.getStringList(_settledMembersKey) ?? [];
      _cachedMembers = savedMembers.toSet();

      final savedRecords = prefs.getStringList(_settledRecordsKey) ?? [];
      _cachedRecords = savedRecords
          .map((r) {
            try {
              return SettlementRecord.fromJson(jsonDecode(r));
            } catch (_) {
              return null;
            }
          })
          .whereType<SettlementRecord>()
          .toList();

      _isLoaded = true;
      settledIdsNotifier.value = Set.from(_cachedIds);
    } catch (e) {
      debugPrint('SettlementStorageService: error initializing - $e');
    }
  }

  static String _normalize(String str) => str.trim().toLowerCase();

  static String _buildMemberKey(String user1, String user2) {
    final u1 = _normalize(user1);
    final u2 = _normalize(user2);
    // Sort alphabetically so the key is symmetric or directional
    return '${u1}__$u2';
  }

  /// Returns all currently settled transaction IDs
  static Future<Set<String>> getSettledIds() async {
    await init();
    return Set.from(_cachedIds);
  }

  /// Synchronously checks if a transaction ID is settled (if cache loaded)
  static bool isSettledSync(String id) {
    return _cachedIds.contains(id);
  }

  /// Asynchronously checks if a transaction ID is settled
  static Future<bool> isSettled(String id) async {
    await init();
    return _cachedIds.contains(id);
  }

  /// Returns the net settlement amount paid between two users.
  /// Positive if user1 paid user2, negative if user2 paid user1.
  static double getNetSettledAmount(String user1, String user2) {
    final u1 = _normalize(user1);
    final u2 = _normalize(user2);
    double total = 0.0;
    for (var r in _cachedRecords) {
      if (!r.isSettled) continue;
      final from = _normalize(r.fromName);
      final to = _normalize(r.toName);
      if (from == u1 && to == u2) {
        total += r.amount;
      } else if (from == u2 && to == u1) {
        total -= r.amount;
      }
    }
    return total;
  }

  /// Returns all settlement records between user1 and user2
  static List<SettlementRecord> getSettlementRecordsBetween(
    String user1,
    String user2,
  ) {
    final u1 = _normalize(user1);
    final u2 = _normalize(user2);
    return _cachedRecords.where((r) {
      if (!r.isSettled) return false;
      final from = _normalize(r.fromName);
      final to = _normalize(r.toName);
      return (from == u1 && to == u2) || (from == u2 && to == u1);
    }).toList();
  }

  /// Marks a specific transaction ID as paid/settled forever
  static Future<void> markSettled(
    String id, {
    bool settled = true,
    String? fromName,
    String? toName,
    double? amount,
    String? method,
  }) async {
    await init();
    final prefs = await SharedPreferences.getInstance();

    if (settled) {
      _cachedIds.add(id);
      if (fromName != null && toName != null) {
        _cachedMembers.add(_buildMemberKey(fromName, toName));
      }
    } else {
      _cachedIds.remove(id);
      if (fromName != null && toName != null) {
        _cachedMembers.remove(_buildMemberKey(fromName, toName));
      }
    }

    await prefs.setStringList(_settledIdsKey, _cachedIds.toList());
    await prefs.setStringList(_settledMembersKey, _cachedMembers.toList());

    // Update recorded history audit
    if (fromName != null && toName != null) {
      try {
        final recordsJson = prefs.getStringList(_settledRecordsKey) ?? [];
        final newRecord = SettlementRecord(
          id: id,
          fromName: fromName,
          toName: toName,
          amount: amount ?? 0.0,
          settledAt: DateTime.now(),
          paymentMethod: method ?? 'UPI',
          isSettled: settled,
        );

        // Remove previous entry with same id if any, then append
        recordsJson.removeWhere((r) {
          try {
            final decoded = jsonDecode(r) as Map<String, dynamic>;
            return decoded['id'] == id;
          } catch (_) {
            return false;
          }
        });
        _cachedRecords.removeWhere((r) => r.id == id);

        if (settled) {
          recordsJson.add(jsonEncode(newRecord.toJson()));
          _cachedRecords.add(newRecord);
        }

        await prefs.setStringList(_settledRecordsKey, recordsJson);
      } catch (e) {
        debugPrint('SettlementStorageService: error saving record - $e');
      }
    }

    settledIdsNotifier.value = Set.from(_cachedIds);
  }

  /// Unmarks/removes the latest settlement between user1 and user2
  static Future<void> unmarkLatestSettlement(
    String user1,
    String user2,
  ) async {
    await init();
    final u1 = _normalize(user1);
    final u2 = _normalize(user2);
    final prefs = await SharedPreferences.getInstance();

    final recordsJson = prefs.getStringList(_settledRecordsKey) ?? [];
    int? indexToRemove;
    for (int i = recordsJson.length - 1; i >= 0; i--) {
      try {
        final decoded = jsonDecode(recordsJson[i]) as Map<String, dynamic>;
        final from = _normalize(decoded['fromName'] ?? '');
        final to = _normalize(decoded['toName'] ?? '');
        if ((from == u1 && to == u2) || (from == u2 && to == u1)) {
          indexToRemove = i;
          break;
        }
      } catch (_) {}
    }

    if (indexToRemove != null) {
      recordsJson.removeAt(indexToRemove);
      await prefs.setStringList(_settledRecordsKey, recordsJson);
      _cachedRecords = recordsJson
          .map((r) {
            try {
              return SettlementRecord.fromJson(jsonDecode(r));
            } catch (_) {
              return null;
            }
          })
          .whereType<SettlementRecord>()
          .toList();
    }
  }

  /// Checks if a 1-on-1 settlement between user and member is marked as settled
  static Future<bool> isMemberSettled({
    required String currentUserName,
    required String memberName,
  }) async {
    await init();
    final key = _buildMemberKey(currentUserName, memberName);
    final reverseKey = _buildMemberKey(memberName, currentUserName);
    return _cachedMembers.contains(key) || _cachedMembers.contains(reverseKey);
  }

  /// Synchronous version of isMemberSettled
  static bool isMemberSettledSync({
    required String currentUserName,
    required String memberName,
  }) {
    final key = _buildMemberKey(currentUserName, memberName);
    final reverseKey = _buildMemberKey(memberName, currentUserName);
    return _cachedMembers.contains(key) || _cachedMembers.contains(reverseKey);
  }

  /// Marks a member-to-member settlement as paid
  static Future<void> markMemberSettled({
    required String currentUserName,
    required String memberName,
    bool isSettled = true,
    double? amount,
    String? method,
    bool isOwed = false,
  }) async {
    await init();
    final payer = isOwed ? memberName : currentUserName;
    final payee = isOwed ? currentUserName : memberName;
    final key = _buildMemberKey(payer, payee);
    final prefs = await SharedPreferences.getInstance();

    if (isSettled) {
      _cachedMembers.add(key);
    } else {
      _cachedMembers.remove(key);
      _cachedMembers.remove(_buildMemberKey(payee, payer));
    }

    await prefs.setStringList(_settledMembersKey, _cachedMembers.toList());

    if (!isSettled) {
      await unmarkLatestSettlement(payer, payee);
    } else {
      final synthId =
          'member_${_normalize(payer)}_${_normalize(payee)}_${DateTime.now().millisecondsSinceEpoch}';
      await markSettled(
        synthId,
        settled: true,
        fromName: payer,
        toName: payee,
        amount: amount,
        method: method,
      );
    }
  }

  /// When a new expense is added or modified in a group, unmark any previous settlement
  /// between the members so the group and balances become active again.
  static Future<void> unmarkGroupSettled(
    GroupModel group, [
    String? currentUserName,
  ]) async {
    await init();
    final prefs = await SharedPreferences.getInstance();

    final List<String> names = [];
    for (var m in group.members) {
      final name = _normalize(m['name'] as String? ?? '');
      if (name.isNotEmpty) {
        names.add(name);
        if (name == 'you' && currentUserName != null && currentUserName.isNotEmpty) {
          names.add(_normalize(currentUserName));
        }
      }
    }
    if (currentUserName != null && currentUserName.isNotEmpty) {
      names.add(_normalize(currentUserName));
    }

    for (int i = 0; i < names.length; i++) {
      for (int j = 0; j < names.length; j++) {
        if (i != j) {
          final m1 = names[i];
          final m2 = names[j];
          _cachedMembers.remove(_buildMemberKey(m1, m2));
          _cachedMembers.remove(_buildMemberKey(m2, m1));

          _cachedIds.removeWhere((id) =>
              id.contains('${m1}_$m2') ||
              id.contains('${m2}_$m1') ||
              id.startsWith('member_${m1}_$m2') ||
              id.startsWith('member_${m2}_$m1'));
        }
      }
    }

    await prefs.setStringList(_settledMembersKey, _cachedMembers.toList());
    await prefs.setStringList(_settledIdsKey, _cachedIds.toList());

    settledIdsNotifier.value = Set.from(_cachedIds);
  }

  /// Checks if all expenses and debts in a group have been completely settled
  static bool isGroupSettled(GroupModel group, String currentUserName) {
    if (group.expenses.isEmpty) {
      return false; // Groups without expenses are considered active (new)
    }

    final normCurrent = _normalize(currentUserName);
    final Map<String, double> netBalances = {};

    for (var expense in group.expenses) {
      final splitMembers =
          expense.splitBetween.where((m) => m['selected'] == true).toList();
      if (splitMembers.isEmpty) continue;
      final individualShare = expense.amount / splitMembers.length;
      final payer = _normalize(
        expense.paidBy.toLowerCase() == 'you'
            ? normCurrent
            : expense.paidBy,
      );

      for (var splitMember in splitMembers) {
        final rawName = splitMember['name'] as String;
        final memberName = _normalize(
          rawName.toLowerCase() == 'you' ? normCurrent : rawName,
        );
        if (memberName != payer) {
          netBalances[payer] = (netBalances[payer] ?? 0.0) + individualShare;
          netBalances[memberName] =
              (netBalances[memberName] ?? 0.0) - individualShare;
        }
      }
    }

    // Adjust netBalances with recorded settlements between members
    final names = netBalances.keys.toList();
    for (int i = 0; i < names.length; i++) {
      for (int j = i + 1; j < names.length; j++) {
        final p1 = names[i];
        final p2 = names[j];
        final settled = getNetSettledAmount(p1, p2);
        if (settled != 0) {
          netBalances[p1] = (netBalances[p1] ?? 0.0) + settled;
          netBalances[p2] = (netBalances[p2] ?? 0.0) - settled;
        }
      }
    }

    final List<MapEntry<String, double>> debtors = [];
    final List<MapEntry<String, double>> creditors = [];

    netBalances.forEach((person, balance) {
      if (balance < -0.01) {
        debtors.add(MapEntry(person, -balance));
      } else if (balance > 0.01) {
        creditors.add(MapEntry(person, balance));
      }
    });

    if (debtors.isEmpty && creditors.isEmpty) {
      return true;
    }

    debtors.sort((a, b) => b.value.compareTo(a.value));
    creditors.sort((a, b) => b.value.compareTo(a.value));

    int dIndex = 0;
    int cIndex = 0;
    List<double> dBalances = debtors.map((e) => e.value).toList();
    List<double> cBalances = creditors.map((e) => e.value).toList();

    int totalTransactions = 0;
    int settledTransactions = 0;

    while (dIndex < debtors.length && cIndex < creditors.length) {
      final debtor = debtors[dIndex].key;
      final creditor = creditors[cIndex].key;
      final dAmount = dBalances[dIndex];
      final cAmount = cBalances[cIndex];
      final settledAmount = (dAmount < cAmount ? dAmount : cAmount);

      if (settledAmount > 0.01) {
        totalTransactions++;
        final txId = '${debtor}_${creditor}_${settledAmount.toStringAsFixed(2)}';
        if (_cachedIds.contains(txId) ||
            _cachedMembers.contains('${debtor}__$creditor') ||
            _cachedMembers.contains('${creditor}__$debtor')) {
          settledTransactions++;
        }
      }

      dBalances[dIndex] -= settledAmount;
      cBalances[cIndex] -= settledAmount;

      if (dBalances[dIndex] <= 0.01) dIndex++;
      if (cBalances[cIndex] <= 0.01) cIndex++;
    }

    return totalTransactions > 0 && settledTransactions >= totalTransactions;
  }

  /// Calculates user net balance for a specific group
  static double calculateGroupUserBalance(
    GroupModel group,
    String currentUserName,
  ) {
    if (isGroupSettled(group, currentUserName)) return 0.0;

    final normCurrent = _normalize(currentUserName);
    double totalOwedToYou = 0.0;
    double totalYouOwe = 0.0;

    for (var expense in group.expenses) {
      final splitMembers =
          expense.splitBetween.where((m) => m['selected'] == true).toList();
      if (splitMembers.isEmpty) continue;
      final individualShare = expense.amount / splitMembers.length;
      final payer = _normalize(
        expense.paidBy.toLowerCase() == 'you'
            ? normCurrent
            : expense.paidBy,
      );
      final isPaidByMe = payer == normCurrent;

      if (isPaidByMe) {
        for (var splitMember in splitMembers) {
          final rawName = splitMember['name'] as String;
          final memberName = _normalize(
            rawName.toLowerCase() == 'you' ? normCurrent : rawName,
          );
          if (memberName != normCurrent) {
            totalOwedToYou += individualShare;
          }
        }
      } else {
        final amIInSplit = splitMembers.any((m) {
          final rawName = m['name'] as String;
          return _normalize(
                rawName.toLowerCase() == 'you' ? normCurrent : rawName,
              ) ==
              normCurrent;
        });
        if (amIInSplit) {
          totalYouOwe += individualShare;
        }
      }
    }

    double balance = totalOwedToYou - totalYouOwe;
    for (var m in group.members) {
      final mName = _normalize(m['name'] as String? ?? '');
      if (mName.isNotEmpty && mName != normCurrent && mName != 'you') {
        balance += getNetSettledAmount(normCurrent, mName);
      }
    }
    return balance;
  }

  /// Clear all stored settlements
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settledIdsKey);
    await prefs.remove(_settledMembersKey);
    await prefs.remove(_settledRecordsKey);
    _cachedIds.clear();
    _cachedMembers.clear();
    settledIdsNotifier.value = {};
  }
}
