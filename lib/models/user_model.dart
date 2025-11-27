class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "name": name,
      "email": email,
      "phone": phone,
      "role": role,
      "createdAt": DateTime.now(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map["uid"],
      name: map["name"],
      email: map["email"],
      phone: map["phone"],
      role: map["role"],
    );
  }
}
