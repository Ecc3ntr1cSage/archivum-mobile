class Account {
  final String? id;
  final String? userId;
  final String title;
  final String method;
  final String? email;
  final String? username;
  final String? password;
  final String? provider;
  final DateTime? createdAt;

  Account({
    this.id,
    this.userId,
    required this.title,
    required this.method,
    this.email,
    this.username,
    this.password,
    this.provider,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'title': title,
      'method': method,
      if (email != null) 'email': email,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (provider != null) 'provider': provider,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      title: json['title'] ?? '',
      method: json['method'] ?? 'email-auth',
      email: json['email'],
      username: json['username'],
      password: json['password'],
      provider: json['provider'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
}
