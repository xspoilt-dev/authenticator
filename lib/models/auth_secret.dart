class AuthSecret {
  final String id;
  final String name;
  final String issuer;
  final String secret;
  final int digits;
  final int period;

  AuthSecret({
    required this.id,
    required this.name,
    required this.issuer,
    required this.secret,
    this.digits = 6,
    this.period = 30,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'issuer': issuer,
      'secret': secret,
      'digits': digits,
      'period': period,
    };
  }

  factory AuthSecret.fromJson(Map<String, dynamic> json) {
    return AuthSecret(
      id: json['id'],
      name: json['name'],
      issuer: json['issuer'],
      secret: json['secret'],
      digits: json['digits'] ?? 6,
      period: json['period'] ?? 30,
    );
  }
}
