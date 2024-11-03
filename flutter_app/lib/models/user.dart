class User {
  String? id;
  String name;
  String email;
  String password;

  User({
    this.id,
    required this.email,
    required this.name,
    required this.password,
  });
  
  factory User.fromJson(Map<String, dynamic> json){
    return User(
      id: json['id'],
      email: json['email'],
      name: json['userName'],
      password: json['password'],
    );
  }
}