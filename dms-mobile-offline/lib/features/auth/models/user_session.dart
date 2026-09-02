// ============================================================================
// UserSession - Session info cho Auth & Scoping
// ============================================================================
// Enterprise: Luu user info + scoping (distributor_id, territory_id)
// de thuc thi Data Isolation - Sales Rep chi thay outlet cua NPP/tuyen duoc gan

class UserSession {
  final int userId;
  final String username;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final int distributorId;   // FK NPP - dung cho scoping
  final int territoryId;    // FK Tuyen ban hang - dung cho scoping
  final String role;        // SALES_REP, SUPERVISOR, ASM, ADMIN
  final String? token;
  final DateTime? tokenExpiry;

  const UserSession({
    required this.userId,
    required this.username,
    required this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    required this.distributorId,
    required this.territoryId,
    required this.role,
    this.token,
    this.tokenExpiry,
  });

  /// Kiem tra quyen tao outlet
  bool get canCreateOutlet => role == 'SALES_REP' || role == 'SUPERVISOR';

  /// Kiem tra quyen duyet outlet
  bool get canApproveOutlet => role == 'SUPERVISOR' || role == 'ASM' || role == 'ADMIN';

  /// Lay ma NPP
  int get distributorIdValue => distributorId;

  /// Lay ma Tuyen
  int get territoryIdValue => territoryId;

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userId: json['user_id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      distributorId: json['distributor_id'] as int? ?? 1,
      territoryId: json['territory_id'] as int? ?? 1,
      role: json['role'] as String? ?? 'SALES_REP',
      token: json['token'] as String?,
      tokenExpiry: json['token_expiry'] != null
          ? DateTime.tryParse(json['token_expiry'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'distributor_id': distributorId,
      'territory_id': territoryId,
      'role': role,
      'token': token,
      if (tokenExpiry != null) 'token_expiry': tokenExpiry!.toIso8601String(),
    };
  }

  UserSession copyWith({
    int? userId,
    String? username,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    int? distributorId,
    int? territoryId,
    String? role,
    String? token,
    DateTime? tokenExpiry,
  }) {
    return UserSession(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      distributorId: distributorId ?? this.distributorId,
      territoryId: territoryId ?? this.territoryId,
      role: role ?? this.role,
      token: token ?? this.token,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
    );
  }
}