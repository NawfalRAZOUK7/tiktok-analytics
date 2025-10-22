/// Authentication data models

class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final DateTime dateJoined;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName = '',
    this.lastName = '',
    required this.dateJoined,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      dateJoined: DateTime.parse(json['date_joined'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'date_joined': dateJoined.toIso8601String(),
    };
  }

  String get displayName {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    }
    return username;
  }
}

class AuthResponse {
  final User user;
  final String token;
  final String message;

  AuthResponse({
    required this.user,
    required this.token,
    required this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
      message: json['message'] as String? ?? '',
    );
  }
}

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String password2;
  final String? firstName;
  final String? lastName;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.password2,
    this.firstName,
    this.lastName,
  });

  Map<String, dynamic> toJson() {
    final data = {
      'username': username,
      'email': email,
      'password': password,
      'password2': password2,
    };
    if (firstName != null && firstName!.isNotEmpty) {
      data['first_name'] = firstName!;
    }
    if (lastName != null && lastName!.isNotEmpty) {
      data['last_name'] = lastName!;
    }
    return data;
  }
}

class ChangePasswordRequest {
  final String oldPassword;
  final String newPassword;
  final String newPassword2;

  ChangePasswordRequest({
    required this.oldPassword,
    required this.newPassword,
    required this.newPassword2,
  });

  Map<String, dynamic> toJson() {
    return {
      'old_password': oldPassword,
      'new_password': newPassword,
      'new_password2': newPassword2,
    };
  }
}
