import 'dart:convert';

class PrizeSplit {
  final int place;
  final double percent;
  final double amount;

  const PrizeSplit({
    required this.place,
    required this.percent,
    required this.amount,
  });

  factory PrizeSplit.fromJson(Map<String, dynamic> json) {
    return PrizeSplit(
      place: (json['place'] as num?)?.toInt() ?? 1,
      percent: (json['percent'] as num?)?.toDouble() ?? 0.0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TournamentModel {
  final String id;
  final String title;
  final String gameId;
  final String mode; // 'Solo', 'Duo', 'Squad'
  final String region;
  final String banner;
  final String description;
  final double entryFee;
  final double prizePool;
  final List<PrizeSplit> prizeSplit;
  final int maxSlots;
  final int registeredCount;
  final DateTime startsAt;
  final DateTime registrationClosesAt;
  final DateTime? checkInOpensAt;
  final DateTime roomReleaseAt;
  final String status; // 'Registration Open', 'Check-in', 'Live', 'Completed', 'Cancelled'
  final String rules;
  final String? roomId;
  final String? roomPassword;
  final bool isUserRegistered;

  const TournamentModel({
    required this.id,
    required this.title,
    required this.gameId,
    required this.mode,
    required this.region,
    required this.banner,
    required this.description,
    required this.entryFee,
    required this.prizePool,
    required this.prizeSplit,
    required this.maxSlots,
    this.registeredCount = 0,
    required this.startsAt,
    required this.registrationClosesAt,
    this.checkInOpensAt,
    required this.roomReleaseAt,
    required this.status,
    required this.rules,
    this.roomId,
    this.roomPassword,
    this.isUserRegistered = false,
  });

  bool get isFull => registeredCount >= maxSlots;
  bool get canRegister => status == 'Registration Open' && !isFull && !isUserRegistered;
  bool get isLive => status == 'Live';
  bool get isCompleted => status == 'Completed';

  bool get isRoomReleased =>
      DateTime.now().isAfter(roomReleaseAt) || status == 'Live' || status == 'Check-in';

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    List<PrizeSplit> splits = [];
    if (json['prize_split'] != null) {
      dynamic rawSplit = json['prize_split'];
      if (rawSplit is String) {
        try {
          rawSplit = jsonDecode(rawSplit);
        } catch (_) {
          rawSplit = [];
        }
      }
      if (rawSplit is List) {
        splits = rawSplit.map((s) => PrizeSplit.fromJson(s as Map<String, dynamic>)).toList();
      }
    }

    return TournamentModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      gameId: json['game_id'] ?? '',
      mode: json['mode'] ?? 'Solo',
      region: json['region'] ?? 'South Asia',
      banner: json['banner'] ?? '',
      description: json['description'] ?? '',
      entryFee: (json['entry_fee'] as num?)?.toDouble() ?? 0.0,
      prizePool: (json['prize_pool'] as num?)?.toDouble() ?? 0.0,
      prizeSplit: splits,
      maxSlots: (json['max_slots'] as num?)?.toInt() ?? 48,
      registeredCount: (json['registered_count'] as num?)?.toInt() ?? (json['current_participants'] as num?)?.toInt() ?? 0,
      startsAt: DateTime.tryParse(json['starts_at'] ?? '') ?? DateTime.now().add(const Duration(hours: 3)),
      registrationClosesAt: DateTime.tryParse(json['registration_closes_at'] ?? '') ?? DateTime.now().add(const Duration(hours: 2)),
      checkInOpensAt: json['check_in_opens_at'] != null ? DateTime.tryParse(json['check_in_opens_at']) : null,
      roomReleaseAt: DateTime.tryParse(json['room_release_at'] ?? '') ?? DateTime.now().add(const Duration(hours: 2, minutes: 45)),
      status: json['status'] ?? 'Registration Open',
      rules: json['rules'] ?? '',
      roomId: json['room_id'],
      roomPassword: json['room_password'],
      isUserRegistered: json['is_registered'] == true || json['user_registered'] == 1,
    );
  }
}

class RegisteredMatchModel {
  final String registrationId;
  final String tournamentId;
  final String tournamentTitle;
  final String gameId;
  final String mode;
  final String banner;
  final String status; // 'CONFIRMED', 'CANCELLED', 'CHECKED_IN'
  final String receiptNumber;
  final DateTime registeredAt;
  final DateTime matchStartsAt;
  final DateTime roomReleaseAt;
  final double entryFee;
  final double prizePool;
  final String? roomId;
  final String? roomPassword;
  final bool roomDecrypted;

  const RegisteredMatchModel({
    required this.registrationId,
    required this.tournamentId,
    required this.tournamentTitle,
    required this.gameId,
    required this.mode,
    required this.banner,
    required this.status,
    required this.receiptNumber,
    required this.registeredAt,
    required this.matchStartsAt,
    required this.roomReleaseAt,
    required this.entryFee,
    required this.prizePool,
    this.roomId,
    this.roomPassword,
    this.roomDecrypted = false,
  });

  bool get canCancel => status == 'CONFIRMED' && DateTime.now().isBefore(roomReleaseAt);

  factory RegisteredMatchModel.fromJson(Map<String, dynamic> json) {
    return RegisteredMatchModel(
      registrationId: json['registration_id'] ?? json['id'] ?? '',
      tournamentId: json['tournament_id'] ?? '',
      tournamentTitle: json['title'] ?? json['tournament_title'] ?? 'Tournament',
      gameId: json['game_id'] ?? '',
      mode: json['mode'] ?? 'Solo',
      banner: json['banner'] ?? '',
      status: json['status'] ?? 'CONFIRMED',
      receiptNumber: json['receipt_number'] ?? '',
      registeredAt: DateTime.tryParse(json['registered_at'] ?? '') ?? DateTime.now(),
      matchStartsAt: DateTime.tryParse(json['starts_at'] ?? '') ?? DateTime.now().add(const Duration(hours: 2)),
      roomReleaseAt: DateTime.tryParse(json['room_release_at'] ?? '') ?? DateTime.now().add(const Duration(hours: 1)),
      entryFee: (json['entry_fee'] as num?)?.toDouble() ?? 0.0,
      prizePool: (json['prize_pool'] as num?)?.toDouble() ?? 0.0,
      roomId: json['room_id'],
      roomPassword: json['room_password'],
      roomDecrypted: json['room_id'] != null && json['room_id'] != 'MASKED_UNTIL_RELEASE',
    );
  }
}
