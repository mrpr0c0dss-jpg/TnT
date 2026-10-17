class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String? phone;
  final String role; // 'player', 'super_admin', 'tournament_manager', 'topup_operator', 'finance_reviewer', 'support'
  final String status; // 'active', 'banned', 'suspended'
  final String avatar;
  final String? banReason;

  const UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.phone,
    required this.role,
    this.status = 'active',
    required this.avatar,
    this.banReason,
  });

  bool get isAdmin => role == 'super_admin';
  bool get isStaff => role != 'player';
  bool get canManageTournaments => role == 'super_admin' || role == 'tournament_manager';
  bool get canManageTopups => role == 'super_admin' || role == 'topup_operator';
  bool get canReviewFinance => role == 'super_admin' || role == 'finance_reviewer';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      displayName: json['display_name'] ?? json['name'] ?? 'Gamer',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'player',
      status: json['status'] ?? 'active',
      avatar: json['avatar'] ?? 'https://api.dicebear.com/7.x/bottts/svg?seed=${json['id'] ?? 'user'}',
      banReason: json['ban_reason'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'email': email,
    'phone': phone,
    'role': role,
    'status': status,
    'avatar': avatar,
    'ban_reason': banReason,
  };
}
