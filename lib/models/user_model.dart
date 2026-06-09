class UserModel {
  final String name;
  final String email;

  const UserModel({
    required this.name,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        name: json['name'] as String,
        email: json['email'] as String,
      );
}
