class User {
  String? id;
  String? name;
  String email;
  //bool isVerified;
  //String password;

  User({
    this.id,
    required this.email,
    this.name,
    //required this.password,
    //required this.isVerified,
  });
  
  factory User.fromJson(Map<String, dynamic> json){
    return User(
      id: json['id'],
      email: json['email'],
      name: json['userName'],
      //isVerified: json['isVerified'],
      //password: json['password'],
    );
  }
}