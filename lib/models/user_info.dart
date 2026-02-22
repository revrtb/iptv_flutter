class UserInfo {
  final String username;
  final String password;
  final String message;
  final int auth;
  final String status;
  final String expDate;
  final String isTrial;
  final String activeCons;
  final String createdAt;
  final String maxConnections;
  final String allowedOutputFormats;

  const UserInfo({
    required this.username,
    required this.password,
    required this.message,
    required this.auth,
    required this.status,
    required this.expDate,
    required this.isTrial,
    required this.activeCons,
    required this.createdAt,
    required this.maxConnections,
    required this.allowedOutputFormats,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      username: json['username']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      auth: _parseInt(json['auth']),
      status: json['status']?.toString() ?? '',
      expDate: json['exp_date']?.toString() ?? '',
      isTrial: json['is_trial']?.toString() ?? '0',
      activeCons: json['active_cons']?.toString() ?? '0',
      createdAt: json['created_at']?.toString() ?? '',
      maxConnections: json['max_connections']?.toString() ?? '0',
      allowedOutputFormats: json['allowed_output_formats']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  bool get isActive => auth == 1 && status == 'Active';
}
